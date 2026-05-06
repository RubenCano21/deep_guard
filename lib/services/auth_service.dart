import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Excepción lanzada cuando el backend devuelve un error conocido.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Resultado exitoso de login / registro.
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final UserModel? user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });
}

class AuthService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _keyAccess = 'access_token';
  static const String _keyRefresh = 'refresh_token';

  // ─── Token storage ────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, access);
    await prefs.setString(_keyRefresh, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  /// POST /api/auth/login/
  /// Body:   { "correo": "...", "password": "..." }
  /// Expect: { "access": "...", "refresh": "...", "usuario": {...} }
  static Future<AuthResult> login({
    required String correo,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login/');

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthException(
        'No se pudo conectar al servidor. Verifica tu conexión.',
      );
    }

    final body = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final access = body['access'] as String?;
      final refresh = body['refresh'] as String?;

      if (access == null || refresh == null) {
        throw const AuthException('Respuesta del servidor inválida.');
      }

      final result = AuthResult(
        accessToken: access,
        refreshToken: refresh,
        user: body['usuario'] != null
            ? UserModel.fromJson(body['usuario'] as Map<String, dynamic>)
            : null,
      );

      await saveTokens(access: access, refresh: refresh);
      return result;
    }

    throw AuthException(_extractError(body, response.statusCode));
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  /// POST /api/auth/register/
  /// Body:   { "correo": "...", "nombre_usuario": "...",
  ///           "nombre_completo": "...", "password": "..." }
  /// Expect: { "access": "...", "refresh": "...", "usuario": {...} }
  static Future<AuthResult> register({
    required String correo,
    required String nombreUsuario,
    required String nombreCompleto,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register/');

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'correo': correo,
              'nombre_usuario': nombreUsuario,
              'nombre_completo': nombreCompleto,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthException(
        'No se pudo conectar al servidor. Verifica tu conexión.',
      );
    }

    final body = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final access = body['access'] as String?;
      final refresh = body['refresh'] as String?;

      if (access == null || refresh == null) {
        throw const AuthException('Respuesta del servidor inválida.');
      }

      final result = AuthResult(
        accessToken: access,
        refreshToken: refresh,
        user: body['usuario'] != null
            ? UserModel.fromJson(body['usuario'] as Map<String, dynamic>)
            : null,
      );

      await saveTokens(access: access, refresh: refresh);
      return result;
    }

    throw AuthException(_extractError(body, response.statusCode));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _decodeBody(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Extrae el mensaje de error más legible del cuerpo de respuesta.
  static String _extractError(Map<String, dynamic> body, int status) {
    // DRF suele enviar { "detail": "..." } o { "campo": ["error"] }
    if (body.containsKey('detail')) {
      return body['detail'].toString();
    }
    if (body.containsKey('non_field_errors')) {
      final list = body['non_field_errors'];
      if (list is List && list.isNotEmpty) return list.first.toString();
    }
    // Primer campo con error
    for (final entry in body.entries) {
      final val = entry.value;
      if (val is List && val.isNotEmpty) return val.first.toString();
      if (val is String) return val;
    }
    return 'Error $status. Intenta de nuevo.';
  }
}
