import 'package:dio/dio.dart';
import 'package:unn_mobile/core/constants/api_url_strings.dart';
import 'package:unn_mobile/core/misc/api_helpers/base_api_helper.dart';
import 'package:unn_mobile/core/models/mark_by_subject.dart';
import 'package:unn_mobile/core/services/interfaces/getting_grade_book.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';

class _JsonKeys {
  static const String semesters = 'semesters';
  static const String semester = 'semester';
  static const String data = 'data';
}

class GettingGradeBookImpl implements GettingGradeBook {
  final LoggerService _loggerService;
  final BaseApiHelper _baseApiHelper;

  GettingGradeBookImpl(
    this._loggerService,
    this._baseApiHelper,
  );

  @override
  Future<Map<int, List<MarkBySubject>>?> getGradeBook() async {
    Response response;
    try {
      response = await _baseApiHelper.get(
        path: ApiPaths.marks,
      );
    } catch (error, stackTrace) {
      _loggerService.logError(error, stackTrace);
      return null;
    }

    final Map<int, List<MarkBySubject>> marks = {};
    for (final course in response.data) {
      for (final semesterInfo in course[_JsonKeys.semesters] ?? []) {
        final semester = semesterInfo[_JsonKeys.semester]?.toInt();
        final data = semesterInfo[_JsonKeys.data] ?? [];
        if (semester != null) {
          final List<MarkBySubject> semesterMarks = data
              .map<MarkBySubject>(
                (markBySubject) => MarkBySubject.fromJson(markBySubject),
              )
              .toList();
          marks[semester] = semesterMarks;
        }
      }
    }
    return marks;
  }
}
