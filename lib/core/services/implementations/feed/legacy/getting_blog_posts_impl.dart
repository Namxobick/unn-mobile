import 'package:dio/dio.dart';
import 'package:unn_mobile/core/constants/api_url_strings.dart';
import 'package:unn_mobile/core/constants/session_identifier_strings.dart';
import 'package:unn_mobile/core/misc/api_helpers/api_helper.dart';
import 'package:unn_mobile/core/models/feed/blog_post_data.dart';
import 'package:unn_mobile/core/services/interfaces/authorisation_service.dart';
import 'package:unn_mobile/core/services/interfaces/feed/legacy/getting_blog_posts.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';

class _QueryParamNames {
  static const start = 'start';
  static const _postId = 'POST_ID';
}

class GettingBlogPostsImpl implements GettingBlogPosts {
  final AuthorizationService _authorizationService;
  final LoggerService _loggerService;
  final ApiHelper _apiHelper;
  final int _numberOfPostsPerPage = 50;

  GettingBlogPostsImpl(
    this._authorizationService,
    this._loggerService,
    this._apiHelper,
  );

  @override
  Future<List<BlogPostData>?> getBlogPosts({
    int pageNumber = 0,
    int? postId,
  }) async {
    Response response;
    try {
      response = await _apiHelper.get(
        path: ApiPaths.blogPostGet,
        queryParameters: {
          SessionIdentifierStrings.sessid: _authorizationService.csrf ?? '',
          _QueryParamNames.start:
              (_numberOfPostsPerPage * pageNumber).toString(),
          _QueryParamNames._postId: postId.toString(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
    } catch (error, stackTrace) {
      _loggerService.log('Exception: $error\nStackTrace: $stackTrace');
      return null;
    }

    dynamic jsonList;
    try {
      jsonList = response.data['result'];
    } catch (erorr, stackTrace) {
      _loggerService.logError(erorr, stackTrace);
      return null;
    }

    List<BlogPostData>? blogPosts;
    try {
      blogPosts = jsonList
          .map<BlogPostData>(
            (blogPostJson) => BlogPostData.fromJson(blogPostJson),
          )
          .toList();
    } catch (error, stackTrace) {
      _loggerService.logError(error, stackTrace);
    }

    if (blogPosts != null) {
      blogPosts.sort((a, b) => b.datePublish.compareTo(a.datePublish));
    }

    return blogPosts;
  }
}
