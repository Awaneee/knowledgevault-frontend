class TokenResponse {
  const TokenResponse({required this.accessToken, required this.tokenType});

  final String accessToken;
  final String tokenType;

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
      );
}
