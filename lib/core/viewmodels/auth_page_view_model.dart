import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:unn_mobile/core/misc/custom_errors/auth_error_messages.dart';
import 'package:unn_mobile/core/models/auth_data.dart';
import 'package:unn_mobile/core/services/interfaces/auth_data_provider.dart';
import 'package:unn_mobile/core/services/interfaces/authorisation_service.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';

class AuthPageViewModel extends BaseViewModel {
  final AuthDataProvider authDataProvider;
  final AuthorizationService authorisationService;

  bool _hasAuthError = false;

  AuthPageViewModel(this.authDataProvider, this.authorisationService);

  bool get hasAuthError => _hasAuthError;

  String _authErrorText = '';
  String get authErrorText => _authErrorText;

  Future<bool> login(String user, String password) async {
    setState(ViewState.busy);
    _resetAuthError();

    AuthRequestResult? authResult;

    try {
      authResult = await authorisationService.auth(user, password);
    } catch (error, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }

    if (authResult == AuthRequestResult.success) {
      await authDataProvider.saveData(AuthData(user, password));
    } else {
      authResult != null
          ? _setAuthError(text: authResult.errorMessage)
          : _setAuthError();
    }

    setState(ViewState.idle);
    return authResult == AuthRequestResult.success;
  }

  void _setAuthError({String text = 'Неизвестная ошибка'}) {
    _hasAuthError = true;
    _authErrorText = text;
  }

  void _resetAuthError() {
    _hasAuthError = false;
    _authErrorText = '';
  }
}
