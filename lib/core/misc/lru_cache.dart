import 'dart:collection';

class LRUCache<Key, Value> {
  int maxSize;
  LinkedHashMap<Key, Value> cache;

  LRUCache(this.maxSize) : cache = LinkedHashMap<Key, Value>();

  Value? get(Key key) {
    Value? value = cache.remove(key);

    if (value != null) {
      cache[key] = value;
    }

    return value;
  }

  void save(Key key, Value newValue) {
    Value? value = cache.remove(key);
    if (value != null) {
      cache[key] = value;
    } else {
      if (cache.length >= maxSize) {
        cache.remove(cache.keys.first);
      }
      cache[key] = newValue;
    }
  }
}
