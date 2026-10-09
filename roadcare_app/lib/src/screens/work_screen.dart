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
    final items = ref
        .watch(incidentProvider)
        .where(
          (e) =>
              e.status == IncidentStatus.assigned ||
              e.status == IncidentStatus.inProgress ||
              e.status == IncidentStatus.awaitingClosure,
        )
        .toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          const PageHeader(
            eyebrow: 'Field operations',
            title: 'Maintenance work',
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
                        '${items.length} active assignments',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '1 due today · 0 overdue',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Current queue'),
          const SizedBox(height: 12),
          ...items.map(
            (incident) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IncidentCard(
                incident: incident,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        IncidentDetailScreen(incidentId: incident.id),
                  ),
                ),
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No active work orders')),
            ),
        ],
      ),
    );
  }
}
