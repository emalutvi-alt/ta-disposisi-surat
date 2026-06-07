class AuthUser {
  final int id;
  final String nama;
  final String email;
  final String role;

  AuthUser({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      nama: json['nama']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'users',
    );
  }
}

class LoginResult {
  final String token;
  final AuthUser user;

  LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token']?.toString() ?? '',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class ProfileData {
  final int id;
  final String nama;
  final String email;
  final String role;
  final String jabatan;

  ProfileData({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.jabatan = '',
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: (json['id'] as num).toInt(),
      nama: json['nama']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'users',
      jabatan: json['jabatan']?.toString() ?? '',
    );
  }
}
