import json

from flask import Flask, request

import nnhash

app = Flask(__name__)


copyright = ['4e2b45523134070af324ffab','670c2d263a29e708a22a771e','9abe8999114260544cc18fc8', '67040be6ae2cc4d7d15e1d9a', '04487cf025f782877ba7aa3f']
dangerous = ['27f279d3ffa58764db5275b6', 'd25d12a25385fd949c380894', 'db965ae6f03b2dadf2a60198', '6b239ebb424f7a6bfb4c1c5d', 'a4f70ca60e64b14915d78196']



# GET
@app.route('/')
def hello_world():
    return 'hello'


#POST
@app.route('/test', methods=['POST'])
def hash():
    imagefiles = request.files['images']
    target = nnhash.gethash(imagefiles)

    for items in copyright :
        if items == target :
            return "copyright"
    for items in dangerous :
        if items == target :
            return "dangerous"
    return "false"


if __name__ == '__main__':
    app.run(ssl_context='adhoc', port=5001)