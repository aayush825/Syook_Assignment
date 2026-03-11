FROM php:8.2-apache

# install mysql extension
RUN docker-php-ext-install mysqli pdo pdo_mysql

# enable apache rewrite module
RUN a2enmod rewrite

# copy app files
COPY . /var/www/html/

# set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
