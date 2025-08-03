import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive/hive.dart';
import 'models/track.dart';


class PlayMusic extends StatefulWidget {
  final Track track;          // Track to start with
  final List<Track>? queue;   // Optional custom queue
  
  const PlayMusic({super.key, required this.track, this.queue});

  @override
  State<PlayMusic> createState() => _PlayMusicState();
}

class _PlayMusicState extends State<PlayMusic> {
  late final Box<String> _favBox;
  late final AudioHandler _handler;
  final getIt = GetIt.instance;
  late Stream<PositionData> _position$;

  @override
  void initState() {
    super.initState();

    _favBox   = Hive.box<String>('favoritesBox');
    _handler  = getIt<AudioHandler>();          // ← your service-locator instance
    _position$ = Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _handler.playbackState.map((s) => s.position).distinct(),
      _handler.playbackState.map((s) => s.bufferedPosition).distinct(),
      _handler.mediaItem.map((item) => item?.duration).distinct(),
      (pos, buf, dur) => PositionData(pos, buf, dur ?? Duration.zero),
    );

    _loadQueueAndPlay();
  }

  Future<void> _loadQueueAndPlay() async {
    final q = widget.queue ?? [widget.track];
    final mediaItems = q.map((t) => t.toMediaItem()).toList();
    await _handler.updateQueue(mediaItems);
    final index = q.indexOf(widget.track);
    await _handler.skipToQueueItem(index);
    await _handler.play();
  }

  bool _isFav(String id) => _favBox.containsKey(id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Now Playing'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<MediaItem?>(
            stream: _handler.mediaItem,
            builder: (_, snap) {
              final item = snap.data;
              if (item == null) return const SizedBox.shrink();
              final fav = _isFav(item.id);
              return IconButton(
                icon: Icon(
                  fav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: fav ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  fav ? _favBox.delete(item.id) : _favBox.put(item.id, item.id);
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),

      body: GestureDetector(
        onLongPress: _showQueueSheet,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- ARTWORK ---------------------------------------------------
              Expanded(
                child: StreamBuilder<MediaItem?>(
                  stream: _handler.mediaItem,
                  builder: (_, snap) {
                    final artPath = snap.data?.artUri?.toFilePath() ?? '';
                    final img = File(artPath).existsSync()
                        ? FileImage(File(artPath))
                        : const AssetImage('assets/placeholder.jpg') as ImageProvider;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image(image: img, fit: BoxFit.cover, width: double.infinity),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // --- TITLE + ARTIST -------------------------------------------
              StreamBuilder<MediaItem?>(
                stream: _handler.mediaItem,
                builder: (_, snap) {
                  final item = snap.data;
                  return Column(
                    children: [
                      Text(item?.title ?? '',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(item?.artist ?? '', style: theme.textTheme.labelMedium),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),

              // --- POSITION SLIDER ------------------------------------------
              StreamBuilder<PositionData>(
                stream: _position$,
                builder: (_, snap) {
                  final data = snap.data ?? PositionData.zero;
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(trackHeight: 3),
                        child: Slider(
                          value: data.position.inMilliseconds.toDouble().clamp(0.0, data.duration.inMilliseconds.toDouble()),
                          max: data.duration.inMilliseconds.toDouble(),
                          onChanged: (v) => _handler.seek(Duration(milliseconds: v.toInt())),
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_format(data.position), style: theme.textTheme.labelSmall),
                          Text(_format(data.duration), style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),

              // --- CONTROL BUTTONS ------------------------------------------
              _Controls(handler: _handler),
            ],
          ),
        ),
      ),
    );
  }

  void _showQueueSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (_) => StreamBuilder<List<MediaItem>>(
        stream: _handler.queue,
        builder: (_, snap) {
          final q = snap.data ?? [];
          return ReorderableListView.builder(
            itemCount: q.length,
            onReorder: (oldIdx, newIdx) {
              if (newIdx > oldIdx) newIdx -= 1;
              _handler.updateQueue(List.of(q)..insert(newIdx, (q.removeAt(oldIdx))));
            },
            itemBuilder: (_, i) => ListTile(
              key: ValueKey(q[i].id),
              leading: Text('${i + 1}'),
              title: Text(q[i].title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(q[i].artist ?? ''),
              onTap: () => _handler.skipToQueueItem(i),
            ),
          );
        },
      ),
    );
  }

  String _format(Duration d) {
    two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

// ────────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS / UTIL
// ────────────────────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final AudioHandler handler;
  const _Controls({required this.handler});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (_, snap) {
        final state = snap.data ?? PlaybackState();
        final playing = state.playing;
        final shuffle = state.shuffleMode == AudioServiceShuffleMode.all;
        final repeat = state.repeatMode;
        IconData repeatIcon;
        switch (repeat) {
          case AudioServiceRepeatMode.all: repeatIcon = CupertinoIcons.repeat; break;
          case AudioServiceRepeatMode.one: repeatIcon = CupertinoIcons.repeat_1; break;
          default: repeatIcon = CupertinoIcons.repeat; break;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                shuffle ? CupertinoIcons.shuffle : CupertinoIcons.shuffle,
                color: shuffle ? Colors.pinkAccent : Colors.white,
              ),
              onPressed: () => handler.setShuffleMode(
                shuffle ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.backward_fill),
              iconSize: 32,
              onPressed: handler.skipToPrevious,
            ),
            Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: IconButton(
                icon: Icon(playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: Colors.black),
                iconSize: 36,
                onPressed: playing ? handler.pause : handler.play,
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.forward_fill),
              iconSize: 32,
              onPressed: handler.skipToNext,
            ),
            IconButton(
              icon: Icon(repeatIcon, color: repeat == AudioServiceRepeatMode.none ? Colors.white : Colors.pinkAccent),
              onPressed: () {
                final next = {
                  AudioServiceRepeatMode.none : AudioServiceRepeatMode.all,
                  AudioServiceRepeatMode.all  : AudioServiceRepeatMode.one,
                  AudioServiceRepeatMode.one  : AudioServiceRepeatMode.none,
                }[repeat]!;
                handler.setRepeatMode(next);
              },
            ),
          ],
        );
      },
    );
  }
}

// Helper DTO binding three position streams together
class PositionData {
  final Duration position, buffered, duration;
  const PositionData(this.position, this.buffered, this.duration);
  static const zero = PositionData(Duration.zero, Duration.zero, Duration.zero);
}

// Extension to convert your Hive Track to a MediaItem
extension _TrackX on Track {
  MediaItem toMediaItem() => MediaItem(
    id: id,
    title: title,
    artist: artist,
    artUri: Uri.file(artworkPath),
    duration: Duration(milliseconds: duration),
    extras: {'path': filePath},
  );
}
