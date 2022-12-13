#!/usr/bin/env bash
set -eu

rm -f /var/spool/postfix/pid/master.pid

SMTP_PORT="${SMTP_PORT:-587}"
DNS_RESOLVER="${DNS_RESOLVER:-1.1.1.1}"

# shellcheck disable=SC2153
echo "[${SMTP_HOST}]:${SMTP_PORT} ${SMTP_USERNAME}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd

postconf -e "relayhost = [${SMTP_HOST}]:${SMTP_PORT}" \
            "smtp_sasl_auth_enable = yes" \
            "smtp_sasl_security_options = noanonymous" \
            "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"

postmap hash:/etc/postfix/sasl_passwd
chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

## overrides
for e in ${!POSTFIX_*} ; do postconf -e "${e:8}=${!e}" ; done
for e in ${!POSTFIXMASTER_*} ; do v="${e:14}" && postconf -Me "${v/__/\/}=${!e}"; done
for e in ${!POSTMAP_*} ; do echo "${!e}" > "/etc/postfix/${e:8}" && postmap "/etc/postfix/${e:8}"; done

mkdir -p /var/spool/postfix/etc
echo "nameserver ${DNS_RESOLVER}" >> /etc/resolv.conf
cp /etc/resolv.conf /var/spool/postfix/etc

chown -R postfix:postfix /var/lib/postfix /var/spool/postfix
chown root:root /var/spool/postfix
chown -R root:root /var/mail /var/spool/postfix/pid /var/spool/postfix/etc
chown -R :postdrop /var/spool/postfix/public /var/spool/postfix/maildrop

exec "$@"
