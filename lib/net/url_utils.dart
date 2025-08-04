

final urlUtils = UrlUtils();

class UrlUtils {
  UrlUtils._internal();
  factory UrlUtils() => _instance;
  static final UrlUtils _instance = UrlUtils._internal();

}
