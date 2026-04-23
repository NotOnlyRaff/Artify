import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/network/http_client_provider.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artist_remote_repository.g.dart';

@riverpod
ArtistRemoteRepository artistRemoteRepository(
  ArtistRemoteRepositoryRef ref,
) {
  final client = ref.watch(httpClientProvider);
  return ArtistRemoteRepository(client);
}

class ArtistRemoteRepository {
  final http.Client client;

  ArtistRemoteRepository(this.client);

  // FIX: prefisso aggiornato da /artist a /artists (convenzione REST plurale).
  Uri _uri(String path) => Uri.parse('${ServerConstant.serverURL}$path');

  Map<String, String> _jsonHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-auth-token': token,
      };

  Map<String, String> _authHeaders(String token) => {
        'Accept': 'application/json',
        'x-auth-token': token,
      };

  Map<String, dynamic>? _tryParseObject(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(
    Map<String, dynamic>? body, {
    String fallback = 'Server error',
  }) {
    if (body == null) return fallback;
    final detail = body['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
      return detail.toString();
    }
    if (detail is Map && detail['msg'] != null) return detail['msg'].toString();
    return fallback;
  }

  // ------------------------------------------------------------------ //
  //  Upload immagine                                                    //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, String>> uploadArtistImage({
    required PickedMedia image,
    required String token,
  }) async {
    try {
      if (token.trim().isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      // FIX: /artists/upload-image
      final request =
          http.MultipartRequest('POST', _uri('/artists/upload-image'));
      request.headers.addAll(_authHeaders(token));

      if (kIsWeb) {
        if (image.bytes == null) {
          return Left(AppFailure('Image bytes are null on Web'));
        }
        request.files.add(http.MultipartFile.fromBytes('image', image.bytes!,
            filename: image.name));
      } else {
        if (image.filePath == null || image.filePath!.trim().isEmpty) {
          return Left(AppFailure('Image path is null on mobile'));
        }
        request.files.add(await http.MultipartFile.fromPath(
            'image', image.filePath!,
            filename: image.name));
      }

      final response = await http.Response.fromStream(await request.send());
      final body = _tryParseObject(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Left(AppFailure(_extractError(body,
            fallback: 'Upload image failed (${response.statusCode})')));
      }

      final imageUrl = body?['image_url']?.toString();
      if (imageUrl == null || imageUrl.isEmpty) {
        return Left(AppFailure('Image URL missing in response'));
      }

      return Right(imageUrl);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Creazione artista                                                  //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, ArtistModel>> createArtist({
    required String name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
    List<String> songIds = const [],
    List<String> albumIds = const [],
    required String token,
  }) async {
    try {
      if (token.trim().isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return Left(AppFailure('Artist name is required'));
      }

      final body = <String, dynamic>{
        'name': trimmedName,
        'song_ids': songIds,
        'album_ids': albumIds,
      };
      if (displayName?.trim().isNotEmpty == true) {
        body['display_name'] = displayName!.trim();
      }
      if (slug?.trim().isNotEmpty == true) body['slug'] = slug!.trim();
      if (imageUrl?.trim().isNotEmpty == true) {
        body['image_url'] = imageUrl!.trim();
      }
      if (bio?.trim().isNotEmpty == true) body['bio'] = bio!.trim();
      if (country?.trim().isNotEmpty == true) body['country'] = country!.trim();

      // FIX: POST /artists
      final response = await client.post(_uri('/artists'),
          headers: _jsonHeaders(token), body: jsonEncode(body));
      final bodyMap = _tryParseObject(response.body);

      if (response.statusCode != 201) {
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Create artist failed (${response.statusCode})')));
      }
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      return Right(ArtistModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Lettura singolo artista                                            //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, ArtistModel>> getArtist({
    required String artistId,
    required String token,
  }) async {
    try {
      if (token.trim().isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      // FIX: GET /artists/{id}
      final response = await client.get(_uri('/artists/$artistId'),
          headers: _authHeaders(token));
      final bodyMap = _tryParseObject(response.body);

      if (response.statusCode != 200) {
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Get artist failed (${response.statusCode})')));
      }
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      return Right(ArtistModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, ArtistModel>> fetchArtistById({
    required String artistId,
    required String token,
  }) =>
      getArtist(artistId: artistId, token: token);

  // ------------------------------------------------------------------ //
  //  Lista / ricerca artisti                                            //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, List<ArtistModel>>> listArtists({
    required String token,
    String? query,
    String? songId,
    String? albumId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (token.trim().isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      final hasFilters = (query?.trim().isNotEmpty == true) ||
          (songId?.trim().isNotEmpty == true) ||
          (albumId?.trim().isNotEmpty == true);

      // FIX: /artists/search o /artists
      Uri uri = _uri(hasFilters ? '/artists/search' : '/artists');

      final queryParams = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        if (query?.trim().isNotEmpty == true) 'q': query!.trim(),
        if (songId?.trim().isNotEmpty == true) 'song_id': songId!.trim(),
        if (albumId?.trim().isNotEmpty == true) 'album_id': albumId!.trim(),
      };
      uri = uri.replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: _authHeaders(token));

      if (response.statusCode != 200) {
        final bodyMap = _tryParseObject(response.body);
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'List artists failed (${response.statusCode})')));
      }

      // FIX: il backend restituisce { "items": [...], "total": ..., "limit": ..., "offset": ... }
      // Non una lista piatta. Estraiamo items.
      final bodyMap = _tryParseObject(response.body);
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      final rawItems = bodyMap['items'];
      if (rawItems is! List) {
        return Left(AppFailure('Missing items in response'));
      }

      final artists = rawItems
          .whereType<Map>()
          .map((item) => ArtistModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      return Right(artists);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<ArtistModel>>> searchArtists({
    required String token,
    String? query,
    String? songId,
    String? albumId,
  }) =>
      listArtists(token: token, query: query, songId: songId, albumId: albumId);

  // ------------------------------------------------------------------ //
  //  Aggiornamento artista                                              //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, ArtistModel>> updateArtist({
    required String artistId,
    String? name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
    List<String>? songIds,
    List<String>? albumIds,
    required String token,
  }) async {
    try {
      if (token.trim().isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name.trim();
      if (displayName != null) body['display_name'] = displayName.trim();
      if (slug != null) body['slug'] = slug.trim();
      if (imageUrl != null) body['image_url'] = imageUrl.trim();
      if (bio != null) body['bio'] = bio.trim();
      if (country != null) body['country'] = country.trim();
      if (songIds != null) body['song_ids'] = songIds;
      if (albumIds != null) body['album_ids'] = albumIds;

      if (body.isEmpty) {
        return Left(AppFailure('No fields provided for artist update'));
      }

      // FIX: PATCH /artists/{id}
      final response = await client.patch(_uri('/artists/$artistId'),
          headers: _jsonHeaders(token), body: jsonEncode(body));
      final bodyMap = _tryParseObject(response.body);

      if (response.statusCode != 200) {
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Update artist failed (${response.statusCode})')));
      }
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      return Right(ArtistModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Eliminazione artista                                               //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, bool>> deleteArtist({
    required String artistId,
    required String token,
  }) async {
    try {
      if (token.trim().isEmpty) {
        return Left(AppFailure('User not authenticated'));
      }

      // FIX: DELETE /artists/{id}
      final response = await client.delete(_uri('/artists/$artistId'),
          headers: _authHeaders(token));

      if (response.statusCode != 200 && response.statusCode != 204) {
        final bodyMap = _tryParseObject(response.body);
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Delete artist failed (${response.statusCode})')));
      }

      return const Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
