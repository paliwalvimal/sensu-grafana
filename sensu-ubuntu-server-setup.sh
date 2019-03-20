#!/bin/bash

# Downlading Signing Keys
echo '================================='
echo 'Downloading Erlang & RabbitMQ Key'
echo '================================='
sudo wget -O - "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" | sudo apt-key add -

echo '================================='
echo 'Downloading Sensu Key'
echo '================================='
sudo wget -q http://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | sudo apt-key add -

echo '================================='
echo 'Downloading Grafana key'
echo '================================='
sudo curl https://packages.grafana.com/gpg.key | sudo apt-key add -


# Adding repositories to system
echo '================================='
echo 'Adding Erlang repo'
echo '================================='
echo "deb https://dl.bintray.com/rabbitmq/debian xenial erlang" | sudo tee /etc/apt/sources.list.d/bintray.erlang.list

echo '================================='
echo 'Adding RabbitMQ repo'
echo '================================='
echo "deb https://dl.bintray.com/rabbitmq/debian xenial main" | sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list

echo '================================='
echo 'Adding Sensu repo'
echo '================================='
echo "deb http://sensu.global.ssl.fastly.net/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list

echo '================================='
echo 'Adding Grafana repo'
echo '================================='
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list


# Updating system
echo '================================='
echo 'Update system'
echo '================================='
sudo apt update -y


# Installing Redis
echo '================================='
echo 'Installing Redis'
echo '================================='
sudo apt install redis-server -y


# Starting Redis
echo '================================='
echo 'Starting Redis'
echo '================================='
sudo service redis-server start


# Installing Erlang (Dependency for RabbitMQ)
echo '================================='
echo 'Installing Erlang'
echo '================================='
sudo apt install erlang-nox -y


# Installing RabbitMQ
echo '================================='
echo 'Installing RabbitMQ'
echo '================================='
sudo apt install rabbitmq-server -y


# Starting RabbitMQ
echo '================================='
echo 'Starting RabbitMQ'
echo '================================='
sudo service rabbitmq-server start


# Adding RabbitMQ vhost for Sensu
echo '================================='
echo 'Starting RabbitMQ vhost for Sensu'
echo '================================='
sudo rabbitmqctl add_vhost /sensu


# Creating RabbitMQ user for Sensu
echo '================================='
echo 'Creating RabbitMQ user for Sensu'
echo '================================='
sudo rabbitmqctl add_user sensu secret
sudo rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"


# Installing Sensu
echo '================================='
echo 'Installing Sensu'
echo '================================='
sudo apt install sensu -y


