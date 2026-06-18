/// Supported HTTP methods
class HttpMethod {
  final String name;
  final bool hasBody;

  const HttpMethod(this.name, {this.hasBody = false});

  static const get = HttpMethod('GET');
  static const post = HttpMethod('POST', hasBody: true);
  static const put = HttpMethod('PUT', hasBody: true);
  static const delete = HttpMethod('DELETE');
  static const patch = HttpMethod('PATCH', hasBody: true);
  static const head = HttpMethod('HEAD');
  static const options = HttpMethod('OPTIONS');

  static const List<HttpMethod> all = [
    get, post, put, delete, patch, head, options,
  ];

  static HttpMethod fromString(String method) {
    return all.firstWhere(
      (m) => m.name == method.toUpperCase(),
      orElse: () => get,
    );
  }
}
