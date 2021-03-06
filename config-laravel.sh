#!/bin/bash

composer dump-autoload --ansi

if grep -q '"post-install-cmd"' composer.json; then
  composer run-script --no-dev post-install-cmd --ansi
fi

php artisan view:clear

# Fixes https://stackoverflow.com/a/52330607
mkdir -p storage/framework/cache/data
php artisan cache:clear

echo '> Creating storage symbolic links...'
php artisan storage:link

set -e

if [ -f $ROOT/supervisor.conf ]; then
  echo '> Applying supervisor.conf...'
  mkdir -p /etc/supervisord.d
  mv $ROOT/supervisor.conf /etc/supervisord.d
fi

if [ -f $ROOT/liara_php.ini ]; then
  echo '> Applying liara_php.ini...'

  # Files in the conf.d are loaded in alphabetical order,
  # so naming a file 99-overrides.ini (for example) will cause it to be loaded last.
  # Settings set in that file will override settings set in the default php.ini.
  cp $ROOT/liara_php.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-liara_php.ini
  cp $ROOT/liara_php.ini /etc/php/${PHP_VERSION}/apache2/conf.d/99-liara_php.ini
  rm $ROOT/liara_php.ini
fi

chgrp -R www-data storage public
chmod -R ug+rwx storage public

# Prepare for read-only filesystem
# We're going to ensure that storage/framework and bootstrap directories are writable.
set -e
mkdir /tmp/.laravel-framework
mkdir /var/www/.laravel-framework
mv /var/www/html/storage/framework/* /var/www/.laravel-framework
rm -rf /var/www/html/storage/framework
ln -s /tmp/.laravel-framework /var/www/html/storage/framework

rm -rf /var/www/html/bootstrap/cache
mkdir -p /tmp/.laravel-bootstrap-cache
ln -s /tmp/.laravel-bootstrap-cache /var/www/html/bootstrap/cache
