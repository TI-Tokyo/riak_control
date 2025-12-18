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

import os
import logging
import tempfile
import subprocess
import rctl_globals

def make_and_exec(url, user, key, template_body, params):
    idf = tempfile.NamedTemporaryFile(dir = rctl_globals.DATADIR,
                                      mode = 'w+',
                                      delete = False)
    idf.write(key['body'])
    idf.close()
    os.chmod(idf.name, 0o600)

    scriptf = tempfile.NamedTemporaryFile(dir = rctl_globals.DATADIR,
                                          mode = 'w+',
                                          delete = False)
    scriptf.write(template_body)
    scriptf.close()

    _scp(url, user, idf.name, scriptf.name)

    _ssh_exec(url, user, idf.name, scriptf.name, params)

    os.unlink(idf.name)
    os.unlink(scriptf.name)
    return []

def _scp(url, user, idf, f):
    p = subprocess.run(["scp", "-i", idf, "-vv", "-o", "KbdInteractiveAuthentication=no", "-o", "PasswordAuthentication=no", f, user+"@"+url+":"],
                       capture_output = True,
                       encoding ='utf8')
    if p.returncode != 0:
        raise rctl_globals.RctlException("scp failed ({}): {}".format(p.returncode, p.stderr))

def _ssh_exec(url, user, idf, script, params):
    logging.info("executing script %s on %s as %s (using key %s)", script, url, user, idf)
    p = subprocess.run(["ssh", user+"@"+url, "-i"+idf, "./"+script],
                       env = params,
                       capture_output = True,
                       encoding ='utf8')
    if p.returncode != 0:
        raise rctl_globals.RctlException("ssh failed")
