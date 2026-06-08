import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/home/data/models/blog_post_model.dart';
import 'package:fe_moblie_flutter/features/home/presentation/providers/home_provider.dart';

class BlogSection extends StatelessWidget {
  const BlogSection({
    super.key,
    required this.isLoading,
    required this.posts,
  });

  final bool isLoading;
  final List<BlogPostModel> posts;

  void _showAllBlogsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tất cả bài viết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C1111),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (itemContext, index) {
                    final post = posts[index];
                    return InkWell(
                      onTap: () {
                        unawaited(context.read<HomeProvider>().trackBlogView(post.slug));
                        Navigator.pop(sheetContext);
                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (context.mounted) {
                            _BlogCard(post: post).showBlogDetailModal(context);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8DADA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BlogThumb(post: post),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((post.category ?? '').isNotEmpty || post.viewCount != null) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if ((post.category ?? '').isNotEmpty)
                                          Text(
                                            post.category!.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B1A1A),
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        if (post.viewCount != null)
                                          Row(
                                            children: [
                                              Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${post.viewCount}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    post.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C1111),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DADA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Blog mới từ SOSBIKE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C1111)),
              ),
              if (posts.length > 5)
                TextButton(
                  onPressed: () => _showAllBlogsModal(context),
                  child: const Text(
                    'Xem thêm',
                    style: TextStyle(color: Color(0xFF8B1A1A), fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tin tức, mẹo bảo dưỡng và hướng dẫn an toàn cho người đi xe máy.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (posts.isEmpty)
            Text('Chưa có bài viết nào.', style: TextStyle(fontSize: 13, color: Colors.grey[700]))
          else
            SizedBox(
              height: 310,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length > 5 ? 5 : posts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _BlogCard(post: post);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BlogThumb extends StatelessWidget {
  const _BlogThumb({required this.post});

  final BlogPostModel post;

  @override
  Widget build(BuildContext context) {
    final url = post.coverImageUrl ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          height: 80,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFEEE3E3),
              child: const Icon(Icons.article, size: 28, color: Color(0xFF8B1A1A)),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFEEE3E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.article, size: 28, color: Color(0xFF8B1A1A)),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.post});

  final BlogPostModel post;

  void showBlogDetailModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<HomeProvider>(
          builder: (consumerContext, provider, _) {
            final currentPost = provider.posts.firstWhere(
              (p) => p.slug == post.slug,
              orElse: () => post,
            );

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chi tiết bài viết',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((currentPost.coverImageUrl ?? '').isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  currentPost.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFEEE3E3),
                                    child: const Icon(Icons.article, size: 48, color: Color(0xFF8B1A1A)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if ((currentPost.category ?? '').isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B1A1A).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                currentPost.category!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B1A1A)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            currentPost.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2C1111),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (currentPost.publishedAt != null || currentPost.viewCount != null) ...[
                            Row(
                              children: [
                                if (currentPost.publishedAt != null)
                                  Text(
                                    'Đăng ngày: ${currentPost.publishedAt!.day.toString().padLeft(2, '0')}/${currentPost.publishedAt!.month.toString().padLeft(2, '0')}/${currentPost.publishedAt!.year}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                  ),
                                if (currentPost.publishedAt != null && currentPost.viewCount != null) ...[
                                  const SizedBox(width: 10),
                                  Text('•', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                  const SizedBox(width: 10),
                                ],
                                if (currentPost.viewCount != null) ...[
                                  Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${currentPost.viewCount} lượt xem',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 16),
                          Text(
                            (currentPost.content ?? '').trim().isNotEmpty ? currentPost.content! : currentPost.summary,
                            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: () {
            unawaited(context.read<HomeProvider>().trackBlogView(post.slug));
            showBlogDetailModal(context);
          },
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _BlogThumb(post: post),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if ((post.category ?? '').isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B1A1A).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                post.category!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8B1A1A)),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          if (post.viewCount != null)
                            Row(
                              children: [
                                Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.viewCount}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2C1111)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
