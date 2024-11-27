abstract interface class GettingVoteKeySigned {
  /// Получает voteKeySigned для поста
  ///
  /// [int] authorId: id автора
  /// [int] id: id поста
  ///
  /// Возвращает [String] или null, если:
  ///   1. Не вышло получить ответ от портала
  ///   2. statusCode не равен 200
  ///   3. Не вышло декодировать ответ
  ///   4. Не вышло из html получить voteKeySigned
  Future<String?> getVoteKeySigned({
    required int authorId,
    required int postId,
  });
}
