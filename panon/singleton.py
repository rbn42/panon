import os
import sys
import json
import socket
from threading import Thread
import logging


class Singleton:

    def __init__(self,  socket_file, timeout=0.01):
        self.socket_file = socket_file
        self.timeout = timeout
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.stop = False

    def server(self):
        try:
            self.socket.bind(self.socket_file)
        except OSError:
            return False
        logging.debug('listen')
        self.socket.listen(1)
        return True

    def loop(self):
        self.socket.settimeout(self.timeout)
        while not self.stop:
            try:
                conn, addr = self.socket.accept()
            except KeyboardInterrupt:
                break
            except socket.timeout:
                yield None
                continue

            try:
                logging.debug('new obj')
                conn.send(b'welcome')
                obj = b''
                while True:
                    data = conn.recv(1024)
                    if data is None or len(data) < 1:
                        break
                    if len(data) < 1:
                        break
                    obj += data
                logging.debug('new json obj')
                conn.close()
                yield json.loads(obj.decode())
            except:
                yield None

    def finish(self):
        self.stop = True
        os.remove(self.socket_file)

    def client(self):
        if not os.path.exists(self.socket_file):
            return False
        self.socket.settimeout(0.5)
        try:
            self.socket.connect(self.socket_file)
        except:
            return False
        msg = self.socket.recv(1024)
        if not msg == b'welcome':
            return False
        env = {k: v for k, v in os.environ.items()}
        obj = {'argv': sys.argv, 'env': env}
        obj = json.dumps(obj).encode()
        self.socket.send(obj)
        self.socket.close()
        return True

    def start(self):
        if self.client():
            return False
        else:
            if os.path.exists(self.socket_file):
                os.remove(self.socket_file)
            self.server()
            return True


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG,)
    SOCKET_FILE = "/run/user/%s/desktop_menu.socket" % os.getuid()
    sin = Singleton(SOCKET_FILE)
    if sin.start():
        for obj in sin.loop():
            print(obj)
        sin.finish()
        print('end loop')
