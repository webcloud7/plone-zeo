from ZEO.ClientStorage import ClientStorage
import os
import socket
import sys
import time


def main():
    zeo_port = os.environ.get('ZEO_PORT', '8100')
    blob_dir = '/data/blobvolume/blobstorage'
    addr = socket.gethostname(), int(zeo_port)
    client = ClientStorage(addr, storage="1", wait=False, read_only=True, realm=None, blob_dir=blob_dir, shared_blob_dir=True)

    server_found = False
    for i in range(60):
        if client.is_connected():
            server_found = True
            break
        time.sleep(1)

    if not server_found:
        sys.stderr.write("Couldn't connect to: %r\n" % (addr, ))
        client.close()
        sys.exit(1)
        return
            
    client.pack(wait=True, days=7)
    sys.stdout.write("DB packed for: %r\n" % (addr, ))
    client.close()


if __name__ == "__main__":
    main()
