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

from http.server import SimpleHTTPRequestHandler, HTTPServer

class RiakRequestRequestHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                str(self.path), str(self.headers), post_data)

        json.decode(post_data)
        self._set_response()
        self.wfile.write("POST request for {}".format(self.path).encode('utf-8'))

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
    args = parser.parse_args()
    docroot = os.path.abspath(args.docroot)
    print("docroot:", docroot)
    run(int(args.port), docroot)

if __name__ == "__main__":
    main()
