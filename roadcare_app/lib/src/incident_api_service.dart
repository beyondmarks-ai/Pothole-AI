import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

abstract class IncidentApi {
  Future<List<RoadIncident>> fetch(AppUser user);
  Future<RoadIncident> create(RoadIncident incident);
  Future<RoadIncident> update(RoadIncident incident);
}

class AzureIncidentApi implements IncidentApi {
  AzureIncidentApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'ROADCARE_API_BASE_URL',
            defaultValue:
                'https://roadcare-ai-api-617db5.azurewebsites.net/api',
          );

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<RoadIncident>> fetch(AppUser user) async {
    final uri = Uri.parse('$_baseUrl/incidents').replace(
      queryParameters: {
        'role': user.role.name,
        'email': user.email,
        if (user.role == UserRole.maintenance) 'team': user.name,
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 30));
    final body = _body(response);
    return (body['incidents'] as List<dynamic>)
        .map((item) => RoadIncident.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RoadIncident> create(RoadIncident incident) async {
    final image = await _encodeFile(incident.imagePath);
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/incidents'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'incident': incident.toJson(),
            if (image != null) ...{
              'imageBase64': image.base64,
              'mimeType': image.mimeType,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));
    return RoadIncident.fromJson(
      _body(response)['incident'] as Map<String, dynamic>,
    );
  }

  @override
  Future<RoadIncident> update(RoadIncident incident) async {
    final repair = await _encodeFile(incident.repairImagePath);
    final response = await _client
        .patch(
          Uri.parse('$_baseUrl/incidents/${Uri.encodeComponent(incident.id)}'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'incident': incident.toJson(),
            if (repair != null) ...{
              'repairImageBase64': repair.base64,
              'mimeType': repair.mimeType,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));
    return RoadIncident.fromJson(
      _body(response)['incident'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _body(http.Response response) {
    late Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const IncidentApiException(
        'The cloud service returned invalid data.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw IncidentApiException(
        body['error'] as String? ??
            'The cloud complaint service is unavailable.',
      );
    }
    return body;
  }
}

class IncidentApiException implements Exception {
  const IncidentApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _EncodedFile {
  const _EncodedFile(this.base64, this.mimeType);
  final String base64;
  final String mimeType;
}

Future<_EncodedFile?> _encodeFile(String? path) async {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!await file.exists()) return null;
  final bytes = await file.readAsBytes();
  final lower = path.toLowerCase();
  final mimeType = lower.endsWith('.png')
      ? 'image/png'
      : lower.endsWith('.webp')
      ? 'image/webp'
      : 'image/jpeg';
  return _EncodedFile(base64Encode(bytes), mimeType);
}
