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

import re, json, datetime, base64, hashlib, sys
import functools
import subprocess
import logging
from http.server import SimpleHTTPRequestHandler, HTTPServer

from rctl_globals import RctlException
import rctl_globals, rctl_ssh

class RiakRequestRequestHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        logging.debug("POST %s\nHeaders:\n%s\nBody:\n%s\n",
                str(self.path), str(self.headers), post_data)
        req = json.loads(post_data)
        cmd = req.get('command')
        handler = HANDLERS.get(cmd)
        send_resp_f = lambda c: self._send_response(c)
        if handler is None:
            self._send_response(400)
            self.wfile.write(b"Bad command")
        else:
            try:
                if self._authorize(req):
                    handler(req, send_resp_f, self.wfile)
                else:
                    self._send_response(403)
                    self.wfile.write(b"Unauthorized")
            except RctlException as e:
                self._send_response(e.status)
                self.wfile.write(e.msg.encode('utf-8'))
            except Exception:
                self._send_response(500)
                print(sys.exception())
                self.wfile.write("handle me: {}".format(repr(sys.exception())).encode('utf-8'))


    def _authorize(self, req):
        try:
            auth = self.headers['authorization']
            creds = auth.split(" ")[1]
            up = base64.b64decode(creds).decode('utf-8').split(":")
            if (rctl_globals.CONFIG['admin']['name'] == up[0] and
                rctl_globals.CONFIG['admin']['password'] == hashlib.sha256(up[1].encode('utf-8')).hexdigest()):
                return True
            else:
                return False
        except:
            return False
        pass

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



def _list_ssh_keys(_req, send_resp_f, wfile):
    send_resp_f(200)
    wfile.write(
        json.dumps(
            rctl_globals.SSH_KEYS
        ).encode('utf-8')
    )

def _store_ssh_key(req, send_resp_f, wfile = None):
    name = req['name']
    body = req['body']
    new_key = {'name': name, 'body': body, 'created': datetime.datetime.now().isoformat()}
    existing_keys = [k.get('name') for k in rctl_globals.SSH_KEYS]
    maybe_replace = lambda a, r: (a['name'] == name) and r or a
    if name in existing_keys:
        rctl_globals.SSH_KEYS = [maybe_replace(k, new_key) for k in rctl_globals.SSH_KEYS]
    else:
        rctl_globals.SSH_KEYS.append(new_key)
    with open(rctl_globals.DATADIR+"/keys", "w") as f:
        json.dump(rctl_globals.SSH_KEYS, f)
    send_resp_f(201)

def _delete_ssh_key(req, send_resp_f, wfile = None):
    name = req['name']
    maybe_delete = lambda a: (a['name'] == name) and r or a
    for k in rctl_globals.SSH_KEYS:
        if k['name'] == name:
            rctl_globals.SSH_KEYS.remove(k)
            break
    with open(rctl_globals.DATADIR+"/keys", "w") as f:
        json.dump(rctl_globals.SSH_KEYS, f)
    send_resp_f(204)

def _list_script_templates(_req, send_resp_f, wfile):
    send_resp_f(200)
    wfile.write(
        json.dumps(
            rctl_globals.SCRIPT_TEMPLATES
            ).encode('utf-8')
        )

def _exec_script(req, send_resp_f, wfile):
    try:
        hh = _parse_hosts(req['hosts'])
        template = rctl_globals.find_template(req['script_name'])
        for h in hh:
            key = rctl_globals.find_key(h['key'])
            logging.info("exec: script: %s, on %s as %s, key: %s",
                         template['name'], h['url'], h['user'], h['key'])
            session = rctl_ssh.make_and_exec(
                h['url'], h['user'], key,
                template['body'], req['params'])
            send_resp_f(202)
            wfile.write(
                json.dumps(session).encode('utf-8')
            )
    except RctlException as e:
        send_resp_f(e.status)
        wfile.write(e.msg.encode('utf-8'))

def _parse_hosts(s):
    try:
        o = []
        r = r'(\w+)@(\w+)\((\w*)\)'
        for h in re.split(", +", s):
            m = re.search(r, h)
            if m.group(3) in ["", "none"]:
                key = None
            else:
                key = m.group(3)
            o += [{'user': m.group(1),
                   'url': m.group(2),
                   'key': key}]
        return o
    except Exception:
        raise rctl_globals.RctlException(400, "malformed target hosts")

def _get_script_output(req, send_resp_f, wfile):
    session = rctl_globals.ACTIVE_SSH_SESSIONS[req['session_id']]
    p = session['process']
    bytes_sent = session['sent_bytes']

    send_resp_f(200)
    try:
        outs, _ = p.communicate(timeout = 1)
        output = outs[bytes_sent:]
        if p.returncode == 0:
            output += "Script terminated successfully\n"
        else:
            output += "Script terminated with error code {}\n".format(p.returncode)
        ret = {
            "session_id": req['session_id'],
            "finished": True,
            "output": output
        }
        wfile.write(json.dumps(ret).encode('utf-8'))
        del rctl_globals.ACTIVE_SSH_SESSIONS[req['session_id']]

        rctl_ssh.cleanup(session['id_file'], session['script_file'])

    except subprocess.TimeoutExpired as e:
        output = e.output[bytes_sent:]
        ret = {
            "session_id": req['session_id'],
            "finished": False,
            "output": output.decode('utf-8')
        }
        wfile.write(json.dumps(ret).encode('utf-8'))
        bytes_sent = len(e.output)
        session |= {'sent_bytes': bytes_sent}
        rctl_globals.ACTIVE_SSH_SESSIONS |= session


HANDLERS = {'ListSshKeys': _list_ssh_keys,
            'StoreSshKey': _store_ssh_key,
            'DeleteSshKey': _delete_ssh_key,
            'ListScriptTemplates': _list_script_templates,
            'ExecScript': _exec_script,
            'GetScriptOutput': _get_script_output
            }
