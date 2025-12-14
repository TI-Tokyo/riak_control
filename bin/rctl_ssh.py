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

import tempfile
import subprocess
import rctl_globals

def make_and_exec(url, user, key, template_body, params):
    idf = tempfile.NamedTemporaryFile(dir = rctl_globals.DATADIR)
    write(idf, key['body'])

    scriptf = tempfile.NamedTemporaryFile(dir = rctl_globals.DATADIR)
    script_body = _make_script(template['body'], req['params'])
    write(scriptf, script_body)

    _scp(url, user, idf, scriptf)

    _ssh_exec(url, user, idf, scriptf)

def _make_script(body, params):
    pp = []
    for p in params:
        pp += p['name'] + "=" + p['value']
    preface = "#!/bin/sh\nexport " + " ".join(pp)
    return preface + "\n" + body

def _scp(url, user, idf, f):
    p = subprocess.run(["scp", user+"@"+url, "-i"+idf, f],
                       capture_output = True,
                       encoding ='utf8')
    if p.returncode != 0:
        raise "scp failed"

def _ssh_exec(url, user, idf, script):
    p = subprocess.run(["ssh", user+"@"+url, "-i"+idf, script],
                       capture_output = True,
                       encoding ='utf8')
    if p.returncode != 0:
        raise "ssh failed"
