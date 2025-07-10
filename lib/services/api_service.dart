import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/article_model.dart';

class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);
  @override
  String toString() => message;
}

class AppData {
  final List<Category> categories;
  final List<Article> articles;
  AppData({required this.categories, required this.articles});
}

class ApiService {
  // !!! GANTI DENGAN URL RAW JSON KONTEN ANDA DARI GITHUB !!!
  static const String _appDataUrl = "https://raw.githubusercontent.com/simbatech30/guidepinjol/refs/heads/main/pinjolribu.json";
  AppData? _cachedAppData;
  dynamic _lastError;

  dynamic getLastError() => _lastError;
  bool isLastFetchDueToNoInternet() => _lastError is NoInternetException;

  Future<AppData> _fetchAndParseData() async {
    // Jika data sudah ada di cache (sudah diacak sebelumnya), langsung kembalikan
    if (_cachedAppData != null) {
      print("Menggunakan data dari cache yang sudah diacak.");
      return _cachedAppData!;
    }

    try {
      final response = await http.get(Uri.parse(_appDataUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));

        List<Category> categories = (jsonData['categories'] as List)
            .map((item) => Category.fromJson(item))
            .toList();

        List<Article> articles = (jsonData['articles'] as List)
            .map((item) => Article.fromJson(item))
            .toList();

        // --- LOGIKA PENGACAKAN POSISI ---
        print("Mengacak urutan kategori dan artikel...");
        categories.shuffle();
        articles.shuffle();
        // ---------------------------------

        _cachedAppData = AppData(categories: categories, articles: articles);
        _lastError = null;
        return _cachedAppData!;
      } else {
        throw HttpException('Gagal memuat data (Status: ${response.statusCode})');
      }
    } on Exception catch (e) {
      if (e is SocketException || e is http.ClientException || e is TimeoutException) {
        _lastError = NoInternetException("Tidak ada koneksi internet. Silakan periksa jaringan Anda.");
      } else {
        _lastError = e;
      }
      rethrow;
    }
  }

  Future<List<Category>> fetchCategories() async {
    final data = await _fetchAndParseData();
    return data.categories;
  }

  Future<List<Article>> fetchArticlesByCategoryId(String categoryId) async {
    final data = await _fetchAndParseData();
    // Filter artikel berdasarkan categoryId, urutannya akan acak karena list utama sudah diacak
    return data.articles.where((article) => article.categoryId == categoryId).toList();
  }

  void clearCache() {
    _cachedAppData = null;
    print("Cache data konten dibersihkan.");
  }
}