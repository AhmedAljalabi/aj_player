// services/audio_handler.dart
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  List<MediaItem> _mediaQueue = [];

  static Future<AudioPlayerHandler> init() async {
    final handler = AudioPlayerHandler();
    await handler._init();
    return handler;
  }

  Future<void> _init() async {
    // Configure audio focus for background
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Forward just_audio states to audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  /* ---- Public API wrappers ---- */
  Future<void> playTrack(Track t) async {
    final item = _trackToMediaItem(t);
    _mediaQueue = [item];
    queue.add(_mediaQueue);
    mediaItem.add(item);

    await _player.setFilePath(t.filePath);
    _player.play();
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration pos) => _player.seek(pos);
  @override
  Future<void> stop() => _player.stop();

  /* ---- Helpers ---- */
  MediaItem _trackToMediaItem(Track t) => MediaItem(
        id: t.id,
        album: 'Local',
        title: t.title,
        artist: t.artist,
        artUri: Uri.file(t.artworkPath),
        duration: null,
      );

  PlaybackState _transformEvent(PlaybackEvent e) => PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        playing: _player.playing,
        updatePosition: e.updatePosition,
        bufferedPosition: e.bufferedPosition,
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
      );

  /* Streams for the UI */
  Stream<bool> get isPlaying$ => _player.playingStream;
  Stream<Duration> get position$ => _player.positionStream;
}
