from flask import Flask
from home import home_bp

app = Flask(__name__)
# Blueprint declaration
app.register_blueprint(home_bp, url_prefix='/api/league')

if __name__ == '__main__':
    app.run(debug=True)
    print('Main Function in Flask app')