import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'incident_detail_screen.dart';

class CitizenDashboardScreen extends ConsumerWidget {
  const CitizenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;
    final reports = ref
        .watch(incidentProvider)
        .where((incident) => incident.reporterEmail == user.email)
        .toList();
    final open = reports
        .where(
          (item) =>
              item.status != IncidentStatus.closed &&
              item.status != IncidentStatus.rejected,
        )
        .length;
    final repaired = reports
        .where((item) => item.status == IncidentStatus.closed)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          PageHeader(
            eyebrow: 'Hello, ${user.name.split(' ').first}',
            title: 'My road reports',
            action: IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track every update',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'From municipal review to completed repair',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 142,
            child: Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Submitted',
                    value: '${reports.length}',
                    icon: Icons.upload_file_rounded,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'In progress',
                    value: '$open',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'Repaired',
                    value: '$repaired',
                    icon: Icons.task_alt_rounded,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionTitle('Latest progress'),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            const _EmptyReports()
          else
            ...reports
                .take(3)
                .map(
                  (incident) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProgressCard(incident: incident),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.incident});
  final RoadIncident incident;

  double get progress => switch (incident.status) {
    IncidentStatus.pendingVerification => .12,
    IncidentStatus.underReview => .28,
    IncidentStatus.approved => .45,
    IncidentStatus.assigned => .58,
    IncidentStatus.inProgress => .72,
    IncidentStatus.awaitingClosure => .88,
    IncidentStatus.closed => 1,
    IncidentStatus.rejected => 1,
  };

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(incidentId: incident.id),
        ),
      ),
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
              '${incident.id} · ${incident.type.label}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(Icons.update_rounded, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    incident.timeline.first.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No reports yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap Report to submit road damage and track its progress here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
