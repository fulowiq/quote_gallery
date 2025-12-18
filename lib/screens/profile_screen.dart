import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import 'login_screen.dart';
// ВИПРАВЛЕНО: Беремо Quote з репозиторію, а не з неіснуючого файлу models
import '../repositories/app_repository.dart';

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

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && context.mounted) {
      await context.read<AppState>().updateAvatar(File(image.path));
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
            GestureDetector(
              onTap: () => _pickAndUploadImage(context),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(8),
                    child: appState.isUploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.email ?? 'Користувач', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),

            StreamBuilder<List<Quote>>(
              stream: appState.allQuotesStream,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(children: [
                        Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Всього цитат у стрічці'),
                      ]),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Темна тема'),
                secondary: Icon(appState.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                value: appState.isDarkMode,
                onChanged: (val) => context.read<AppState>().toggleTheme(val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}