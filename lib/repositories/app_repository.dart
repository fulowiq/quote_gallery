import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- КЛАС QUOTE (Модель даних) ---
// Живе тут, щоб не створювати окремий файл
class Quote {
  final String id;
  final String text;
  final String author;
  final List<String> tags;
  final String userId;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime? timestamp;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.tags,
    required this.userId,
    this.imageUrl,
    this.isFavorite = false,
    this.timestamp,
  });

  factory Quote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quote(
      id: doc.id,
      text: data['text'] ?? '',
      author: data['author'] ?? 'Невідомий',
      tags: List<String>.from(data['tags'] ?? []),
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'],
      isFavorite: data['isFavorite'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

// --- РЕПОЗИТОРІЙ ---
class AppRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. РЕКОМЕНДАЦІЇ: Беремо ВСІ цитати з бази (для загальної стрічки)
  Stream<List<Quote>> getGlobalQuotesStream() {
    return _db
        .collection('quotes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Quote.fromFirestore(doc)).toList());
  }

  // 2. МОЇ: Беремо тільки цитати поточного користувача
  Stream<List<Quote>> getUserQuotesStream(String userId) {
    return _db
        .collection('quotes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final quotes = snapshot.docs.map((doc) => Quote.fromFirestore(doc)).toList();
      // Сортуємо вручну на клієнті
      quotes.sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));
      return quotes;
    });
  }

  // Додавання цитати
  Future<void> addQuote(Map<String, dynamic> data) async {
    await _db.collection('quotes').add(data);
  }

  // Видалення
  Future<void> deleteQuote(String id) async {
    await _db.collection('quotes').doc(id).delete();
  }

  // Лайк
  Future<void> toggleFavorite(String id, bool currentStatus) async {
    await _db.collection('quotes').doc(id).update({'isFavorite': !currentStatus});
  }

  // Завантаження Аватарки (Вимога Лаби 6 про інтеграцію Storage [cite: 436])
  Future<void> uploadUserAvatar(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final Reference ref = _storage.ref().child('avatars/${user.uid}.jpg');
      await ref.putFile(imageFile);
      final String downloadUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(downloadUrl);
      await user.reload();
    } catch (e) {
      // Якщо впаде через оплату - не страшно, код є для звіту
      rethrow;
    }
  }
}