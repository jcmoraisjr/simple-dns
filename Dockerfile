FROM alpine:3.4
RUN apk --no-cache add bash bind
COPY templates/ /var/lib/simple-dns/
COPY start.sh /
CMD ["/start.sh"]
