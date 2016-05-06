#!/usr/bin/env python3.5

import asyncio

def main():
    @asyncio.coroutine
    def handle_echo(reader, writer):
        while True:
            data = yield from reader.read(100)
            if not data:
                print("No data. Exiting handle_echo")
                return
            message = data.decode()
            addr = writer.get_extra_info('peername')
            s = "Received %r from %r" % (message, addr)
            print(s)
            writer.write(bytes(s + "\r\n", encoding="utf8"))
            #yield from writer.drain()
            # print("Close the client socket")
            # writer.close()

    loop = asyncio.get_event_loop()
    coro = asyncio.start_server(handle_echo, '0.0.0.0', 8888, loop=loop)
    server = loop.run_until_complete(coro)

    # Serve requests until Ctrl+C is pressed
    print('Serving on {}'.format(server.sockets[0].getsockname()))
    try:
        loop.run_forever()
    except KeyboardInterrupt:
        pass

    # Close the server
    server.close()
    loop.run_until_complete(server.wait_closed())
    loop.close()

if __name__ == '__main__':
    main()