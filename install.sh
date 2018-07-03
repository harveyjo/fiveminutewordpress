#!/bin/bash


# Pull-in the command line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--name)
    NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--database)
    DATABASE="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--password)
    PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


# Get the latest version of wordpress
curl -LO https://wordpress.org/latest.zip

# Just in case
sudo apt-get install unzip

# Unzip the folder
unzip latest.zip -d .
mv wordpress/* ./

rm latest.zip


# Add a wp-config.php to the project
echo "<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to \"wp-config.php\" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', '${DATABASE}');

/** MySQL database username */
define('DB_USER', 'root');

/** MySQL database password */
define('DB_PASSWORD', '${PASSWORD}');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */" >> wp-config.php


# Get some unique secure credentials for keys and salts
curl https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php


echo "/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');" >> wp-config.php


# Make sure composer is installed
EXPECTED_SIGNATURE="$(curl https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

# Setup Composer and create the project
php composer-setup.php --quiet
RESULT=$?
rm composer-setup.php


php composer.phar init


# Create a custom docker-compose.yaml
echo "wordpress_core:
  image: wordpress
  links:
    - ${DATABASE}:mysql
  volumes:
    - ./:/var/www/html/
  ports:
    - 8000:80
${DATABASE}:
  image: mariadb
  environment:
    MYSQL_ROOT_PASSWORD: ${PASSWORD}
  volumes:
    - ./mysql_data:/var/lib/mysql
phpmyadmin:
  image: phpmyadmin/phpmyadmin
  links:
    - ${DATABASE}:mysql
  ports:
    - 8080:80
  environment:
    MYSQL_USERNAME: root
    MYSQL_ROOT_PASSWORD: ${PASSWORD}" > docker-compose.yaml
    PMA_HOST: mysql

# Run the containers
docker-compose up --build


