TAG=quay.io/jcmoraisjr/simple-dns
build:
	docker build -t $(TAG) .
run:
	docker stop simple-dns && docker rm simple-dns || :
	docker run -d \
	  -p 53:53/tcp \
	  -p 53:53/udp \
	  -e DOMAIN=mydomain:0.0.10 \
	  -e DNS_A=ns1:127.0.0.1,host1:10.0.0.1,host2:10.0.0.2 \
	  --name simple-dns $(TAG)
