#!/bin/sh

docker run -it -p 4223:4223 -p 8223:8223 nats-streaming -p 4223 -m 8223
