class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' অথবা 'user'

  UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });
}
