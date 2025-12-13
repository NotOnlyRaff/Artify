import 'dart:convert';
import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_remote_repository.g.dart';

@riverpod
AuthRemoteRepository authRemoteRepository(AuthRemoteRepositoryRef ref) {
  return AuthRemoteRepository();
}

class AuthRemoteRepository {
  Future<Either<AppFailure, UserModel>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ServerConstant.serverURL}/auth/signup',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'name': name,
            'email': email,
            'password': password,
          },
        ),
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 201) {
        if (resBodyMap['detail'] != null) {
          return Left(AppFailure(_extractErrorMessage(resBodyMap)));
        }
        return Left(AppFailure(response.body));
      }

      final resBodyMapD = resBodyMap;
      return Right(UserModel.fromMap(resBodyMapD));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ServerConstant.serverURL}/auth/login',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'email': email,
            'password': password,
          },
        ),
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBodyMap['detail']));
      }

      return Right(
        UserModel.fromMap(resBodyMap['user']).copyWith(
          token: resBodyMap['token'],
        ),
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, UserModel>> getCurrentUserData(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ServerConstant.serverURL}/auth/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBodyMap['detail']));
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

    if (detail is String) {
      return detail;
    }

    // Caso tipico FastAPI: [{"loc": [...], "msg": "...", "type": "..."}]
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
      return detail.toString();
    }

    if (detail is Map && detail['msg'] is String) {
      return detail['msg'] as String;
    }

    return detail?.toString() ?? 'Unknown error';
  }
}
