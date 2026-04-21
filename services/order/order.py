from flask import Flask
app = Flask(__name__)

@app.route('/order')
def order():
    return "Thanks for ordering"