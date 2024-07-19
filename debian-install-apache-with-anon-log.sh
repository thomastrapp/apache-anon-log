#!/usr/bin/env bash

set -euo pipefail

perror_exit() { echo "Error: $@" >&2 ; exit 1 ; }


thisdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fconf="$thisdir/apache-anon-log.conf"
test -f "$fconf" || perror_exit "file does not exist '$fconf'"
conf=$(cat "$fconf")


apt update
apt upgrade -y
apt install -y apache2 curl dnsutils


cat << EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
  DocumentRoot /var/www/html
  $conf
</VirtualHost>
EOF

apachectl restart
sleep 5


anonlog=/var/log/apache2/anon.access.log
errorlog=/var/log/apache2/anon.error.log
truncate -s0 "$anonlog"
truncate -s0 "$errorlog"


useragent="USR_AGENT"
loip=$(nslookup -query=A localhost | awk '/^Address: / { print $2 }')
[[ "$loip" == "127.0.0.1" ]] || perror_exit "ip-addr of localost != '$loip'"


# normal log
curl -fs --ipv4 -H "User-Agent: $useragent" localhost >/dev/null || perror_exit "triggering anon log failed"

test -f "$anonlog"              || perror_exit "expected file '$anonlog' to exist"
grep 127.0.0.66 "$anonlog"      || perror_exit "expected entry in anon error log"
grep -i "$useragent" "$anonlog" && perror_exit "user-agent exposed in anon log"
grep 127.0.0.1 "$anonlog"       && perror_exit "ip-addr exposed in anon log"


# error log
curl -s --ipv4 -H "User-Agent: $useragent" 'localhost/%' >/dev/null || perror_exit "triggering anon error log failed"

test -f "$errorlog"              || perror_exit "expected file '$errorlog' to exist"
grep 127.0.0.66 "$errorlog"      || perror_exit "expected entry in anon error log"
grep -i "$useragent" "$errorlog" && perror_exit "user-agent exposed in anon error log"
grep 127.0.0.1 "$errorlog"       && perror_exit "ip-addr exposed in anon error log"

exit 0

