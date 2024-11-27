import 'dart:io';

import 'package:injector/injector.dart';
import 'package:path/path.dart' as path;
import 'package:unn_mobile/core/misc/size_converter.dart';
import 'package:unn_mobile/core/models/file_data.dart';
import 'package:unn_mobile/core/services/interfaces/file_downloader.dart';
import 'package:unn_mobile/core/services/interfaces/getting_file_data.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';
import 'package:unn_mobile/core/viewmodels/factories/attached_file_view_model_factory.dart';

enum AttachedFileType {
  image,
  audio,
  gif,
  unknown,
}

class AttachedFileViewModel extends BaseViewModel {
  static const Map<String, AttachedFileType> _fileTypes = {
    '.png': AttachedFileType.image,
    '.jpg': AttachedFileType.image,
    '.jpeg': AttachedFileType.image,
    '.gif': AttachedFileType.gif,
    '.mp3': AttachedFileType.audio,
    '.wav': AttachedFileType.audio,
    '.ogg': AttachedFileType.audio,
  };

  /// Глобальный набор файлов, которые сейчас грузятся
  static final Map<int, Future<File?>> _pendingFileDownloads = {};

  final GettingFileData _fileDataService;
  final LoggerService _loggerService;
  final FileDownloaderService _fileDownloaderService;

  final SizeConverter sizeConverter = SizeConverter();

  late int _fileId;

  FileData? _loadedData;

  bool _isLoadingData = false;
  bool _hasError = false;
  String? _error;

  AttachedFileViewModel(
    this._fileDataService,
    this._loggerService,
    this._fileDownloaderService,
  );
  factory AttachedFileViewModel.cached(AttachedFileCacheKey key) {
    return Injector.appInstance
        .get<AttachedFileViewModelFactory>()
        .getViewModel(key);
  }

  String get error => _error ?? '';

  // '_.' - чтобы substring не падал с ошибкой, если данных еще нет
  String get fileExtension =>
      path.extension(_loadedData?.name ?? '_.').substring(1);

  String get fileName => _loadedData?.name ?? '';

  String get fileSizeText {
    if (_loadedData == null) {
      return '';
    }
    final sizeNoUnits = sizeConverter
        .convertBytesToSize(_loadedData!.sizeInBytes)
        .toStringAsFixed(2);
    final unitString = sizeConverter.lastUsedUnit!.getUnitString();
    return '$sizeNoUnits $unitString';
  }

  AttachedFileType get fileType =>
      _fileTypes[path.extension(_loadedData?.name ?? '')] ??
      AttachedFileType.unknown;

  bool get hasError => _hasError;

  /// Статус скачивания файла
  bool get isDownloadingFile => _pendingFileDownloads.containsKey(_fileId);

  /// Статус получения информации о файле
  bool get isLoadingData => _isLoadingData;

  Future<File?> getFile({bool force = false}) async {
    if (_loadedData == null) {
      return null;
    }
    final fileName = '${_loadedData?.id}_${_loadedData?.name}';

    final fileId = _loadedData!.id;
    try {
      final downloadUrl = _loadedData!.downloadUrl;
      if (force && _pendingFileDownloads.containsKey(fileId)) {
        await _pendingFileDownloads[fileId];
        _pendingFileDownloads.remove(fileId);
      }
      _pendingFileDownloads.putIfAbsent(
        fileId,
        () => _fileDownloaderService.downloadFile(
          fileName,
          downloadUrl: downloadUrl,
          force: force,
        ),
      );
      notifyListeners();
      return await _pendingFileDownloads[_loadedData!.id];
    } catch (error, stack) {
      _loggerService.logError(error, stack);
      return null;
    } finally {
      _pendingFileDownloads.remove(_loadedData!.id);
      notifyListeners();
    }
  }

  void init({int? fileId, FileData? fileData}) {
    assert(fileId != null || fileData != null);
    if (initialized) {
      return;
    }
    isInitialized = true;

    _fileId = fileData?.id ?? fileId!;

    _isLoadingData = true;
    if (fileData == null) {
      _loadData(fileId!).then((file) {
        _loadedData = file;
      }).catchError((error, stack) {
        _loggerService.logError(error, stack);
        _hasError = true;
      }).whenComplete(() {
        _isLoadingData = false;
        notifyListeners(); // Я надеюсь, это выполнится после строчек выше
      });
      return;
    }
    _loadedData = fileData;
    notifyListeners();
  }

  Future<FileData?> _loadData(int fileId) async {
    return await _fileDataService.getFileData(id: fileId);
  }
}
