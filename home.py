from flask import Blueprint, jsonify, request
from DB import db_cursor, db_connection
from utils import prediction
from pandas import DataFrame
from json import dumps

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
    
@home_bp.route('/predict')
def predict():
    # db_cursor.execute('SELECT * FROM league."Deliveries" WHERE batsman_id=478 AND bowler_id=176')
    # query_data = db_cursor.fetchall()
    batsman_name = 'SK Raina'
    bowler_name = 'Harbhajan Singh'
    db_cursor.callproc(f'league.getbatvsbowlstats', (batsman_name, bowler_name))
    totalDf = DataFrame(db_cursor.fetchall())
    inp_list = [{
        'batsmanid': totalDf['batsmanid'].iloc[0],
        'bowlerid': totalDf['bowlerid'].iloc[0],
        'prevbatsmanstrikerate': totalDf['prevbatsmanstrikerate'].iloc[-1],
        'prevbowlerstrikerate': totalDf['prevbowlerstrikerate'].iloc[-1]
    },]
    predDf = DataFrame(inp_list)
    pred_data = prediction.prepare_data(totalDf, predDf)
    # jsonable_preds = prediction.np_to_py_native_convert(pred_data)
    # print(jsonable_preds)
    return jsonify({
        'status': 200,
        'prediction': dumps(pred_data, default=prediction.np_to_py_native_convert),
        'data': 'success'
    })