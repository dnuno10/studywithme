import 'dart:convert';
import 'package:http/http.dart' as http;

class ContentService {
  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, dynamic>> generateContent({
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
      throw Exception('Error al generar contenido: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'];

    if (result is Map<String, dynamic>) {
      return result;
    }

    throw Exception('La respuesta no tuvo el formato esperado.');
  }
}
