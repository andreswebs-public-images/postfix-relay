FROM debian:bullseye-slim

ARG DEBIAN_FRONTEND="noninteractive"

RUN \
    apt-get update && \
    apt-get --yes --no-install-recommends install \
      postfix \
      libsasl2-modules \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN \
    postconf -e \
      "smtp_use_tls = yes" \
      "smtp_tls_note_starttls_offer = yes" \
      "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
      "smtp_tls_security_level = encrypt" \
      "maillog_file = /dev/stdout" \
      "mynetworks = 0.0.0.0/0"

COPY run.sh /

RUN chmod +x /run.sh

VOLUME ["/var/lib/postfix", "/var/mail", "/var/spool/postfix"]

EXPOSE 25

ENTRYPOINT ["/run.sh"]

CMD ["postfix", "start-fg"]
