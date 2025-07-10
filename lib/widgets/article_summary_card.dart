import 'package:flutter/material.dart';
import '../models/article_model.dart';

class ArticleSummaryCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleSummaryCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              article.logoUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: Icon(Icons.article_outlined, color: Colors.grey[500])),
            ),
          ),
        ),
        title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(article.shortContent ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}