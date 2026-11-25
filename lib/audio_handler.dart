import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'stations.dart';

/// Runs in an Android foreground service, so playback continues when the app
/// is closed, with notification + lock-screen + Bluetooth controls.
class RadioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  List<Station> _stations = [];
  int _index = 0;
  final current = ValueNotifier<Station?>(null);

  RadioHandler() {
    _player.playbackEventStream.listen(_broadcast, onError: (_) {});
    _player.processingStateStream.listen((s) {
      // Looping "broadcast" file ended: re-join at the live position.
      if (s == ProcessingState.completed && current.value?.syncLoop == true) {
        _tune(_index);
      }
    });
  }

  void _broadcast(PlaybackEvent e) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _index,
    ));
  }

  MediaItem _item(Station s) => MediaItem(id: s.url, title: s.name, album: s.group);

  Future<void> playGroup(List<Station> stations, int index) async {
    _stations = stations;
    queue.add(stations.map(_item).toList());
    await _tune(index);
  }

  Future<void> _tune(int i) async {
    _index = i;
    final s = _stations[i];
    current.value = s;
    mediaItem.add(_item(s));
    try {
      final src = s.url.startsWith('assets/')
          ? AudioSource.asset(s.url)
          : AudioSource.uri(Uri.parse(s.url));
      final d = await _player.setAudioSource(src);
      if (s.syncLoop && d != null && d.inMilliseconds > 0) {
        final ms = DateTime.now().millisecondsSinceEpoch % d.inMilliseconds;
        await _player.seek(Duration(milliseconds: ms));
      }
      _player.play(); // not awaited: completes only when playback stops
    } catch (_) {
      // stream unreachable; stay on this station so the user can retry/skip
    }
  }

  Future<void> setVol(double v) => _player.setVolume(v);

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_stations.isNotEmpty) await _tune((_index + 1) % _stations.length);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_stations.isNotEmpty) {
      await _tune((_index - 1 + _stations.length) % _stations.length);
    }
  }
}
