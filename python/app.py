from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector

app = Flask(__name__)
CORS(app)

def get_connection():
    return mysql.connector.connect(
        host="127.0.0.1",
        user="root",
        password="1234",
        database="timeWise"
    )

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    username = data.get('username')
    password = data.get('password')

    conn = get_connection()
    cursor = conn.cursor()

    query = "SELECT * FROM Akun WHERE username=%s AND password=%s"
    cursor.execute(query, (username, password))

    result = cursor.fetchone()
    conn.close()

    return jsonify({"status": "success" if result else "fail"})


@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    username = data.get('username')
    password = data.get('password')

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM Akun WHERE username=%s", (username,))
    if cursor.fetchone():
        return jsonify({"status": "username_taken"})

    cursor.execute(
        "INSERT INTO Akun (idAkun, username, password) VALUES (NULL, %s, %s)",
        (username, password)
    )
    conn.commit()
    conn.close()

    return jsonify({"status": "registered"})


if __name__ == '__main__':
    app.run(debug=True)