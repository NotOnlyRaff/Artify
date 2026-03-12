import 'dart:convert';
import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/network/http_client_provider.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
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

  Future<Either<AppFailure, UserModel>> signup({
    required String name,
    required String email,
    required String password,
    required bool isArtist,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${ServerConstant.serverURL}/auth/signup'),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'is_artist': isArtist,
        }),
      );

      if (response.body.trim().isEmpty) {
        return Left(
          AppFailure('Empty response body. Status: ${response.statusCode}'),
        );
      }

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 201) {
        return Left(AppFailure(_extractErrorMessage(resBodyMap)));
      }

      return Right(UserModel.fromMap(resBodyMap));
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
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.body.trim().isEmpty) {
        return Left(
          AppFailure('Empty response body. Status: ${response.statusCode}'),
        );
      }

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(_extractErrorMessage(resBodyMap)));
      }

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
      );

      if (response.body.trim().isEmpty) {
        return Left(
          AppFailure('Empty response body. Status: ${response.statusCode}'),
        );
      }

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(_extractErrorMessage(resBodyMap)));
      }

      return Right(
        UserModel.fromMap(resBodyMap).copyWith(
          token: token,
        ),
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
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
      return detail.toString();
    }

    if (detail is Map && detail['msg'] != null) {
      return detail['msg'].toString();
    }

    return 'Errore del server';
  }
}
