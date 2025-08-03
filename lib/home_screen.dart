import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:aj_player/models/track.dart';
import 'package:aj_player/play_music.dart';
import 'package:aj_player/models/playlist.dart';
import 'package:aj_player/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Track> trackBox;
  late Box<String> favBox;
  late Box<Playlist> playlistBox;

  @override
  void initState() {
    super.initState();
    trackBox = Hive.box<Track>('tracksBox');
    favBox = Hive.box<String>('favoritesBox');
    playlistBox = Hive.box<Playlist>('playlistsBox');
  }

  @override
  Widget build(BuildContext context) {
    final tracks = trackBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/A (3).jpg'),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Good Morning!", style: TextStyle(fontSize: 12, color: Colors.white70)),
            Text("Ahmed Aljalabi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(CupertinoIcons.bell), onPressed: () {}),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: tracks.isEmpty
            ? const Center(child: Text("No tracks found"))
            : GridView.builder(
                itemCount: tracks.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10),
                itemBuilder: (_, i) => _TrackTile(
                  track: tracks[i],
                  isFav: favBox.containsKey(tracks[i].id),
                  onFavToggle: () {
                    final id = tracks[i].id;
                    favBox.containsKey(id) ? favBox.delete(id) : favBox.put(id, id);
                    setState(() {});
                  },
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayMusic(track: tracks[i])),
                  ),
                  onLongPress: () => _showPlaylistDialog(tracks[i]),
                ),
              ),
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(30, 0, 30, 20),
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(.6),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(CupertinoIcons.home, color: Colors.white), onPressed: () {}),
            IconButton(icon: const Icon(CupertinoIcons.search, color: Colors.white), onPressed: () {}),
            IconButton(icon: const Icon(CupertinoIcons.heart, color: Colors.white), onPressed: () {}),
            IconButton(
              icon: const Icon(CupertinoIcons.person, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistDialog(Track track) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          for (final p in playlistBox.values)
            ListTile(
              title: Text(p.name),
              onTap: () {
                p.trackIds.add(track.id);
                p.save();
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New playlist'),
            onTap: () {
              final controller = TextEditingController();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Playlist name'),
                  content: TextField(controller: controller),
                  actions: [
                    TextButton(
                      child: const Text('Create'),
                      onPressed: () {
                        playlistBox.add(Playlist(name: controller.text, trackIds: [track.id]));
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close sheet
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final bool isFav;
  final VoidCallback onFavToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TrackTile({
    required this.track,
    required this.isFav,
    required this.onFavToggle,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: File(track.artworkPath).existsSync()
                      ? FileImage(File(track.artworkPath))
                      : const AssetImage('assets/placeholder.jpg') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(track.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(track.artist),
            IconButton(
              icon: Icon(isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: Colors.red),
              onPressed: onFavToggle,
            ),
          ],
        ),
      ),
    );
  }
}
