import json

from flask import Flask, request

import nnhash

app = Flask(__name__)


copyright = ['e53929a448ae45ecc9f465a5','03c440f364b23fdc381d97d1','a8fab3b0769175fd48424aeb']
dangerous = ['8dc077b5a7f1c65b8cb8886a', '36dd53046cc4b1d83363760c']


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