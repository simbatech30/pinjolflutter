import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../models/article_model.dart';
import '../widgets/article_summary_card.dart';
import '../widgets/fallback_banner_widget.dart'; // <-- IMPORT WIDGET BANNER BARU
import 'article_detail_screen.dart';
import '../services/api_service.dart';
import '../services/ad_service.dart';
import '../main.dart'; // Untuk akses instance global

class CategoryArticlesScreen extends StatefulWidget {
  final Category category;

  const CategoryArticlesScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryArticlesScreen> createState() => _CategoryArticlesScreenState();
}

class _CategoryArticlesScreenState extends State<CategoryArticlesScreen> {
  late Future<List<Article>> _futureArticles;

  // Logika banner (_bannerAd, _isBannerAdLoaded, _createBannerAd) dihapus dari sini

  @override
  void initState() {
    super.initState();
    _loadArticles();
    // Hanya preload interstitial
    if (adService.areAdsGloballyEnabled) {
      adService.createInterstitialAd();
    }
  }

  void _loadArticles() {
    setState(() {
      _futureArticles = apiService.fetchArticlesByCategoryId(widget.category.id);
    });
  }

  @override
  void dispose() {
    // Tidak perlu dispose banner di sini lagi
    super.dispose();
  }

  void _navigateToArticleDetail(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(article: article),
      ),
    );
  }

  // ... (_buildNoInternetUI dan _buildErrorUI tetap sama) ...
  Widget _buildNoInternetUI(String message) { /* ... */ }
  Widget _buildErrorUI(dynamic error) { /* ... */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1.0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
        actionsIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
        actions: [ /* ... Tombol Refresh ... */ ],
      ),
      // --- GUNAKAN WIDGET FALLBACK BANNER DI SINI ---
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 8.0), // Beri sedikit padding jika perlu
        child: FallbackBannerWidget(),
      ),
      body: FutureBuilder<List<Article>>(
        future: _futureArticles,
        builder: (context, snapshot) {
          // ... (Logika FutureBuilder tetap sama) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            if (snapshot.error is NoInternetException) {
              return _buildNoInternetUI((snapshot.error as NoInternetException).message);
            }
            return _buildErrorUI(snapshot.error);
          } else if (snapshot.hasData) {
            final articles = snapshot.data!;
            if (articles.isEmpty) return const Center(child: Text('Belum ada artikel dalam kategori ini.'));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              itemCount: articles.length,
              itemBuilder: (ctx, index) {
                final article = articles[index];
                return ArticleSummaryCard(
                  article: article,
                  onTap: () {
                    adService.showInterstitialAd(onAdDismissed: () {
                      _navigateToArticleDetail(article);
                    });
                  },
                );
              },
            );
          }
          return const Center(child: Text('Tidak ada data artikel.'));
        },
      ),
    );
  }
}