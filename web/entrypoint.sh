#!/bin/sh
set -e

APP_HOST=${APP_HOST:-app}
APP_PORT_NUMBER=${APP_PORT_NUMBER:-8065}
DOMAIN=${DOMAIN:-localhost}

CERT_DIR="/cert"
FULLCHAIN="$CERT_DIR/fullchain.pem"
PRIVKEY="$CERT_DIR/privkey.pem"

generate_self_signed() {
    echo "⚠️ Certificates not found. Generating self-signed certificate for ${DOMAIN}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$PRIVKEY" \
        -out "$FULLCHAIN" \
        -subj "/C=US/ST=State/L=City/O=Mattermost/CN=${DOMAIN}"
    echo "✅ Self-signed certificate generated."
}

if [ ! -f "$FULLCHAIN" ] || [ ! -f "$PRIVKEY" ]; then
    generate_self_signed
else
    echo "✅ Certificates found. Skipping generation."
fi

# ПУТЬ ДОЛЖЕН СОВПАДАТЬ С DOCKERFILE
CONF_AVAILABLE="/etc/nginx/sites-available/mattermost-ssl"
CONF_ENABLED="/etc/nginx/conf.d/mattermost.conf"

if [ -w "$CONF_ENABLED" ]; then
    rm -f "$CONF_ENABLED"
fi

ln -s -f "$CONF_AVAILABLE" "$CONF_ENABLED"

echo "🔄 Configuring Nginx for ${DOMAIN} -> ${APP_HOST}:${APP_PORT_NUMBER}"
sed -i "s/{%APP_HOST%}/${APP_HOST}/g" "$CONF_ENABLED"
sed -i "s/{%APP_PORT%}/${APP_PORT_NUMBER}/g" "$CONF_ENABLED"
sed -i "s/{%DOMAIN%}/${DOMAIN}/g" "$CONF_ENABLED"

echo "🚀 Starting Nginx..."
exec nginx -g 'daemon off;'
