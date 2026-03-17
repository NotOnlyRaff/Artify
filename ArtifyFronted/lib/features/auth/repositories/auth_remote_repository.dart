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
  return AuthRemoteRepository(client);
}

class AuthRemoteRepository {
  final http.Client client;

  AuthRemoteRepository(this.client);

  AuthLocalRepository get _localRepository => AuthLocalRepository();

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
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        final resBodyMap = _tryParseJson(response.body);
        if (resBodyMap != null) {
          return Left(AppFailure(_extractErrorMessage(resBodyMap)));
        }
        return Left(AppFailure('Server error: ${response.statusCode}'));
      }

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      return Right(
        UserModel.fromMap(resBodyMap['user']).copyWith(
          token: resBodyMap['token']?.toString() ?? '',
        ),
      );
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

  Future<Either<AppFailure, String>> uploadProfilePicture({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final token = await _localRepository.getToken();

      if (token == null || token.isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      final uri =
          Uri.parse('${ServerConstant.serverURL}/auth/upload-profile-picture');

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

      if (response.body.trim().isEmpty) {
        return Left(
          AppFailure('Empty response body. Status: ${response.statusCode}'),
        );
      }

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        return Left(AppFailure(_extractErrorMessage(resBodyMap)));
      }

      final imageUrl = resBodyMap['image_url']?.toString();
      if (imageUrl == null || imageUrl.isEmpty) {
        return Left(AppFailure('Invalid image upload response'));
      }

      return Right(imageUrl);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  MediaType _getMediaType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }

    return MediaType('application', 'octet-stream');
  }

  Future<Either<AppFailure, UserModel>> updateProfile({
    String? name,
    String? profilePicUrl,
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
          if (profilePicUrl != null) 'image_url': profilePicUrl,
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

  Either<AppFailure, UserModel> _handleUserResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return Left(
        AppFailure('Risposta vuota dal server. Status: ${response.statusCode}'),
      );
    }

    final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

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

    if (response.body.trim().isNotEmpty) {
      final resBodyMap = _tryParseJson(response.body);
      if (resBodyMap != null) {
        return Left(AppFailure(_extractErrorMessage(resBodyMap)));
      }
    }

    return Left(AppFailure('Server error: ${response.statusCode}'));
  }

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
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

  Map<String, String> _authHeaders(String token) => {
        'Accept': 'application/json',
        'x-auth-token': token,
      };
}
