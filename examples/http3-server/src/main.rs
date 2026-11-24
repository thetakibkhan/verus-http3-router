use std::collections::HashMap;
use std::error::Error;
use std::fmt::Write as _;
use std::io::{self, ErrorKind};
use std::net::UdpSocket;
use std::rc::Rc;
use std::time::{Duration, Instant};

use tquic::h3::connection::Http3Connection;
use tquic::h3::{Header, Http3Config, Http3Error, Http3Event, NameValue};
use tquic::{
    Config, Connection, Endpoint, PacketInfo, PacketSendHandler, TlsConfig, TransportHandler,
};

struct UdpSender(UdpSocket);

impl PacketSendHandler for UdpSender {
    fn on_packets_send(&self, packets: &[(Vec<u8>, PacketInfo)]) -> tquic::Result<usize> {
        for (sent, (packet, info)) in packets.iter().enumerate() {
            match self.0.send_to(packet, info.dst) {
                Ok(_) => {}
                Err(error) if error.kind() == ErrorKind::WouldBlock => return Ok(sent),
                Err(error) => return Err(error.into()),
            }
        }
        Ok(packets.len())
    }
}

struct Requests {
    config: Http3Config,
    connections: HashMap<u64, Http3Connection>,
}

impl TransportHandler for Requests {
    fn on_conn_established(&mut self, conn: &mut Connection) {
        let Some(index) = conn.index() else {
            return;
        };
        match Http3Connection::new_with_quic_conn(conn, &self.config) {
            Ok(connection) => {
                self.connections.insert(index, connection);
            }
            Err(error) => eprintln!("HTTP/3 setup failed: {error:?}"),
        }
    }

    fn on_conn_closed(&mut self, conn: &mut Connection) {
        if let Some(index) = conn.index() {
            self.connections.remove(&index);
        }
    }

    fn on_stream_readable(&mut self, conn: &mut Connection, _: u64) {
        let Some(http3) = conn
            .index()
            .and_then(|index| self.connections.get_mut(&index))
        else {
            return;
        };
        loop {
            match http3.poll(conn) {
                Ok((stream, Http3Event::Headers { headers, fin })) => {
                    print!("{}", render_headers(stream, fin, &headers));
                    if let Err(error) =
                        http3.send_headers(conn, stream, &[Header::new(b":status", b"204")], true)
                    {
                        eprintln!("HTTP/3 response failed: {error:?}");
                    }
                }
                Ok(_) => {}
                Err(Http3Error::Done) => return,
                Err(error) => {
                    eprintln!("HTTP/3 poll failed: {error:?}");
                    return;
                }
            }
        }
    }

    fn on_conn_created(&mut self, _: &mut Connection) {}
    fn on_stream_created(&mut self, _: &mut Connection, _: u64) {}
    fn on_stream_writable(&mut self, _: &mut Connection, _: u64) {}
    fn on_stream_closed(&mut self, _: &mut Connection, _: u64) {}
    fn on_new_token(&mut self, _: &mut Connection, _: Vec<u8>) {}
}

fn render_headers(stream: u64, fin: bool, headers: &[impl NameValue]) -> String {
    let mut output = format!(
        "Headers stream={stream} fin={fin} fields={}\n",
        headers.len()
    );
    for header in headers {
        writeln!(
            output,
            "  name={:02x?} value={:02x?}",
            header.name(),
            header.value()
        )
        .expect("writing to a String succeeds");
    }
    output
}

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<_> = std::env::args().collect();
    let [_, cert, key] = args.as_slice() else {
        return Err("usage: http3-server CERT.pem KEY.pem".into());
    };

    let mut config = Config::new()?;
    config.set_tls_config(TlsConfig::new_server_config(
        cert,
        key,
        vec![b"h3".to_vec()],
        false,
    )?);
    let requests = Requests {
        config: Http3Config::new().map_err(|error| io::Error::other(format!("{error:?}")))?,
        connections: HashMap::new(),
    };

    let socket = UdpSocket::bind("127.0.0.1:0")?;
    socket.set_read_timeout(Some(Duration::from_millis(10)))?;
    let local = socket.local_addr()?;
    let sender = Rc::new(UdpSender(socket.try_clone()?));
    let mut endpoint = Endpoint::new(Box::new(config), true, Box::new(requests), sender);

    println!("Listening on {local}");
    let mut buffer = [0; 65_535];
    loop {
        match socket.recv_from(&mut buffer) {
            Ok((length, src)) => {
                let info = PacketInfo {
                    src,
                    dst: local,
                    time: Instant::now(),
                };
                if let Err(error) = endpoint.recv(&mut buffer[..length], &info) {
                    eprintln!("QUIC receive failed: {error:?}");
                }
            }
            Err(error)
                if matches!(
                    error.kind(),
                    ErrorKind::TimedOut | ErrorKind::WouldBlock | ErrorKind::Interrupted
                ) => {}
            Err(error) => return Err(error.into()),
        }
        endpoint.on_timeout(Instant::now());
        endpoint.process_connections()?;
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn renders_order_duplicates_and_non_utf8_bytes() {
        let headers: &[(&[u8], &[u8])] = &[
            (b"x-repeat", b"first"),
            (b"x-marker", b"\xff"),
            (b"x-repeat", b"last"),
        ];

        assert_eq!(
            super::render_headers(4, true, headers),
            concat!(
                "Headers stream=4 fin=true fields=3\n",
                "  name=[78, 2d, 72, 65, 70, 65, 61, 74] value=[66, 69, 72, 73, 74]\n",
                "  name=[78, 2d, 6d, 61, 72, 6b, 65, 72] value=[ff]\n",
                "  name=[78, 2d, 72, 65, 70, 65, 61, 74] value=[6c, 61, 73, 74]\n",
            ),
        );
    }
}
