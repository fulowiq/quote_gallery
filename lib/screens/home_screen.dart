import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'profile_screen.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  const QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    quote.text,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${quote.author}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (quote.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: quote.tags.map((tag) => Chip(
                  label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                    labelText: 'Цитата', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(
                    labelText: 'Автор', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                    labelText: 'Теги (через кому)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                // Додаємо через Provider
                context.read<AppState>().addQuote(
                  textController.text,
                  authorController.text,
                  tagsController.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Додати'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Стрічка', icon: Icon(Icons.dynamic_feed)),
            Tab(text: 'Улюблені', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuoteList(appState.quotesStream),
          _buildQuoteList(appState.favoriteQuotesStream),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Універсальний будівник списку зі StreamBuilder
  Widget _buildQuoteList(Stream<List<Quote>> stream) {
    return StreamBuilder<List<Quote>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final quotes = snapshot.data ?? [];

        if (quotes.isEmpty) {
          return const Center(
            child: Text('Поки що тут пусто. Додайте першу цитату!'),
          );
        }

        return ListView.builder(
          itemCount: quotes.length,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (context, index) {
            final quote = quotes[index];
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
          },
        );
      },
    );
  }
}