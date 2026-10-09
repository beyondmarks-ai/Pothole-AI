import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref
        .watch(incidentProvider)
        .firstWhere((item) => item.id == incidentId);
    return Scaffold(
      appBar: AppBar(
        title: Text(incident.id),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            height: 205,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF314657), Color(0xFF162630)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: Icon(
                    Icons.add_road_rounded,
                    size: 92,
                    color: Colors.white12,
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(incident.confidence * 100).round()}% AI confidence',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.type.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Annotated evidence preview',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () {},
                        icon: const Icon(Icons.fullscreen_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.roadName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.area,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              SeverityPill(severity: incident.severity),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value:
                        '${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.speed_rounded,
                    label: 'Priority score',
                    value: '${incident.priorityScore} / 100',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Road health',
                    value: '${incident.healthScore} / 100',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.engineering_outlined,
                    label: 'Assigned team',
                    value: incident.assignedTeam ?? 'Not assigned',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Reported by',
                    value: incident.reporterName,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Assessment'),
          const SizedBox(height: 10),
          Text(incident.description),
          const SizedBox(height: 22),
          const SectionTitle('Audit timeline'),
          const SizedBox(height: 10),
          ...incident.timeline.asMap().entries.map(
            (entry) => _Timeline(
              event: entry.value,
              last: entry.key == incident.timeline.length - 1,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _ActionBar(incident: incident),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 19,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.event, required this.last});
  final TimelineEvent event;
  final bool last;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 3,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  event.detail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d MMM · h:mm a').format(event.time),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.incident});
  final RoadIncident incident;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(incidentProvider.notifier);
    final role = ref.watch(sessionProvider)!.role;

    if (role == UserRole.citizen) {
      return _ReadOnlyStatus(
        icon: Icons.notifications_active_outlined,
        text:
            'You will be notified when the municipal team updates this report.',
      );
    }

    final municipal =
        role == UserRole.officer || role == UserRole.administrator;
    if (!municipal) {
      return _maintenanceAction(context, controller);
    }

    switch (incident.status) {
      case IncidentStatus.pendingVerification:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              controller.transition(
                incident.id,
                IncidentStatus.underReview,
                'Manual review started by municipal officer',
              );
              showAppMessage(context, 'Manual review started');
            },
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Start manual review'),
          ),
        );
      case IncidentStatus.underReview:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  controller.transition(
                    incident.id,
                    IncidentStatus.rejected,
                    'Report rejected after manual review',
                  );
                  showAppMessage(context, 'Report rejected');
                },
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  controller.transition(
                    incident.id,
                    IncidentStatus.approved,
                    'Case approved after manual review',
                  );
                  showAppMessage(context, 'Case approved');
                },
                icon: const Icon(Icons.approval_rounded),
                label: const Text('Approve case'),
              ),
            ),
          ],
        );
      case IncidentStatus.approved:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _assign(context, controller),
            icon: const Icon(Icons.assignment_ind_rounded),
            label: const Text('Assign maintenance team'),
          ),
        );
      case IncidentStatus.assigned:
        return const _ReadOnlyStatus(
          icon: Icons.engineering_rounded,
          text: 'Assigned team will update repair progress.',
        );
      case IncidentStatus.inProgress:
        return const _ReadOnlyStatus(
          icon: Icons.construction_rounded,
          text: 'Repair work is currently in progress.',
        );
      case IncidentStatus.awaitingClosure:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  controller.transition(
                    incident.id,
                    IncidentStatus.inProgress,
                    'Further work requested',
                  );
                  showAppMessage(context, 'Returned for further work');
                },
                child: const Text('Request rework'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  controller.transition(
                    incident.id,
                    IncidentStatus.closed,
                    'Case closed by officer',
                  );
                  showAppMessage(context, 'Case closed successfully');
                },
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Approve closure'),
              ),
            ),
          ],
        );
      case IncidentStatus.closed:
      case IncidentStatus.rejected:
        return OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.archive_outlined),
          label: Text('Case ${incident.status.label.toLowerCase()}'),
        );
    }
  }

  Widget _maintenanceAction(
    BuildContext context,
    IncidentController controller,
  ) {
    if (incident.status == IncidentStatus.assigned) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            controller.transition(
              incident.id,
              IncidentStatus.inProgress,
              'Repair work started by ${incident.assignedTeam ?? 'maintenance team'}',
            );
            showAppMessage(context, 'Work marked in progress');
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start repair work'),
        ),
      );
    }
    if (incident.status == IncidentStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            controller.transition(
              incident.id,
              IncidentStatus.awaitingClosure,
              'Completion evidence uploaded by maintenance team',
            );
            showAppMessage(context, 'Sent for officer verification');
          },
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('Add repair evidence'),
        ),
      );
    }
    return _ReadOnlyStatus(
      icon: Icons.schedule_rounded,
      text: incident.status == IncidentStatus.awaitingClosure
          ? 'Waiting for municipal closure approval.'
          : 'No maintenance action is required at this stage.',
    );
  }

  void _assign(BuildContext context, IncidentController controller) =>
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign maintenance team',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              ...['Team Shakti', 'Team Veera', 'Ward 6 Rapid Unit'].map(
                (team) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(team.substring(5, 6))),
                  title: Text(team),
                  subtitle: const Text('Available today'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.transition(
                      incident.id,
                      IncidentStatus.assigned,
                      'Work assigned to $team',
                      team: team,
                    );
                    Navigator.pop(context);
                    showAppMessage(context, 'Assigned to $team');
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _ReadOnlyStatus extends StatelessWidget {
  const _ReadOnlyStatus({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
