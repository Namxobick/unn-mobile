import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injector/injector.dart';
import 'package:unn_mobile/core/misc/http_helper.dart';
import 'package:unn_mobile/core/models/file_data.dart';
import 'package:unn_mobile/core/services/interfaces/authorisation_service.dart';
import 'package:unn_mobile/core/services/interfaces/getting_file_data.dart';

class GettingFileDataImpl implements GettingFileData {
  final String _path = 'rest/disk.attachedObject.get';
  final String _sessid = 'sessid';
  final String _id = 'id';
  final String _sessionIdCookieKey = "PHPSESSID";

  @override
  Future<FileData?> getFileData({
    required int id,
  }) async {
    final authorisationService =
        Injector.appInstance.get<AuthorisationService>();

    final requestSender = HttpRequestSender(path: _path, queryParams: {
      _sessid: authorisationService.csrf ?? '',
      _id: id.toString(),
    }, cookies: {
      _sessionIdCookieKey: authorisationService.sessionId ?? '',
    });

    HttpClientResponse response;
    try {
      response = await requestSender.get(timeoutSeconds: 60);
    } catch (error, stackTrace) {
      await FirebaseCrashlytics.instance
          .log("Exception: $error\nStackTrace: $stackTrace");
      return null;
    }

    final statusCode = response.statusCode;

    if (statusCode != 200) {
      await FirebaseCrashlytics.instance.log(
          '${runtimeType.toString()}: statusCode = $statusCode; fileId = $id');
      return null;
    }

    dynamic jsonMap;
    try {
      jsonMap = jsonDecode(
          await HttpRequestSender.responseToStringBody(response))['result'];
    } catch (error, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }

    FileData? fileData;
    try {
      fileData = FileData.fromJson(jsonMap);
    } catch (error, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }

    return fileData;
  }
}
