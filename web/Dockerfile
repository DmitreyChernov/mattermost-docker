FROM nginxinc/nginx-unprivileged:mainline-alpine

USER root

# Устанавливаем openssl и curl
RUN apk add --no-cache openssl curl

# Удаляем дефолтный конфиг
RUN rm -f /etc/nginx/conf.d/default.conf

# КОПИРУЕМ КОНФИГ ПРЯМО ИЗ КОРНЯ ПАПКИ web В ПАПКУ NGINX
# Так как файл лежит как web/mattermost-ssl, относительный путь просто "mattermost-ssl"
COPY mattermost-ssl /etc/nginx/sites-available/mattermost-ssl

# Копируем скрипт входа
COPY entrypoint.sh /entrypoint.sh

# Создаем папку для сертификатов и настраиваем права
RUN mkdir -p /cert \
    && chown -R nginx:nginx /etc/nginx/sites-available \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && chown -R nginx:nginx /cert \
    && chown nginx:nginx /entrypoint.sh \
    && chmod u+x /entrypoint.sh

# Создаем PID файл
RUN touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

# Оптимизация nginx.conf
RUN sed -i "/^http {/a \    proxy_buffering off;\n" /etc/nginx/nginx.conf \
    && sed -i '/temp_path/d' /etc/nginx/nginx.conf \
    && sed -i 's!/tmp/nginx.pid!/var/run/nginx.pid!g' /etc/nginx/nginx.conf

USER nginx

HEALTHCHECK CMD curl --fail http://localhost:8080 || exit 1

ENTRYPOINT ["/entrypoint.sh"]

VOLUME ["/var/run", "/etc/nginx/conf.d/", "/var/cache/nginx/", "/cert"]
