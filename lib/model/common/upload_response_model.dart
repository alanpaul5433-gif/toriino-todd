class UploadResponseModel {
  final String? uploadUrl;
  final String? key;
  final String? publicUrl;

  UploadResponseModel({
    this.uploadUrl,
    this.key,
    this.publicUrl,
  });

  factory UploadResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadResponseModel(
      uploadUrl: json['uploadUrl'],
      key: json['key'],
      publicUrl: json['publicUrl'],
    );
  }
}
