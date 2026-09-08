class Game {
  const Game(
      {required this.id,
      required this.whiteId,
      required this.blackId,
      required this.fen,
      this.whiteUsername,
      this.blackUsername,
      this.turn = 'white',
      this.whiteSeconds = 600,
      this.blackSeconds = 600,
      this.result,
      this.moves = const [],
      this.status = 'active'});
  final String id, whiteId, blackId, fen, status;
  final String? whiteUsername, blackUsername;
  final String turn;
  final int whiteSeconds, blackSeconds;
  final String? result;
  final List<String> moves;
  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'].toString(),
        whiteId: json['white_id'].toString(),
        blackId: json['black_id'].toString(),
        fen: json['fen'] as String,
        whiteUsername: json['white_username'] as String?,
        blackUsername: json['black_username'] as String?,
        turn: json['turn'] as String? ?? 'white',
        whiteSeconds: json['white_seconds'] as int? ?? 600,
        blackSeconds: json['black_seconds'] as int? ?? 600,
        result: json['result'] as String?,
        status: json['status'] as String? ?? 'active',
        moves: List<String>.from(json['moves'] ?? const []),
      );
}
