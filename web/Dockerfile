FROM nginxinc/nginx-unprivileged:mainline-alpine

USER root

# 1. Устанавливаем openssl (для генерации сертификатов) И curl (для healthcheck)
RUN apk add --no-cache openssl curl

# Удаляем дефолтный конфиг и копируем наши
RUN rm -f /etc/nginx/conf.d/default.conf
COPY ["./mattermost", "./mattermost-ssl", "/etc/nginx/sites-available/"]

# Копируем скрипт входа
COPY entrypoint.sh /entrypoint.sh

# Настраиваем права доступа для пользователя nginx
# Важно: даем права на запись в папку с сертификатами (/cert), если она будет маппиться как volume
RUN mkdir -p /cert \
    && chown -R nginx:nginx /etc/nginx/sites-available \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && chown -R nginx:nginx /cert \
    && chown nginx:nginx /entrypoint.sh \
    && chmod u+x /entrypoint.sh

# Создаем файл PID и настраиваем права
RUN touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

# Копируем конфиг безопасности
COPY ./security.conf /etc/nginx/conf.d/
RUN chown -R nginx:nginx /etc/nginx/conf.d/security.conf

# Оптимизация nginx.conf (буферизация и пути)
RUN sed -i "/^http {/a \    proxy_buffering off;\n" /etc/nginx/nginx.conf \
    && sed -i '/temp_path/d' /etc/nginx/nginx.conf \
    && sed -i 's!/tmp/nginx.pid!/var/run/nginx.pid!g' /etc/nginx/nginx.conf

# Переключаемся на непривилегированного пользователя
USER nginx

# Healthcheck (порт должен совпадать с тем, что слушает Nginx внутри, обычно 8080 в этом образе)
HEALTHCHECK CMD curl --fail http://localhost:8080 || exit 1

ENTRYPOINT ["/entrypoint.sh"]

# Тома для сохранения данных и конфигов
VOLUME ["/var/run", "/etc/nginx/conf.d/", "/var/cache/nginx/", "/cert"]
