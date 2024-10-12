import 'package:unn_mobile/core/models/blog_data.dart';

abstract interface class BlogPostsService {
  Future<List<BlogData>?> getBlogPosts({int? pageNumber, int perpage = 50});
}