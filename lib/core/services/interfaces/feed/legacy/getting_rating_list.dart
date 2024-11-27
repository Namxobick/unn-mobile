import 'package:unn_mobile/core/models/rating_list.dart';

abstract interface class GettingRatingList {
  /// Получает [RatingList], содержащий одну реакцию и до 20 пользователей, поставившие эту реакцию
  ///
  /// [String] voteKeySigned: bitrix
  /// [ReactionType] reactionType: тип реакции
  /// [pageNumber] номер страницы (на странице до 20 пользователей)
  ///
  /// Возвращает [RatingList] или null, если:
  ///   1. Не вышло получить ответ от портала
  ///   2. statusCode не равен 200
  ///   3. Не вышло декодировать ответ
  Future<RatingList?> getReactionListByReaction({
    required String voteKeySigned,
    required ReactionType reactionType,
    int pageNumber = 0,
  });

  /// Возвращает кол-во реакций каждого типа
  ///
  /// [String] voteKeySigned: bitrix
  ///
  /// Возвращает [Map] или null, если:
  ///   1. Не вышло получить ответ от портала
  ///   2. statusCode не равен 200
  ///   3. Не вышло декодировать ответ
  ///   4. Нет реакций
  Future<Map<ReactionType, int>?> getNumbersOfReactions({
    required String voteKeySigned,
  });

  /// Вовзращает список реакций
  ///
  /// [String] voteKeySigned: bitrix
  ///
  /// Возвращает [Map] или null, если:
  ///   1. Если передали пустую строку
  ///   2. [getNumbersOfReactions] вернул null
  Future<RatingList?> getRatingList({
    required String voteKeySigned,
  });
}
