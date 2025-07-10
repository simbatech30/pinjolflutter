import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk SystemUiOverlayStyle
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_html/flutter_html.dart';
import '../main.dart';
import '../models/article_model.dart';
import '../services/ad_service.dart';

// Instance global adService dari main.dart (diasumsikan)
// final AdService adService = AdService();

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (adService.isAdConfigLoaded && adService.areAdsGloballyEnabled) {
      _createBannerAd();
    } else {
      print("ArticleDetailScreen initState: Ads are disabled or config not loaded. Skipping ad creation.");
    }
  }

  void _createBannerAd() {
    if (!adService.areAdsGloballyEnabled || adService.bannerAdUnitId.isEmpty) {
      print("Banner Ad creation skipped in ArticleDetailScreen: Ads disabled or AdUnitId missing.");
      if (mounted) setState(() => _isBannerAdLoaded = false);
      return;
    }
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: adService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded in ArticleDetailScreen.');
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad in ArticleDetailScreen: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme appTextTheme = Theme.of(context).textTheme;
    final Color borderColor = Colors.grey.shade400;

    return Scaffold(
      // --- APPBAR YANG DISESUAIKAN ---
      appBar: AppBar(
        title: Text(widget.article.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1.0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        iconTheme: IconThemeData( // Untuk warna tombol kembali (leading icon)
          color: Theme.of(context).colorScheme.primary, // Atau onSurface
        ),
        // Tidak ada actions di halaman ini, jadi actionsIconTheme tidak terlalu relevan
      ),
      // --- AKHIR APPBAR ---
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (widget.article.logoUrl != null && widget.article.logoUrl!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Image.network(
                          widget.article.logoUrl!,
                          height: 100,
                          errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Text(
                    widget.article.title,
                    style: appTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Html(
                    data: widget.article.content,
                    style: { // Style untuk HTML content
                      "body": Style(
                        fontSize: FontSize(appTextTheme.bodyLarge?.fontSize ?? 16.0),
                        lineHeight: LineHeight.em(1.5),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        fontSize: FontSize(appTextTheme.bodyLarge?.fontSize ?? 16.0),
                        padding: HtmlPaddings.only(bottom: 12.0),
                        lineHeight: LineHeight.em(1.5),
                      ),
                      "ul": Style(
                        padding: HtmlPaddings.only(left: 25.0, bottom: 10.0),
                        margin: Margins.symmetric(vertical: 8.0),
                        listStyleType: ListStyleType.disc,
                      ),
                      "ol": Style(
                        padding: HtmlPaddings.only(left: 25.0, bottom: 10.0),
                        margin: Margins.symmetric(vertical: 8.0),
                        listStyleType: ListStyleType.decimal,
                      ),
                      "li": Style(
                        fontSize: FontSize(appTextTheme.bodyLarge?.fontSize ?? 16.0),
                        lineHeight: LineHeight.em(1.6),
                        padding: HtmlPaddings.only(bottom: 4.0),
                      ),
                      "strong": Style(fontWeight: FontWeight.bold),
                      "em": Style(fontStyle: FontStyle.italic),
                      "a": Style(
                        color: Theme.of(context).colorScheme.primary,
                        textDecoration: TextDecoration.underline,
                      ),
                      "table": Style(
                        width: Width.auto(),
                        border: Border.all(color: borderColor),
                        margin: Margins.symmetric(vertical: 12.0),
                      ),
                      "thead": Style( backgroundColor: Colors.grey[200] ),
                      "th": Style(
                        padding: HtmlPaddings.all(8.0),
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                        border: Border.all(color: borderColor),
                        backgroundColor: Colors.grey[200],
                      ),
                      "td": Style(
                        padding: HtmlPaddings.all(8.0),
                        textAlign: TextAlign.left,
                        border: Border.all(color: borderColor),
                      ),
                    },
                    onLinkTap: (url, attributes, element) {
                      if (url != null) {
                        print('Link tapped: $url');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Link di-tap: $url (implementasi url_launcher diperlukan untuk membuka)')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (adService.areAdsGloballyEnabled && _isBannerAdLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}