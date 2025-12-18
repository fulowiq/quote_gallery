import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Модель даних
class Quote {
  final String id;
  final String text;
  final String author;
  final List<String> tags;
  final String userId;
  bool isFavorite;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.tags,
    required this.userId,
    this.isFavorite = false,
  });

  factory Quote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quote(
      id: doc.id,
      text: data['text'] ?? '',
      author: data['author'] ?? 'Невідомий',
      tags: List<String>.from(data['tags'] ?? []),
      userId: data['userId'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
    );
  }
}

class AppState extends ChangeNotifier {
  bool _isDarkMode = false
  bool get isDarkMode => _isDarkMode;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Stream<List<Quote>> get quotesStream {
    return _db
        .collection('quotes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Quote.fromFirestore(doc)).toList());
  }

  Stream<List<Quote>> get favoriteQuotesStream {
    return quotesStream.map(
          (quotes) => quotes.where((q) => q.isFavorite).toList(),
    );
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // Додавання цитати в базу
  Future<void> addQuote(String text, String author, String tagsRaw) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('quotes').add({
        'text': text,
        'author': author.isEmpty ? 'Невідомий' : author,
        'tags': tagsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'userId': user.uid,
        'isFavorite': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(name: 'add_quote', parameters: {
        'has_author': author.isNotEmpty ? 1 : 0,
      });
    } catch (e) {
      debugPrint("Помилка додавання: $e");
    }
  }

  Future<void> toggleFavorite(String quoteId, bool currentStatus) async {
    try {
      await _db.collection('quotes').doc(quoteId).update({
        'isFavorite': !currentStatus,
      });
    } catch (e) {
      debugPrint("Помилка оновлення лайка: $e");
    }
  }

  Future<void> removeQuote(String quoteId) async {
    try {
      await _db.collection('quotes').doc(quoteId).delete();
    } catch (e) {
      debugPrint("Помилка видалення: $e");
    }
  }
}