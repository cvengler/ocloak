ocloak(1)

# NAME

ocloak - Open RFC 9458 OHTTP Relay

# SYNOPSIS

*ocloak* <_subcommand_> [_options_]

# DESCRIPTION

*ocloak* is an Oblivious HTTP (OHTTP) relay as described in RFC 9458. It forwards
encapsulated requests to permitted gateways over HTTPS and returns their
responses. The relay sees the client connection and the selected gateway, but
cannot decrypt the encapsulated HTTP messages. Clients need the gateway's OHTTP
key configuration to create requests.

An OHTTP client sends a *POST* to */ohttp/*_host_ with the content type
*message/ohttp-req*. If the request names only a host, the relay uses the
matching rule's *path=*, or */.well-known/ohttp-gateway* if none is set.

# CONFIGURATION

The daemon reads the TOML configuration file specified with *-c*. The file is
usually located at */etc/ocloak/ocloak.conf*.

## Gateway policy

The relay evaluates *[[allowed]]* rules in file order. The first matching rule
decides whether to forward the request and how. A rule with *deny = true*
refuses it. Requests that match no rule are refused.

A rule's *hosts=* list specifies gateway hostnames. The literal *"\*"* matches
any hostname. Partial wildcards are not supported. With
*require\_dns\_ohttp\_discovery = true*, the rule matches only if the gateway
advertises the *ohttp* parameter in a DNS HTTPS record (RFC 9540).

Use *path* to change the default */.well-known/ohttp-gateway* request path to
something else. Requests that include their own path match only rules with
*arbitrary\_paths = true*, even if the requested path is the rule's fixed path.

## Timeouts and Limits

The *[defaults]* section controls how the relay accepts and forwards requests.
Specify durations as strings with an *ms*, *s*, *m*, or *h* suffix (for example,
*15s*), and sizes with an *B*, *KiB*, *MiB*, or *GiB* suffix (for example,
*10MiB*).

*tls\_handshake\_timeout=*
	Time limit for the client's TLS handshake when the relay terminates TLS.

*connect\_timeout=*
	Time limit for establishing a connection to the gateway.

*read\_timeout=*
	Time limit for each read of the client's request body, and the gateway's
	response body. This is not a time limit for the entire request, and is meant
	to terminate stalled connections.

*max_request_size=*
	The maximum size of an encapsulated HTTP request.

*max_redirects=*
	Maximum number of redirects to follow from a gateway. Redirects must stay on
	the same origin (scheme, host and port).

*user_agent=*
	Value of the User-Agent header sent to the gateway.

## TLS

Instead of using a TLS terminating reverse proxy, it's possible to enable HTTPS
directly on the listener. Make sure the *[tls]* section is enabled and contains
both *cert\_path=* and *private\_key\_path=*. The daemon user needs read access
to these files (also for reloading renewed certificates later on).

You can use systemd's *SupplementaryGroups=* setting to grant additional access
to the ephemeral daemon user.

## Index page

Optionally serve a static file to *GET /* requests. In the *[index]* section,
specify the path to the file using *file_path=* to enable this feature.

The content type header is assumed by inspecting the file's first byte, unless a
value is explicitly configured with *content_type=*.

Custom HTTP response headers can be specified using *http_headers=*, which
expects a dictionary of header names to values.

# SIGNALS

*SIGHUP*
	On Unix, reread the configuration file and reload the TLS certificate and
	private key if TLS is configured.

	Restart the daemon to change the listening address or apply changes to
	outbound HTTP client settings. A change to *read_timeout=* takes effect for
	client request bodies on reload, but for gateway responses only after a
	restart.

# EXAMPLES

Run the relay using the system configuration:

	ocloak daemon -c /etc/ocloak/ocloak.conf

# SEE ALSO

RFC 9458 (Oblivious HTTP), RFC 9540 (Discovery of Oblivious Services via Service
Binding Records)

# AUTHORS

This program was originally written and is currently maintained by kpcyrd.
Bug reports and patches are welcome on Github:

	_https://github.com/kpcyrd/ocloak_
