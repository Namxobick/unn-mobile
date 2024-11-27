import 'package:dio/dio.dart';
import 'package:unn_mobile/core/constants/regular_expressions.dart';
import 'package:unn_mobile/core/constants/api_url_strings.dart';
import 'package:unn_mobile/core/misc/api_helpers/api_helper.dart';
import 'package:unn_mobile/core/services/interfaces/feed/legacy/getting_vote_key_signed.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';

class _PathParts {
  static const blog = 'blog';
}

class GettingVoteKeySignedImpl implements GettingVoteKeySigned {
  final LoggerService _loggerService;
  final ApiHelper _apiHelper;

  GettingVoteKeySignedImpl(
    this._loggerService,
    this._apiHelper,
  );

  @override
  Future<String?> getVoteKeySigned({
    required int authorId,
    required int postId,
  }) async {
    final path =
        '${ApiPaths.companyPersonalUser}/$authorId/${_PathParts.blog}/$postId/';

    final Response response;

    try {
      response = await _apiHelper.get(
        path: path,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
    } catch (error, stackTrace) {
      _loggerService.log('Exception: $error\nStackTrace: $stackTrace');
      return null;
    }

    String? keySignedMatches;
    try {
      keySignedMatches = (RegularExpressions.keySignedRegExp
          .firstMatch(response.data)
          ?.group(0) as String);
    } catch (error, stackTrace) {
      _loggerService.logError(error, stackTrace);
      return null;
    }

    return keySignedMatches.split(' \'')[1].split('\'')[0];
  }
}
