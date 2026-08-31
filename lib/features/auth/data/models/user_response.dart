class UserResponse {
  const UserResponse({
    required this.id,
    required this.username,
    required this.email,
  });

  final int id;
  final String username;
  final String email;

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
      );
}
