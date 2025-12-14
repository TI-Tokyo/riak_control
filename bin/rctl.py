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

import os, sys, argparse, datetime
import json
import tempfile

import rctl_httpd
import rctl_globals


def load_globals():
    global DATADIR, SSH_KEYS, SCRIPT_TEMPLATES
    try:
        with open(DATADIR+"/keys") as f:
            SSH_KEYS = json.load(f)
    except:
        SSH_KEYS = []
    try:
        pfx = ETCDIR
        with open(pfx+"/script-templates") as f:
            SCRIPT_TEMPLATES = json.load(f)
            for t in SCRIPT_TEMPLATES:
                if t["file"]:
                    with open(pfx+"/script-templates.d/"+t["file"]) as ff:
                        t["body"] = ff.read()
    except:
        SCRIPT_TEMPLATES = []

def main():
    global ETCDIR, DATADIR

    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--port", default = "8091", help = "Port to listen on")
    parser.add_argument("-r", "--docroot", help = "Document root")
    parser.add_argument("-d", "--datadir", default = ".", help = "Path under which data will be kept")
    parser.add_argument("-c", "--etcdir", default = os.path.dirname(sys.argv[0]), help = "Path to read script templates from")
    args = parser.parse_args()

    DATADIR = args.datadir
    ETCDIR = args.etcdir

    load_globals()

    docroot = os.path.abspath(args.docroot)
    print("docroot:", docroot)
    rctl_httpd.run(int(args.port), docroot)

if __name__ == "__main__":
    main()
