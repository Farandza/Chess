class User {
  const User(
      {required this.id,
      required this.username,
      required this.email,
      this.emailVerified = false,
      this.rating = 1200});
  final String id;
  final String username;
  final String email;
  final bool emailVerified;
  final int rating;
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'].toString(),
        username: json['username'] as String,
        email: json['email'] as String,
        emailVerified: json['email_verified'] as bool? ?? false,
        rating: json['rating'] as int? ?? 1200,
      );
}
