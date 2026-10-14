import 'package:flutter_test/flutter_test.dart';
import 'package:roadcare/src/ai_analysis_service.dart';
import 'package:roadcare/src/models.dart';

void main() {
  test('parses accepted Azure Foundry analysis', () {
    final result = RoadDamageAnalysis.fromJson({
      'accepted': true,
      'damageType': 'alligator_crack',
      'confidence': .91,
      'severity': 'critical',
      'severityScore': 89,
      'priorityScore': 90,
      'healthScore': 11,
      'summary': 'Wide interconnected cracking across the lane.',
      'rejectionReason': '',
      'provider': 'Azure AI Foundry',
      'model': 'gpt-4.1-mini',
    });

    expect(result.accepted, isTrue);
    expect(result.damageType, DamageType.alligatorCrack);
    expect(result.confidencePercent, 91);
    expect(result.priorityScore, 90);
  });

  test('parses a rejected unrelated image without inventing damage', () {
    final result = RoadDamageAnalysis.fromJson({
      'accepted': false,
      'damageType': null,
      'confidence': .98,
      'severity': 'low',
      'severityScore': 0,
      'priorityScore': 0,
      'healthScore': 100,
      'summary': 'Indoor selfie.',
      'rejectionReason': 'Upload a clear photo of a road surface.',
      'provider': 'Azure AI Foundry',
      'model': 'gpt-4.1-mini',
    });

    expect(result.accepted, isFalse);
    expect(result.damageType, isNull);
    expect(result.priorityScore, 0);
  });
}
