import 'dart:convert';
import 'package:http/http.dart' as http;

class ContentGenerationResponse {
  final int statusCode;
  final Map<String, dynamic> result;

  const ContentGenerationResponse({
    required this.statusCode,
    required this.result,
  });
}

class ContentRequestException implements Exception {
  final int statusCode;
  final String body;

  const ContentRequestException({
    required this.statusCode,
    required this.body,
  });

  @override
  String toString() {
    return 'ContentRequestException(statusCode: $statusCode, body: $body)';
  }
}

class ContentService {
  static const String baseUrl = 'http://localhost:3000';

  Future<ContentGenerationResponse> generateContent({
    required String content,
    required String mode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/generate');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'content': content, 'mode': mode}),
    );

    if (response.statusCode != 200) {
      throw ContentRequestException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'];

    if (result is Map<String, dynamic>) {
      return ContentGenerationResponse(
        statusCode: response.statusCode,
        result: result,
      );
    }

    throw Exception('La respuesta no tuvo el formato esperado.');
  }
}
