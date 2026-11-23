# o'cloak - Open RFC 9458 OHTTP Relay

See [Oblivious HTTP](https://en.wikipedia.org/wiki/Oblivious_HTTP) and [RFC
9458](https://www.rfc-editor.org/rfc/rfc9458) for details.

Optionally uses [RFC 9540](https://www.rfc-editor.org/rfc/rfc9540) to require
the `ohttp` parameter in `HTTPS` DNS records as opt-in signal to receive
anonymized requests.

## Setting up a relay

```sh
git clone https://github.com/kpcyrd/ocloak.git
cd ocloak
cargo build --release
sudo install -Dm755 target/release/ocloak -t /usr/bin/
sudo install -Dm640 contrib/ocloak.conf -t /etc/ocloak/
sudo install -Dm644 contrib/ocloak.service -t /etc/systemd/system/
sudo systemctl enable --now ocloak
```

## Making a request

Using the [pvcli] tool, you can make an OHTTP request through the relay:

```sh
# https://github.com/cloudflareresearch/pvcli

pvcli --ohttp --proxy https://gateway.ohttp.info --gateway-path /.well-known/ohttp-gateway --config-path /.well-known/ohttp-gateway -v https://target.ohttp.info --first-hop 'http://127.0.0.1:1312/ohttp/gateway.ohttp.info'

# Since it's relaying through localhost, your own IP will be printed
```

```sh
# https://github.com/cloudflareresearch/pvcli

pvcli --ohttp --proxy https://ohttp-repro.exe.xyz --gateway-path /.well-known/ohttp-gateway --config-path /.well-known/ohttp-gateway -v https://ohttp-repro.exe.xyz/attestations/sha256:a8b7bdca41ee219ebc632b4174ead70a7117411198058d4b353ec9beb4043e0d --first-hop 'http://127.0.0.1:1312/ohttp/ohttp-repro.exe.xyz'
```

[pvcli]: https://github.com/cloudflareresearch/pvcli

## Configuring TLS

Instead of using a reverse proxy for TLS termination, you can configure TLS directly in ocloak (which uses rustls):

```toml
# /etc/ocloak/ocloak.conf

[tls]
cert_path = "/etc/ocloak/cert.pem"
key_path = "/etc/ocloak/key.pem"
```

## Setting up an info page

The minimal configuration for a static info page looks like this:

```toml
# /etc/ocloak/ocloak.conf

[index]
file_path = "/var/www/html/index.html"
```

You can optionally set http response headers, e.g. for HSTS:

```toml
# /etc/ocloak/ocloak.conf

[index]
file_path = "/var/www/html/index.html"
http_headers = { "Strict-Transport-Security" = "max-age=31536000; includeSubDomains; preload" }
```

## Troubleshooting

### Check RFC 9540 DNS OHTTP discovery

Some relays refuse gateways if the DNS OHTTP discovery is not properly configured. You can check the DNS OHTTP discovery for a list of domains using:

```sh
cargo run --release -- plumbing check-dns -v \
    ohttp.test.orca.toys gateway.ohttp.info example.com ccc.de crypto.cloudflare.com x.y.z.abc
```

### Query the DNS HTTPS RR

To inspect the raw HTTPS RR for a domain, that's used in RFC 9540 DNS OHTTP discovery, you can use the following command:

```sh
cargo run --release -- plumbing query-https-rr example.com
```

## License

`GPL-3.0-or-later`
