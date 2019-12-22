#!/bin/bash

function generate_data() {
    local D_UID="${1}"
    local GRAFANA_RPT_SERVER="${2}"
    local RPT_API_KEY="${3}"
    cat <<EOL
[
    {
        "icon":	"doc",
        "includeVars": true,
        "keepTime": true,
        "tags":	[],
        "targetBlank": true,
        "title": "PDF Report",
        "tooltip": "Generate PDF Report",
        "type":	"link",
        "url": "${GRAFANA_RPT_SERVER}/api/v5/report/${D_UID}?apitoken=${RPT_API_KEY}"
    }
]
EOL
}

function add_link() {
    local DASHBOARD="${1}"
    local AUTH_API_KEY="${2}"
    local GRAFANA_SERVER="${3}"
    local RPT_API_KEY="${4}"
    local GRAFANA_RPT_SERVER="${5}"

    local D_TITLE=$(echo ${DASHBOARD} | jq -r '.dashboard.title')
    local D_UID=$(echo ${DASHBOARD} | jq -r '.dashboard.uid')

    DASHBOARD=$(echo ${DASHBOARD} | jq '.dashboard.links += '"$(generate_data ${D_UID} ${GRAFANA_RPT_SERVER}:8686 ${RPT_API_KEY})"'')
    echo "Adding report link to dahboard ${D_TITLE}"

    curl -s -i -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer ${AUTH_API_KEY}" \
        -X POST --data "${DASHBOARD}" \
        http://${GRAFANA_SERVER}:3000/api/dashboards/db
}

function start() {
    read -p "Auth API Key: " AUTH_API_KEY     # API Key with editor permission for adding links to dashboard
    read -p "Report API Key: " RPT_API_KEY    # API Key with viewer permission for generating reports
    read -p "Grafana Server: " GRAFANA_SERVER
    read -p "Grafana Report Server: " GRAFANA_RPT_SERVER
    read -p "Dashboard ID (A - for all): " D_UID

    if [[ ${D_UID} == 'a' || ${D_UID} == 'A' ]]; then
        local DASHBOARD_LIST=$(curl -s -H "Authorization: Bearer ${AUTH_API_KEY}" ${GRAFANA_SERVER}:3000/api/search?type=dash-db | jq -r '.[] | @base64')
        for DASHBOARD in $DASHBOARD_LIST
        do
            D_UID=$(echo ${DASHBOARD} | base64 --decode | jq -r '.uid')
            DASHBOARD=$(curl -s -H "Authorization: Bearer ${AUTH_API_KEY}" ${GRAFANA_SERVER}:3000/api/dashboards/uid/${D_UID})
            add_link "${DASHBOARD}" "${AUTH_API_KEY}" "${GRAFANA_SERVER}" "${RPT_API_KEY}" "${GRAFANA_RPT_SERVER}"
        done
    else
        DASHBOARD=$(curl -s -H "Authorization: Bearer ${AUTH_API_KEY}" ${GRAFANA_SERVER}:3000/api/dashboards/uid/${D_UID})
        add_link "${DASHBOARD}" "${AUTH_API_KEY}" "${GRAFANA_SERVER}" "${RPT_API_KEY}" "${GRAFANA_RPT_SERVER}"
    fi
}

start
