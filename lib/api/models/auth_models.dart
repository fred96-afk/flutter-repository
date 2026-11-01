class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class AuthResponse {
  const AuthResponse({
    required this.token,
    this.email,
    this.name,
    this.roleId,
    this.role,
    this.permissions = const [],
    this.raw,
  });

  final String token;
  final String? email;
  final String? name;
  final int? roleId;
  final String? role;
  final List<String> permissions;
  final Map<String, dynamic>? raw;

  Map<String, dynamic> toJson() => {
    'token': token,
    'email': email,
    'name': name,
    'roleId': roleId,
    'role': role,
    'permissions': permissions,
  };

  factory AuthResponse.fromJson(dynamic json) {
    if (json is String) {
      return AuthResponse(token: json);
    }
    if (json is Map<String, dynamic>) {
      final userObj = json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null;
      return AuthResponse(
        token: (json['token'] ?? json['accessToken'] ?? json['jwt'] ?? '').toString(),
        email: userObj?['email']?.toString() ?? json['email']?.toString(),
        name: userObj?['name']?.toString() ?? json['name']?.toString() ?? json['userName']?.toString(),
        roleId: userObj?['roleId'] is int
            ? userObj!['roleId'] as int
            : (json['roleId'] is int ? json['roleId'] as int : null),
        role: userObj?['role']?.toString() ?? json['role']?.toString(),
        permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        raw: json,
      );
    }
    return const AuthResponse(token: '');
  }
}

class UserRequest {
  const UserRequest({
    required this.name,
    required this.email,
    required this.password,
    this.roleId = 2,
  });

  final String name;
  final String email;
  final String password;
  final int roleId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'roleId': roleId,
  };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
  };
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    this.isVerified = false,
  });

  final int id;
  final String name;
  final String email;
  final int roleId;
  final bool isVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    roleId: json['roleId'] is int ? json['roleId'] as int : 0,
    isVerified: json['isVerified'] == true,
  );
}
