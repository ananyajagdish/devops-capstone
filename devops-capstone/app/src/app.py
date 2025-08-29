import datetime

from flask import Flask, request, jsonify
app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>Welcome</h1>'

@app.route('/dow/<string:date_string>', methods=['GET'])
def get_dow(date_string):
    try:
        date_obj = datetime.datetime.strptime(date_string, '%Y-%m-%d')
        day_of_week = date_obj.strftime('%A')

        return f"The day of the week is {day_of_week}"
    except ValueError:
        return "Invalid Date"

@app.route('/healthz', methods=['GET'])
def get_health():
    return f"success!"

@app.route('/readyz', methods=['GET'])
def get_ready():
    return f"success!"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port = 8080)