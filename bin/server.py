#!/bin/env python

## Copyright (c) 2025 TI Tokyo    All Rights Reserved.
##
## This file is provided to you under the Apache License,
## Version 2.0 (the "License"); you may not use this file
## except in compliance with the License.  You may obtain
## a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing,
## software distributed under the License is distributed on an
## "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
## KIND, either express or implied.  See the License for the
## specific language governing permissions and limitations
## under the License.

import os, argparse
import functools
import logging
import json
import datetime

from http.server import SimpleHTTPRequestHandler, HTTPServer

SSH_KEYS = []
SCRIPT_TEMPLATES = []
PREFIX = "."

def list_ssh_keys(_req):
    global SSH_KEYS
    return SSH_KEYS

def store_ssh_key(req):
    global SSH_KEYS, PREFIX
    name = req['name']
    body = req['body']
    new_key = {'name': name, 'body': body, 'created': datetime.datetime.now().isoformat()}
    existing_keys = [k.get('name') for k in SSH_KEYS]
    maybe_replace = lambda a, r: (a['name'] == name) and r or a
    if name in existing_keys:
        SSH_KEYS = [maybe_replace(k, new_key) for k in SSH_KEYS]
    else:
        SSH_KEYS.append(new_key)
    with open(PREFIX+"/keys", "w") as f:
        json.dump(SSH_KEYS, f)
    return []

def delete_ssh_key(req):
    global SSH_KEYS, PREFIX
    name = req['name']
    maybe_delete = lambda a: (a['name'] == name) and r or a
    for k in SSH_KEYS:
        if k['name'] == name:
            SSH_KEYS.remove(k)
            break
    with open(PREFIX+"/keys", "w") as f:
        json.dump(SSH_KEYS, f)
    return []

def list_script_templates(_req):
    global SCRIPT_TEMPLATES
    return SCRIPT_TEMPLATES

def exec_script(req):
    print("hey, executing!")



HANDLERS = {'ListSshKeys': list_ssh_keys,
            'StoreSshKey': store_ssh_key,
            'DeleteSshKey': delete_ssh_key,
            'ListScriptTemplates': list_script_templates,
            'ExecScript': exec_script
            }


def load_globals():
    try:
        with open(PREFIX+"/keys") as f:
            SSH_KEYS = json.load(f)
    except:
        SSH_KEYS = []
    try:
        with open(PREFIX+"/script-templates") as f:
            SCRIPT_TEMPLATES = json.load(f)
    except:
        SCRIPT_TEMPLATES = []

class RiakRequestRequestHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                str(self.path), str(self.headers), post_data)
        req = json.loads(post_data)
        cmd = req.get('command')
        handler = HANDLERS.get(cmd)
        if handler is None:
            resp = "Bad command"
        else:
            resp = json.dumps(handler(req))
        self._send_response(200)
        self.wfile.write(resp.encode('utf-8'))

    def _send_response(self, code):
        self.send_response(code)
        self.send_header("content-type", "application/json")
        self.end_headers()

def run(port, docroot):
    server_address = ("", port)
    Handler = functools.partial(RiakRequestRequestHandler, directory = docroot)
    httpd = HTTPServer(server_address, Handler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--port", default = "8091", help = "Port to listen on")
    parser.add_argument("-r", "--docroot", help = "Document root")
    parser.add_argument("-d", "--prefix", default = ".", help = "Path under which data will be kept")
    args = parser.parse_args()

    PREFIX = args.prefix
    load_globals()

    docroot = os.path.abspath(args.docroot)
    print("docroot:", docroot)
    run(int(args.port), docroot)

if __name__ == "__main__":
    main()
