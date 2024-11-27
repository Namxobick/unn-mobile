import 'package:injector/injector.dart';
import 'package:unn_mobile/core/misc/current_user_sync_storage.dart';
import 'package:unn_mobile/core/models/rating_list.dart';
import 'package:unn_mobile/core/models/user_short_info.dart';
import 'package:unn_mobile/core/services/interfaces/feed/legacy/getting_rating_list.dart';
import 'package:unn_mobile/core/services/interfaces/feed/legacy/getting_vote_key_signed.dart';
import 'package:unn_mobile/core/services/interfaces/feed/reaction_manager.dart';
import 'package:unn_mobile/core/viewmodels/base_view_model.dart';
import 'package:unn_mobile/core/viewmodels/factories/reaction_view_model_factory.dart';

class ReactionViewModel extends BaseViewModel {
  static const noId = -1;

  final GettingVoteKeySigned _gettingVoteKeySigned;
  final GettingRatingList _gettingRatingList;
  final ReactionManager _reactionManager;
  final CurrentUserSyncStorage _currentUserSyncStorage;

  RatingList? _ratingList;
  String? _voteKeySigned;

  bool _isLoading = true;

  bool _isChangingReaction = false;

  ReactionViewModel(
    this._gettingVoteKeySigned,
    this._gettingRatingList,
    this._reactionManager,
    this._currentUserSyncStorage,
  );

  factory ReactionViewModel.cached(ReactionCacheKey key) {
    return Injector.appInstance
        .get<ReactionViewModelFactory>()
        .getViewModel(key);
  }

  bool get canAddReaction =>
      ReactionType.values
          .map((e) => getReactionCount(e))
          .where((e) => e > 0)
          .length <
      ReactionType.values.length;

  ReactionType? get currentReaction {
    return _ratingList?.getReactionByUser(
      _currentUserSyncStorage.currentUserData?.bitrixId ?? noId,
    );
  }

  bool get isChangingReaction => _isChangingReaction;

  bool get isLoading => _isLoading;

  int get reactionCount => _ratingList?.getTotalNumberOfReactions() ?? 0;

  Iterable<ReactionType> get reactionList =>
      _ratingList?.ratingList.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((e) => e.key) ??
      [];

  int getReactionCount(ReactionType reaction) {
    return _ratingList?.getNumberOfReactions(reaction) ?? 0;
  }

  void init({
    String? voteKeySigned,
    int? postId,
    int? authorId,
    RatingList? ratingList,
  }) {
    _isLoading = true;
    notifyListeners();

    _ratingList = ratingList;

    _loadData(voteKeySigned: voteKeySigned, postId: postId, authorId: authorId)
        .whenComplete(() {
      _isLoading = false;
      notifyListeners();
    });
  }

  void toggleLike() {
    if (currentReaction != null) {
      _setReaction(null);
    } else {
      _setReaction(ReactionType.like);
    }
    notifyListeners();
  }

  void toggleReaction(ReactionType reaction) async {
    if (_isChangingReaction) {
      return;
    }
    final currentReaction = this.currentReaction;

    // Убираем реакцию и ставим новую, если она не та же, что была
    await _setReaction(null);
    if (currentReaction != reaction) {
      await _setReaction(reaction);
    }
  }

  Future<void> _loadData({
    String? voteKeySigned,
    int? postId,
    int? authorId,
  }) async {
    assert((voteKeySigned == null) != (postId == null && authorId == null));
    _voteKeySigned = voteKeySigned;
    _voteKeySigned ??= await _gettingVoteKeySigned.getVoteKeySigned(
      authorId: authorId!,
      postId: postId!,
    );

    if (_voteKeySigned == null) {
      return;
    }
    if (_ratingList != null) {
      return;
    }
    _ratingList = await _gettingRatingList.getRatingList(
      voteKeySigned: _voteKeySigned!,
    );
  }

  Future<void> _setReaction(ReactionType? reaction) async {
    if (_isChangingReaction) {
      return;
    }
    try {
      _isChangingReaction = true;
      final profileId = _currentUserSyncStorage.currentUserData?.bitrixId;
      if (profileId == null) {
        return;
      }
      if (_voteKeySigned == null) {
        return;
      }
      if (reaction == null) {
        final currentReactionInfo =
            _ratingList?.getReactionInfoByUser(profileId);
        final currentReactionType = _ratingList?.getReactionByUser(profileId);
        if (currentReactionInfo == null || currentReactionType == null) {
          return;
        }
        // Временно удаляем реакцию, чтобы показать действие
        _ratingList!.removeReaction(profileId);
        notifyListeners();
        if (!await _reactionManager.removeReaction(_voteKeySigned!)) {
          // Если реакция не удалилась - восстанавливаем её
          _ratingList!.addReactions(
            currentReactionType,
            [currentReactionInfo],
          );
          notifyListeners();
        }
      } else {
        // Добавляем временно, чтобы сразу показать действие
        _ratingList?.addReactions(
          reaction,
          [UserShortInfo(profileId, '', '')],
        );
        notifyListeners();
        final reactionUserInfo = await _reactionManager.addReaction(
          reaction,
          _voteKeySigned!,
        );
        // Удаляем временную реакцию
        _ratingList?.removeReaction(profileId);
        if (reactionUserInfo != null) {
          // Если реакция реально добавилась - фиксируем это
          _ratingList?.addReactions(
            reaction,
            [reactionUserInfo],
          );
        }
        notifyListeners();
      }
    } finally {
      _isChangingReaction = false;
      notifyListeners();
    }
  }
}
