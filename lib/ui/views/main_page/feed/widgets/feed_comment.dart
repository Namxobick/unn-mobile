import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'package:unn_mobile/core/misc/app_settings.dart';
import 'package:unn_mobile/core/misc/custom_bb_tags.dart';
import 'package:unn_mobile/core/models/blog_post_comment.dart';
import 'package:unn_mobile/core/models/rating_list.dart';
import 'package:unn_mobile/core/viewmodels/feed_comment_view_model.dart';
import 'package:unn_mobile/ui/unn_mobile_colors.dart';
import 'package:unn_mobile/ui/views/base_view.dart';
import 'package:unn_mobile/ui/views/main_page/feed/widgets/attached_file.dart';
import 'package:unn_mobile/ui/views/main_page/feed/widgets/reaction_bubble.dart';
import 'package:unn_mobile/ui/widgets/shimmer.dart';
import 'package:unn_mobile/ui/widgets/shimmer_loading.dart';

class FeedCommentView extends StatelessWidget {
  const FeedCommentView({
    super.key,
    required this.comment,
  });

  final BlogPostComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaledAddButtonSize = MediaQuery.of(context).textScaler.scale(20) + 8;
    return BaseView<FeedCommentViewModel>(
      builder: (context, model, child) {
        return Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ShimmerLoading(
                      isLoading: model.isBusy,
                      child: CircleAvatar(
                        backgroundImage: model.authorAvatar,
                        radius: MediaQuery.of(context).textScaler.scale(20),
                        child: model.hasAvatar
                            ? null
                            : Text(
                                style: theme.textTheme.headlineSmall!.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: MediaQuery.of(context)
                                      .textScaler
                                      .scale(20),
                                ),
                                model.authorInitials,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ShimmerLoading(
                      isLoading: model.isBusy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!model.isBusy)
                            Text(
                              model.authorName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Container(
                                width: double.infinity,
                                height: MediaQuery.of(context)
                                    .textScaler
                                    .clamp(maxScaleFactor: 1.5)
                                    .scale(16),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          if (!model.isBusy)
                            Text(
                              model.comment.dateTime,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  bottom: 10,
                  right: 10,
                  top: 8,
                ),
                child: model.renderMessage
                    ? BBCodeText(
                        data: model.message,
                        stylesheet: getBBStyleSheet(),
                      )
                    : const SizedBox(),
              ),
              for (final file in model.files)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: AttachedFile(
                    fileData: file,
                    backgroundColor: theme
                        .extension<UnnMobileColors>()!
                        .defaultPostHighlight,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final reaction in ReactionType.values)
                        if (model.getReactionCount(reaction) > 0)
                          ReactionBubble(
                            isSelected: model.selectedReaction == reaction,
                            onPressed: () {
                              model.toggleReaction(reaction);
                            },
                            icon: Image.asset(reaction.assetName),
                            text: model.getReactionCount(reaction).toString(),
                          ),
                      if (!model.isBusy && model.canAddReaction)
                        IconButton.filledTonal(
                          padding: const EdgeInsets.all(0),
                          constraints: BoxConstraints.tightFor(
                            height: scaledAddButtonSize,
                            width: scaledAddButtonSize,
                          ),
                          onPressed: () {
                            showReactionChoicePanel(context, model);
                          },
                          icon: Icon(
                            Icons.add,
                            size: MediaQuery.of(context)
                                .textScaler
                                .clamp(maxScaleFactor: 1.3)
                                .scale(16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onModelReady: (model) => model.init(comment),
    );
  }

  static void showReactionChoicePanel(
    BuildContext context,
    FeedCommentViewModel model,
  ) {
    // TODO: объединить с этой панелькой из ленты
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Выбор реакции',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Divider(
                  indent: 8,
                  endIndent: 8,
                  thickness: 0.5,
                  color: Color(0xE5A2A2A2),
                ),
              ),
              const SizedBox(height: 10),
              Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final reaction in ReactionType.values)
                        _circleAvatarWithCaption(
                          reaction,
                          context,
                          model,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  static Widget _circleAvatarWithCaption(
    ReactionType reaction,
    BuildContext context,
    FeedCommentViewModel model,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: () {
          if (AppSettings.vibrationEnabled) {
            HapticFeedback.selectionClick();
          }
          model.toggleReaction(reaction);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 21,
                    backgroundImage: AssetImage(reaction.assetName),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                reaction.caption,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
