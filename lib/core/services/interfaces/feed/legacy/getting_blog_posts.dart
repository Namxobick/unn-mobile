import 'package:unn_mobile/core/models/feed/blog_post_data.dart';

abstract interface class GettingBlogPosts {
  /// Получает 50 записей из живой ленты или 1 запись по конкретному postId
  ///
  /// [pageNumber]: номер страницы, с которой возьмутся записи (поумолчанию 0)
  /// (т.е. на 0-ой странице первые 50 записей, на 1-ой - с 50 по 99 запись и т.д.)
  /// [postId]: id поста (не blogId), который нужно получить (по умолчанию null)
  /// P.s. postId приоритетнее pageNumber
  ///
  /// Возвращает:
  ///   - список [BlogPostData]
  ///   - пустой список, если конкретный postId не вышло получить
  ///   - null, если:
  ///     1. Не вышло получить ответ от портала
  ///     2. statusCode не равен 200
  ///     3. Не вышло декодировать ответ
  Future<List<BlogPostData>?> getBlogPosts({int pageNumber = 0, int? postId});
}
