import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unn_mobile/core/models/feed/blog_post.dart';

abstract interface class FeedUpdaterService with ChangeNotifier {
  List<BlogPost> get feedPosts;

  /// Номер последней загруженной страницы ленты.
  ///
  /// Значение по умолчанию равно 0, когда ни одной страницы не загружено.
  int get lastLoadedPage;

  /// Обновляет ленту.
  ///
  /// Очищает список [feedPosts], сбрасывает [lastLoadedPage] в начальное значение
  /// и загружает первую страницу постов из ленты. Уведомляет подписчиков по завершении.
  Future<void> updateFeed();

  /// Загружает следующую страницу ленты.
  ///
  /// Этот метод увеличивает номер последней загруженной страницы и загружает
  /// соответствующую страницу постов. Если загрузка уже выполняется, метод ничего не делает.
  Future<void> loadNextPage();
}
