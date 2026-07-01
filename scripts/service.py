#!/usr/bin/env python3
import os
import json
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = int(os.environ.get('PORT', 8080))
LOG_PATH = os.environ.get('LOG_PATH', '/var/log/infra-demo/service.log')

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({
                'status': 'healthy',
                'service': 'infra-demo',
                'version': '1.0.0'
            })
            self.wfile.write(response.encode())
            logging.info(f'Health check from {self.client_address[0]}')
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')
    
    def log_message(self, format, *args):
        logging.info(f'{self.address_string()} - {format % args}')

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), HealthHandler)
    print(f'Starting health service on port {PORT}')
    logging.info(f'Service started on port {PORT}')
    server.serve_forever()
