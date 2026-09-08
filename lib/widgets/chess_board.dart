import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/material.dart';
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';

class ChessBoard extends StatelessWidget {
  const ChessBoard(
      {super.key,
      required this.game,
      required this.player,
      required this.onMove});
  final bishop.Game game;
  final int player;
  final ValueChanged<String> onMove;
  @override
  Widget build(BuildContext context) {
    final state = game.squaresState(player);
    return AspectRatio(
        aspectRatio: 1,
        child: BoardController(
          state: state.board,
          playState: state.state,
          pieceSet: PieceSet.merida(),
          theme: BoardTheme.brown,
          moves: state.moves,
          markerTheme:
              MarkerTheme(empty: MarkerTheme.dot, piece: MarkerTheme.corners()),
          onMove: (move) {
            final bishopMove = game.bishopMove(move);
            if (bishopMove != null) onMove(game.toAlgebraic(bishopMove));
          },
        ));
  }
}
