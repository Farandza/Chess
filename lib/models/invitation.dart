class Invitation {
  const Invitation({
    required this.id,
    required this.fromUser,
    required this.minutes,
  });

  final String id;
  final String fromUser;
  final int minutes;

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'].toString(),
      fromUser: json['from_username'] as String? ?? 'Unknown',
      minutes: json['minutes'] as int? ?? 10,
    );
  }
}
