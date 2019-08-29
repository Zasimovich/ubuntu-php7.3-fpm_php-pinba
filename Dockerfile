FROM ubuntu
MAINTAINER zasymovych
LABEL O.Zasimovich "o.zasimovich@gmail.com"

ENV TIMEZONE Europe/Kiev
ENV PHP_MEMORY_LIMIT 1024M
ENV MAX_UPLOAD 128M
ENV PHP_MAX_FILE_UPLOAD 128
ENV PHP_MAX_POST 128M</blockquote>

RUN ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
	&& echo "${TIMEZONE}" > /etc/timezone 

RUN apt-get update && \
    apt-get install software-properties-common net-tools nano apt-utils supervisor -y && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get update && apt-get upgrade -y
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install php php7.3-pinba php-fpm -y
EXPOSE 9000

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.3/fpm/pool.d/www.conf && \ 
#    sed -i -e "s/listen\s*=\s*127.0.0.1:9000/listen = [::]:9000/g"    /etc/php/7.3/fpm/pool.d/www.conf && \
    sed -i -e "s/listen = \/run\/php\/php7.3-fpm.sock/listen = 127.0.0.1:9000/g" /etc/php/7.3/fpm/pool.d/www.conf && \
    sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/7.3/fpm/pool.d/www.conf && \
    sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/7.3/fpm/pool.d/www.conf && \ 
    sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/7.3/fpm/pool.d/www.conf && \
    sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/7.3/fpm/pool.d/www.conf && \
    sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php/7.3/fpm/pool.d/www.conf

# Nginx logs to Docker log collector
#RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
#     ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./config/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY ./config/pinba/pinba.ini /etc/php/7.3/mods-available/pinba.ini
VOLUME /etc/php/7.3/mods-available/

#CMD ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisor/supervisord.conf"] # Процесс мы можем стартовать таким способом, через supervisord или ...
#or
RUN mkdir -p /run/php #решение проблемы -> ERROR: Unable to create the PID file (/run/php/php7.3-fpm.pid).: No such file or directory (2)
CMD ["php-fpm7.3", "-F"]
