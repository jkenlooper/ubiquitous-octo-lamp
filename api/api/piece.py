from flask import abort, json
from flask.views import MethodView
import redis

from app import db
from database import fetch_query_string, rowify
from constants import ACTIVE, IN_QUEUE

encoder = json.JSONEncoder(indent=2, sort_keys=True)

redisConnection = redis.from_url('redis://localhost:6379/0/')

class PuzzlePieceView(MethodView):
    """
    Get info about a single puzzle piece.
    """

    def get(self, puzzle_id, piece):

        cur = db.cursor()
        result = cur.execute(fetch_query_string('select_puzzle_id_by_puzzle_id.sql'), {
            'puzzle_id': puzzle_id
            }).fetchall()
        if not result:
            # 404 if puzzle or piece does not exist
            abort(404)

        (result, col_names) = rowify(result, cur.description)
        puzzle = result[0].get('puzzle')

        # Only allow if there is data in redis
        if not redisConnection.zscore('pcupdates', puzzle):
            abort(400)

        # Fetch just the piece properties
        publicPieceProperties = ('x', 'y', 'rotate', 's', 'w', 'h', 'b')
        pieceProperties = redisConnection.hmget('pc:{puzzle}:{piece}'.format(puzzle=puzzle, piece=piece), *publicPieceProperties)
        pieceData = dict(zip(publicPieceProperties, pieceProperties))
        return encoder.encode(pieceData)