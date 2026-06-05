class BlogPostModel {
  final String blogpostId;
  final String slug;
  final String title;
  final String summary;
  final String? content;
  final String? coverImageUrl;
  final String? category;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  BlogPostModel({
    required this.blogpostId,
    required this.slug,
    required this.title,
    required this.summary,
    this.content,
    this.coverImageUrl,
    this.category,
    required this.isPublished,
    this.publishedAt,
    this.createdAt,
  });

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    return BlogPostModel(
      blogpostId: (json['blogpostid'] ?? json['blogPostId'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      content: json['content']?.toString(),
      coverImageUrl: json['coverimageurl']?.toString(),
      category: json['category']?.toString(),
      isPublished: json['ispublished'] == true,
      publishedAt: json['publishedat'] == null ? null : DateTime.tryParse(json['publishedat'].toString()),
      createdAt: json['createdat'] == null ? null : DateTime.tryParse(json['createdat'].toString()),
    );
  }
}
