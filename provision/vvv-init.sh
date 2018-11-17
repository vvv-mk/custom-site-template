#!/usr/bin/env bash
# Provision WordPress Stable

# fetch the first host as the primary domain. If none is available, generate a default using the site name
DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`
SITE_TITLE=`get_config_value 'site_title' "${DOMAIN}"`
WP_VERSION=`get_config_value 'wp_version' 'latest'`
WP_TYPE=`get_config_value 'wp_type' "single"`
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Make a database, if we don't already have one
echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# Download Bedrock
if [ ! -d public_html ]
then

  # Nginx Logs
  echo "Creating logs"
  mkdir -p ${VVV_PATH_TO_SITE}/log
  touch ${VVV_PATH_TO_SITE}/log/error.log
  touch ${VVV_PATH_TO_SITE}/log/access.log

  echo "Installing Bedrock stack using Composer"

  noroot composer create-project cdk-comp/bedrock ${VVV_PATH_TO_SITE}/public_html

  echo "Setup .env"

  sed -i -e "s/DB_NAME=database_name/DB_NAME=${DB_NAME}/g" "${VVV_PATH_TO_SITE}/public_html/.env"
  sed -i -e "s/DB_USER=database_user/DB_USER=wp/g" "${VVV_PATH_TO_SITE}/public_html/.env"
  sed -i -e "s/DB_PASSWORD=database_password/DB_PASSWORD=wp/g" "${VVV_PATH_TO_SITE}/public_html/.env"
  sed -i -e "s/CDK_HOST=test.test/CDK_HOST=${DOMAIN}/g" "${VVV_PATH_TO_SITE}/public_html/.env"
fi

cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

if [ -n "$(type -t is_utility_installed)" ] && [ "$(type -t is_utility_installed)" = function ] && `is_utility_installed core tls-ca`; then
    sed -i "s#{{TLS_CERT}}#ssl_certificate /vagrant/certificates/${VVV_SITE_NAME}/dev.crt;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}#ssl_certificate_key /vagrant/certificates/${VVV_SITE_NAME}/dev.key;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
else
    sed -i "s#{{TLS_CERT}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
fi
