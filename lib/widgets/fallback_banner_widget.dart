import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:easy_audience_network/easy_audience_network.dart'; // <-- TAMBAHKAN IMPORT INI
import '../main.dart'; // Untuk akses instance adService global
import 'package:easy_audience_network/src/banner.dart';

class FallbackBannerWidget extends StatefulWidget {
  const FallbackBannerWidget({super.key});

  @override
  State<FallbackBannerWidget> createState() => _FallbackBannerWidgetState();
}

class _FallbackBannerWidgetState extends State<FallbackBannerWidget> {
  admob.BannerAd? _admobBanner;
  bool _isAdmobBannerLoaded = false;
  bool _didAdmobFail = false;

  @override
  void initState() {
    super.initState();
    // Memuat iklan hanya jika diaktifkan secara global
    if (adService.areAdsGloballyEnabled) {
      _loadAdmobBanner();
    }
  }

  void _loadAdmobBanner() {
    // Jika ID AdMob kosong, langsung fallback ke FAN
    if (adService.admobBannerUnitId.isEmpty) {
      print("ID AdMob Banner kosong, langsung fallback ke FAN.");
      if (mounted) {
        setState(() {
          _didAdmobFail = true;
        });
      }
      return;
    }

    _admobBanner = admob.BannerAd(
      adUnitId: adService.admobBannerUnitId,
      request: const admob.AdRequest(),
      size: admob.AdSize.banner,
      listener: admob.BannerAdListener(
        onAdLoaded: (ad) {
          print('AdMob Banner Ad berhasil dimuat.');
          if (mounted) {
            setState(() {
              _isAdmobBannerLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('AdMob Banner Ad gagal dimuat: $error. Fallback ke FAN.');
          ad.dispose();
          if (mounted) {
            setState(() {
              _didAdmobFail = true;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _admobBanner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika iklan dinonaktifkan secara global, jangan tampilkan apa-apa
    if (!adService.areAdsGloballyEnabled) {
      return const SizedBox.shrink();
    }

    // Prioritas 1: Tampilkan AdMob Banner jika sudah termuat
    if (_isAdmobBannerLoaded && _admobBanner != null) {
      return SizedBox(
        width: _admobBanner!.size.width.toDouble(),
        height: _admobBanner!.size.height.toDouble(),
        child: admob.AdWidget(ad: _admobBanner!),
      );
    }

    // Prioritas 2: Jika AdMob gagal, tampilkan Facebook Banner
    if (_didAdmobFail && adService.fanBannerPlacementId.isNotEmpty) {
      return EasyBannerAd( // Sekarang widget ini akan dikenali
        placementId: adService.fanBannerPlacementId,
        bannerSize: BannerSize.STANDARD, // Atau ukuran lain
        listener: (event, args) {
          print("Easy FAN Banner Listener: $event");
        },
      );
    }

    // Tampilkan placeholder dengan ukuran yang benar saat iklan sedang dimuat
    return SizedBox(
      height: admob.AdSize.banner.height.toDouble(),
      width: admob.AdSize.banner.width.toDouble(),
      child: const Center(
        // child: CircularProgressIndicator(strokeWidth: 2), // Opsional: tampilkan loading
      ),
    );
  }
}