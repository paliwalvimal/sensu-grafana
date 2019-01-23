#!/bin/bash

# This script requires "vim" and "wget"

# Asking for Sensu Server Public IP
read -p "Sensu Server IP: " SENSU_SERVER_IP
echo '================================='
echo 'PUBLIC IP: ' ${SENSU_SERVER_IP}
echo '================================='


# Fetching Private IP of local system
LOCAL_PRIVATE_IP="$(hostname -i)"
echo '================================='
echo 'PRIVATE IP: ' ${LOCAL_PRIVATE_IP}
echo '================================='


# Installing EPEL
echo '================================='
echo 'Installing EPEL'
echo '================================='
sudo yum install epel-release -y


# Creating repository configuration file
echo '================================='
echo 'Adding Sensu repo'
echo '================================='
echo '[sensu]
name=sensu
baseurl=https://sensu.global.ssl.fastly.net/yum/$releasever/$basearch/
gpgkey=https://repositories.sensuapp.org/yum/pubkey.gpg
gpgcheck=1
enabled=1' | sudo tee /etc/yum.repos.d/sensu.repo


# Installing Sensu
echo '================================='
echo 'Installing Sensu'
echo '================================='
sudo yum install sensu -y


# Installing Sensu Plugins
echo '================================='
echo 'Installing Sensu Plugins'
echo '================================='
cd /opt/sensu/embedded/bin/

sudo sensu-install -p cpu-checks
sudo sensu-install -p disk-checks
sudo sensu-install -p memory-checks


# Configuring Transport
echo '================================='
echo 'Configuring Transport'
echo '================================='
echo '{
    "transport": {
        "name": "rabbitmq",
        "reconnect_on_error": true
    }
}' | sudo tee /etc/sensu/conf.d/transport.json


# Configuring RabbitMQ
echo '================================='
echo 'Configuring RabbitMQ'
echo '================================='
echo '{
    "rabbitmq": {
        "host": '\"${SENSU_SERVER_IP}\"',
        "port": 5672,
        "vhost": "/sensu",
        "user": "sensu",
        "password": "secret"
    }
}' | sudo tee /etc/sensu/conf.d/rabbitmq.json


# Configuring Sensu Client
echo '================================='
echo 'Configuring Sensu Client'
echo '================================='
echo '{
    "client": {
        "name": "centos-client",
        "address": '\"${LOCAL_PRIVATE_IP}\"',
        "subscriptions": [
            "linux"
        ]
    }
}' | sudo tee /etc/sensu/conf.d/client.json


# Starting Sensu Client
echo '================================='
echo 'Starting Sensu'
echo '================================='
sudo service sensu-client start


# Autostart services on every boot
sudo chkconfig sensu-client on