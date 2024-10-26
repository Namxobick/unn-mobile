import 'dart:convert';
import 'dart:io';

import 'package:unn_mobile/core/constants/api_url_strings.dart';
import 'package:unn_mobile/core/constants/session_identifier_strings.dart';
import 'package:unn_mobile/core/misc/http_helper.dart';
import 'package:unn_mobile/core/models/feed/blog_post_data.dart';
import 'package:unn_mobile/core/services/interfaces/authorisation_service.dart';
import 'package:unn_mobile/core/services/interfaces/feed/getting_blog_posts.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';

class _QueryParamNames {
  static const start = 'start';
  static const _postId = 'POST_ID';
}

class GettingBlogPostsImpl implements GettingBlogPosts {
  final AuthorizationService _authorisationService;
  final LoggerService _loggerService;
  final int _numberOfPostsPerPage = 50;

  GettingBlogPostsImpl(
    this._authorisationService,
    this._loggerService,
  );

  @override
  Future<List<BlogPostData>?> getBlogPosts({
    int pageNumber = 0,
    int? postId,
  }) async {
    final requestSender = HttpRequestSender(
      path: ApiPaths.blogPostGet,
      queryParams: {
        SessionIdentifierStrings.sessid: _authorisationService.csrf ?? '',
        _QueryParamNames.start: (_numberOfPostsPerPage * pageNumber).toString(),
        _QueryParamNames._postId: postId.toString(),
      },
      cookies: {
        SessionIdentifierStrings.sessionIdCookieKey:
            _authorisationService.sessionId ?? '',
      },
    );

    HttpClientResponse response;
    try {
      response = await requestSender.get(timeoutSeconds: 60);
    } catch (error, stackTrace) {
      _loggerService.log('Exception: $error\nStackTrace: $stackTrace');
      return null;
    }

    final statusCode = response.statusCode;

    if (statusCode != 200) {
      _loggerService.log(
        'statusCode = $statusCode; pageNumber = $pageNumber; postId = $postId;',
      );
      return null;
    }

    final str = await HttpRequestSender.responseToStringBody(response);
    dynamic jsonList;
    try {
      jsonList = jsonDecode(str)['result'];
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
