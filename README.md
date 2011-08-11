# About travis-worker #

This is home for the next generation of Travis CI worker. It is a WIP and is still very rough around the edges
for broader community of contributors to jump in.


## Getting started ##

Install Bundler:

    gem install bundler

Pull down dependencies:

    bundle install

Fetch base Vagrant box (Ubuntu 10.04, 32-bit):

    vagrant box add base http://files.vagrantup.com/lucid32_old.box

Pull down submodules (Travis cookbooks, et cetera):

    git submodule update --init

Spin up a new Vagrant VM that will be provisioned with Opscode Chef:

    vagrant init
    vagrant up


## Running tests ##

On Ruby 1.9.2:

    bundle exec rake test


## License & copyright information ##

See LICENSE file.

Copyright (c) 2011 [Travis CI development team](https://github.com/travis-ci).
