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
