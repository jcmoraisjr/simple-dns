# Simple-DNS

An authoritative and recursive DNS server with dynamic configuration.

**Note:** Only for local usage! Do not use this server on untrusted networks.

# Usage

Run the DNS server:

    docker run -d \
     -p 53:53 -p 53:53/udp \
     -e DOMAIN=mydomain:0.168.192 \
     -e DNS_A=ns1:127.0.0.1,myhost:192.168.0.10 \
     quay.io/jcmoraisjr/simple-dns

Query the DNS server:

    nslookup myhost.mydomain localhost
    nslookup google.com localhost

# Deploy

Simple-DNS configures a Bind server dinamically, based on environment variables:

* `DOMAIN`: Domain and reverse IP in the following format: `<domain>:<reverse>`
* `DNS_A`: A comma separated list of `<name>:<ip>` entries
* Create an A record resolving `ns1` name to the IP of the DNS server

Use this systemd unit to configure automatic startup:

    [Unit]
    Description=Simple DNS
    After=docker.service
    Requires=docker.service
    [Service]
    ExecStartPre=-/usr/bin/docker stop simple-dns
    ExecStartPre=-/usr/bin/docker rm simple-dns
    ExecStart=/usr/bin/docker run \
      -p 53:53/tcp \
      -p 53:53/udp \
      -e DOMAIN=mydomain:0.168.192 \
      -e DNS_A=ns1:127.0.0.1,host1:192.168.0.10,host1:192.168.0.11 \
      --name simple-dns \
      quay.io/jcmoraisjr/simple-dns:latest
    RestartSec=10s
    Restart=always
    [Install]
    WantedBy=multi-user.target
