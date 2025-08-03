import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

class TrackScanner {
  static Future<void> scanAndCache() async {
    final musicDir = await getExternalStorageDirectory();
    if (musicDir == null) return;

    final mp3Files = musicDir
        .listSync(recursive: true)
        .where((f) => f.path.toLowerCase().endsWith('.mp3'));

    final box = Hive.box<Track>('tracksBox'); // open in bootstrap
    for (var file in mp3Files) {
      final track = Track(
        id: const Uuid().v4(),
        title: file.uri.pathSegments.last,
        artist: 'Unknown',
        filePath: file.path,
        artworkPath: 'assets/placeholder.jpg',
        duration: 0,
      );
      await box.put(track.id, track);
    }
  }
}
