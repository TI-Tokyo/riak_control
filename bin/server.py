#!/bin/env python

import os, argparse
import functools
import logging

from http.server import SimpleHTTPRequestHandler, HTTPServer

class RiakRequestRequestHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                str(self.path), str(self.headers), post_data.decode('utf-8'))

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
