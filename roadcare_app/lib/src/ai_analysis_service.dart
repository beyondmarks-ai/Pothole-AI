import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'models.dart';

class RoadDamageAnalysis {
  const RoadDamageAnalysis({
    required this.accepted,
    required this.damageType,
    required this.confidence,
    required this.severity,
    required this.severityScore,
    required this.priorityScore,
    required this.healthScore,
    required this.summary,
    required this.rejectionReason,
    required this.provider,
    required this.model,
  });

  factory RoadDamageAnalysis.fromJson(Map<String, dynamic> json) {
    final damageName = json['damageType'] as String?;
    return RoadDamageAnalysis(
      accepted: json['accepted'] == true,
      damageType: damageName == null ? null : _damageType(damageName),
      confidence: (json['confidence'] as num? ?? 0).toDouble().clamp(0, 1),
      severity: _severity(json['severity'] as String? ?? 'low'),
      severityScore: (json['severityScore'] as num? ?? 0).round().clamp(0, 100),
      priorityScore: (json['priorityScore'] as num? ?? 0).round().clamp(0, 100),
      healthScore: (json['healthScore'] as num? ?? 100).round().clamp(0, 100),
      summary: json['summary'] as String? ?? '',
      rejectionReason:
          json['rejectionReason'] as String? ?? 'This image was not accepted.',
      provider: json['provider'] as String? ?? 'Azure AI Foundry',
      model: json['model'] as String? ?? 'gpt-4.1-mini',
    );
  }

  final bool accepted;
  final DamageType? damageType;
  final double confidence;
  final Severity severity;
  final int severityScore;
  final int priorityScore;
  final int healthScore;
  final String summary;
  final String rejectionReason;
  final String provider;
  final String model;

  int get confidencePercent => (confidence * 100).round();
}

class AiAnalysisException implements Exception {
  const AiAnalysisException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RoadDamageAiService {
  RoadDamageAiService({http.Client? client, String? endpoint})
    : _client = client ?? http.Client(),
      _endpoint =
          endpoint ??
          const String.fromEnvironment(
            'ROADCARE_AI_API_URL',
            defaultValue:
                'https://roadcare-ai-api-617db5.azurewebsites.net/api/analyze',
          );

  final http.Client _client;
  final String _endpoint;

  Future<RoadDamageAnalysis> analyze(XFile image) async {
    if (_endpoint.isEmpty) {
      throw const AiAnalysisException(
        'AI analysis is not configured in this app build.',
      );
    }
    final bytes = await File(image.path).readAsBytes();
    if (bytes.isEmpty) {
      throw const AiAnalysisException('The selected image could not be read.');
    }
    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'imageBase64': base64Encode(bytes),
            'mimeType': _mimeType(image.path),
          }),
        )
        .timeout(const Duration(seconds: 50));
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const AiAnalysisException('The AI service returned invalid data.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiAnalysisException(
        body['error'] as String? ??
            'Image analysis is temporarily unavailable.',
      );
    }
    return RoadDamageAnalysis.fromJson(body);
  }
}

String _mimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

DamageType _damageType(String value) => switch (value) {
  'longitudinal_crack' => DamageType.longitudinalCrack,
  'transverse_crack' => DamageType.transverseCrack,
  'alligator_crack' => DamageType.alligatorCrack,
  _ => DamageType.pothole,
};

Severity _severity(String value) => switch (value) {
  'critical' => Severity.critical,
  'high' => Severity.high,
  'medium' => Severity.medium,
  _ => Severity.low,
};
