import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Важливо!
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'providers/app_state.dart'; // Наш новий файл

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const QuoteGalleryApp(),
    ),
  );
}

class QuoteGalleryApp extends StatelessWidget {
  const QuoteGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Слухаємо зміни теми
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'QuoteGallery',
      debugShowCheckedModeBanner: false,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}