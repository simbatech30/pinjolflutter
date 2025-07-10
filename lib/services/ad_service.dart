import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:easy_audience_network/easy_audience_network.dart';
import 'package:http/http.dart' as http;

class AdConfig {
  final bool adsGloballyEnabled;
  final Map<String, String> admobAndroidIds;
  final Map<String, String> admobIosIds;
  final Map<String, String> fanAndroidIds;
  final Map<String, String> fanIosIds;

  AdConfig({
    required this.adsGloballyEnabled,
    required this.admobAndroidIds,
    required this.admobIosIds,
    required this.fanAndroidIds,
    required this.fanIosIds,
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    Map<String, String> parsePlatformIds(Map<String, dynamic>? platformJson) {
      if (platformJson == null) return {};
      return {
        'banner': platformJson['banner'] as String? ?? '',
        'interstitial': platformJson['interstitial'] as String? ?? '',
        'appOpen': platformJson['appOpen'] as String? ?? '',
      };
    }

    return AdConfig(
      adsGloballyEnabled: json['adsGloballyEnabled'] as bool? ?? false,
      admobAndroidIds: parsePlatformIds(json['admob']?['android']),
      admobIosIds: parsePlatformIds(json['admob']?['ios']),
      fanAndroidIds: parsePlatformIds(json['fan']?['android']),
      fanIosIds: parsePlatformIds(json['fan']?['ios']),
    );
  }
}

class AdService {
  AdConfig? _adConfig;
  bool _isAdConfigLoaded = false;
  bool get isAdConfigLoaded => _isAdConfigLoaded;
  bool get areAdsGloballyEnabled => _adConfig?.adsGloballyEnabled ?? false;

  static const String _adConfigUrl = "https://raw.githubusercontent.com/simbatech30/guidepinjol/refs/heads/main/adconfigtest.json";

  Future<void> loadRemoteAdConfig() async {
    if (_isAdConfigLoaded) return;

    try {
      final response = await http.get(Uri.parse(_adConfigUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        _adConfig = AdConfig.fromJson(jsonData);
        _isAdConfigLoaded = true;
        print("Ad config loaded: ${_adConfig?.adsGloballyEnabled}");
      } else {
        _setDefaultFallbackConfig();
      }
    } catch (e) {
      _setDefaultFallbackConfig();
    }
  }

  void _setDefaultFallbackConfig() {
    _adConfig = AdConfig(
      adsGloballyEnabled: false,
      admobAndroidIds: {},
      admobIosIds: {},
      fanAndroidIds: {},
      fanIosIds: {},
    );
    _isAdConfigLoaded = true;
  }

  String _getAdUnitId(String network, String adType) {
    if (!_isAdConfigLoaded || _adConfig == null) return '';
    Map<String, String> ids;
    if (network == 'admob') {
      ids = Platform.isAndroid ? _adConfig!.admobAndroidIds : _adConfig!.admobIosIds;
    } else {
      ids = Platform.isAndroid ? _adConfig!.fanAndroidIds : _adConfig!.fanIosIds;
    }
    return ids[adType] ?? '';
  }

  String get admobBannerUnitId => _getAdUnitId('admob', 'banner');
  String get admobInterstitialUnitId => _getAdUnitId('admob', 'interstitial');
  String get admobAppOpenUnitId => _getAdUnitId('admob', 'appOpen');
  String get fanBannerPlacementId => _getAdUnitId('fan', 'banner');
  String get fanInterstitialPlacementId => _getAdUnitId('fan', 'interstitial');

  admob.InterstitialAd? _admobInterstitialAd;
  int _admobLoadAttempts = 0;
  int _fanInterstitialId = 0;
  bool _isFanInterstitialLoaded = false;

  void createInterstitialAd() {
    if (!areAdsGloballyEnabled) return;
    _admobInterstitialAd = null;
    _admobLoadAttempts = 0;
    _loadAdmobInterstitial();
  }

  void _loadAdmobInterstitial() {
    if (admobInterstitialUnitId.isEmpty) {
      _loadFanInterstitial();
      return;
    }

    admob.InterstitialAd.load(
      adUnitId: admobInterstitialUnitId,
      request: const admob.AdRequest(),
      adLoadCallback: admob.InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _admobInterstitialAd = ad;
          _admobLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _admobLoadAttempts++;
          print("AdMob Interstitial failed: $error");
          _admobInterstitialAd = null;
          _loadFanInterstitial();
        },
      ),
    );
  }

  void _loadFanInterstitial() {
    if (fanInterstitialPlacementId.isEmpty) return;

    _isFanInterstitialLoaded = false;
    EasyAudienceNetwork.loadInterstitialAd(
      _fanInterstitialId,
      placementId: fanInterstitialPlacementId,
      listener: (event, args) {
        print("FAN Interstitial: $event -> $args");
        if (event == InterstitialAdPlatformInterfaceResult.LOADED) {
          _isFanInterstitialLoaded = true;
        }
      },
    );
  }

  void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (!areAdsGloballyEnabled) {
      onAdDismissed?.call();
      return;
    }

    if (_admobInterstitialAd != null) {
      _admobInterstitialAd!.fullScreenContentCallback = admob.FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _admobInterstitialAd = null;
          createInterstitialAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _admobInterstitialAd = null;
          createInterstitialAd();
          onAdDismissed?.call();
        },
      );
      _admobInterstitialAd!.show();
      _admobInterstitialAd = null;
    } else if (_isFanInterstitialLoaded) {
      EasyAudienceNetwork.showInterstitialAd(_fanInterstitialId);
      _isFanInterstitialLoaded = false;
      createInterstitialAd();
      onAdDismissed?.call();
    } else {
      print("No interstitial ad available.");
      onAdDismissed?.call();
    }
  }

  // AppOpen Ads (AdMob only)
  admob.AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;

  void loadAppOpenAd() {
    if (!areAdsGloballyEnabled || admobAppOpenUnitId.isEmpty) return;
    if (_appOpenAd != null || _isShowingAppOpenAd) return;

    admob.AppOpenAd.load(
      adUnitId: admobAppOpenUnitId,
      request: const admob.AdRequest(),
      adLoadCallback: admob.AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (error) => _appOpenAd = null,
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    if (!areAdsGloballyEnabled || _appOpenAd == null || _isShowingAppOpenAd) return;

    _appOpenAd!.fullScreenContentCallback = admob.FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingAppOpenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
    );

    _appOpenAd!.show();
  }

  void disposeAds() {
    _admobInterstitialAd?.dispose();
    _appOpenAd?.dispose();
  }
}
