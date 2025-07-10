class Category {
  final String id;
  final String title;
  final String imageUrl;

  Category({required this.id, required this.title, required this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}