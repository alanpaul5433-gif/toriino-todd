abstract class BaseApiServices {
  Future<dynamic> getGetApiResponse(String url, {Map<String, String>? headers});
  Future<dynamic> getPostApiResponse(
    String url,
    dynamic data,
    Map<String, String> header,
  );
  Future<dynamic> getPutApiResponse(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  });
  Future<dynamic> getPatchApiResponse(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  });
  Future<dynamic> getDeleteApiResponse(
    String url, {
    Map<String, String>? headers,
  });
}
