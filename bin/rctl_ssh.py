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

import os, time, uuid
import logging
import tempfile
import subprocess
import rctl_globals

def make_and_exec(url, user, key, template_body, params):
    if key:
        idf = tempfile.NamedTemporaryFile(dir = rctl_globals.DATADIR,
                                          mode = 'w+',
                                          delete = False)
        idf.write(key['body'])
        idf.close()
        os.chmod(idf.name, 0o600)
        idf_name = idf.name
    else:
        idf_name = None

    scriptf = tempfile.NamedTemporaryFile(dir = rctl_globals.DATADIR,
                                          mode = 'w+',
                                          delete = False)
    pp = []
    for p in params:
        pp += [p+"=\""+params[p]+"\""]
    pstr = "#!/bin/sh\nexport " + " ".join(pp) + "\n"

    scriptf.write(pstr + template_body)
    scriptf.close()

    _scp(url, user, idf_name, scriptf.name)

    res = _ssh_exec(url, user, idf_name, scriptf.name, params)

    if idf_name is not None:
        os.unlink(idf.name)
    os.unlink(scriptf.name)

    return res

def _scp(url, user, idf, f):
    logging.info("copying script %s to %s as %s (using key %s)", f, url, user, idf)
    if idf:
        idf_args = ["-i", idf]
    else:
        idf_args = []
    try:
        p = subprocess.run(["scp"] + idf_args +
                           ["-o", "KbdInteractiveAuthentication=no",
                            "-o", "PasswordAuthentication=no",
                            f, user+"@"+url+":"],
                           capture_output = True,
                           encoding ='utf8',
                           timeout = 15)
        if p.returncode != 0:
            raise rctl_globals.RctlException(404, "scp failed ({}): {}".format(p.returncode, p.stderr))
    except subprocess.TimeoutExpired:
        raise rctl_globals.RctlException(408, "Host unreachable")

def _ssh_exec(url, user, idf_name, scriptf_name, params):
    logging.info("executing script %s on %s as %s (using key %s)", scriptf_name, url, user, idf_name)
    if idf_name is not None:
        idf_args = ["-i", idf_name]
    else:
        idf_args = []

    subprocess.run(["ssh"] + idf_args + [user+"@"+url, "chmod", "+x", os.path.basename(scriptf_name)])
    p = subprocess.Popen(["ssh"] + idf_args +
                         [user+"@"+url, "./"+os.path.basename(scriptf_name)],
                         encoding ='utf8',
                         stdout = subprocess.PIPE,
                         stderr = subprocess.STDOUT,
                         text = True)

    session_id = str(uuid.uuid4())
    session = {
        "process": p,
        "sent_bytes": 0
    }
    rctl_globals.ACTIVE_SSH_SESSIONS |= {session_id: session}

    return {"session_id": session_id}
