import 'dart:collection';

import 'package:client/features/home/song/model/song_model.dart';

enum PlaybackSourceType {
  manual,
  latest,
  recent,
  library,
  search,
  artist,
  album,
  playlist,
  restored;

  static PlaybackSourceType fromString(String? value) {
    return PlaybackSourceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PlaybackSourceType.manual,
    );
  }
}

enum PlaybackRepeatMode {
  off,
  all,
  one;

  static PlaybackRepeatMode fromString(String? value) {
    return PlaybackRepeatMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PlaybackRepeatMode.off,
    );
  }
}

class PlaybackQueueItem {
  final String queueId;
  final SongModel song;
  final PlaybackSourceType sourceType;
  final String? sourceId;
  final DateTime addedAt;
  final bool isManuallyQueued;

  const PlaybackQueueItem({
    required this.queueId,
    required this.song,
    required this.sourceType,
    required this.addedAt,
    this.sourceId,
    this.isManuallyQueued = false,
  });

  PlaybackQueueItem copyWith({
    String? queueId,
    SongModel? song,
    PlaybackSourceType? sourceType,
    Object? sourceId = _copySentinel,
    DateTime? addedAt,
    bool? isManuallyQueued,
  }) {
    return PlaybackQueueItem(
      queueId: queueId ?? this.queueId,
      song: song ?? this.song,
      sourceType: sourceType ?? this.sourceType,
      sourceId: identical(sourceId, _copySentinel)
          ? this.sourceId
          : sourceId as String?,
      addedAt: addedAt ?? this.addedAt,
      isManuallyQueued: isManuallyQueued ?? this.isManuallyQueued,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queue_id': queueId,
      'song': song.toJson(),
      'source_type': sourceType.name,
      'source_id': sourceId,
      'added_at': addedAt.toIso8601String(),
      'is_manually_queued': isManuallyQueued,
    };
  }

  factory PlaybackQueueItem.fromMap(Map<String, dynamic> map) {
    final rawSong = map['song'];
    final songMap = rawSong is Map<String, dynamic>
        ? rawSong
        : Map<String, dynamic>.from(rawSong as Map);

    return PlaybackQueueItem(
      queueId: map['queue_id']?.toString() ?? '',
      song: SongModel.fromJson(songMap),
      sourceType: PlaybackSourceType.fromString(map['source_type']?.toString()),
      sourceId: map['source_id']?.toString(),
      addedAt: DateTime.tryParse(map['added_at']?.toString() ?? '') ??
          DateTime.now(),
      isManuallyQueued: map['is_manually_queued'] == true,
    );
  }
}

class PlaybackQueueIndexedItem {
  final PlaybackQueueItem item;
  final int absoluteIndex;
  final int queuePosition;

  const PlaybackQueueIndexedItem({
    required this.item,
    required this.absoluteIndex,
    required this.queuePosition,
  });
}

class PlaybackQueueState {
  static const _sentinel = Object();
  static const int historyPreviewLimit = 20;

  final List<PlaybackQueueItem> items;
  final int? currentIndex;
  final PlaybackRepeatMode repeatMode;
  final bool isRestoring;

  const PlaybackQueueState({
    this.items = const [],
    this.currentIndex,
    this.repeatMode = PlaybackRepeatMode.off,
    this.isRestoring = false,
  });

  UnmodifiableListView<PlaybackQueueItem> get queue =>
      UnmodifiableListView(items);

  PlaybackQueueItem? get currentItem {
    final index = currentIndex;
    if (index == null || index < 0 || index >= items.length) return null;
    return items[index];
  }

  SongModel? get currentSong => currentItem?.song;

  PlaybackQueueItem? get nextItem {
    final index = currentIndex;
    if (index == null) return null;
    final candidate = index + 1;
    if (candidate < items.length) {
      return items[candidate];
    }
    return null;
  }

  PlaybackQueueItem? get previousItem {
    final index = currentIndex;
    if (index == null) return null;
    final candidate = index - 1;
    if (candidate >= 0) {
      return items[candidate];
    }
    return null;
  }

  bool get hasNextItem =>
      nextItem != null ||
      (repeatMode == PlaybackRepeatMode.all && items.isNotEmpty);

  bool get hasPreviousItem =>
      previousItem != null ||
      (repeatMode == PlaybackRepeatMode.all && items.isNotEmpty);

  List<PlaybackQueueItem> get previousItems {
    final index = currentIndex;
    if (index == null || index <= 0 || index > items.length) return const [];
    return items.sublist(0, index);
  }

  List<PlaybackQueueItem> get upcomingItems {
    final index = currentIndex;
    if (index == null || index + 1 >= items.length) return const [];
    return items.sublist(index + 1);
  }

  List<PlaybackQueueIndexedItem> get queuedEntries {
    final index = currentIndex;
    if (index == null || index + 1 >= items.length) return const [];

    final entries = <PlaybackQueueIndexedItem>[];
    for (var i = index + 1; i < items.length; i++) {
      final item = items[i];
      if (!item.isManuallyQueued) break;
      entries.add(
        PlaybackQueueIndexedItem(
          item: item,
          absoluteIndex: i,
          queuePosition: entries.length + 1,
        ),
      );
    }
    return entries;
  }

  List<PlaybackQueueItem> get queuedItems =>
      queuedEntries.map((entry) => entry.item).toList(growable: false);

  bool get hasQueue => items.isNotEmpty;

  bool get hasCurrent => currentItem != null;

  int get totalItems => items.length;

  int get historyCount => previousItems.length;

  List<PlaybackQueueItem> get recentPreviousItems {
    final history = previousItems;
    if (history.isEmpty) return const [];

    final startIndex = history.length > historyPreviewLimit
        ? history.length - historyPreviewLimit
        : 0;

    return history.sublist(startIndex).reversed.toList(growable: false);
  }

  int get historyOverflowCount {
    final overflow = historyCount - recentPreviousItems.length;
    return overflow > 0 ? overflow : 0;
  }

  int get queuedCount => queuedEntries.length;

  bool get hasQueuedItems => queuedCount > 0;

  PlaybackQueueState copyWith({
    List<PlaybackQueueItem>? items,
    Object? currentIndex = _sentinel,
    PlaybackRepeatMode? repeatMode,
    bool? isRestoring,
  }) {
    return PlaybackQueueState(
      items: items ?? this.items,
      currentIndex: identical(currentIndex, _sentinel)
          ? this.currentIndex
          : currentIndex as int?,
      repeatMode: repeatMode ?? this.repeatMode,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'current_index': currentIndex,
      'repeat_mode': repeatMode.name,
    };
  }

  factory PlaybackQueueState.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => PlaybackQueueItem.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <PlaybackQueueItem>[];

    final rawIndex = map['current_index'];
    final parsedIndex =
        rawIndex is int ? rawIndex : int.tryParse(rawIndex?.toString() ?? '');

    final safeIndex =
        parsedIndex != null && parsedIndex >= 0 && parsedIndex < items.length
            ? parsedIndex
            : (items.isNotEmpty ? 0 : null);

    return PlaybackQueueState(
      items: items,
      currentIndex: safeIndex,
      repeatMode: PlaybackRepeatMode.fromString(
        map['repeat_mode']?.toString(),
      ),
      isRestoring: false,
    );
  }
}

const _copySentinel = Object();
