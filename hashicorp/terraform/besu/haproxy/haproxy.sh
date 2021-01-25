#!/bin/sh
sudo /usr/sbin/haproxy -f /etc/haproxy.cfg -D -p /var/run/haproxy.pid
