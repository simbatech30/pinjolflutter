import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_audience_network/easy_audience_network.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/api_service.dart';

// Membuat instance global agar mudah diakses dari seluruh aplikasi
final AdService adService = AdService();
final ApiService apiService = ApiService();

void main() async {
  // Pastikan Flutter Binding sudah siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi kedua SDK Iklan
  await MobileAds.instance.initialize();
  await EasyAudienceNetwork.init();

  // Load konfigurasi Ad Unit ID dari JSON Online
  await adService.loadRemoteAdConfig();

  // Load App Open Ad hanya jika iklan diaktifkan dari remote config
  if (adService.areAdsGloballyEnabled && adService.isAdConfigLoaded) {
    adService.loadAppOpenAd();
  } else {
    print("App Open Ad loading skipped: Iklan nonaktif oleh remote config atau config gagal dimuat.");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Gunakan WidgetsBindingObserver untuk mendeteksi siklus hidup aplikasi (misal: kembali dari background)
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Coba tampilkan App Open Ad setelah aplikasi berjalan dan config dimuat
    if (adService.isAdConfigLoaded && adService.areAdsGloballyEnabled) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          print("MyApp initState: Mencoba menampilkan AppOpenAd.");
          if (adService.areAdsGloballyEnabled) {
            adService.showAppOpenAdIfAvailable();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    adService.disposeAds();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Tampilkan App Open Ad ketika aplikasi kembali dari background
    if (state == AppLifecycleState.resumed) {
      if (adService.areAdsGloballyEnabled && adService.isAdConfigLoaded) {
        if (adService.wasInterstitialDismissedRecently) {
          // Jika Interstitial baru saja ditutup, jangan tampilkan App Open Ad
          print("AppOpenAd dilewati: Interstitial Ad baru saja ditutup.");
          adService.wasInterstitialDismissedRecently = false; // Reset flag
        } else {
          print("AppOpenAd attempt: Aplikasi resume dan tidak ada Interstitial Ad yang baru ditutup.");
          adService.showAppOpenAdIfAvailable();
        }
      } else {
        print("AppOpenAd attempt dilewati saat resume: Iklan nonaktif atau config belum dimuat.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Panduan Anda', // Ganti dengan judul aplikasi Anda
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), // Ganti 'teal' dengan warna dasar tema Anda
        useMaterial3: true,
        // Tema global untuk AppBar agar konsisten
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700], // Atau warna lain
          foregroundColor: Colors.white,
          elevation: 2.0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}