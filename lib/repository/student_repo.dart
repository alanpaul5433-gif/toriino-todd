import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class StudentSearchResult {
  final String userId;
  final String displayName;
  final String email;

  StudentSearchResult({
    required this.userId,
    required this.displayName,
    required this.email,
  });

  factory StudentSearchResult.fromJson(Map<String, dynamic> json) {
    return StudentSearchResult(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? json['email'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class StudentRepo {
  final _apiServices = NetworkApiServices();

  /// Search students by name or email. Returns a list of matching students.
  Future<List<StudentSearchResult>> search(String query) async {
    if (query.trim().length < 2) return [];
    final headers = await AuthInterceptor.getAuthHeaders();
    final response = await _apiServices.getGetApiResponse(
      AppUrl.studentSearch(query.trim()),
      headers: headers,
    );
    final List<dynamic> items =
        (response is Map ? response['students'] : response) as List? ?? [];
    return items
        .map((e) => StudentSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
