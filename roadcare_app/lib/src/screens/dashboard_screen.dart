import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'incident_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentProvider);
    final user = ref.watch(sessionProvider)!;
    final reviewQueue = incidents
        .where(
          (item) =>
              item.status == IncidentStatus.pendingVerification ||
              item.status == IncidentStatus.underReview ||
              item.status == IncidentStatus.awaitingClosure,
        )
        .toList();
    final activeRepairs = incidents
        .where(
          (item) =>
              item.status == IncidentStatus.approved ||
              item.status == IncidentStatus.assigned ||
              item.status == IncidentStatus.inProgress,
        )
        .length;
    final closed = incidents
        .where((item) => item.status == IncidentStatus.closed)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          PageHeader(
            eyebrow: 'Municipal officer',
            title: 'Hello, ${user.name.split(' ').first}',
          ),
          const SizedBox(height: 8),
          const Text(
            'Review citizen reports and move approved cases to repair.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          _ReviewSummary(
            waiting: reviewQueue.length,
            active: activeRepairs,
            closed: closed,
          ),
          const SizedBox(height: 28),
          const SectionTitle('Needs your action'),
          const SizedBox(height: 6),
          const Text(
            'Citizen reports waiting for review or closure approval.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (reviewQueue.isEmpty)
            const _EmptyQueue()
          else
            ...reviewQueue.map(
              (incident) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(
                  incident: incident,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          IncidentDetailScreen(incidentId: incident.id),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.waiting,
    required this.active,
    required this.closed,
  });

  final int waiting;
  final int active;
  final int closed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          _SummaryItem(
            value: waiting,
            label: 'To review',
            color: AppColors.amber,
          ),
          const _SummaryDivider(),
          _SummaryItem(
            value: active,
            label: 'In repair',
            color: AppColors.blue,
          ),
          const _SummaryDivider(),
          _SummaryItem(value: closed, label: 'Closed', color: AppColors.teal),
        ],
      ),
    ),
  );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 42,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.incident, required this.onTap});

  final RoadIncident incident;
  final VoidCallback onTap;

  String get actionLabel => switch (incident.status) {
    IncidentStatus.pendingVerification => 'Review report',
    IncidentStatus.underReview => 'Approve or reject',
    IncidentStatus.awaitingClosure => 'Verify repair',
    _ => 'Open case',
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
            '${incident.area} • Reported by ${incident.reporterName}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SeverityPill(severity: incident.severity),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.task_alt_rounded, color: AppColors.teal),
          SizedBox(width: 12),
          Expanded(child: Text('No reports need your action right now.')),
        ],
      ),
    ),
  );
}
