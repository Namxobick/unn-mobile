import 'package:unn_mobile/core/services/interfaces/feed/legacy/getting_blog_post_comments.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';
import 'package:unn_mobile/core/viewmodels/feed_comment_view_model.dart';
import 'package:unn_mobile/core/viewmodels/feed_post_view_model.dart';

class CommentsPageViewModel extends BaseViewModel {
  final GettingBlogPostComments _gettingBlogPostCommentsService;

  final List<FeedCommentViewModel> commentViewmodels = [];

  FeedPostViewModel? post;

  int loadedPage = 1;
  int totalPages = 1;

  CommentsPageViewModel(
    this._gettingBlogPostCommentsService,
  );

  bool get commentsAvailable => loadedPage < totalPages;

  int get commentsCount => post?.blogData.numberOfComments ?? 0;

  bool get isLoadingComments => state == ViewState.busy;

  void init(FeedPostViewModel post) {
    this.post = post;
    refresh();
  }

  Future<void> loadMoreComments() async {
    if (isLoadingComments || loadedPage == 1) {
      return;
    }
    loadedPage--;
    await _loadComments(loadedPage);
  }

  Future<void> refresh() async {
    totalPages = 1;
    await post?.refresh();
    totalPages =
        (commentsCount / GettingBlogPostComments.commentsPerPage).ceil();
    loadedPage = totalPages;
    commentViewmodels.clear();

    await _loadComments(loadedPage);
    // Загружаем до конца, либо первые 3 страницы, если их больше
    while (loadedPage > 1 && loadedPage > totalPages - 2) {
      await loadMoreComments();
    }
  }

  Future<void> _loadComments(int page) async {
    if (isLoadingComments) {
      return;
    }
    try {
      setState(ViewState.busy);
      if (post == null) {
        return;
      }
      final comments =
          await _gettingBlogPostCommentsService.getBlogPostComments(
        postId: post!.blogData.id,
        pageNumber: page,
      );
      if (comments == null) {
        return;
      }
      commentViewmodels.addAll(
        comments.map((c) => FeedCommentViewModel.cached(c.id)..init(c)),
      );
    } finally {
      // Не важно, как мы вышли - флаги убрать всё равно надо
      setState(ViewState.idle);
    }
  }
}
