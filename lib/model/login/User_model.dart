class UserModel {
  String? accessToken;
  String? idToken;
  String? refreshToken;
  int? expiresIn;
  String? tokenType;

  UserModel({
    this.accessToken,
    this.idToken,
    this.refreshToken,
    this.expiresIn,
    this.tokenType,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    accessToken = json['accessToken'] ?? json['token'];
    idToken = json['idToken'];
    refreshToken = json['refreshToken'];
    expiresIn = json['expiresIn'];
    tokenType = json['tokenType'];
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'tokenType': tokenType,
    };
  }
}
