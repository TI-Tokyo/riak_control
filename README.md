# Riak Control

**Riak Control** is a standalone companion application for OpenRiak.
It provides a web-based UI for:

* Initial deployment of OpenRiak nodes to remote machines (such as AWS instances);
* Cluster admin operations:
  - observing nodes (`riak admin cluster status`, with additional
    details such as memory usage, uptime);
  - operation on nodes: stage (leave, join, replace, force replace,
    down, stop), plan, commit;
  - inspection of effective app env vars on individual nodes;
  - inspecting and editing advanced.config on nodes;
  - restarting nodes: individually, also rolling restart of entire
    cluster (requires `riak-deadmanshand` agent running on target
    nodes alongside riak).
* Observing backend status (currently leveled only).
* TictacAAE status.
* Managing users, groups.

It is implemented as a single-page web app written in Elm. Assuming you installed
it from a package, start it with `riak-control` and point your
browser at <this-host-address>:8091.

Compatibility note: While Riak Control can be used to deploy nodes of
any version, its full functionality (cluster observability, monitoring
and admin tasks) will only work with OpenRiak version 3.4.x and later.

## Configuring

The port on which the server running Riak Control web app will be
listening can be set via environment variable `RIAK_CONTROL_PORT`.

### rctl.conf
```
{
    "admin": {
        "name": "barsyk",
        "password": "b72fd0f9173971a62181358f796f7304f2c7fb48ef6cc109331652b8808fafb5"
    }
}
```

## Preparing OpenRiak

On the riak side, several steps need to be taken on the node
Riak Control will be connecting to.

### Security setup

- Enable riak security, thus: `riak admin security enable`.

- Create a user (`riak admin security add-user $RIAK_CONTROL_USER
password=$PASSWORD`). These will be the user and password you will
configure Riak Control with.

- Importantly, `riak admin security grant riak_kv.riak_control on any
to $RIAK_CONTROL_USER`.

- Also, `riak admin security add-source all 127.0.0.1/32 password`
(substitute "127.0.0.1/32" as appropriate).

### Configure OpenRiak

* riak.conf:

- uncomment and set `listener.https.internal` to IP:PORT riak_control
will be connecting to.

- uncomment `ssl.certfile`, `ssl.keyfile` and `ssl.cacertfile` (and
of course put all the keys and certiicate files in
$(platform\_etc\_dir).

* advanced.config:

- `{riak_kv, [{secure_referer_check, false}]}` (this should be
properly dealt with before a 1.0 release).
