import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Імпортуємо репозиторій, де тепер живе клас Quote
import '../repositories/app_repository.dart';

class AppState extends ChangeNotifier {
  final AppRepository _repository = AppRepository();
  bool _isDarkMode = false;
  bool _isUploading = false;

  bool get isDarkMode => _isDarkMode;
  bool get isUploading => _isUploading;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Стріми даних
  Stream<List<Quote>> get allQuotesStream => _repository.getGlobalQuotesStream();

  Stream<List<Quote>> get myQuotesStream {
    if (currentUser == null) return const Stream.empty();
    return _repository.getUserQuotesStream(currentUser!.uid);
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // Зміна аватарки
  Future<void> updateAvatar(File imageFile) async {
    _isUploading = true;
    notifyListeners();
    try {
      await _repository.uploadUserAvatar(imageFile);
      await currentUser?.reload();
    } catch (e) {
      debugPrint("Storage error: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Додавання цитати (одразу публікується)
  Future<void> addQuote(String text, String author, String tagsRaw) async {
    if (currentUser == null) return;

    final quoteData = {
      'text': text,
      'author': author.isEmpty ? 'Невідомий' : author,
      'tags': tagsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'userId': currentUser!.uid,
      'isFavorite': false,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _repository.addQuote(quoteData);
  }

  Future<void> removeQuote(String id) async {
    await _repository.deleteQuote(id);
  }

  Future<void> toggleFavorite(String id, bool status) async {
    await _repository.toggleFavorite(id, status);
  }
}