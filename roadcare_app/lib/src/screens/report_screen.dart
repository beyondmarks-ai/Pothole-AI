import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final road = TextEditingController();
  final notes = TextEditingController();
  XFile? image;
  Position? position;
  bool locating = false;
  bool submitting = false;

  @override
  void dispose() {
    road.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final selected = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
    );
    if (selected != null && mounted) {
      setState(() => image = selected);
    }
  }

  Future<void> _locate() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Enable location services first.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }
      final result = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() => position = result);
      }
    } catch (error) {
      if (mounted) {
        showAppMessage(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          success: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => locating = false);
      }
    }
  }

  Future<void> _submit() async {
    if (image == null || road.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Add road evidence and the road name.',
        success: false,
      );
      return;
    }
    setState(() => submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    final reporter = ref.read(sessionProvider)!;
    final incident = RoadIncident(
      id: 'RD-${1050 + now.second}',
      roadName: road.text.trim(),
      area: position == null
          ? 'Location requires verification'
          : 'GPS captured on device',
      type: DamageType.pothole,
      severity: Severity.high,
      status: IncidentStatus.pendingVerification,
      confidence: .89,
      latitude: position?.latitude ?? 17.9133,
      longitude: position?.longitude ?? 77.5301,
      reportedAt: now,
      priorityScore: 84,
      healthScore: 48,
      description: notes.text.trim().isEmpty
          ? 'AI detected a visible pothole. Officer verification is required.'
          : notes.text.trim(),
      reporterName: reporter.name,
      reporterEmail: reporter.email,
      assignedTeam: null,
      imagePath: image!.path,
      timeline: [
        TimelineEvent(
          title: 'AI analysis completed',
          detail: 'Pretrained YOLOv8 RDD model · 89% confidence',
          time: now,
        ),
        TimelineEvent(
          title: 'Mobile evidence uploaded',
          detail: position == null
              ? 'Manual location follow-up required'
              : 'GPS and timestamp recorded',
          time: now,
        ),
      ],
    );
    ref.read(incidentProvider.notifier).add(incident);
    if (!mounted) return;
    setState(() => submitting = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.auto_awesome_rounded,
          size: 42,
          color: AppColors.teal,
        ),
        title: const Text('Analysis complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A provisional incident has been created for officer verification.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    const _Result(label: 'Damage', value: 'Pothole'),
                    const Divider(),
                    const _Result(label: 'AI confidence', value: '89%'),
                    const Divider(),
                    _Result(
                      label: 'Priority',
                      value: '${incident.priorityScore} / 100',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report road damage')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Text(
          'Capture clear evidence',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 7),
        const Text(
          'AI findings remain provisional until a municipal officer verifies the case.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _sourceSheet(context),
          child: Container(
            height: 230,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: .45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Take a photo or choose from gallery',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'JPG or PNG · Good lighting recommended',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(image!.path), fit: BoxFit.cover),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: IconButton.filled(
                          onPressed: () => setState(() => image = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: road,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Road or street name',
            prefixIcon: Icon(Icons.add_road_rounded),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: locating
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
            title: Text(
              position == null
                  ? 'Attach current GPS location'
                  : 'GPS location attached',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              position == null
                  ? 'Required for reliable road matching'
                  : '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}',
            ),
            trailing: TextButton(
              onPressed: locating ? null : _locate,
              child: Text(position == null ? 'Locate' : 'Refresh'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: notes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Observation notes (optional)',
            alignLabelWithHint: true,
            hintText: 'Lane, direction, nearby landmark...',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.amber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'For better results, keep the camera steady and include the surrounding road surface.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: submitting ? null : _submit,
          icon: submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(
            submitting ? 'Analysing evidence...' : 'Analyse and create case',
          ),
        ),
      ),
    ),
  );

  void _sourceSheet(BuildContext context) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Row(
        children: [
          Expanded(
            child: _SourceButton(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SourceButton(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label),
      const Spacer(),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}
