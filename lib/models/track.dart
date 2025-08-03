import 'package:hive/hive.dart';
part 'track.g.dart';

@HiveType(typeId: 0)
class Track extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String artist;
  @HiveField(3) final String filePath;   // absolute path on disk
  @HiveField(4) final String artworkPath;
  @HiveField(5) final int duration;  

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.artworkPath,
    required this.duration,
  });
}
