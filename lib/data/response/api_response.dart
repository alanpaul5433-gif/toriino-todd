import 'package:getxmvvm/data/response/status.dart';

class ApiResponse<T> {
  Status? status;
  T? data;
  String? massage;
  ApiResponse({this.status, this.data, this.massage});

  ApiResponse.loading() : status = Status.loading;
  ApiResponse.success(this.data) : status = Status.success;
  ApiResponse.error(this.massage) : status = Status.error;

  @override
  String toString() {
    return "Status: $status, Data: $data, Message: $massage";
  }
}
