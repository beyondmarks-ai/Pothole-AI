import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'incident_detail_screen.dart';

class WorkScreen extends ConsumerWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;
    final items = ref
        .watch(incidentProvider)
        .where(
          (incident) =>
              incident.assignedTeam == user.name &&
              (incident.status == IncidentStatus.assigned ||
                  incident.status == IncidentStatus.inProgress ||
                  incident.status == IncidentStatus.awaitingClosure),
        )
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          PageHeader(eyebrow: 'Assigned repair team', title: user.name),
          const SizedBox(height: 8),
          const Text(
            'Update only the repair jobs assigned to your team.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.engineering_rounded,
                  size: 38,
                  color: Colors.white,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${items.length} active ${items.length == 1 ? 'job' : 'jobs'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Open a job to post its latest progress',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('My assigned jobs'),
          const SizedBox(height: 6),
          const Text(
            'Start the repair when you arrive, then upload completion evidence when the work is finished.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (incident) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AssignedJobCard(incident: incident),
            ),
          ),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.task_alt_rounded, color: AppColors.teal),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('No active jobs are assigned to your team.'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignedJobCard extends StatelessWidget {
  const _AssignedJobCard({required this.incident});

  final RoadIncident incident;

  String get actionLabel => switch (incident.status) {
    IncidentStatus.assigned => 'Start repair work',
    IncidentStatus.inProgress => 'Upload completion update',
    IncidentStatus.awaitingClosure => 'Waiting for officer approval',
    _ => 'Open job',
  };

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.roadName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(status: incident.status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${incident.id} • ${incident.area}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IncidentDetailScreen(incidentId: incident.id),
                ),
              ),
              icon: Icon(
                incident.status == IncidentStatus.awaitingClosure
                    ? Icons.hourglass_top_rounded
                    : Icons.update_rounded,
              ),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    ),
  );
}
