from flask import Flask, jsonify, request, Response, render_template
import os
import json
import csv
from flask_cors import CORS, cross_origin
import logging

log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

app = Flask(__name__)
cors = CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'
@cross_origin()

@app.route('/api/logs', methods=['GET'])
def log():
    with open("log", "r+") as f:
        data=f.read().encode('utf-8')
    return Response(data, mimetype='text/plain')

@app.route('/api/list', methods=['GET'])
def vmlist():  
    list = os.popen('./proxmoxlist.sh').read()
    return jsonify(json.JSONDecoder().decode(list))

@app.route('/api/list/nodes', methods=['GET'])
def nodes():
    with open('./data/nodes.csv', 'r') as f:
        reader = csv.reader(f, delimiter=',')
        data_list = list()
        for row in reader:
            data_list.append(row)
    data = [dict(zip(data_list[0],row)) for row in data_list]
    data.pop(0)
    return jsonify(data)

@app.route('/api/list/master', methods=['GET'])
def master():
    with open('./data/master.csv', 'r') as f:
        reader = csv.reader(f, delimiter=',')
        data_list = list()
        for row in reader:
            data_list.append(row)
    data = [dict(zip(data_list[0],row)) for row in data_list]
    data.pop(0)
    return jsonify(data)

@app.route('/api/list/nodes', methods=['POST'])
def ekle():
    os.popen('./addnode.sh ' +  request.values.get('id') + ' > log')
    params = {
        'status': 'preparing',
        'id': request.values.get('id')
    }
    return jsonify(params)

@app.route('/api/list/nodes', methods=['DELETE'])
def sil():
    os.popen('./deletenode.sh ' +  request.values.get('id') + ' > log')
    params = {
        'status': 'preparing',
        'id': request.values.get('id')
    }
    return jsonify(params)

@app.route("/")
def index():
    ifile = open("./data/master.csv", "r")
    reader = csv.reader(ifile, delimiter=",")
    rownum = 0	
    a = []
    for row in reader:
        a.append (row)
        rownum += 1
    ifile.close()
    return render_template("index.html", status=a)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
