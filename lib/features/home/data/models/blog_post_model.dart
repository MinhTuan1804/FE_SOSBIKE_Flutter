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
  final int? viewCount;

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
    this.viewCount,
  });

  BlogPostModel copyWith({
    String? blogpostId,
    String? slug,
    String? title,
    String? summary,
    String? content,
    String? coverImageUrl,
    String? category,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    int? viewCount,
  }) {
    return BlogPostModel(
      blogpostId: blogpostId ?? this.blogpostId,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

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
      viewCount: json['viewCount'] != null ? int.tryParse(json['viewCount'].toString()) : null,
    );
  }
}
