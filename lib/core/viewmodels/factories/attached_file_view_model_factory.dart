import 'package:flutter/foundation.dart';
import 'package:unn_mobile/core/services/interfaces/file_downloader.dart';
import 'package:unn_mobile/core/services/interfaces/getting_file_data.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';
import 'package:unn_mobile/core/viewmodels/attached_file_view_model.dart';
import 'package:unn_mobile/core/viewmodels/factories/cached_view_model_factory_base.dart';

typedef AttachedFileCacheKey = int;

class AttachedFileViewModelFactory extends CachedViewModelFactoryBase<
    AttachedFileCacheKey, AttachedFileViewModel> {
  AttachedFileViewModelFactory() : super(100);

  @override
  @protected
  AttachedFileViewModel createViewModel(key) {
    return AttachedFileViewModel(
      getService<GettingFileData>(),
      getService<LoggerService>(),
      getService<FileDownloaderService>(
        dependencyName: 'FeedFileDownloaderService',
      ),
    );
  }
}
