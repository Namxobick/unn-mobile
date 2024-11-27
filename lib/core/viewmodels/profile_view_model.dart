import 'package:injector/injector.dart';
import 'package:unn_mobile/core/misc/current_user_sync_storage.dart';
import 'package:unn_mobile/core/misc/user_functions.dart';
import 'package:unn_mobile/core/models/student_data.dart';
import 'package:unn_mobile/core/models/user_data.dart';
import 'package:unn_mobile/core/models/user_short_info.dart';
import 'package:unn_mobile/core/services/interfaces/getting_profile.dart';
import 'package:unn_mobile/core/services/interfaces/getting_profile_of_current_user_service.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';
import 'package:unn_mobile/core/viewmodels/factories/profile_view_model_factory.dart';

class ProfileViewModel extends BaseViewModel {
  final GettingProfileOfCurrentUser _getCurrentUserService;
  final CurrentUserSyncStorage _currentUserSyncStorage;
  final GettingProfile _getProfileService;
  final LoggerService _loggerService;

  bool _isLoading = false;

  bool _hasError = false;

  UserData? _loadedData;
  UserShortInfo? _shortInfo;

  String? _description;

  ProfileViewModel(
    this._getCurrentUserService,
    this._getProfileService,
    this._loggerService,
    this._currentUserSyncStorage,
  );

  factory ProfileViewModel.cached(ProfileCacheKey key) {
    return Injector.appInstance
        .get<ProfileViewModelFactory>()
        .getViewModel(key);
  }
  factory ProfileViewModel.currentUser() {
    return Injector.appInstance
        .get<ProfileViewModelFactory>()
        .getCurrentUserViewModel();
  }
  String? get avatarUrl => _loadedData?.fullUrlPhoto ?? _shortInfo?.photoSrc;

  String get description => _description ?? '';

  String get fullname =>
      _loadedData?.fullname.toString() ?? //
      _shortInfo?.fullname ?? //
      'Не удалось загрузить';

  bool get hasAvatar =>
      _loadedData?.fullUrlPhoto != null || _shortInfo?.photoSrc != null;

  bool get hasError => _hasError;

  String get initials => getUserInitials(_loadedData, _shortInfo);

  bool get isLoading => _isLoading;

  bool get hasShortInfo => _shortInfo != null;

  void init({
    bool force = false,
    int? userId,
    bool loadCurrentUser = false,
    bool loadFromPost = false,
    UserShortInfo? userShortInfo,
  }) {
    assert((userId == null) == loadCurrentUser || userShortInfo != null);
    if (force || (_loadedData == null && _shortInfo == null)) {
      _isLoading = true;
      _hasError = false;
      _shortInfo = userShortInfo;
      notifyListeners();

      (loadCurrentUser ? _getCurrentUser() : _getProfile(userId!, loadFromPost))
          .then((data) {
        _loadedData = data;
        _description = switch (data.runtimeType) {
          const (StudentData) => (data as StudentData).eduGroup,
          _ => '',
        };
      }).catchError((error, stack) {
        _loggerService.logError(error, stack);
        _hasError = true;
      }).whenComplete(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<UserData?> _getCurrentUser() async {
    final currentUser = await _getCurrentUserService.getProfileOfCurrentUser();
    return currentUser ?? _currentUserSyncStorage.currentUserData;
  }

  Future<UserData?> _getProfile(int userId, bool loadFromPost) async {
    return loadFromPost
        ? await _getProfileService.getProfileByAuthorIdFromPost(
            authorId: userId,
          )
        : await _getProfileService.getProfile(
            userId: userId,
          );
  }
}
