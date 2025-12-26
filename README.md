# Riak Control

Riak Control is a standalone user management application for Riak.
It provides a web-based user interface for:

* managing users in a Riak Cluster;
* cluster admin operations.

It is implemented as a web app written in Elm. Assuming you installed
it from a package, start it with `riak-control` and point your
browser at <this-host-address>:8091.

## Configuring

The port on which the server running Riak Control web app will be
listening can be set via environment variable `RIAK_CONTROL_PORT`.

## Preparing riak

On the riak side, several steps need to be taken on the riak node
riak_control will be connecting to.

### Security setup

- Enable riak security, thus: `riak admin security enable`.

- Create a user (`riak admin security add-user $RIAK_CONTROL_USER
password=$PASSWORD`). These will be the user and password you will
configure riak_control with.

- Importantly, `riak admin security grant riak_kv.riak_control on any
to $RIAK_CONTROL_USER`.

- Also, `riak admin security add-source all 127.0.0.1/32 password`
(substitute "127.0.0.1/32" as appropriate).

### Configure riak

* riak.conf:

- uncomment and set `listener.https.internal` to IP:PORT riak_control
will be connecting to.

- uncomment `ssl.certfile`, `ssl.keyfile` and `ssl.cacertfile` (and
of course put all the keys and certiicate files in
$(platform\_etc\_dir).

* advanced.config:

- `{riak_kv, [{secure_referer_check, false}]}` (this should be
properly dealt with before a 1.0 release).

### rctl.conf
```
{
    "admin": {
        "name": "barsyk",
        "password": "b72fd0f9173971a62181358f796f7304f2c7fb48ef6cc109331652b8808fafb5"
    }
}
```
