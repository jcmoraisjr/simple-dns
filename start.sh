#!/bin/bash
set -e

die() { echo $* >&2; exit 1; }

[ -z "$DOMAIN" ] && die "\$DOMAIN is undefined"

IFS=":" read -r domain reverse <<< "$DOMAIN"
IFS=":" read -r ttl_domain ttl_reverse <<< "$TTL"

if grep -q ' ' <<< "$domain" || ! egrep -q '^([0-9]{1,3}.){3}$' <<< "${reverse}."; then
  die "Invalid domain:reverse param: $DOMAIN"
fi

ttl_domain=${ttl_domain:-1h}
ttl_reverse=${ttl_reverse:-1d}

echo "Domain: $domain TTL $ttl_domain"
echo "Reverse: $reverse TTL $ttl_reverse"

named_tmpl=/var/lib/simple-dns/named.conf.template
binddb_tmpl=/var/lib/simple-dns/bind.db.template

named_conf=/etc/bind/named.conf
domain_conf=/var/bind/master/${domain}.db
reverse_conf=/var/bind/master/${reverse}.db

mkdir -p /etc/bind /var/bind/master

sed \
  -e "s/{{DOMAIN}}/$domain/g" \
  -e "s/{{REVERSE}}/$reverse/g" \
   $named_tmpl > $named_conf

sed \
  -e "s/{{HEADER}}/BIND data file for $domain/" \
  -e "s/{{DOMAIN}}/$domain/g" \
  -e "s/{{TTL}}/$ttl_domain/g" \
   $binddb_tmpl > $domain_conf

sed \
  -e "s/{{HEADER}}/BIND reverse data file for $reverse.in-addr.arpa/" \
  -e "s/{{DOMAIN}}/$domain/g" \
  -e "s/{{TTL}}/$ttl_reverse/g" \
   $binddb_tmpl > $reverse_conf

IFS="." read -r i1 i2 i3 <<< "$reverse"
network="${i3}.${i2}.${i1}"

echo "A records:"
unset ns1
for dns_a in ${DNS_A//,/ }; do
  IFS=":" read -r name ip <<< "$dns_a"
  if [ -z "$name" ] || [ -z "$ip" ]; then
    die "Invalid name:ip A record: $dns_a"
  fi
  echo "  ${name}: ${ip}"
  printf '%-11s IN      A     %s\n' "$name" "$ip" >> $domain_conf
  [ "$name" = "ns1" ] && ns1=$ip
  ip_rev="${ip#$network.}"
  if [ "$ip" != "$ip_rev" ]; then
    printf '%-11s IN      PTR   %s.%s.\n' "$ip_rev" "$name" "$domain" >> $reverse_conf
  fi
done
[ -z "$ns1" ] && die "No 'ns1' A record"

exec /usr/sbin/named -g
