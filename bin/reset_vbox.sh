#!/bin/sh

rm -rf ~/.VirtualBox/
rm -rf ~/VirtualBox\ VMs/
rm -rf ~/.vagrant
rm ~/travis-worker/.vagrant
rm ~/travis-worker/base/.vagrant

killall VBoxXPCOMIPCD
killall VBoxSVC
killall VBoxHeadless

