#!/bin/bash
set -eu

cd /var/www/html

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then

	if [ -z "$POSTGRESQL_PASSWORD" ]; then
		echo >&2 'error: missing required POSTGRESQL_PASSWORD environment variable'
		echo >&2 '  Did you forget to -e POSTGRESQL_PASSWORD=... ?'
		echo >&2
		echo >&2 '  (Also of interest might be POSTGRESQL_USERNAME and POSTGRESQL_DB_NAME.)'
		exit 1
	fi

    if ! [ -e application/config/config.php ]; then
        echo >&2 "Copying default container default config files into config volume..."
        cp -dR /var/lime/application/config/* application/config
        echo >&2 "Enabling DB-specific config file ..."
        cp application/config/config-$DB_TYPE.php application/config/config.php
    fi

    if ! [ -e plugins/index.html ]; then
        echo >&2 "No index.html file in plugins dir in $(pwd) Copying defaults..."
        cp -dR /var/lime/plugins/* plugins
    fi

    if ! [ -e upload/index.html ]; then
        echo >&2 "No index.html file upload dir in $(pwd) Copying defaults..."
        cp -dR /var/lime/upload/* upload
    fi

	DBSTATUS=$(TERM=dumb php -f /usr/local/bin/gdx-check-install.php)

	if [ "${DBSTATUS}" = "NOINSTALL" ]; then
        echo >&2 'Database not yet populated - installing Limesurvey database'
	    php application/commands/console.php install "#[\ReturnTypeWillChange]" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_NAME" "$ADMIN_EMAIL" verbose
	fi

    #flush asssets (clear cache on restart)
    php application/commands/console.php flushassets
fi

exec "$@"