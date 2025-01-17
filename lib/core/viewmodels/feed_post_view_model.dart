import 'package:event/event.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:injector/injector.dart';
import 'package:unn_mobile/core/models/feed/blog_post_data.dart';
import 'package:unn_mobile/core/services/interfaces/feed/getting_blog_posts.dart';
import 'package:unn_mobile/core/services/interfaces/feed/last_feed_load_date_time_provider.dart';
import 'package:unn_mobile/core/services/interfaces/logger_service.dart';
import 'package:unn_mobile/core/viewmodels/attached_file_view_model.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';
import 'package:unn_mobile/core/viewmodels/factories/feed_post_view_model_factory.dart';
import 'package:unn_mobile/core/viewmodels/profile_view_model.dart';
import 'package:unn_mobile/core/viewmodels/reaction_view_model.dart';

class FeedPostViewModel extends BaseViewModel {
  final GettingBlogPosts _gettingBlogPosts;
  final LoggerService _loggerService;
  final LastFeedLoadDateTimeProvider _lastFeedLoadDateTimeProvider;

  final HtmlUnescape _unescaper = HtmlUnescape();

  final List<AttachedFileViewModel> attachedFileViewModels = [];

  final onError = Event();

  late BlogPostData blogData;

  late ProfileViewModel _profileViewModel;

  late ReactionViewModel _reactionViewModel;

  FeedPostViewModel(
    this._gettingBlogPosts,
    this._loggerService,
    this._lastFeedLoadDateTimeProvider,
  );
  factory FeedPostViewModel.cached(FeedPostCacheKey key) {
    return Injector.appInstance
        .get<FeedPostViewModelFactory>()
        .getViewModel(key);
  }

  int get authorId => blogData.authorBitrixId;

  int get commentsCount => blogData.numberOfComments;

  int get filesCount => blogData.files?.length ?? 0;

  bool get isNewPost =>
      _lastFeedLoadDateTimeProvider.lastFeedLoadDateTime?.isBefore(postTime) ??
      false;

  String get postText => _unescaper.convert(blogData.detailText.trim());

  DateTime get postTime => blogData.datePublish.toLocal();

  ProfileViewModel get profileViewModel => _profileViewModel;

  ReactionViewModel get reactionViewModel => _reactionViewModel;

  void init(BlogPostData blogData) {
    this.blogData = blogData;

    _profileViewModel = ProfileViewModel.cached(blogData.authorBitrixId)
      ..init(loadFromPost: true, userId: blogData.authorBitrixId);
    _reactionViewModel = ReactionViewModel.cached(blogData.authorBitrixId)
      ..init(postId: blogData.id, authorId: blogData.authorBitrixId);
    attachedFileViewModels.clear();
    attachedFileViewModels.addAll(
      blogData.files?.map((fileId) => AttachedFileViewModel.cached(fileId)) ??
          [],
    );
    notifyListeners();
  }

  Future<void> refresh() async {
    await _gettingBlogPosts.getBlogPosts(postId: blogData.id).then(
      (value) {
        if (value == null || value.isEmpty) {
          onError.broadcast();
          return;
        }
        init(value.first);
      },
    ).catchError((error, stack) {
      _loggerService.logError(error, stack);
      onError.broadcast();
    });
  }
}
