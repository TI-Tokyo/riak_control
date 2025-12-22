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

import os, sys, argparse
import base64, json
import logging

import rctl_globals, rctl_config, rctl_server


def _load_config():
    try:
        with open(rctl_globals.ETCDIR+"/rctl.conf") as f:
            rctl_globals.CONFIG = json.load(f)
    except:
        rctl_globals.CONFIG = rctl_config.default_config()
        logging.info("Config not found: using defaults (admin user: %s, password: %s)",
                     rctl_globals.CONFIG['admin']['name'],
                     base64.b64decode(
                         rctl_globals.CONFIG['admin']['password']).decode('utf-8'))

def _load_globals():
    try:
        with open(rctl_globals.DATADIR+"/keys") as f:
            rctl_globals.SSH_KEYS = json.load(f)
    except:
        rctl_globals.SSH_KEYS = []
    logging.info("loaded %d ssh keys", len(rctl_globals.SSH_KEYS))
    pfx = rctl_globals.ETCDIR

    with open(pfx+"/script-templates") as f:
        rctl_globals.SCRIPT_TEMPLATES = json.load(f)
        for t in rctl_globals.SCRIPT_TEMPLATES:
            if t.get("file"):
                with open(pfx+"/script-templates.d/"+t["file"]) as ff:
                    t["body"] = ff.read()
    logging.info("loaded %d templates", len(rctl_globals.SCRIPT_TEMPLATES))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--port", default = "8091", help = "Port to listen on")
    parser.add_argument("-r", "--docroot", help = "Document root")
    parser.add_argument("-d", "--datadir", default = ".", help = "Path under which data will be kept")
    parser.add_argument("-c", "--etcdir", default = os.path.dirname(sys.argv[0]), help = "Path to read script templates from")
    args = parser.parse_args()

    logging.basicConfig(filename = "console.log",
                        format = "%(asctime)s.%(msecs)03d %(levelname)s %(message)s",
                        datefmt = "%c",
                        level = logging.INFO)

    rctl_globals.DATADIR = args.datadir
    rctl_globals.ETCDIR = args.etcdir

    _load_config()
    _load_globals()

    docroot = os.path.abspath(args.docroot)
    rctl_server.run(int(args.port), docroot)

if __name__ == "__main__":
    main()
