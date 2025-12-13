import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artist_remote_repository.g.dart';

@riverpod
ArtistRemoteRepository artistRemoteRepository(ArtistRemoteRepositoryRef ref) {
  return ArtistRemoteRepository();
}

class ArtistRemoteRepository {
  Uri _uri(String path) => Uri.parse('${ServerConstant.serverURL}$path');

  Map<String, String> _jsonHeaders(String token) => {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      };

  // ───────────────── CREATE ARTIST ─────────────────
  //
  // POST /artist
  // body (ArtistCreate):
  // {
  //   "name": "...",                 // required
  //   "display_name": "...",
  //   "slug": "...",
  //   "image_url": "...",
  //   "bio": "...",
  //   "country": "...",
  //   "song_ids": ["..."],
  //   "album_ids": ["..."]
  // }

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
      final uri = _uri('/artist');

      final body = <String, dynamic>{
        'name': name.trim(),
        'song_ids': songIds,
        'album_ids': albumIds,
      };

      if (displayName != null && displayName.trim().isNotEmpty) {
        body['display_name'] = displayName.trim();
      }
      if (slug != null && slug.trim().isNotEmpty) {
        body['slug'] = slug.trim();
      }
      if (imageUrl != null && imageUrl.trim().isNotEmpty) {
        body['image_url'] = imageUrl.trim();
      }
      if (bio != null && bio.trim().isNotEmpty) {
        body['bio'] = bio.trim();
      }
      if (country != null && country.trim().isNotEmpty) {
        body['country'] = country.trim();
      }

      final res = await http.post(
        uri,
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 201) {
        if (resBodyMap is Map<String, dynamic> &&
            resBodyMap['detail'] != null) {
          return Left(AppFailure(_extractErrorMessage(resBodyMap['detail'])));
        }
        return Left(AppFailure('Create artist failed (${res.statusCode})'));
      }
      if (resBodyMap is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for ArtistCreate'));
      }

      final artist = ArtistModel.fromMap(
        Map<String, dynamic>.from(resBodyMap),
      );
      return Right(artist);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── GET SINGLE ARTIST ─────────────
  //
  // GET /artist/{artist_id}
  // response_model = ArtistOut

  Future<Either<AppFailure, ArtistModel>> getArtist({
    required String artistId,
    required String token,
  }) async {
    try {
      final uri = _uri('/artist/$artistId');

      final res = await http.get(
        uri,
        headers: _jsonHeaders(token),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBodyMap['detail']?.toString() ?? 'Get artist failed',
            ),
          );
        }
        return Left(AppFailure('Get artist failed (${res.statusCode})'));
      }

      if (resBodyMap is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for ArtistOut'));
      }

      final artist = ArtistModel.fromMap(
        Map<String, dynamic>.from(resBodyMap),
      );
      return Right(artist);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── LIST ARTISTS ──────────────────

  Future<Either<AppFailure, List<ArtistModel>>> listArtists({
    required String token,
    String? search,   // ignorati ora
    String? songId,
    String? albumId,
  }) async {
    try {
      // Lista completa, nessun query param
      final uri = _uri('/artist');

      final res = await http.get(
        uri,
        headers: _jsonHeaders(token),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBodyMap['detail']?.toString() ?? 'List artists failed',
            ),
          );
        }
        return Left(AppFailure('List artists failed (${res.statusCode})'));
      }

      if (resBodyMap is! List) {
        return Left(AppFailure('Invalid response format for artists list'));
      }

      final artists = <ArtistModel>[];
      for (final item in resBodyMap) {
        if (item is Map<String, dynamic>) {
          artists.add(ArtistModel.fromMap(item));
        } else if (item is Map) {
          artists.add(
            ArtistModel.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }

      return Right(artists);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }


    // ───────────────── SEARCH ARTISTS ──────────────────
  //
  // GET /artist/search?q=...&song_id=...&album_id=...

  Future<Either<AppFailure, List<ArtistModel>>> searchArtists({
    required String token,
    String? query,
    String? songId,
    String? albumId,
  }) async {
    try {
      Uri uri = _uri('/artist/search');

      final queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (songId != null && songId.isNotEmpty) {
        queryParams['song_id'] = songId;
      }
      if (albumId != null && albumId.isNotEmpty) {
        queryParams['album_id'] = albumId;
      }

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final res = await http.get(
        uri,
        headers: _jsonHeaders(token),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBodyMap['detail']?.toString() ?? 'Search artists failed',
            ),
          );
        }
        return Left(AppFailure('Search artists failed (${res.statusCode})'));
      }

      if (resBodyMap is! List) {
        return Left(AppFailure('Invalid response format for artists search'));
      }

      final artists = <ArtistModel>[];
      for (final item in resBodyMap) {
        if (item is Map<String, dynamic>) {
          artists.add(ArtistModel.fromMap(item));
        } else if (item is Map) {
          artists.add(
            ArtistModel.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }

      return Right(artists);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }


  // ───────────────── UPDATE ARTIST ─────────────────
  //
  // PATCH /artist/{artist_id}
  // body = ArtistUpdate (tutti opzionali)

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
      final uri = _uri('/artist/$artistId');

      final body = <String, dynamic>{};

      if (name != null) body['name'] = name.trim();
      if (displayName != null) body['display_name'] = displayName.trim();
      if (slug != null) body['slug'] = slug.trim();
      if (imageUrl != null) body['image_url'] = imageUrl.trim();
      if (bio != null) body['bio'] = bio.trim();
      if (country != null) body['country'] = country.trim();

      if (songIds != null) {
        body['song_ids'] = songIds;
      }
      if (albumIds != null) {
        body['album_ids'] = albumIds;
      }

      if (body.isEmpty) {
        return Left(AppFailure('No fields provided for artist update'));
      }

      final res = await http.patch(
        uri,
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBodyMap['detail']?.toString() ?? 'Update artist failed',
            ),
          );
        }
        return Left(AppFailure('Update artist failed (${res.statusCode})'));
      }

      if (resBodyMap is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for ArtistUpdate'));
      }

      final artist = ArtistModel.fromMap(
        Map<String, dynamic>.from(resBodyMap),
      );
      return Right(artist);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── DELETE ARTIST ─────────────────
  //
  // DELETE /artist/{artist_id}

  Future<Either<AppFailure, bool>> deleteArtist({
    required String artistId,
    required String token,
  }) async {
    try {
      final uri = _uri('/artist/$artistId');

      final res = await http.delete(
        uri,
        headers: _jsonHeaders(token),
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        dynamic resBodyMap;
        try {
          resBodyMap = jsonDecode(res.body);
        } catch (_) {
          return Left(
            AppFailure('Delete artist failed (${res.statusCode})'),
          );
        }

        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBodyMap['detail']?.toString() ?? 'Delete artist failed',
            ),
          );
        }

        return Left(
          AppFailure('Delete artist failed (${res.statusCode})'),
        );
      }

      return const Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  String _extractErrorMessage(dynamic detail) {
    if (detail is String) return detail;
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
