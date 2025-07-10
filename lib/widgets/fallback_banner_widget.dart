import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_audience_network/easy_audience_network.dart';
import '../main.dart';
import '../services/ad_service.dart';

class FallbackBannerWidget extends StatefulWidget {
  const FallbackBannerWidget({super.key});

  @override
  State<FallbackBannerWidget> createState() => _FallbackBannerWidgetState();
}

class _FallbackBannerWidgetState extends State<FallbackBannerWidget> {
  BannerAd? _admobBannerAd;
  bool _isAdmobBannerLoaded = false;
  bool _isFanBannerLoaded = false;
  bool _showAdmobBanner = false;
  bool _showFanBanner = false;

  @override
  void initState() {
    super.initState();
    if (adService.isAdConfigLoaded && adService.areAdsGloballyEnabled) {
      _loadBannerAds();
    } else {
      print("FallbackBannerWidget: Ads are disabled or config not loaded");
    }
  }

  void _loadBannerAds() {
    // Try AdMob first
    if (adService.admobBannerUnitId.isNotEmpty) {
      _loadAdmobBanner();
    } else {
      // If no AdMob, try FAN
      _loadFanBanner();
    }
  }

  void _loadAdmobBanner() {
    if (adService.admobBannerUnitId.isEmpty) {
      _loadFanBanner();
      return;
    }

    print("Loading AdMob Banner");
    _admobBannerAd?.dispose();
    _admobBannerAd = BannerAd(
      adUnitId: adService.admobBannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('AdMob Banner loaded in FallbackBannerWidget');
          if (mounted) {
            setState(() {
              _isAdmobBannerLoaded = true;
              _showAdmobBanner = true;
              _showFanBanner = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('AdMob Banner failed to load in FallbackBannerWidget: $error');
          ad.dispose();
          _admobBannerAd = null;
          if (mounted) {
            setState(() {
              _isAdmobBannerLoaded = false;
              _showAdmobBanner = false;
            });
          }
          // Fallback to FAN
          _loadFanBanner();
        },
      ),
    );
    _admobBannerAd!.load();
  }

  void _loadFanBanner() {
    if (adService.fanBannerPlacementId.isEmpty) {
      print("FAN Banner placement ID is empty");
      return;
    }

    print("Loading FAN Banner with placement: ${adService.fanBannerPlacementId}");

    if (mounted) {
      setState(() {
        _isFanBannerLoaded = false;
        _showFanBanner = true;
        _showAdmobBanner = false;
      });
    }

    // Load FAN Banner using EasyAudienceNetwork
    EasyAudienceNetwork.showBannerAd(
      placementId: adService.fanBannerPlacementId,
      bannerSize: BannerSize.STANDARD,
      listener: (result, value) {
        print('FAN Banner Event in FallbackBannerWidget: $result -> $value');
        if (mounted) {
          switch (result) {
            case BannerAdResult.LOADED:
              setState(() {
                _isFanBannerLoaded = true;
                _showFanBanner = true;
                _showAdmobBanner = false;
              });
              break;
            case BannerAdResult.ERROR:
              setState(() {
                _isFanBannerLoaded = false;
                _showFanBanner = false;
              });
              break;
            case BannerAdResult.CLICKED:
              print('FAN Banner clicked');
              break;
            case BannerAdResult.LOGGING_IMPRESSION:
              print('FAN Banner impression logged');
              break;
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _admobBannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika ads tidak aktif, jangan tampilkan widget
    if (!adService.areAdsGloballyEnabled) {
      return const SizedBox.shrink();
    }

    // Tampilkan AdMob Banner jika tersedia
    if (_showAdmobBanner && _isAdmobBannerLoaded && _admobBannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _admobBannerAd!.size.width.toDouble(),
        height: _admobBannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _admobBannerAd!),
      );
    }

    // Tampilkan FAN Banner jika tersedia
    if (_showFanBanner && _isFanBannerLoaded) {
      return Container(
        alignment: Alignment.center,
        height: 50, // Standard banner height
        child: const FacebookBannerAd(
          placementId: '', // This will be set by EasyAudienceNetwork
          bannerSize: BannerSize.STANDARD,
        ),
      );
    }

    // Tampilkan placeholder loading jika FAN sedang dimuat
    if (_showFanBanner && !_isFanBannerLoaded) {
      return Container(
        alignment: Alignment.center,
        height: 50,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Jika tidak ada banner yang berhasil dimuat, jangan tampilkan apa-apa
    return const SizedBox.shrink();
  }
}
