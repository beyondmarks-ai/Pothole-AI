import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'incident_detail_screen.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentProvider);
    return SafeArea(
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(17.9133, 77.5301),
              initialZoom: 13.3,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gecb.roadcare',
              ),
              MarkerLayer(
                markers: incidents
                    .map(
                      (incident) => Marker(
                        point: LatLng(incident.latitude, incident.longitude),
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _open(context, incident),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _severityColor(incident.severity),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.priority_high_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface
                    .withValues(alpha: .96),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live incident map',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${incidents.length} cases · Bidar jurisdiction',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 92,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _Legend(color: AppColors.teal, label: 'Low'),
                    _Legend(color: AppColors.amber, label: 'Medium'),
                    _Legend(color: Color(0xFFEE7B30), label: 'High'),
                    _Legend(color: AppColors.danger, label: 'Critical'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, RoadIncident incident) =>
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.roadName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  SeverityPill(severity: incident.severity),
                ],
              ),
              const SizedBox(height: 6),
              Text('${incident.id} · ${incident.area}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusPill(status: incident.status),
                  const Spacer(),
                  Text(
                    'Priority ${incident.priorityScore}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            IncidentDetailScreen(incidentId: incident.id),
                      ),
                    );
                  },
                  child: const Text('Open case'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

Color _severityColor(Severity severity) => switch (severity) {
  Severity.low => AppColors.teal,
  Severity.medium => AppColors.amber,
  Severity.high => const Color(0xFFEE7B30),
  Severity.critical => AppColors.danger,
};
