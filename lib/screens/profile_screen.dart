import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'login_screen.dart';
import '../providers/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профіль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
            const SizedBox(height: 16),
            Text(user?.email ?? 'Користувач',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),

            // Картка зі статистикою (Live)
            StreamBuilder<List<Quote>>(
              stream: appState.quotesStream,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const Text('Всього цитат'),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Налаштування теми
            Card(
              child: SwitchListTile(
                title: const Text('Темна тема'),
                secondary: Icon(appState.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                value: appState.isDarkMode,
                onChanged: (val) => context.read<AppState>().toggleTheme(val),
              ),
            ),
            const SizedBox(height: 16),

            // Тест крашу
            OutlinedButton(
              onPressed: () => FirebaseCrashlytics.instance.crash(),
              child: const Text('Викликати помилку (Test Crash)'),
            ),
          ],
        ),
      ),
    );
  }
}