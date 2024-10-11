import 'package:injector/injector.dart';
import 'package:unn_mobile/core/misc/current_user_sync_storage.dart';
import 'package:unn_mobile/core/models/employee_data.dart';
import 'package:unn_mobile/core/models/schedule_filter.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';
import 'package:unn_mobile/core/viewmodels/main_page_route_view_model.dart';
import 'package:unn_mobile/core/viewmodels/schedule_tab_view_model.dart';

class ScheduleScreenViewModel extends BaseViewModel
    implements MainPageRouteViewModel {
  final CurrentUserSyncStorage _currentUserSyncStorage;

  ScheduleScreenViewModel(this._currentUserSyncStorage);

  int selectedTab = 0;

  List<IDType> get tabIDTypes => switch (_currentUserSyncStorage.typeOfUser) {
        const (EmployeeData) => [
            IDType.lecturer,
            IDType.group,
            IDType.student,
          ],
        _ => [
            IDType.student,
            IDType.group,
            IDType.lecturer,
          ] // Объединяем результат для StudentData и всего остального
      };

  List<ScheduleTabViewModel> get tabViewModels => _tabViewModels;
  late final List<ScheduleTabViewModel> _tabViewModels;

  void init() {
    if (isInitialized) {
      return;
    }
    isInitialized = true;
    _tabViewModels = tabIDTypes.map(
      (idType) {
        return Injector.appInstance.get<ScheduleTabViewModel>();
      },
    ).toList();
  }

  @override
  void refresh() {
    _tabViewModels[selectedTab].refresh();
  }
}