# Installing WizardVan
echo '================================='
echo 'Installing WizardVan'
echo '================================='
sudo apt install git -y
git clone https://github.com/grepory/wizardvan.git
cd wizardvan
sudo cp -R lib/sensu/extensions/* /etc/sensu/extensions


# Installing Mailer
echo '================================='
echo 'Installing Mailer'
echo '================================='
/opt/sensu/embedded/bin/sensu-install -p mailer


# Creating Required Paths
echo '================================='
echo 'Creating Required Paths'
echo '================================='
sudo mkdir -p /etc/sensu/conf.d/handlers/


# Configuring Relay Handler
echo '================================='
echo 'Configuring Relay Handler'
echo '================================='
echo '{
    "relay": {
        "graphite": {
            "host": "localhost",
            "port": 2003,
            "max_queue_size": 0
        }
    }
}' | sudo tee /etc/sensu/conf.d/handlers/relay.json


# Configuring Mailer Handler
echo '================================='
echo 'Configuring Mailer Handler'
echo '================================='
echo '{
    "handlers": {
        "mailer": {
            "type": "pipe",
            "filter": "state-change-only",
            "command": "/opt/sensu/embedded/bin/handler-mailer.rb"
        }
    }
}' | sudo tee /etc/sensu/conf.d/handlers/mailer.json


# Configuring Mailer
echo '================================='
echo 'Configuring Mailer'
echo '================================='
echo '{
    "mailer": {
        "admin_gui": "http://SENSU_SERVER_IP:3000",
        "mail_from": "abc@xyz.com",
        "mail_to": "abc@xyz.com",
        "smtp_address": "localhost",
        "smtp_port": "25",
        "smtp_domain": "localhost"
    }
}' | sudo tee /etc/sensu/conf.d/mailer.json


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


# Configuring Sensu API
echo '================================='
echo 'Configuring Sensu API'
echo '================================='
echo '{
    "api": {
        "host": "localhost",
        "bind": "0.0.0.0",
        "port": 4567
    }
}' | sudo tee /etc/sensu/conf.d/api.json


# Configuring Redis
echo '================================='
echo 'Configuring Redis'
echo '================================='
echo '{
    "redis": {
        "host": "localhost",
        "port": 6379
    }
}' | sudo tee /etc/sensu/conf.d/redis.json


# Configuring RabbitMQ
echo '================================='
echo 'Configuring RabbitMQ'
echo '================================='
echo '{
    "rabbitmq": {
        "host": "localhost",
        "port": 5672,
        "vhost": "/sensu",
        "user": "sensu",
        "password": "secret"
    }
}' | sudo tee /etc/sensu/conf.d/rabbitmq.json


read -p "Configure checks for Linux(L), Windows(W), Both(B): " CHECK_CONF_INPUT
declare -l CHECK_CONF_INPUT_LOWER=$CHECK_CONF_INPUT

if [[ -z $CHECK_CONF_INPUT_LOWER ]]; then
    echo "Skipping checks and metric configuration as no input was received."
else
    if [[ $CHECK_CONF_INPUT_LOWER == "l" || $CHECK_CONF_INPUT_LOWER == "b" ]]; then
        echo '================================='
        echo 'Configuring Linux Checks & Metrics'
        echo '================================='
        
        # Configuring CPU Checks
        echo '================================='
        echo 'Configuring CPU Checks'
        echo '================================='
        echo '{
            "checks": {
                "checks-linux-cpu-usage": {
                    "command": "/opt/sensu/embedded/bin/check-cpu.rb -w 80 -c 90",
                    "interval": 30,
                    "subscribers": [
                        "linux"
                    ],
                    "handlers": [
                        "mailer"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/checks_cpu_usage_linux.json

        # Configuring Disk Checks
        echo '================================='
        echo 'Configuring Disk Checks'
        echo '================================='
        echo '{
            "checks": {
                "checks-linux-disk-usage": {
                    "command": "/opt/sensu/embedded/bin/check-disk-usage.rb -w 80 -c 90",
                    "interval": 30,
                    "subscribers": [
                        "linux"
                    ],
                    "handlers": [
                        "mailer"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/checks_disk_usage_linux.json

        # Configuring Memory Checks
        echo '================================='
        echo 'Configuring Memory Checks'
        echo '================================='
        echo '{
            "checks": {
                "checks-linux-memory-usage": {
                    "command": "/opt/sensu/embedded/bin/check-memory-percent.rb -w 80 -c 90",
                    "interval": 30,
                    "subscribers": [
                        "linux"
                    ],
                    "handlers": [
                        "mailer"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/checks_memory_usage_linux.json

        # Configuring CPU Metrics
        echo '================================='
        echo 'Configuring CPU Metrics'
        echo '================================='
        echo '{
            "checks": {
                "metrics-linux-cpu-usage": {
                    "type": "metric",
                    "command": "/opt/sensu/embedded/bin/metrics-cpu-pcnt-usage.rb",
                    "interval": 30,
                    "subscribers": [
                        "linux"
                    ],
                    "handlers": [
                        "relay"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/metrics_cpu_usage_linux.json

        # Configuring Memory Metrics
        echo '================================='
        echo 'Configuring Memory Metrics'
        echo '================================='
        echo '{
            "checks": {
                "metrics-linux-memory-usage": {
                    "type": "metric",
                    "command": "/opt/sensu/embedded/bin/metrics-memory-percent.rb",
                    "interval": 30,
                    "subscribers": [
                        "linux"
                    ],
                    "handlers": [
                        "relay"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/metrics_memory_usage_linux.json

        # Configuring Disk Usage Metrics
        echo '================================='
        echo 'Configuring Disk Usage Metrics'
        echo '================================='
        echo '{
            "checks": {
                "metrics-linux-disk-usage": {
                    "type": "metric",
                    "command": "/opt/sensu/embedded/bin/metrics-disk-usage.rb",
                    "interval": 30,
                    "subscribers": [
                        "linux"
                    ],
                    "handlers": [
                        "relay"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/metrics_disk_usage_linux.json
    fi

    if [[ $CHECK_CONF_INPUT_LOWER == "w" || $CHECK_CONF_INPUT_LOWER == "b" ]]; then
        echo '================================='
        echo 'Configuring Windows Checks & Metrics'
        echo '================================='
        
        # Configuring CPU Checks
        echo '================================='
        echo 'Configuring CPU Checks'
        echo '================================='
        echo '{
            "checks": {
                "checks-win-cpu-usage": {
                    "command": "c:\\opt\\sensu\\embedded\\bin\\ruby.exe c:\\opt\\sensu\\embedded\\bin\\check-windows-cpu-load.rb -w 80 -c 90",
                    "interval": 30,
                    "subscribers": [
                        "win"
                    ],
                    "handlers": [
                        "mailer"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/checks_cpu_usage_win.json

        # Configuring Disk Checks
        echo '================================='
        echo 'Configuring Disk Checks'
        echo '================================='
        echo '{
            "checks": {
                "checks-win-disk-usage": {
                    "command": "c:\\opt\\sensu\\embedded\\bin\\ruby.exe c:\\opt\\sensu\\embedded\\bin\\check-windows-disk.rb -w 80 -c 90",
                    "interval": 30,
                    "subscribers": [
                        "win"
                    ],
                    "handlers": [
                        "mailer"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/checks_disk_usage_win.json

        # Configuring Memory Checks
        echo '================================='
        echo 'Configuring Memory Checks'
        echo '================================='
        echo '{
            "checks": {
                "checks-win-memory-usage": {
                    "command": "c:\\opt\\sensu\\embedded\\bin\\ruby.exe c:\\opt\\sensu\\embedded\\bin\\check-windows-ram.rb -w 80 -c 90",
                    "interval": 30,
                    "subscribers": [
                        "win"
                    ],
                    "handlers": [
                        "mailer"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/checks_memory_usage_win.json

        # Configuring CPU Metrics
        echo '================================='
        echo 'Configuring CPU Metrics'
        echo '================================='
        echo '{
            "checks": {
                "metrics-win-cpu-usage": {
                    "type": "metric",
                    "command": "c:\\opt\\sensu\\embedded\\bin\\metric-windows-cpu-load.rb.bat",
                    "interval": 30,
                    "subscribers": [
                        "win"
                    ],
                    "handlers": [
                        "relay"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/metrics_cpu_usage_win.json

        # Configuring Memory Metrics
        echo '================================='
        echo 'Configuring Memory Metrics'
        echo '================================='
        echo '{
            "checks": {
                "metrics-win-memory-usage": {
                    "type": "metric",
                    "command": "c:\\opt\\sensu\\embedded\\bin\\metric-windows-ram-usage.rb.bat",
                    "interval": 30,
                    "subscribers": [
                        "win"
                    ],
                    "handlers": [
                        "relay"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/metrics_memory_usage_win.json

        # Configuring Disk Metrics
        echo '================================='
        echo 'Configuring Disk Metrics'
        echo '================================='
        echo '{
            "checks": {
                "metrics-win-disk-usage": {
                    "type": "metric",
                    "command": "c:\\opt\\sensu\\embedded\\bin\\metric-windows-disk-usage.rb.bat",
                    "interval": 30,
                    "subscribers": [
                        "win"
                    ],
                    "handlers": [
                        "relay"
                    ]
                }
            }
        }' | sudo tee /etc/sensu/conf.d/metrics_disk_usage_win.json
    fi
fi


# Starting services
echo '================================='
echo 'Starting Sensu'
echo '================================='
sudo service sensu-server start
sudo service sensu-api start


# Installing Carbon Cache
echo '================================='
echo 'Installing Carbon'
echo '================================='
sudo DEBIAN_FRONTEND=noninteractive apt -q -y --force-yes install graphite-carbon
echo "CARBON_CACHE_ENABLED=true" > /etc/default/graphite-carbon
sudo service carbon-cache start


# Installing Graphite
echo '================================='
echo 'Installing Graphite'
echo '================================='
sudo apt install graphite-web apache2 libapache2-mod-wsgi -y
chown _graphite /var/lib/graphite
sudo -u _graphite graphite-manage syncdb --noinput
sudo rm -f /etc/apache2/sites-enabled/000-default.conf
sudo cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-enabled/graphite.conf
sudo service apache2 restart


# Installing Grafana
# Updating packages and Installing Grafana
echo '================================='
echo 'Installing Grafana'
echo '================================='
sudo apt install grafana -y
sudo service grafana-server start


# Autostart services on every boot
echo '================================='
echo 'Autostart services on Boot'
echo '================================='
sudo update-rc.d rabbitmq-server defaults
sudo update-rc.d sensu-server defaults
sudo update-rc.d sensu-api defaults
sudo update-rc.d carbon-cache defaults
sudo update-rc.d apache2 defaults
sudo systemctl enable grafana-server.service
