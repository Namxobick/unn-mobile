import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unn_mobile/core/viewmodels/main_page_view_model.dart';
import 'package:unn_mobile/ui/views/main_page/main_page_routing.dart';

class MainPageNavigationBar extends StatelessWidget {
  final void Function(int)? onDestinationSelected;
  final MainPageViewModel model;
  const MainPageNavigationBar({
    super.key,
    this.onDestinationSelected,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 0.3,
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
        NavigationBar(
          destinations: _getNavbarDestinations(
            model,
            context,
          ),
          height: 60,
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          animationDuration: const Duration(milliseconds: 0),
          selectedIndex: getSelectedBarIndex(context),
          onDestinationSelected: onDestinationSelected,
        ),
      ],
    );
  }

  static int getSelectedBarIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    return MainPageRouting.navbarRoutes
        .indexWhere((route) => location.startsWith(route.pageRoute));
  }

  List<Widget> _getNavbarDestinations(
    MainPageViewModel model,
    BuildContext context,
  ) {
    final routes = MainPageRouting.navbarRoutes;
    final destinations = [
      for (final route in routes)
        NavigationDestination(
          icon: Icon(route.unselectedIcon),
          selectedIcon: Icon(
            route.selectedIcon,
            color: Theme.of(context).primaryColorDark,
          ),
          label: route.pageTitle,
          enabled: !route.isDisabled,
        ),
    ];
    return destinations;
  }
}
