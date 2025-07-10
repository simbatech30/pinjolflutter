class Article {
  final String id;
  final String categoryId;
  final String title;
  final String content;
  final String? logoUrl;
  final String? shortContent;

  Article({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    this.logoUrl,
    this.shortContent,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      content: json['content'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      shortContent: json['shortContent'] as String?,
    );
  }
}