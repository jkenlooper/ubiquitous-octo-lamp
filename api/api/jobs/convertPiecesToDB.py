# TODO: Save the pieces from redis back to the SQL DB for archiving.  The
# pieceData in Redis should be deleted afterwards.
#
# This job should be ran by a janitor worker.  It should find all puzzles in
# redis that haven't had any activity in the last week or so.

import sys
import os.path
import math
import time

import sqlite3
import redis

from api.app import db
from api.database import rowify
from api.tools import loadConfig

# Get the args from the janitor and connect to the database
config_file = sys.argv[1]
config = loadConfig(config_file)

db_file = config['SQLITE_DATABASE_URI']
db = sqlite3.connect(db_file)

redisConnection = redis.from_url('redis://localhost:6379/0/')

def transfer(puzzle):
    cur = db.cursor()

    query = """select * from Puzzle where (id = :puzzle)"""
    (result, col_names) = rowify(cur.execute(query, {'puzzle': puzzle}).fetchall(), cur.description)
    puzzle_data = result[0]

    query = """select * from Piece where (puzzle = :puzzle)"""
    (all_pieces, col_names) = rowify(cur.execute(query, {'puzzle': puzzle}).fetchall(), cur.description)

    query_update_piece = """
    update Piece set x = :x, y = :y, r = :r, parent = :parent, status = :status where puzzle = :puzzle and id = :id
    """

    # Save the redis data to the db
    groups = set()
    for piece in all_pieces:
        pieceFromRedis = redisConnection.hgetall('pc:{puzzle}:{id}'.format(**piece))

        piece['x'] = pieceFromRedis.get('x')
        piece['y'] = pieceFromRedis.get('y')
        piece['r'] = pieceFromRedis.get('r')
        piece['parent'] = pieceFromRedis.get('g', None)
        piece['status'] = pieceFromRedis.get('s', None)
        cur.execute(query_update_piece, piece)

        # Find all the groups for each piece
        groups.add(pieceFromRedis.get('g'))

    db.commit()

    # Create a pipe for buffering commands and disable atomic transactions
    pipe = redisConnection.pipeline(transaction=False)

    # Delete all piece data
    for piece in all_pieces:
        pipe.delete('pc:{puzzle}:{id}'.format(**piece))

    # Delete all groups
    for g in groups:
        pipe.delete('pcg:{puzzle}:{g}'.format(puzzle=puzzle, g=g))

    # Delete Piece Fixed
    pipe.delete('pcfixed:{puzzle}'.format(puzzle=puzzle))

    # Delete Piece Stacked
    pipe.delete('pcstacked:{puzzle}'.format(puzzle=puzzle))

    # Delete Piece X
    pipe.delete('pcx:{puzzle}'.format(puzzle=puzzle))

    # Delete Piece Y
    pipe.delete('pcy:{puzzle}'.format(puzzle=puzzle))

    # Remove from the pcupdates sorted set
    pipe.zrem('pcupdates', puzzle)

    pipe.execute()
    cur.close()

def transferOldest(target_memory):

    # No puzzles that have been modified in the last 30 minutes
    newest = int(time.time()) - (30 * 60)

    # Get the 10 oldest puzzles
    puzzles = redisConnection.zrange('pcupdates', 0, 10, withscores=True)
    #print('cycle over old puzzles: {0}'.format(puzzles))
    for (puzzle, timestamp) in puzzles:
        # There may be a chance that since this process has started that
        # a puzzle could have been updated.
        latest_timestamp = redisConnection.zscore('pcupdates', puzzle)

        if latest_timestamp < newest:
            #print('transfer: {0}'.format(puzzle))
            transfer(puzzle)
            memory = redisConnection.info(section='memory')
            #print('used_memory: {used_memory_human}'.format(**memory))
            if memory.get('used_memory') < target_memory:
                break

def transferAll():
    # Get all puzzles
    puzzles = redisConnection.zrange('pcupdates', 0, -1)
    print('transferring puzzles: {0}'.format(puzzles))
    for puzzle in puzzles:
        print('transfer puzzle: {0}'.format(puzzle))
        transfer(puzzle)
        memory = redisConnection.info(section='memory')
        print('used_memory: {used_memory_human}'.format(**memory))

if __name__ == '__main__':
    confirm = raw_input("Transfer all puzzle data out of redis and into sqlite database? y/n\n")
    if confirm == 'y':
        transferAll()