#!/bin/sh

# guest:guest has full access to /

rabbitmqctl add_vhost travis
rabbitmqctl add_user guest guest
rabbitmqctl set_permissions -p travis guest ".*" ".*" ".*"
