from flask import Blueprint, jsonify, request
from DB import db_cursor

home_bp = Blueprint(name='home', import_name=__name__)

@home_bp.route('/index')
def index():
    """
    docstring
    """
    return 'Index page'

@home_bp.route('/players', methods=['POST'])
def get_players():
    player = request.json.get('playerName')
    selectedPlayerIds = request.json.get('selectedIds')
    players_query = f'SELECT player_id as id, player_name, dob, batting_hand, bowling_skill FROM league."Players"'
    where_conditions = []
    if (player is not None):
         where_conditions.append(f'LOWER(player_name) like \'%{player.lower()}%\'')
    if(selectedPlayerIds is not None):
        where_conditions.append(f'player_id not in ({",".join(selectedPlayerIds)})')
    if(where_conditions is not None and len(where_conditions) > 0):
        players_query = f'{players_query} WHERE {" AND ".join(where_conditions)}'
    db_cursor.execute(players_query)
    return jsonify({
        'status':200,
        'data': db_cursor.fetchall()
    })

@home_bp.route('/')
def home():
    db_cursor.callproc(f'league.getbatvsbowldetails', ("DA Warner","TS Mills"))
    data = db_cursor.fetchall()
    return jsonify({
        'status': 200,
        'data': data
    })
    # return 'API Home page'