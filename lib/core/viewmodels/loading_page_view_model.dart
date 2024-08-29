import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:unn_mobile/core/misc/app_open_tracker.dart';
import 'package:unn_mobile/core/misc/app_settings.dart';
import 'package:unn_mobile/core/misc/loading_pages.dart';
import 'package:unn_mobile/core/misc/current_user_sync_storage.dart';
import 'package:unn_mobile/core/models/loading_page_data.dart';
import 'package:unn_mobile/core/services/interfaces/authorisation_service.dart';
import 'package:unn_mobile/core/services/interfaces/authorisation_refresh_service.dart';
import 'package:unn_mobile/core/services/interfaces/getting_profile_of_current_user_service.dart';
import 'package:unn_mobile/core/services/interfaces/user_data_provider.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';
import 'package:unn_mobile/ui/router.dart';

enum _TypeScreen {
  authScreen,
  mainScreen,
}

class LoadingPageViewModel extends BaseViewModel {
  final AuthorizationRefreshService initializingApplicationService;
  final CurrentUserSyncStorage typeOfCurrentUser;
  final GettingProfileOfCurrentUser gettingProfileOfCurrentUser;
  final UserDataProvider userDataProvider;
  final AppOpenTracker appOpenTracker;

  LoadingPageViewModel(
    this.initializingApplicationService,
    this.typeOfCurrentUser,
    this.gettingProfileOfCurrentUser,
    this.userDataProvider,
    this.appOpenTracker,
  );

  final actualLoadingPage = LoadingPages().actualLoadingPage;

  LoadingPageModel get loadingPageData => actualLoadingPage;

  void disateRoute(context) {
    _init().then((value) => _goToScreen(context, value));
  }

  Future<_TypeScreen> _init() async {
    AuthRequestResult? authRequestResult;
    late _TypeScreen typeScreen;

    await AppSettings.load();

    try {
      authRequestResult = await initializingApplicationService.refreshLogin();
    } catch (error, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
    typeScreen = switch (authRequestResult) {
      null => _TypeScreen.authScreen,
      AuthRequestResult.success => _TypeScreen.mainScreen,
      AuthRequestResult.noInternet => _TypeScreen.mainScreen,
      AuthRequestResult.wrongCredentials => _TypeScreen.authScreen,
    };

    if (typeScreen == _TypeScreen.mainScreen) {
      await _initUserData();
    }

    return typeScreen;
  }

  void _goToScreen(context, _TypeScreen typeScreen) {
    final routes = switch (typeScreen) {
      _TypeScreen.authScreen => Routes.authPage,
      _TypeScreen.mainScreen => Routes.mainPagePrefix,
    };
    Navigator.of(context!).pushNamedAndRemoveUntil(routes, (route) => false);
  }

  Future<void> _initUserData() async {
    if (await appOpenTracker.isFirstTimeOpenOnVersion()) {
      final profile =
          await gettingProfileOfCurrentUser.getProfileOfCurrentUser();
      userDataProvider.saveData(profile);
    }

    await typeOfCurrentUser.updateCurrentUserInfo();
    if (typeOfCurrentUser.currentUserData != null &&
        typeOfCurrentUser.currentUserData!.fullUrlPhoto != null) {
      DefaultCacheManager().downloadFile(
        typeOfCurrentUser.currentUserData!.fullUrlPhoto!,
      );
    }
  }
}
