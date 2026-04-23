import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final playbackQueueLocalRepositoryProvider =
    Provider<PlaybackQueueLocalRepository>(
  (ref) => PlaybackQueueLocalRepository(),
);

class PlaybackQueueLocalRepository {
  static const String _boxName = 'playback_queue';
  static const String _stateKey = 'playback_state';

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  Future<void> saveState(PlaybackQueueState state) async {
    await _box.put(_stateKey, state.toMap());
  }

  PlaybackQueueState? loadState() {
    final raw = _box.get(_stateKey);
    if (raw is Map<String, dynamic>) {
      return PlaybackQueueState.fromMap(raw);
    }
    if (raw is Map) {
      return PlaybackQueueState.fromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> clearState() async {
    await _box.delete(_stateKey);
  }
}
