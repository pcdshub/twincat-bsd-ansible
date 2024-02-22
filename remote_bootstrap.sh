#!/bin/sh
# shellcheck disable=SC1078,SC1079,SC2140
# Exit early if python 3 already installed
if test -e /usr/local/bin/python3; then
  echo "python3 already installed"
  exit
fi
# Exit early if running on linux by accident
if ! test -e /bin/freebsd-version; then
  echo "not on bsd, whoops!"
  exit
fi

set -e

# setup psproxy if needed
if ! grep ANSIBLE /usr/local/etc/pkg.conf; then
  echo "
# BEGIN ANSIBLE MANAGED BLOCK
PKG_ENV {
    http_proxy: "http://psproxy:3128",
    https_proxy: "http://psproxy:3128",
}
# END ANSIBLE MANAGED BLOCK
" >> /usr/local/etc/pkg.conf
fi

# setup ntp if needed
if ! grep ANSIBLE /etc/ntp.conf; then
  echo "
# BEGIN ANSIBLE MANAGED BLOCK
disable monitor

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default kod nomodify notrap nopeer noquery
restrict 127.0.0.1

server psntp1.pcdsn iburst
server psntp2.pcdsn iburst
server psntp3.pcdsn iburst
# END ANSIBLE MANAGED BLOCK
" >> /etc/ntp.conf

  # Stop ntp service, force a sync, start it again
  service ntpd stop
  ntpd -g -q
  service ntpd start
fi

# Install python 3
pkg install -y python3
