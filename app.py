from flask import Flask
from home import home_bp

app = Flask(__name__)
# Blueprint declaration
app.register_blueprint(home_bp, url_prefix='/api/league')