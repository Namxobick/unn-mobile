import 'package:dio/dio.dart';
import 'package:unn_mobile/core/constants/regular_expressions.dart';
import 'package:unn_mobile/core/constants/api_url_strings.dart';
import 'package:unn_mobile/core/misc/api_helpers/api_helper.dart';
import 'package:unn_mobile/core/models/feed/blog_post_comment_data.dart';
import 'package:unn_mobile/core/services/interfaces/feed/legacy/getting_blog_post_comments.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';

class _JsonKeys {
  static const _messageListKey = 'messageList';
}

class GettingBlogPostCommentsImpl implements GettingBlogPostComments {
  final LoggerService _loggerService;
  final ApiHelper _apiHelper;

  GettingBlogPostCommentsImpl(
    this._loggerService,
    this._apiHelper,
  );
  @override
  Future<List<BlogPostCommentData>?> getBlogPostComments({
    required int postId,
    int pageNumber = 1,
  }) async {
    final bodyAsJson = await getRawBodyOfBlogComments(
      postId: postId,
      pageNumber: pageNumber,
    );

    if (bodyAsJson == null) {
      return null;
    }

    return parseComments(bodyAsJson);
  }

  Future<Map<String, dynamic>?> getRawBodyOfBlogComments({
    required int postId,
    int pageNumber = 0,
  }) async {
    final Response response;
    try {
      response = await _apiHelper.post(
        path: ApiPaths.ajax,
        queryParameters: {
          'mode': 'class',
          AjaxActionStrings.actionKey: AjaxActionStrings.navigateComment,
          'c': AjaxActionStrings.comment,
        },
        body: {
          'ENTITY_XML_ID': 'BLOG_$postId',
          'AJAX_POST': 'Y',
          'MODE': 'LIST',
          'comment_post_id': postId.toString(),
          'PAGEN_1': pageNumber.toString(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    } catch (error, stackTrace) {
      _loggerService.log('Exception: $error\nStackTrace: $stackTrace');
      return null;
    }

    return response.data;
  }

  List<BlogPostCommentData>? parseComments(Map<String, dynamic> bodyAsJson) {
    const unknownString = 'unknown';

    if (!bodyAsJson.containsKey(_JsonKeys._messageListKey)) {
      _loggerService.log(
        'json doesn\'t contain the messageList key',
      );
      return null;
    }

    final htmlBody = bodyAsJson[_JsonKeys._messageListKey] as String;

    final comments = <BlogPostCommentData>[];

    final commentsAttachedFilesId = parseCommentsFilesId(htmlBody);

    final authorMatches =
        RegularExpressions.authorRegExp.allMatches(htmlBody).iterator;
    final dateTimeMatches =
        RegularExpressions.dateTimeRegExp.allMatches(htmlBody).iterator;
    final keySignedMatches =
        RegularExpressions.keySignedRegExp.allMatches(htmlBody).iterator;

    for (final messageMatch
        in RegularExpressions.commentIdAndMessageRegExp.allMatches(htmlBody)) {
      if (!authorMatches.moveNext()) {
        _loggerService.log('no author matches');
        break;
      }

      final authorMatch = authorMatches.current;

      if (!dateTimeMatches.moveNext()) {
        _loggerService.log('no dateTime matches');
        break;
      }

      if (!keySignedMatches.moveNext()) {
        _loggerService.log('no keySigned matches');
        break;
      }

      final dateTimeMatch = dateTimeMatches.current;
      final keySignedMatche = keySignedMatches.current;

      final id = messageMatch.group(1).toInt();
      final message = messageMatch.group(2)?.replaceAll('\\n', '\n');
      final authorId = authorMatch.group(1).toInt();
      final dateTime = dateTimeMatch.group(1);
      final keySigned =
          keySignedMatche.group(0)?.split(' \'')[1].split('\'')[0];

      if (id != null && authorId != null) {
        comments.add(
          BlogPostCommentData(
            id: id,
            authorBitrixId: authorId,
            dateTime: dateTime ?? unknownString,
            message: message ?? unknownString,
            keySigned: keySigned ?? unknownString,
            attachedFiles: commentsAttachedFilesId[id] ?? [],
          ),
        );
      }
    }

    return comments;
  }

  Map<int, List<int>> parseCommentsFilesId(String htmlBody) {
    final commentIdToAttachFiles = <int, List<int>>{};

    RegularExpressions.filesRegExp.allMatches(htmlBody).forEach((match) {
      final commentId = match.group(1);
      final filesListAsString = match.group(2);

      if (commentId != null && filesListAsString != null) {
        final commentIdAsInt = commentId.toInt();
        if (commentIdAsInt != null) {
          commentIdToAttachFiles[commentIdAsInt] =
              filesListAsString.split(',').map((idAsString) {
            return idAsString.substring(1, idAsString.length - 1).toInt()!;
          }).toList();
        }
      }
    });

    return commentIdToAttachFiles;
  }
}

extension on String? {
  int? toInt() {
    if (this == null) {
      return null;
    }

    try {
      return int.parse(this!);
    } on FormatException {
      return null;
    }
  }
}
