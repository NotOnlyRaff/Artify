import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_client_provider.g.dart';

@riverpod
http.Client httpClient(HttpClientRef ref) {
  final authLocalRepository = ref.watch(authLocalRepositoryProvider);
  return _AuthClient(authLocalRepository);
}

class _AuthClient extends http.BaseClient {
  final AuthLocalRepository _authLocalRepository;
  final http.Client _inner = http.Client();

  _AuthClient(this._authLocalRepository);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Content-Type'] = 'application/json';

    final token = await _authLocalRepository.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['x-auth-token'] = token;
    }

    return _inner.send(request);
  }
}
