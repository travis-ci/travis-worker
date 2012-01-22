#!/bin/sh

rabbitmqctl add_vhost "travis.development"
rabbitmqctl add_user travisci_worker travisci_worker_password

rabbitmqctl set_permissions -p "travisci.development" travisci_worker ".*" ".*" ".*"
rabbitmqctl set_permissions -p "travisci.development" guest         ".*" ".*" ".*"
