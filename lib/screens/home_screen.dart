import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../widgets/category_card.dart';
import '../widgets/fallback_banner_widget.dart'; // <-- IMPORT WIDGET BANNER BARU
import 'category_articles_screen.dart';
import 'loan_calculator_screen.dart';
import '../services/api_service.dart';
import '../services/ad_service.dart';
import '../main.dart'; // Untuk akses instance global apiService dan adService

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Category>> _futureCategories;

  // Logika banner (_bannerAd, _isBannerAdLoaded, _createBannerAd) dihapus dari sini

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Hanya preload interstitial, banner ditangani oleh widgetnya sendiri
    if (adService.areAdsGloballyEnabled) {
      adService.createInterstitialAd();
    }
  }

  void _loadCategories() {
    setState(() {
      _futureCategories = apiService.fetchCategories();
    });
  }

  @override
  void dispose() {
    // Tidak perlu dispose banner di sini lagi
    super.dispose();
  }

  void _navigateToCategoryArticles(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryArticlesScreen(category: category),
      ),
    );
  }

  Widget _buildCalculatorCard() {
    return GestureDetector(
      onTap: () {
        if (adService.areAdsGloballyEnabled) {
          adService.showInterstitialAd(onAdDismissed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoanCalculatorScreen()),
            );
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoanCalculatorScreen()),
          );
        }
      },
      child: Card(
        elevation: 4.0,
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.asset(
                'assets/images/calculator_card.png', // Ganti dengan path gambar Anda
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.calculate_rounded,
                      size: 60,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                "Kalkulator Pinjaman",
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (_buildNoInternetUI dan _buildErrorUI tetap sama seperti sebelumnya) ...
  Widget _buildNoInternetUI(String message) { /* ... */ }
  Widget _buildErrorUI(dynamic error) { /* ... */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Anda'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1.0,
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        actionsIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
        actions: [ /* ... Tombol AppBar Anda ... */ ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: _futureCategories,
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
                  final categories = snapshot.data!;
                  if (categories.isEmpty) return const Center(child: Text('Tidak ada kategori ditemukan.'));
                  return ListView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: categories.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index < categories.length) {
                        final category = categories[index];
                        return CategoryCard(
                          category: category,
                          onTap: () {
                            adService.showInterstitialAd(onAdDismissed: () {
                              _navigateToCategoryArticles(category);
                            });
                          },
                        );
                      } else {
                        return _buildCalculatorCard();
                      }
                    },
                  );
                }
                return const Center(child: Text('Tidak ada data kategori.'));
              },
            ),
          ),
          // --- GUNAKAN WIDGET FALLBACK BANNER DI SINI ---
          const FallbackBannerWidget(),
        ],
      ),
    );
  }
}