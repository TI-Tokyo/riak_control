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

from http.server import SimpleHTTPRequestHandler, HTTPServer
import re
import json
import functools
import logging
import rctl_globals

HANDLERS = {'ListSshKeys': _list_ssh_keys,
            'StoreSshKey': _store_ssh_key,
            'DeleteSshKey': _delete_ssh_key,
            'ListScriptTemplates': _list_script_templates,
            'ExecScript': _exec_script
            }

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

def _list_ssh_keys(_req):
    global SSH_KEYS
    return SSH_KEYS

def _store_ssh_key(req):
    global SSH_KEYS, DATADIR
    name = req['name']
    body = req['body']
    new_key = {'name': name, 'body': body, 'created': datetime.datetime.now().isoformat()}
    existing_keys = [k.get('name') for k in SSH_KEYS]
    maybe_replace = lambda a, r: (a['name'] == name) and r or a
    if name in existing_keys:
        SSH_KEYS = [maybe_replace(k, new_key) for k in SSH_KEYS]
    else:
        SSH_KEYS.append(new_key)
    with open(DATADIR+"/keys", "w") as f:
        json.dump(SSH_KEYS, f)
    return []

def _delete_ssh_key(req):
    global SSH_KEYS, DATADIR
    name = req['name']
    maybe_delete = lambda a: (a['name'] == name) and r or a
    for k in SSH_KEYS:
        if k['name'] == name:
            SSH_KEYS.remove(k)
            break
    with open(DATADIR+"/keys", "w") as f:
        json.dump(SSH_KEYS, f)
    return []

def _list_script_templates(_req):
    global SCRIPT_TEMPLATES
    return SCRIPT_TEMPLATES

def _exec_script(req):
    try:
        hh = _parse_hosts(req['hosts'])
        template = rctl_globals.find_template(req['script_name'])
        for h in hh:
            key = rctl_globals.find_key(h['key'])
            rctl_ssh.make_and_exec(h['url'], h['user'], key, template['body'], req['params'])
            return []
    except:
        return []

def _parse_hosts(s):
    o = []
    r = r'(\w+)@(\w+)\((\w+)\)'
    for h in re.split(", +", s):
        m = re.search(r, h)
        o += [{'user': m.group(1),
               'url': m.group(2),
               'key': m.group(3)}]
    return o

