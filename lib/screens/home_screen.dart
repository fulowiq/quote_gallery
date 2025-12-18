import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
// Імпортуємо репозиторій, щоб бачити клас Quote
import '../repositories/app_repository.dart';
import 'profile_screen.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  const QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.text,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '— ${quote.author}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                IconButton(
                  icon: Icon(
                    quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: quote.isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    context.read<AppState>().toggleFavorite(quote.id, quote.isFavorite);
                  },
                ),
              ],
            ),
            if (quote.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: quote.tags.map((tag) => Chip(
                  label: Text('#$tag', style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAddQuoteDialog(BuildContext context) {
    final textController = TextEditingController();
    final authorController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нова цитата'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textController, decoration: const InputDecoration(labelText: 'Текст', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 10),
              TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Автор', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: tagsController, decoration: const InputDecoration(labelText: 'Теги (через кому)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                context.read<AppState>().addQuote(
                  textController.text,
                  authorController.text,
                  tagsController.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Опублікувати'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuoteGallery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Рекомендації'), // Тут будуть Всі цитати
            Tab(text: 'Мої'),          // Тут тільки твої
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка 1: Рекомендації
          _buildQuoteList(appState.allQuotesStream, canDelete: false),

          // Вкладка 2: Мої
          _buildQuoteList(appState.myQuotesStream, canDelete: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuoteList(Stream<List<Quote>> stream, {required bool canDelete}) {
    return StreamBuilder<List<Quote>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final quotes = snapshot.data ?? [];
        if (quotes.isEmpty) return const Center(child: Text('Порожньо'));

        return ListView.builder(
          itemCount: quotes.length,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (context, index) {
            final quote = quotes[index];

            // Свайп для видалення тільки у вкладці "Мої"
            if (canDelete) {
              return Dismissible(
                key: Key(quote.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  context.read<AppState>().removeQuote(quote.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Цитату видалено')),
                  );
                },
                child: QuoteCard(quote: quote),
              );
            }
            return QuoteCard(quote: quote);
          },
        );
      },
    );
  }
}