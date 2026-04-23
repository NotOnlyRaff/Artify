import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AudioWave extends StatefulWidget {
  final String path;

  const AudioWave({
    super.key,
    required this.path,
  });

  @override
  State<AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> {
  final PlayerController playerController = PlayerController();

  bool _isPrepared = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    debugPrint('[AudioWave] initAudioPlayer() – path: ${widget.path}');

    if (widget.path.isEmpty) {
      debugPrint(
          '[AudioWave] ERROR – path vuoto, impossibile preparare il player');
      setState(() {
        _hasError = true;
        _errorMessage = 'Empty audio path';
      });
      return;
    }

    try {
      await playerController.preparePlayer(path: widget.path);
      debugPrint(
        '[AudioWave] preparePlayer() completato – '
        'duration: ${playerController.maxDuration} ms',
      );

      // Listener per loggare tutti i cambi di stato del player
      playerController.addListener(_onPlayerStateChanged);

      if (!mounted) return;
      setState(() {
        _isPrepared = true;
        _hasError = false;
        _errorMessage = null;
      });
    } catch (e, st) {
      debugPrint('[AudioWave] preparePlayer() ERROR: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onPlayerStateChanged() {
    final s = playerController.playerState;
    debugPrint(
      '[AudioWave] state changed → '
      'isPlaying: ${s.isPlaying}, '
      'isPaused: ${s.isPaused}, '
      'isStopped: ${s.isStopped}',
    );
  }

  Future<void> _togglePlayPause() async {
    final s = playerController.playerState;
    debugPrint(
      '[AudioWave] togglePlayPause() tapped – '
      'before → isPlaying: ${s.isPlaying}, isPaused: ${s.isPaused}',
    );

    try {
      if (!s.isPlaying) {
        await playerController.startPlayer();
        debugPrint('[AudioWave] startPlayer() chiamato');
      } else if (!s.isPaused) {
        await playerController.pausePlayer();
        debugPrint('[AudioWave] pausePlayer() chiamato');
      }
    } catch (e, st) {
      debugPrint('[AudioWave] togglePlayPause() ERROR: $e');
      debugPrint(st.toString());
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    debugPrint('[AudioWave] dispose() – sto rilasciando il PlayerController');
    playerController.removeListener(_onPlayerStateChanged);
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stato di errore: mostro un mini messaggio + icona
    if (_hasError) {
      return Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Error loading waveform',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: _isPrepared ? _togglePlayPause : null,
          icon: _isPrepared
              ? Icon(
                  playerController.playerState.isPlaying
                      ? CupertinoIcons.pause_solid
                      : CupertinoIcons.play_arrow_solid,
                  size: 20,
                )
              : const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
        ),
        Expanded(
          child: SizedBox(
            height: 60, // un po’ più compatto del 100 originale
            child: AudioFileWaveforms(
              size: const Size(double.infinity, 60),
              playerController: playerController,
              playerWaveStyle: const PlayerWaveStyle(
                fixedWaveColor: Pallete.borderColor,
                liveWaveColor: Pallete.gradient2,
                spacing: 6,
                showSeekLine: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
