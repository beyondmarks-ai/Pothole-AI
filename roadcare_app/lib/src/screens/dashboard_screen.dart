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
    final pending = incidents
        .where((e) => e.status == IncidentStatus.pendingVerification)
        .length;
    final active = incidents
        .where(
          (e) =>
              e.status == IncidentStatus.inProgress ||
              e.status == IncidentStatus.assigned,
        )
        .length;
    final critical = incidents
        .where((e) => e.severity == Severity.critical)
        .length;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                PageHeader(
                  eyebrow: 'Good morning, ${user.name.split(' ').first}',
                  title: 'Road operations',
                  action: Stack(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                      Positioned(
                        right: 8,
                        top: 7,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navy, AppColors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CITY CONDITION',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '67 / 100',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Road health requires attention',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 15),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: const LinearProgressIndicator(
                                value: .67,
                                minHeight: 7,
                                color: AppColors.teal,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_road_rounded,
                          color: Colors.white,
                          size: 36,
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
                          label: 'Pending',
                          value: '$pending',
                          icon: Icons.fact_check_outlined,
                          color: AppColors.amber,
                          caption: 'Need review',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: 'Active work',
                          value: '$active',
                          icon: Icons.construction_rounded,
                          color: const Color(0xFF7B61FF),
                          caption: 'On field',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: 'Critical',
                          value: '$critical',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          caption: 'High priority',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle('Priority queue'),
                const SizedBox(height: 12),
                ...incidents
                    .take(3)
                    .map(
                      (incident) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IncidentCard(
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
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
