import re
STARTING_FEN='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
MOVE_RE=re.compile(r'^[a-h][1-8][a-h][1-8][qrbn]?$')
def validate_move(move:str)->bool:return bool(MOVE_RE.match(move))
