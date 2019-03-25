#!/bin/bash

read -p "API Key: " API_KEY
read -p "Grafana Server [localhost]: " GRAFANA_SERVER
read -p "Dashboard ID (A - for all): " D_UID

if [[ -z ${D_UID} ]]; then echo "Required either Dashboard ID or A"; exit 1; fi

declare -l GRAFANA_ADDR=${GRAFANA_SERVER}
if [[ -z ${GRAFANA_ADDR} ]]; then GRAFANA_ADDR="localhost"; fi

if [[ ${D_UID} == 'a' || ${D_UID} == 'A' ]]; then
    D_FOLDER=$(date +%F_%T)
    mkdir ~/${D_FOLDER}
    D_FOLDER=~/${D_FOLDER}

    DASHBOARD_LIST=$(curl -s -H "Authorization: Bearer ${API_KEY}" ${GRAFANA_ADDR}:3000/api/search?type=dash-db | jq -r '.[] | @base64')
    for DASHBOARD in $DASHBOARD_LIST
    do
        D_UID=$(echo ${DASHBOARD} | base64 --decode | jq -r '.uid')
        D_TITLE=$(echo ${DASHBOARD} | base64 --decode | jq -r '.title')
        echo "Generating report for ${D_TITLE}..."
        curl -s -o "${D_FOLDER}/${D_TITLE}.pdf" http://${GRAFANA_ADDR}:8686/api/v5/report/${D_UID}?apitoken=${API_KEY}
        sleep 5s
    done
else
    D_TITLE=$(curl -s -H "Authorization: Bearer ${API_KEY}" ${GRAFANA_ADDR}:3000/api/dashboards/uid/${D_UID} | jq -r '.dashboard.title')
    D_FOLDER=~
    echo "Generating report for ${D_TITLE}..."
    curl -s -o "${D_FOLDER}/${D_TITLE}.pdf" http://${GRAFANA_ADDR}:8686/api/v5/report/${D_UID}?apitoken=${API_KEY}
fi
