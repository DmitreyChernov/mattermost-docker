#!/bin/sh
set -e

# Переменные окружения
APP_HOST=${APP_HOST:-app}
APP_PORT_NUMBER=${APP_PORT_NUMBER:-8065} # Mattermost по умолчанию слушает 8065 внутри контейнера
DOMAIN=${DOMAIN:-localhost}

CERT_DIR="/cert"
FULLCHAIN="$CERT_DIR/fullchain.pem"
PRIVKEY="$CERT_DIR/privkey.pem"
# Поддержка старых имен файлов для совместимости
OLD_CERT="$CERT_DIR/cert.pem"
OLD_KEY="$CERT_DIR/key-no-password.pem"

# Функция генерации самоподписанного сертификата
generate_self_signed() {
    echo "⚠️ Certificates not found. Generating self-signed certificate for ${DOMAIN}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$PRIVKEY" \
        -out "$FULLCHAIN" \
        -subj "/C=US/ST=State/L=City/O=Mattermost/CN=${DOMAIN}"
    
    # Создаем симлинки для совместимости со старым скриптом, если он ищет cert.pem
    ln -sf "$FULLCHAIN" "$OLD_CERT"
    ln -sf "$PRIVKEY" "$OLD_KEY"
    
    echo "✅ Self-signed certificate generated successfully."
}

# Проверка наличия сертификатов (проверяем оба варианта имен)
if [ ! -f "$FULLCHAIN" ] || [ ! -f "$PRIVKEY" ]; then
    if [ ! -f "$OLD_CERT" ] || [ ! -f "$OLD_KEY" ]; then
        generate_self_signed
    else
        echo "ℹ️ Found legacy certificate files."
        FULLCHAIN="$OLD_CERT"
        PRIVKEY="$OLD_KEY"
    fi
else
    echo "✅ Certificates found. Skipping generation."
fi

# Определяем, включен ли SSL
if [ -f "$FULLCHAIN" ] && [ -f "$PRIVKEY" ]; then
    echo " SSL enabled."
    ssl="-ssl"
else
    echo "⚠️ No valid certificates found. Running in HTTP mode (not recommended for production)."
    ssl=""
fi

# Подготовка конфига Nginx
CONF_AVAILABLE="/etc/nginx/sites-available/mattermost${ssl}"
CONF_ENABLED="/etc/nginx/conf.d/mattermost.conf"

# Удаляем старый конфиг, если есть права на запись
if [ -w "$CONF_ENABLED" ]; then
    rm -f "$CONF_ENABLED"
fi

# Создаем ссылку на нужный конфиг (http или https)
ln -s -f "$CONF_AVAILABLE" "$CONF_ENABLED"

# Замена переменных в конфиге
echo "🔄 Configuring Nginx for host: ${APP_HOST}:${APP_PORT_NUMBER} and domain: ${DOMAIN}"
sed -i "s/{%APP_HOST%}/${APP_HOST}/g" "$CONF_ENABLED"
sed -i "s/{%APP_PORT%}/${APP_PORT_NUMBER}/g" "$CONF_ENABLED"
# Добавляем замену домена, если в шаблоне конфига есть заглушка для server_name
# Обычно в оригинальных шаблонах mattermost-docker server_name задан жестко или через envsubst, 
# но добавим на всякий случай, если вы используете кастомный шаблон с {%DOMAIN%}
sed -i "s/{%DOMAIN%}/${DOMAIN}/g" "$CONF_ENABLED"

# Запуск Nginx
echo "🚀 Starting Nginx..."
exec nginx -g 'daemon off;'
