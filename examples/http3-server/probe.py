"""Send one HTTP/3 request with ordered repeated fields using aioquic 1.3.0."""

import asyncio
import sys
from pathlib import Path

import aioquic
from aioquic.asyncio.client import connect
from aioquic.asyncio.protocol import QuicConnectionProtocol
from aioquic.h3.connection import H3_ALPN, H3Connection
from aioquic.h3.events import HeadersReceived
from aioquic.quic.configuration import QuicConfiguration
from aioquic.quic.events import ConnectionTerminated


class Probe(QuicConnectionProtocol):
    def __init__(self, quic, stream_handler=None):
        super().__init__(quic, stream_handler=stream_handler)
        self.http = H3Connection(quic)
        self.stream_id = None
        self.response = asyncio.get_running_loop().create_future()

    async def request(self, headers):
        self.stream_id = self._quic.get_next_available_stream_id()
        self.http.send_headers(self.stream_id, headers, end_stream=True)
        self.transmit()
        return await self.response

    def quic_event_received(self, event):
        if self.response.done():
            return
        if isinstance(event, ConnectionTerminated):
            self.response.set_exception(ConnectionError(f"QUIC closed: {event}"))
            return
        for response in self.http.handle_event(event):
            if isinstance(response, HeadersReceived) and response.stream_id == self.stream_id:
                self.response.set_result(response)
                return


async def request(port, cert, headers):
    config = QuicConfiguration(is_client=True, alpn_protocols=H3_ALPN, cafile=cert)
    async with connect("127.0.0.1", port, configuration=config, create_protocol=Probe) as client:
        return await client.request(headers)


def hex_list(value):
    return "[" + ", ".join(f"{byte:02x}" for byte in value) + "]"


def main():
    port, cert, server_log = sys.argv[1:]
    headers = [
        (b":method", b"GET"),
        (b":scheme", b"https"),
        (b":authority", f"127.0.0.1:{port}".encode("ascii")),
        (b":path", b"/phase0?probe=1"),
        (b"x-repeat", b"first"),
        (b"x-marker", b"\xff"),
        (b"x-repeat", b"last"),
    ]
    print(f"aioquic {aioquic.__version__}")
    response = asyncio.run(asyncio.wait_for(request(int(port), cert, headers), timeout=10))
    if not response.stream_ended or response.headers != [(b":status", b"204")]:
        raise SystemExit(f"Unexpected HTTP/3 response: {response}")
    expected = [
        f"Headers stream={response.stream_id} fin=true fields={len(headers)}",
        *(f"  name={hex_list(name)} value={hex_list(value)}" for name, value in headers),
    ]
    observed = Path(server_log).read_text().splitlines()[1:]
    if observed != expected:
        raise SystemExit(f"Unexpected server event: {observed!r}")
    print("PASS: HTTP/3 204 and one Headers event with 7 fields in exact byte order")


if __name__ == "__main__":
    main()
