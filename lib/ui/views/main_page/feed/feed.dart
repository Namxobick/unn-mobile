import 'package:flutter/material.dart';
import 'package:injector/injector.dart';
import 'package:unn_mobile/core/viewmodels/factories/main_page_routes_view_models_factory.dart';
import 'package:unn_mobile/core/viewmodels/feed_screen_view_model.dart';
import 'package:unn_mobile/ui/views/base_view.dart';
import 'package:unn_mobile/ui/views/main_page/feed/widgets/feed_post.dart';
import 'package:unn_mobile/ui/views/main_page/main_page_tab_state.dart';
import 'package:unn_mobile/ui/widgets/offline_overlay_displayer.dart';

class FeedScreenView extends StatefulWidget {
  final int routeIndex;
  const FeedScreenView({super.key, required this.routeIndex});

  @override
  State<FeedScreenView> createState() => FeedScreenViewState();
}

class FeedScreenViewState extends State<FeedScreenView>
    implements MainPageTabState {
  late ScrollController _scrollController;

  late FeedScreenViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = Injector.appInstance
        .get<MainPageRoutesViewModelsFactory>()
        .getViewModelByRouteIndex<FeedScreenViewModel>(widget.routeIndex);

    _scrollController = ScrollController(
      initialScrollOffset: _viewModel.scrollPosition,
      keepScrollOffset: true,
    );

    _viewModel.scrollToTop = () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    };
    _viewModel.onRefresh = () => refreshTab();
    _scrollController.addListener(scrollUpdate);
  }

  void scrollUpdate() {
    _viewModel.scrollPosition = _scrollController.offset;
  }

  @override
  Widget build(BuildContext context) {
    final parentScaffold = Scaffold.maybeOf(context);

    return OfflineOverlayDisplayer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Лента'),
          leading: parentScaffold?.hasDrawer ?? false
              ? IconButton(
                  onPressed: () {
                    parentScaffold?.openDrawer();
                  },
                  icon: const Icon(Icons.menu),
                )
              : null,
        ),
        body: BaseView<FeedScreenViewModel>(
          model: _viewModel,
          builder: (context, model, child) {
            return Column(
              children: [
                if (model.showSyncFeedButton)
                  TextButton(
                    onPressed: () => model.syncFeed(),
                    child: const Text('Обновить ленту'),
                  ),
                Expanded(
                  child: NotificationListener<ScrollEndNotification>(
                    child: RefreshIndicator(
                      onRefresh: model.updateFeed,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        child: Column(
                          children: [
                            for (final post in model.posts)
                              FeedPost(
                                post: post,
                                showingComments: false,
                              ),
                            if (model.loadingPosts)
                              const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    onNotification: (scrollEnd) {
                      final metrics = scrollEnd.metrics;
                      if (metrics.maxScrollExtent - metrics.pixels < 300) {
                        model.getMorePosts();
                      }
                      return true;
                    },
                  ),
                ),
              ],
            );
          },
          onModelReady: (model) => model.init(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.scrollToTop = null;
    _viewModel.onRefresh = null;
    _scrollController.removeListener(scrollUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void refreshTab() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.decelerate,
    );
  }
}
