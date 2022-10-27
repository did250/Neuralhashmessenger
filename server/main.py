import json

from flask import Flask, request

import nnhash

app = Flask(__name__)

dangerous = ["b4c339deb101343e885efb15", "25f3a8593eb58f22ddf4f4e1","25f3a8593ef58f22ddf4f4e1"]
# GET
@app.route('/')
def hello_world():
    return 'hello'

@app.route('/test', methods=['POST'])
def hash():
    imagefiles = request.files['images']
    target = nnhash.gethash(imagefiles)

    for items in dangerous :

        if items == target :
            return "true"
    return "false"
    # data = request.form.get('name')
    # print(data)
    # data2 = request.form.get('images')
    # print(data2)
    # # return nnhash.gethash("시간표.png")
    # return "your name is %s" %data

if __name__ == '__main__':
    app.run(ssl_context='adhoc')


