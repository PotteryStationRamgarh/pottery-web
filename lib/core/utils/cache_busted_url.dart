class CacheBustedUrl {
  CacheBustedUrl._();

  static String withVersion(String url, int version) {
    if (url.trim().isEmpty) return url;
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters)
      ..['v'] = version.toString();
    return uri.replace(queryParameters: params).toString();
  }
}
