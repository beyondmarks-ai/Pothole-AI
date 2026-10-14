import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'incident_api_service.dart';
import 'models.dart';
import 'notification_service.dart';

final sessionProvider = NotifierProvider<SessionController, AppUser?>(
  SessionController.new,
);
final incidentProvider =
    NotifierProvider<IncidentController, List<RoadIncident>>(
      IncidentController.new,
    );
final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
final incidentApiProvider = Provider<IncidentApi>((ref) => AzureIncidentApi());

class SessionController extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;
  void signIn(String email, UserRole role) => state = AppUser(
    name: switch (role) {
      UserRole.citizen => 'Rahul Patil',
      UserRole.maintenance => 'Team Shakti',
      UserRole.officer || UserRole.administrator => 'Ananya Rao',
    },
    email: email.trim().isEmpty
        ? role == UserRole.citizen
              ? 'citizen@roadcare.app'
              : 'officer@roadcare.gov.in'
        : email.trim(),
    role: role,
  );
  void signOut() => state = null;
}

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;
  void toggle(bool dark) => state = dark ? ThemeMode.dark : ThemeMode.light;
}

class IncidentController extends Notifier<List<RoadIncident>> {
  @override
  List<RoadIncident> build() => const [];

  Future<void> refresh() async {
    final user = ref.read(sessionProvider);
    if (user == null) return;
    try {
      final previous = {for (final incident in state) incident.id: incident};
      final fetched = await ref.read(incidentApiProvider).fetch(user);
      state = fetched;
      if (user.role == UserRole.citizen) {
        for (final incident in fetched) {
          final oldStatus = previous[incident.id]?.status;
          if (incident.status == IncidentStatus.closed &&
              oldStatus != null &&
              oldStatus != IncidentStatus.closed) {
            NotificationService.instance.showRepairCompleted(incident);
          }
        }
      }
    } catch (_) {
      // Keep the last successful snapshot when the network is temporarily down.
    }
  }

  Future<RoadIncident> add(RoadIncident incident) async {
    final saved = await ref.read(incidentApiProvider).create(incident);
    state = [saved, ...state.where((item) => item.id != saved.id)];
    return saved;
  }

  Future<void> transition(
    String id,
    IncidentStatus next,
    String action, {
    String? team,
    String? repairImagePath,
  }) async {
    final before = state;
    final updated = [
      for (final incident in state)
        if (incident.id == id)
          incident.copyWith(
            status: next,
            assignedTeam: team,
            repairImagePath: repairImagePath,
            timeline: [
              TimelineEvent(
                title: action,
                detail: 'Updated in RoadCare mobile',
                time: DateTime.now(),
              ),
              ...incident.timeline,
            ],
          )
        else
          incident,
    ];
    state = updated;
    try {
      final pending = updated.firstWhere((incident) => incident.id == id);
      final saved = await ref.read(incidentApiProvider).update(pending);
      state = [
        for (final incident in state)
          if (incident.id == id) saved else incident,
      ];
    } catch (_) {
      state = before;
      return;
    }
  }
}
