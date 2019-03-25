#!/bin/bash

# Install go-lang
curl -O https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
tar -C /usr/local -xf go1.12.1.linux-amd64.tar.gz
rm -f go1.12.1.linux-amd64.tar.gz

echo "export $PATH=$PATH:/usr/local/go/bin" >> ~/.profile

# Install grafana-reporter
go get github.com/IzakMarais/reporter
go install -v github.com/IzakMarais/reporter/cmd/grafana-reporter

# Install PDF LaTex
apt install texlive-latex-base -y

# Starting service on every boot
cp $(which grafana-reporter) /etc/init.d/grafana-reporter

# Starting reporting service
nohup grafana-reporter &

# grafana-reporter service runs on port 8686 so you need to whitelist the port
# Steps to setup grafana-reporter:
# 1. Click on setting icon within any dashboard
# 2. Click on Links from left panel
# 3. Add new link
# 4. Select link from dropdown menu in first option
# 5. Provide URL: http://{IP_ADDRESS}:8686/api/v5/report/{dashboardUID}?apitoken=xxxx
# 6. Provide title, tooltipand select doc for icon option.
# 7. Select time range, variable values and open in new tab
# 8. Click update, save the dashboard and you are all set.
