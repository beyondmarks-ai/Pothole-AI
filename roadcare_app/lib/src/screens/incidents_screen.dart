import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../store.dart';
import '../widgets.dart';
import 'incident_detail_screen.dart';

class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key, this.onlyMine = false});
  final bool onlyMine;
  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  String query = '';
  IncidentStatus? filter;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(incidentProvider);
    final user = ref.watch(sessionProvider)!;
    final items = all.where((item) {
      final matchText =
          '${item.id} ${item.roadName} ${item.area} ${item.type.label}'
              .toLowerCase()
              .contains(query.toLowerCase());
      final owned = !widget.onlyMine || item.reporterEmail == user.email;
      return owned && matchText && (filter == null || item.status == filter);
    }).toList();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              children: [
                PageHeader(
                  eyebrow: widget.onlyMine ? 'Your submissions' : 'All records',
                  title: widget.onlyMine ? 'My reports' : 'Incident cases',
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search road, case or damage',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: filter == null,
                        onTap: () => setState(() => filter = null),
                      ),
                      ...[
                        IncidentStatus.pendingVerification,
                        IncidentStatus.underReview,
                        IncidentStatus.approved,
                        IncidentStatus.inProgress,
                        IncidentStatus.awaitingClosure,
                        IncidentStatus.closed,
                      ].map(
                        (status) => _FilterChip(
                          label: status.label,
                          selected: filter == status,
                          onTap: () => setState(() => filter = status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No matching cases'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => IncidentCard(
                      incident: items[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              IncidentDetailScreen(incidentId: items[index].id),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: selected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
    ),
  );
}
