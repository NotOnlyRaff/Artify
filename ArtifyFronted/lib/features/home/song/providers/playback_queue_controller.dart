import 'dart:async';
import 'dart:math';

import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/repositories/playback_queue_local_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final playbackQueueControllerProvider =
    NotifierProvider<PlaybackQueueController, PlaybackQueueState>(
  PlaybackQueueController.new,
);

class PlaybackQueueController extends Notifier<PlaybackQueueState> {
  final Random _random = Random();
  bool _isRestoring = false;

  CurrentSongNotifier get _player =>
      ref.read(currentSongNotifierProvider.notifier);

  PlaybackQueueLocalRepository get _localRepository =>
      ref.read(playbackQueueLocalRepositoryProvider);

  @override
  PlaybackQueueState build() {
    Future.microtask(_restoreQueue);
    return const PlaybackQueueState(isRestoring: true);
  }

  Future<void> _restoreQueue() async {
    if (_isRestoring) return;
    _isRestoring = true;

    try {
      final restored = _localRepository.loadState();
      if (restored == null || restored.items.isEmpty) {
        state = state.copyWith(isRestoring: false);
        return;
      }

      state = restored.copyWith(isRestoring: false);

      if (ref.read(currentSongNotifierProvider) == null &&
          restored.currentSong != null) {
        await _player.updateSong(
          restored.currentSong!,
          syncQueue: false,
          autoplay: false,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[PlaybackQueueController] restore error: $error\n$stackTrace');
      state = const PlaybackQueueState(isRestoring: false);
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> _persistState() async {
    if (state.items.isEmpty) {
      await _localRepository.clearState();
      return;
    }
    await _localRepository.saveState(state);
  }

  Future<void> _replaceQueueAndPlay({
    required List<PlaybackQueueItem> items,
    required int startIndex,
    bool autoplay = true,
  }) async {
    if (items.isEmpty) {
      await clearQueue();
      return;
    }

    state = PlaybackQueueState(
      items: items,
      currentIndex: startIndex.clamp(0, items.length - 1),
      repeatMode: state.repeatMode,
      isRestoring: false,
    );
    await _persistState();
    await _player.updateSong(
      state.currentSong!,
      syncQueue: false,
      autoplay: autoplay,
    );
  }

  List<PlaybackQueueItem> _buildItems(
    List<SongModel> songs, {
    required PlaybackSourceType sourceType,
    String? sourceId,
    bool isManuallyQueued = false,
  }) {
    return songs.asMap().entries.map((entry) {
      final index = entry.key;
      final song = entry.value;

      return PlaybackQueueItem(
        queueId:
            '${DateTime.now().microsecondsSinceEpoch}-${song.id}-$index-${_random.nextInt(1 << 20)}',
        song: song,
        sourceType: sourceType,
        sourceId: sourceId,
        addedAt: DateTime.now(),
        isManuallyQueued: isManuallyQueued,
      );
    }).toList(growable: false);
  }

  void syncSingleSongQueue(
    SongModel song, {
    PlaybackSourceType sourceType = PlaybackSourceType.manual,
    String? sourceId,
  }) {
    state = PlaybackQueueState(
      items: _buildItems(
        [song],
        sourceType: sourceType,
        sourceId: sourceId,
      ),
      currentIndex: 0,
      repeatMode: state.repeatMode,
      isRestoring: false,
    );
    unawaited(_persistState());
  }

  Future<void> playSongs(
    List<SongModel> songs, {
    int startIndex = 0,
    PlaybackSourceType sourceType = PlaybackSourceType.manual,
    String? sourceId,
    bool autoplay = true,
  }) async {
    if (songs.isEmpty) return;

    final items = _buildItems(
      songs,
      sourceType: sourceType,
      sourceId: sourceId,
    );

    await _replaceQueueAndPlay(
      items: items,
      startIndex: startIndex,
      autoplay: autoplay,
    );
  }

  Future<void> playSongNow(
    SongModel song, {
    List<SongModel>? contextSongs,
    int? startIndex,
    PlaybackSourceType sourceType = PlaybackSourceType.manual,
    String? sourceId,
  }) async {
    if (contextSongs != null && contextSongs.isNotEmpty) {
      final resolvedIndex = startIndex ??
          contextSongs.indexWhere((candidate) => candidate.id == song.id);

      await playSongs(
        contextSongs,
        startIndex: resolvedIndex >= 0 ? resolvedIndex : 0,
        sourceType: sourceType,
        sourceId: sourceId,
      );
      return;
    }

    await playSongs(
      [song],
      startIndex: 0,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  Future<void> playNext(
    SongModel song, {
    PlaybackSourceType sourceType = PlaybackSourceType.manual,
    String? sourceId,
  }) async {
    if (!state.hasCurrent) {
      await playSongs(
        [song],
        sourceType: sourceType,
        sourceId: sourceId,
      );
      return;
    }

    final insertIndex = (state.currentIndex ?? -1) + 1;
    final updated = [...state.items];
    updated.insertAll(
      insertIndex.clamp(0, updated.length),
      _buildItems(
        [song],
        sourceType: sourceType,
        sourceId: sourceId,
        isManuallyQueued: true,
      ),
    );

    state = state.copyWith(items: updated);
    await _persistState();
  }

  Future<void> addToQueue(
    SongModel song, {
    PlaybackSourceType sourceType = PlaybackSourceType.manual,
    String? sourceId,
  }) async {
    if (!state.hasCurrent) {
      await playSongs(
        [song],
        sourceType: sourceType,
        sourceId: sourceId,
      );
      return;
    }

    final updated = [
      ...state.items,
      ..._buildItems(
        [song],
        sourceType: sourceType,
        sourceId: sourceId,
        isManuallyQueued: true,
      ),
    ];

    state = state.copyWith(items: updated);
    await _persistState();
  }

  int? _nextIndex({required bool fromCompletion}) {
    final currentIndex = state.currentIndex;
    if (currentIndex == null || state.items.isEmpty) return null;

    if (fromCompletion && state.repeatMode == PlaybackRepeatMode.one) {
      return currentIndex;
    }

    final candidate = currentIndex + 1;
    if (candidate < state.items.length) {
      return candidate;
    }

    if (state.repeatMode == PlaybackRepeatMode.all) {
      return 0;
    }

    return null;
  }

  int? _previousIndex() {
    final currentIndex = state.currentIndex;
    if (currentIndex == null || state.items.isEmpty) return null;

    final candidate = currentIndex - 1;
    if (candidate >= 0) {
      return candidate;
    }

    if (state.repeatMode == PlaybackRepeatMode.all) {
      return state.items.length - 1;
    }

    return null;
  }

  Future<bool> handleTrackCompleted() async {
    final nextIndex = _nextIndex(fromCompletion: true);
    if (nextIndex == null) {
      return false;
    }

    state = state.copyWith(currentIndex: nextIndex);
    await _persistState();
    await _player.updateSong(
      state.currentSong!,
      syncQueue: false,
    );
    return true;
  }

  Future<bool> skipToNext() async {
    final nextIndex = _nextIndex(fromCompletion: false);
    if (nextIndex == null) {
      return false;
    }

    state = state.copyWith(currentIndex: nextIndex);
    await _persistState();
    await _player.updateSong(
      state.currentSong!,
      syncQueue: false,
    );
    return true;
  }

  Future<bool> skipToPrevious({
    Duration restartThreshold = const Duration(seconds: 3),
  }) async {
    final position = _player.audioPlayer.position;
    if (position > restartThreshold) {
      _player.seek(0);
      return true;
    }

    final previousIndex = _previousIndex();
    if (previousIndex == null) {
      _player.seek(0);
      return false;
    }

    state = state.copyWith(currentIndex: previousIndex);
    await _persistState();
    await _player.updateSong(
      state.currentSong!,
      syncQueue: false,
    );
    return true;
  }

  Future<bool> skipToIndex(int index, {bool autoplay = true}) async {
    if (index < 0 || index >= state.items.length) return false;

    state = state.copyWith(currentIndex: index);
    await _persistState();
    await _player.updateSong(
      state.currentSong!,
      syncQueue: false,
      autoplay: autoplay,
    );
    return true;
  }

  Future<void> removeQueueItem(String queueId) async {
    final index = state.items.indexWhere((item) => item.queueId == queueId);
    if (index == -1) return;

    final updated = [...state.items]..removeAt(index);
    final currentIndex = state.currentIndex;
    final wasPlaying = _player.isPlaying;

    if (updated.isEmpty) {
      state = state.copyWith(items: const [], currentIndex: null);
      await _persistState();
      await _player.stopAndClear();
      return;
    }

    if (currentIndex == null) {
      state = state.copyWith(items: updated);
      await _persistState();
      return;
    }

    if (index < currentIndex) {
      state = state.copyWith(
        items: updated,
        currentIndex: currentIndex - 1,
      );
      await _persistState();
      return;
    }

    if (index > currentIndex) {
      state = state.copyWith(items: updated);
      await _persistState();
      return;
    }

    final replacementIndex =
        index < updated.length ? index : updated.length - 1;

    state = state.copyWith(
      items: updated,
      currentIndex: replacementIndex,
    );
    await _persistState();
    await _player.updateSong(
      state.currentSong!,
      syncQueue: false,
      autoplay: wasPlaying,
    );
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= state.items.length ||
        newIndex < 0 ||
        newIndex >= state.items.length ||
        oldIndex == newIndex) {
      return;
    }

    final updated = [...state.items];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    var currentIndex = state.currentIndex;
    if (currentIndex != null) {
      if (oldIndex == currentIndex) {
        currentIndex = newIndex;
      } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
        currentIndex -= 1;
      } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
        currentIndex += 1;
      }
    }

    state = state.copyWith(
      items: updated,
      currentIndex: currentIndex,
    );
    await _persistState();
  }

  Future<void> clearQueue({bool stopPlayback = true}) async {
    state = state.copyWith(
      items: const [],
      currentIndex: null,
      isRestoring: false,
    );
    await _persistState();

    if (stopPlayback) {
      await _player.stopAndClear();
    }
  }

  PlaybackRepeatMode cycleRepeatMode() {
    final nextMode = switch (state.repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };

    state = state.copyWith(repeatMode: nextMode);
    unawaited(_persistState());
    return nextMode;
  }
}
