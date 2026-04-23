import 'dart:convert';
import 'dart:typed_data';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/network/http_client_provider.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_remote_repository.g.dart';

@riverpod
AuthRemoteRepository authRemoteRepository(AuthRemoteRepositoryRef ref) {
  final client = ref.watch(httpClientProvider);
  // FIX: AuthLocalRepository iniettato via costruttore invece di essere
  // istanziato direttamente in ogni getter (bypassava Riverpod DI).
  final localRepository = ref.watch(authLocalRepositoryProvider);
  return AuthRemoteRepository(client, localRepository);
}

class AuthRemoteRepository {
  final http.Client client;
  // FIX: iniettato, non più AuthLocalRepository() ad ogni chiamata.
  final AuthLocalRepository _localRepository;

  AuthRemoteRepository(this.client, this._localRepository);

  // ------------------------------------------------------------------ //
  //  Headers                                                            //
  // ------------------------------------------------------------------ //

  Future<Map<String, String>> _jsonHeaders({bool authenticated = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await _localRepository.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }
      headers['x-auth-token'] = token;
    }

    return headers;
  }

  Map<String, String> _authHeaders(String token) => {
        'Accept': 'application/json',
        'x-auth-token': token,
      };

  // ------------------------------------------------------------------ //
  //  Auth                                                               //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, UserModel>> signup({
    required String name,
    required String email,
    required String password,
    required bool isArtist,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${ServerConstant.serverURL}/auth/signup'),
        headers: await _jsonHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'is_artist': isArtist,
        }),
      );
      return _handleUserResponse(response);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${ServerConstant.serverURL}/auth/login'),
        headers: await _jsonHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        final resBodyMap = _tryParseJson(response.body);
        if (resBodyMap != null) {
          return Left(AppFailure(_extractErrorMessage(resBodyMap)));
        }
        return Left(AppFailure('Server error: ${response.statusCode}'));
      }

      // Login risponde con { token: "...", user: {...} }
      // UserModel.fromMap gestisce già questo formato.
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Right(UserModel.fromMap(resBodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, UserModel>> getCurrentUserData(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ServerConstant.serverURL}/auth/'),
        headers: _authHeaders(token),
      );
      final result = _handleUserResponse(response);
      return result.map((user) => user.copyWith(token: token));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Profilo                                                            //
  // ------------------------------------------------------------------ //

  /// FIX: restituisce UserModel invece di String (imageUrl).
  /// Il backend /auth/upload-profile-picture restituisce UserOut (utente
  /// aggiornato). Parsarlo qui elimina la seconda chiamata a updateProfile
  /// nel viewmodel — un round-trip in meno.
  Future<Either<AppFailure, UserModel>> uploadProfilePicture({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final token = await _localRepository.getToken();
      if (token == null || token.isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      final uri = Uri.parse(
        '${ServerConstant.serverURL}/auth/upload-profile-picture',
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['x-auth-token'] = token;
      request.headers['Accept'] = 'application/json';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: _getMediaType(fileName),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Il backend risponde con UserOut — parsarlo e aggiungere il token.
      final result = _handleUserResponse(response);
      return result.map((user) => user.copyWith(token: token));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, UserModel>> updateProfile({
    String? name,
    String? imageUrl,
  }) async {
    try {
      final token = await _localRepository.getToken();
      if (token == null || token.isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      final response = await client.patch(
        Uri.parse('${ServerConstant.serverURL}/auth/update-profile'),
        headers: await _jsonHeaders(authenticated: true),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (imageUrl != null) 'image_url': imageUrl,
        }),
      );

      final result = _handleUserResponse(response);
      return result.map((user) => user.copyWith(token: token));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, String>> deleteUser(String userId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ServerConstant.serverURL}/auth/delete/$userId'),
        headers: await _jsonHeaders(authenticated: true),
      );
      return _handleStatusOnlyResponse(
        response,
        successStatuses: const {200, 204},
        successMessage: 'Utente eliminato con successo',
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  /// Elimina un utente usando un token esplicito invece di leggerlo dallo storage.
  /// Usato nel rollback dell'onboarding artista: il token è ottenuto tramite
  /// loginForArtistOnboarding (non salvato in storage) e serve per cancellare
  /// l'utente appena creato se la creazione del profilo artista fallisce.
  Future<Either<AppFailure, String>> deleteUserWithToken({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('${ServerConstant.serverURL}/auth/delete/$userId'),
        headers: _authHeaders(token),
      );
      return _handleStatusOnlyResponse(
        response,
        successStatuses: const {200, 204},
        successMessage: 'Utente eliminato con successo',
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, String>> changePassword({
    required String userId,
    String? currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse('${ServerConstant.serverURL}/auth/change-password/$userId'),
        headers: await _jsonHeaders(authenticated: true),
        body: jsonEncode({
          if (currentPassword != null && currentPassword.trim().isNotEmpty)
            'current_password': currentPassword.trim(),
          'new_password': newPassword.trim(),
        }),
      );
      return _handleStatusOnlyResponse(
        response,
        successStatuses: const {200, 204},
        successMessage: 'Password aggiornata con successo',
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Helper privati                                                     //
  // ------------------------------------------------------------------ //

  Either<AppFailure, UserModel> _handleUserResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return Left(
        AppFailure('Risposta vuota dal server. Status: ${response.statusCode}'),
      );
    }
    final resBodyMap = _tryParseJson(response.body);
    if (resBodyMap == null) {
      return Left(AppFailure('Risposta non valida dal server'));
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      return Left(AppFailure(_extractErrorMessage(resBodyMap)));
    }
    return Right(UserModel.fromMap(resBodyMap));
  }

  Either<AppFailure, String> _handleStatusOnlyResponse(
    http.Response response, {
    required Set<int> successStatuses,
    required String successMessage,
  }) {
    if (successStatuses.contains(response.statusCode)) {
      return Right(successMessage);
    }
    final resBodyMap = _tryParseJson(response.body);
    if (resBodyMap != null) {
      return Left(AppFailure(_extractErrorMessage(resBodyMap)));
    }
    return Left(AppFailure('Server error: ${response.statusCode}'));
  }

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(Map<String, dynamic> resBodyMap) {
    final detail = resBodyMap['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        return first['msg'].toString();
      }
    }
    return 'Errore del server';
  }

  MediaType _getMediaType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('application', 'octet-stream');
  }
}
