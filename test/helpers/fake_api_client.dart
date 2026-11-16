import 'package:dio/dio.dart';
import 'package:elikas_mobile/core/network/api_client.dart';

/// Answers GETs from a path -> JSON body map; throws for anything else
/// (or for every path while [offline]).
class FakeApiClient extends ApiClient {
  FakeApiClient(this.bodies) : super(dio: Dio());

  final Map<String, Object?> bodies;
  bool offline = false;
  final List<String> calls = [];

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add(path);
    if (offline || !bodies.containsKey(path)) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: bodies[path],
    );
  }
}
