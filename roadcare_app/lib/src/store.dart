import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  List<RoadIncident> build() => _demoIncidents;
  void add(RoadIncident incident) => state = [incident, ...state];
  void transition(
    String id,
    IncidentStatus next,
    String action, {
    String? team,
    String? repairImagePath,
  }) {
    state = [
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
    if (next == IncidentStatus.closed) {
      final completed = state.firstWhere((incident) => incident.id == id);
      NotificationService.instance.showRepairCompleted(completed);
    }
  }
}

final _now = DateTime.now();
final _demoIncidents = <RoadIncident>[
  RoadIncident(
    id: 'RD-1048',
    roadName: 'Mailoor Main Road',
    area: 'Near ITI Campus, Bidar',
    type: DamageType.pothole,
    severity: Severity.critical,
    status: IncidentStatus.pendingVerification,
    confidence: .92,
    latitude: 17.9133,
    longitude: 77.5301,
    reportedAt: _now.subtract(const Duration(minutes: 28)),
    priorityScore: 94,
    healthScore: 38,
    description: 'Large visible pothole affecting the left traffic lane. Officer inspection required.',
    reporterName: 'Rahul Patil',
    reporterEmail: 'citizen@roadcare.app',
    assignedTeam: null,
    timeline: [
      TimelineEvent(
        title: 'AI analysis completed',
        detail: 'YOLOv8-Small-RDD2022 · 92% confidence',
        time: _now.subtract(const Duration(minutes: 25)),
      ),
      TimelineEvent(
        title: 'Evidence uploaded',
        detail: 'GPS and timestamp validated',
        time: _now.subtract(const Duration(minutes: 28)),
      ),
    ],
  ),
  RoadIncident(
    id: 'RD-1047',
    roadName: 'Udgir Road',
    area: 'Gandhi Nagar',
    type: DamageType.alligatorCrack,
    severity: Severity.high,
    status: IncidentStatus.inProgress,
    confidence: .86,
    latitude: 17.9181,
    longitude: 77.5194,
    reportedAt: _now.subtract(const Duration(hours: 5)),
    priorityScore: 82,
    healthScore: 51,
    description: 'Interconnected cracking across an approximately 2.5 metre road-surface area.',
    reporterName: 'Meera Kulkarni',
    reporterEmail: 'meera@example.com',
    assignedTeam: 'Team Shakti',
    timeline: [
      TimelineEvent(
        title: 'Repair started',
        detail: 'Team Shakti checked in on site',
        time: _now.subtract(const Duration(hours: 1)),
      ),
      TimelineEvent(
        title: 'Work assigned',
        detail: 'Target completion: today',
        time: _now.subtract(const Duration(hours: 3)),
      ),
    ],
  ),
  RoadIncident(
    id: 'RD-1042',
    roadName: 'Station Road',
    area: 'Old City, Bidar',
    type: DamageType.transverseCrack,
    severity: Severity.medium,
    status: IncidentStatus.awaitingClosure,
    confidence: .78,
    latitude: 17.9225,
    longitude: 77.5168,
    reportedAt: _now.subtract(const Duration(days: 1, hours: 2)),
    priorityScore: 61,
    healthScore: 67,
    description:
        'Transverse crack crossing approximately half of the carriageway.',
    reporterName: 'Rahul Patil',
    reporterEmail: 'citizen@roadcare.app',
    assignedTeam: 'Team Veera',
    timeline: [
      TimelineEvent(
        title: 'Completion evidence added',
        detail: 'Before/after photos ready for review',
        time: _now.subtract(const Duration(hours: 2)),
      ),
      TimelineEvent(
        title: 'Repair started',
        detail: 'Surface cleaned and sealed',
        time: _now.subtract(const Duration(hours: 6)),
      ),
    ],
  ),
  RoadIncident(
    id: 'RD-1036',
    roadName: 'Hyderabad Road',
    area: 'Naubad',
    type: DamageType.longitudinalCrack,
    severity: Severity.low,
    status: IncidentStatus.closed,
    confidence: .81,
    latitude: 17.9008,
    longitude: 77.5417,
    reportedAt: _now.subtract(const Duration(days: 4)),
    priorityScore: 34,
    healthScore: 78,
    description: 'Narrow longitudinal surface crack along the road edge.',
    reporterName: 'Sanjay Rao',
    reporterEmail: 'sanjay@example.com',
    assignedTeam: 'Team Shakti',
    timeline: [
      TimelineEvent(
        title: 'Case closed',
        detail: 'Repair verified by municipal officer',
        time: _now.subtract(const Duration(days: 2)),
      ),
      TimelineEvent(
        title: 'Completion evidence added',
        detail: 'Seal verified at the same GPS location',
        time: _now.subtract(const Duration(days: 2, hours: 2)),
      ),
    ],
  ),
];
