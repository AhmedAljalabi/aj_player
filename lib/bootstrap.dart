// lib/bootstrap.dart
//
// Single entry-point to initialise *everything* the app relies on:
// • Permissions (permission_handler)
// • Hive (tracks, playlists, favourites)
// • SharedPreferences
// • Background audio-service handler
// • TrackScanner to populate Hive from local storage
// • GetIt service-locator registration
//
// Call  ➜  await AppBootstrap.init();   before runApp() in main.dart.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

import 'models/track.dart';
import 'models/playlist.dart';
import 'services/audio_handler.dart';
import 'services/track_scanner.dart';

class AppBootstrap {
  // make the ctor private so nobody instantiates this class
  AppBootstrap._();

  // ---------------------------------------------------------------------------
  // Public static API
  // ---------------------------------------------------------------------------
  static late SharedPreferences prefs;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1️⃣ Ask for storage permission first (Android) ---------------------------
    await _requestStoragePerm();

    // 2️⃣ Hive setup ----------------------------------------------------------
    await Hive.initFlutter();
    Hive.registerAdapter(TrackAdapter());     // generated via build_runner
    Hive.registerAdapter(PlaylistAdapter());

    // Open all boxes you’ll use across the app
    await Future.wait([
      Hive.openBox<Track>('tracksBox'),
      Hive.openBox<String>('favoritesBox'),
      Hive.openBox<Playlist>('playlistsBox'),
    ]);

    // 3️⃣ Shared preferences --------------------------------------------------
    prefs = await SharedPreferences.getInstance();

    // 4️⃣ Background audio handler -------------------------------------------
    final audioHandler = await AudioPlayerHandler.init();
    GetIt.I.registerSingleton<AudioPlayerHandler>(audioHandler);

    // 5️⃣ Scan local storage for mp3/flac files (only first run or manual) ---
    //    You can wrap this in a flag if you want to skip scanning every launch.
    await TrackScanner.scanAndCache();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  static Future<void> _requestStoragePerm() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      // If permission is denied, you may want to show a dialog and/or exit.
      debugPrint('Storage permission not granted – app functionality limited.');
    }
  }
}
