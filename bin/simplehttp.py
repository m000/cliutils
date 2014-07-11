#!/usr/bin/env python

# Simple wrapper for binding a SimpleHTTPServer on localhost or the specified address.
# Directly invoking the SimpleHTTPServer binds the server to 0.0.0.0 (non-configurable).
#
# Source: http://stackoverflow.com/a/12268922/277172

import sys
from SimpleHTTPServer import SimpleHTTPRequestHandler
import BaseHTTPServer

def test(HandlerClass=SimpleHTTPRequestHandler, ServerClass=BaseHTTPServer.HTTPServer):
    protocol = "HTTP/1.0"
    host = '127.0.0.1'
    port = 18000
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if ':' in arg:
            host, port = arg.split(':')
            port = int(port)
        else:
            try:
                port = int(sys.argv[1])
            except:
                host = sys.argv[1]
    server_address = (host, port)

    HandlerClass.protocol_version = protocol
    httpd = ServerClass(server_address, HandlerClass)

    sa = httpd.socket.getsockname()
    print "Serving HTTP on", 'http://%s:%d' % (sa[0], sa[1]), "..."
    httpd.serve_forever()

if __name__ == "__main__":
    test()
