#!/bin/sh

rabbitmqctl add_vhost "travis.development"
rabbitmqctl add_user travis_worker travis_worker_password

rabbitmqctl set_permissions -p "travis.development" travis_worker ".*" ".*" ".*"
rabbitmqctl set_permissions -p "travis.development" guest         ".*" ".*" ".*"
