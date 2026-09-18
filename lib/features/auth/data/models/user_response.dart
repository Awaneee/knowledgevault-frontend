class UserResponse {
  const UserResponse({
    required this.id,
    required this.username,
    required this.email,
    this.hasAvatar = false,
  });

  final int id;
  final String username;
  final String email;
  final bool hasAvatar;

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        hasAvatar: json['has_avatar'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'has_avatar': hasAvatar,
      };
}
