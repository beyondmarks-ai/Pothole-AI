import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../ai_analysis_service.dart';
import '../models.dart';
import '../notification_service.dart';
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
  RoadDamageAnalysis? analysis;
  String? analysisError;
  Position? position;
  String? locationName;
  bool locating = false;
  bool analyzing = false;
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
      setState(() {
        image = selected;
        analysis = null;
        analysisError = null;
      });
      await _analyze(selected);
    }
  }

  Future<RoadDamageAnalysis?> _analyze(XFile selected) async {
    setState(() {
      analyzing = true;
      analysisError = null;
    });
    try {
      final result = await RoadDamageAiService().analyze(selected);
      if (!mounted || image?.path != selected.path) return null;
      setState(() => analysis = result);
      return result;
    } catch (error) {
      if (!mounted || image?.path != selected.path) return null;
      final message = error is AiAnalysisException
          ? error.message
          : 'Could not analyse this image. Check your connection and retry.';
      setState(() => analysisError = message);
      return null;
    } finally {
      if (mounted && image?.path == selected.path) {
        setState(() => analyzing = false);
      }
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
      String? resolvedAddress;
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (placemarks.isNotEmpty) {
          resolvedAddress = _formatAddress(placemarks.first);
        }
      } catch (_) {
        resolvedAddress = null;
      }
      if (mounted) {
        setState(() {
          position = result;
          locationName = resolvedAddress;
        });
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
    var verified = analysis;
    if (verified == null) {
      verified = await _analyze(image!);
      if (!mounted || verified == null) return;
    }
    if (!verified.accepted || verified.damageType == null) {
      showAppMessage(context, verified.rejectionReason, success: false);
      return;
    }
    final acceptedResult = verified;
    await NotificationService.instance.requestPermission();
    if (!mounted) return;
    setState(() => submitting = true);
    final now = DateTime.now();
    final reporter = ref.read(sessionProvider)!;
    final incident = RoadIncident(
      id: 'RD-${now.millisecondsSinceEpoch}',
      roadName: road.text.trim(),
      area:
          locationName ??
          (position == null
              ? 'Location requires verification'
              : 'Pinned location - address lookup unavailable'),
      type: acceptedResult.damageType!,
      severity: acceptedResult.severity,
      status: IncidentStatus.pendingVerification,
      confidence: acceptedResult.confidence,
      latitude: position?.latitude ?? 17.9133,
      longitude: position?.longitude ?? 77.5301,
      reportedAt: now,
      priorityScore: acceptedResult.priorityScore,
      healthScore: acceptedResult.healthScore,
      description: notes.text.trim().isEmpty
          ? '${acceptedResult.summary} Officer verification is required.'
          : notes.text.trim(),
      reporterName: reporter.name,
      reporterEmail: reporter.email,
      assignedTeam: null,
      imagePath: image!.path,
      timeline: [
        TimelineEvent(
          title: 'AI analysis completed',
          detail:
              '${acceptedResult.provider} ${acceptedResult.model} · ${acceptedResult.confidencePercent}% confidence',
          time: now,
        ),
        TimelineEvent(
          title: 'Mobile evidence uploaded',
          detail: position == null
              ? 'Manual location follow-up required'
              : locationName ?? 'GPS pinned; address lookup unavailable',
          time: now,
        ),
      ],
    );
    try {
      await ref.read(incidentProvider.notifier).add(incident);
    } catch (error) {
      if (!mounted) return;
      setState(() => submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit the report. Check your internet connection and try again.\n$error',
          ),
        ),
      );
      return;
    }
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
                    _Result(
                      label: 'Damage',
                      value: acceptedResult.damageType!.label,
                    ),
                    const Divider(),
                    _Result(
                      label: 'AI confidence',
                      value: '${acceptedResult.confidencePercent}%',
                    ),
                    const Divider(),
                    _Result(
                      label: 'Severity',
                      value: acceptedResult.severity.label,
                    ),
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
                          onPressed: () => setState(() {
                            image = null;
                            analysis = null;
                            analysisError = null;
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (image != null) ...[
          const SizedBox(height: 12),
          _AnalysisCard(
            analyzing: analyzing,
            analysis: analysis,
            error: analysisError,
            onRetry: analyzing ? null : () => _analyze(image!),
          ),
        ],
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
                  : locationName == null
                  ? 'GPS attached - address unavailable'
                  : 'Exact address found',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              position == null
                  ? 'Required for reliable road matching'
                  : locationName ??
                        'Tap Refresh to try the address lookup again',
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
          onPressed: submitting || analyzing || analysis?.accepted == false
              ? null
              : _submit,
          icon: submitting || analyzing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(
            analyzing
                ? 'Checking road evidence...'
                : submitting
                ? 'Creating case...'
                : analysis?.accepted == false
                ? 'Choose a valid road photo'
                : 'Analyse and create case',
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

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analyzing,
    required this.analysis,
    required this.error,
    required this.onRetry,
  });

  final bool analyzing;
  final RoadDamageAnalysis? analysis;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (analyzing) {
      return const Card(
        child: ListTile(
          leading: CircularProgressIndicator(strokeWidth: 2),
          title: Text('GPT-4.1 mini is checking this photo'),
          subtitle: Text(
            'Validating the road scene, damage type, and severity…',
          ),
        ),
      );
    }
    if (error != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.cloud_off_rounded),
          title: const Text('Analysis could not be completed'),
          subtitle: Text(error!),
          trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      );
    }
    final result = analysis;
    if (result == null) return const SizedBox.shrink();
    if (!result.accepted) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.cancel_outlined),
          title: const Text('Photo rejected'),
          subtitle: Text(result.rejectionReason),
          isThreeLine: true,
        ),
      );
    }
    return Card(
      color: AppColors.teal.withValues(alpha: .1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: AppColors.teal),
                SizedBox(width: 8),
                Text(
                  'Verified road damage',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(result.damageType!.label)),
                Chip(label: Text('${result.confidencePercent}% confidence')),
                Chip(label: Text('${result.severity.label} severity')),
                Chip(label: Text('Priority ${result.priorityScore}/100')),
              ],
            ),
            if (result.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(result.summary),
            ],
          ],
        ),
      ),
    );
  }
}

String? _formatAddress(Placemark placemark) {
  final values = <String?>[
    placemark.name,
    placemark.street,
    placemark.subThoroughfare,
    placemark.thoroughfare,
    placemark.subLocality,
    placemark.locality,
    placemark.subAdministrativeArea,
    placemark.administrativeArea,
    placemark.postalCode,
    placemark.country,
  ];
  final seen = <String>{};
  final parts = <String>[];
  for (final value in values) {
    final part = value?.trim();
    if (part == null || part.isEmpty) continue;
    if (seen.add(part.toLowerCase())) parts.add(part);
  }
  return parts.isEmpty ? null : parts.join(', ');
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
