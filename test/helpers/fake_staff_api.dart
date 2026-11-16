import 'package:dio/dio.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';

/// A staff API whose answers are scripted per "METHOD path":
/// an int status (2xx = success) or a [DioExceptionType] for a transport
/// failure. Unscripted calls answer 200 with `{data: {}}`.
class FakeStaffApi extends StaffApiClient {
  FakeStaffApi() : super(dio: Dio());

  final Map<String, List<Object>> script = {};
  final Map<String, Object?> getBodies = {};
  final List<String> calls = [];
  final List<Object?> bodies = [];

  void answer(String key, Object outcome) => (script[key] ??= []).add(outcome);

  Future<Response<dynamic>> _respond(String key, Object? data) async {
    calls.add(key);
    bodies.add(data);
    final queue = script[key];
    final outcome = (queue == null || queue.isEmpty)
        ? 200
        : (queue.length == 1 ? queue.first : queue.removeAt(0));
    final options = RequestOptions(path: key);
    if (outcome is DioExceptionType) {
      throw DioException(requestOptions: options, type: outcome);
    }
    // An outcome can also be (status, body) for a scripted answer body.
    final (status, scriptedBody) = outcome is (int, Object?)
        ? outcome
        : (outcome as int, null);
    final body =
        scriptedBody ??
        (status < 300
            ? (getBodies[key] ?? {'success': true, 'data': <String, dynamic>{}})
            : {
                'success': false,
                'message': 'Refused ($status)',
                'errors': status == 422
                    ? {
                        'family_id': [
                          'This family already got its box in this round.',
                        ],
                      }
                    : null,
              });
    final response = Response(
      requestOptions: options,
      statusCode: status,
      data: body,
    );
    if (status >= 300) {
      throw DioException(
        requestOptions: options,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    return response;
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _respond('GET $path', queryParameters);

  @override
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Duration timeout = const Duration(seconds: 15),
  }) => _respond('POST $path', data);

  @override
  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Duration timeout = const Duration(seconds: 15),
  }) => _respond('PATCH $path', data);

  @override
  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Duration timeout = const Duration(seconds: 15),
  }) => _respond('PUT $path', data);
}
