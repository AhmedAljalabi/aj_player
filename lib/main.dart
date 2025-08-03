import 'package:flutter/material.dart';
import 'package:aj_player/home_screen.dart';
import 'package:aj_player/bootstrap.dart';  // bootstrapping dependencies

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // required for async init
  await AppBootstrap.init();                 // sets up permissions, Hive, prefs

  final isDark = AppBootstrap.prefs.getBool('isDark') ?? true;

  runApp(MyApp(isDarkMode: isDark));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AJ Player',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const HomeScreen(),
    );
  }
}
