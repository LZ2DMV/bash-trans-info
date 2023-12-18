#!/bin/bash

sessionId=$(curl -s -X POST 'https://asti.dobrich.bg:8443/rest-auth/guests?aid=7768' | sed 's/"//g')

routesData=$(curl -s -k -H "eurogps.eu.sid: $sessionId" https://asti.dobrich.bg:8443/rest-its/scheme/routes)
linesData=$(curl -s -k -H "eurogps.eu.sid: $sessionId" https://asti.dobrich.bg:8443/rest-its/scheme/stop-lines)
stopsData=$(curl -s -k -H "eurogps.eu.sid: $sessionId" 'https://asti.dobrich.bg:8443/rest-its/scheme/stops?filter=true')

function collectLinesDesc {
    if [ -z "$linesDesc" ]; then
        linesDesc=$(curl -s -k -H "eurogps.eu.sid: $sessionId" https://asti.dobrich.bg:8443/rest-its/scheme/lines/)
    fi
}

function stopNameToStopId {
    echo $stopsData | jq --arg name "$1" '.[] | select(.name == $name) | .id' | jq -s -r 'join(", ")'
}

function getStopNames {
    echo $stopsData | jq -r '.[].name'
}

function stopNameAndNumById {
    echo $stopsData | jq -r --arg id "$1" '.[] | select(.id == ($id | tonumber)) | "\(.number),\(.name)"'
}

function getRoutesForLine {
    echo $linesData | jq -r --arg id "$1" '.[] | select(.lineId == ($id | tonumber)) | .routeId' | sort -u | paste -sd ","
}

function routeNameById {
    echo $routesData | jq -r --arg id "$1" '.[] | select(.id == ($id | tonumber)).name'
}

function stopsFromLineId {
    declare -A arr
    local routeIds=$(getRoutesForLine "$1")
    IFS=',' read -ra routeIds <<< "$routeIds"
    for routeId in "${routeIds[@]}"; do
        declare -a o=()
        routeName=$(routeNameById "$routeId")
        routeStopIds=($(echo "$routesData" | jq --arg id "$routeId" '.[] | select(.id == ($id | tonumber)) | .stopIds | .[]'))
        echo -e "Направление $routeName:\n"
        for stopId in "${routeStopIds[@]}"; do
            remainingTime=$(echo "$linesData" | jq -c -r --arg id "$stopId" --arg rid "$routeId" '.[] |
                select(.stopId == ($id | tonumber) and .routeId == ($rid | tonumber)) | .remainingTime[0]')
            stopName=$(echo "$stopsData" | jq -r '.[] | select(.id == '$stopId') | .name')
            remainingTimeInMinutes=$((remainingTime / 60))
            o+=("$stopName")
            arr["$stopName"]="$remainingTimeInMinutes"
        done
        for k in "${!o[@]}"; do
            if [ "$k" -eq $((${#o[@]} - 1)) ]; then
                arr[${o[$k]}]="последна"
            else
                arr[${o[$k]}]+=" м."
            fi
            echo "Спирка ${o[$k]} - ${arr[${o[$k]}]}"
        done
        echo
    done
}

function linesFromStopId {
    declare -a arr
    IFS=', ' read -ra id_arr <<< "$1"
    i=true
    for id in "${id_arr[@]}"; do
        stopNumName=$(stopNameAndNumById "$id")
        stopSchedule=$(curl -s -k -H "eurogps.eu.sid: $sessionId" https://asti.dobrich.bg:8443/rest-its/scheme/stop-lines/$id)
        for row in $(echo "$stopSchedule" | jq -c -r '.[] | {lineId, remainingTime, routeId}'); do
            lineId=$(echo "$row" | jq -r '.lineId')
            routeId=$(echo "$row" | jq -r '.routeId')
            remainingTime=$(echo "$row" | jq -r '.remainingTime[0]')
            routeName=$(echo "$routesData" | jq -r '.[] | select(.id == '$routeId') | .name')
            remainingTimeInMinutes=$((remainingTime / 60))
            (( key = lineId*1000 ))
            while [[ -n "${arr[$key]}" ]]; do
                (( key++ ))
            done
            arr["$key"]="$remainingTimeInMinutes,$routeName"
        done
        [ $i = true ] && i=false || echo
        echo -e "Спирка $(cut -d',' -f2 <<< $stopNumName) ($(cut -d',' -f1 <<< $stopNumName))\n"
        for key in "${!arr[@]}"; do
            (( newKey = key/1000 ))
            IFS=',' read -ra values <<< "${arr[$key]}"
            if [ $newKey -gt "12" ]; then
                collectLinesDesc
                newKey=$(echo $linesDesc | jq -r --arg id "$newKey" '.[] | select(.id == ($id | tonumber)) | .number' | awk '{ print toupper($0) }')
            fi
            echo "Линия $newKey (${values[1]}) - ${values[0]} минути"
        done
        arr=()
    done
}

#stopsFromLineId "4"
#linesFromStopId "41547"
#stopNameToStopId "Шуменски университет"

#id=$(stopNameToStopId "Батовска")
#linesFromStopId "$id"
