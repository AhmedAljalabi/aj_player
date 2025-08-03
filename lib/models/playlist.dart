// models/playlist.dart
import 'package:hive/hive.dart';
part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) List<String> trackIds; // list of Track.id

  Playlist({required this.name, required this.trackIds});
}
