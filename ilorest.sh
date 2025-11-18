#!/bin/bash
# 2025-11-05 create For HPE Server

ILOREST="/usr/sbin/ilorest"

function FanDiscovery {

    FANS_JSON=$($ILOREST serverinfo --fans -j)
    RESULT=""

    # 팬 이름 목록만 추출
    while IFS= read -r FAN; do
        RESULT+=$(echo -e "\n{\n\"{#FAN}\": \"$FAN\"\n},")
    done < <(echo "$FANS_JSON" | jq -r '.fans | keys[]')

    # JSON 출력
    echo -e "{"
    echo -e "\"data\":["

    # 마지막 쉼표 제거
    JSON=$(echo "$RESULT" | sed '$s/,$//')
    echo "$JSON"

    echo "]}"
}



function FanStatus {
FAN="$1"
ITEM="$2"

        if [[ "$ITEM" == "rpm" ]]; then
            REPLY="$($ILOREST serverinfo --fans -j | jq -r --arg fan "$FAN" '.fans[$fan].Reading')"
                elif [[ "$ITEM" == "status" ]]; then
                REPLY="$($ILOREST serverinfo --fans -j | jq -r --arg fan "$FAN" '.fans[$fan].Health')"
        else
            REPLY="Unknown item: $ITEM"
                fi

                echo "$REPLY"
}

function PsuDiscovery {

# ilorest 출력 중 JSON만 추출 ( '{' 부터 끝까지 )
    PSUS_JSON=$($ILOREST serverinfo --power -j | sed -n '/^{/,$p')

        RESULT=""

# PSU 개수 확인
            COUNT=$(echo "$PSUS_JSON" | jq -r '.power.PowerSupplies | length')

# PSU 목록 생성
            for ((i=0; i<COUNT; i++)); do
                PSU_NAME="PSU_$((i+1))"
                    RESULT+=$(echo -e "\n{\n\"{#PSU}\": \"$PSU_NAME\"\n},")
                    done

# JSON 출력
                    echo -e "{"
                    echo -e "\"data\":["

# 마지막 쉼표 제거
                    JSON=$(echo "$RESULT" | sed '$s/,$//')
                    echo "$JSON"

                    echo "]}"
    }

function PsuStatus {

        PSU="$1"  # 예: PSU_1 또는 PSU_2
            INDEX=$((${PSU#PSU_} - 1))  # PSU_1 → 0, PSU_2 → 1

# ilorest 출력 중 JSON만 추출
            PSUS_JSON=$($ILOREST serverinfo --power -j | sed -n '/^{/,$p')

# Health 값 추출
                echo "$PSUS_JSON" | jq -r ".power.PowerSupplies[$INDEX].Health"
            }

function RAMDiscovery {

            RAMS_JSON=$($ILOREST serverinfo --memory -j | sed -n '/^{/,$p')
                RESULT=""

# DIMM 목록 추출 (Configuration 항목만)
                    while IFS= read -r RAM; do
                        RESULT+=$(echo -e "\n{\n\"{#RAM}\": \"$RAM\"\n},")
                            done < <(echo "$RAMS_JSON" | jq -r '.memory | keys[] | select(test("Memory/DIMM Configuration"))')

# JSON 출력
                            echo -e "{"
                            echo -e "\"data\":["

# 마지막 쉼표 제거
                            JSON=$(echo "$RESULT" | sed '$s/,$//')
                            echo "$JSON"

                            echo "]}"
            }

function RAMStatus {

    RAM="$1"

            RAMS_JSON=$($ILOREST serverinfo --memory -j | sed -n '/^{/,$p')

            echo "$RAMS_JSON" | jq -r --arg RAM "$RAM" '.memory[$RAM]["Health"]'
              }


function TempDiscovery {
        TEMPS_JSON=$($ILOREST serverinfo --thermals -j 2>/dev/null | sed -n '/^{/,$p')

                # .thermals 키 확인
                if ! echo "$TEMPS_JSON" | jq -e '.thermals' >/dev/null 2>&1; then
                            echo '{"data":[]}'
                                        return
                                            fi

                                                echo '{"data":['
                                                        FIRST=1
                                                                INDEX=0

                                                                    echo "$TEMPS_JSON" | jq -r '.thermals | keys[]' | while read -r SENSOR; do
                                                                            LOCATION=$(echo "$TEMPS_JSON" | jq -r --arg key "$SENSOR" '.thermals[$key].Location' 2>/dev/null)

                                                                                    # Location이 null이면 무시
                                                                                    if [ -z "$LOCATION" ] || [ "$LOCATION" = "null" ]; then
                                                                                                    continue
                                                                                                                fi

                                                                                                                        SENSOR_NAME="${LOCATION} Temp"

                                                                                                                                if [ $FIRST -eq 0 ]; then
                                                                                                                                                echo ","
                                                                                                                                                            fi
                                                                                                                                                                    FIRST=0

                                                                                                                                                                            echo -n "{\"{#TEMP}\":\"$SENSOR_NAME\",\"{#TEMPINDEX}\":\"$INDEX\"}"
                                                                                                                                                                                    INDEX=$((INDEX + 1))
                                                                                                                                                                                        done
                                                                                                                                                                                            echo ']}'
        }

        function TempStatus {
                INDEX="$1"
                        TEMPS_JSON=$($ILOREST serverinfo --thermals -j 2>/dev/null | sed -n '/^{/,$p')

                                # .thermals 확인
                                if ! echo "$TEMPS_JSON" | jq -e '.thermals' >/dev/null 2>&1; then
                                            echo 0
                                                        return
                                                            fi

                                                                # 인덱스 기반으로 n번째 센서 찾기
                                                                MATCH_KEY=$(echo "$TEMPS_JSON" | jq -r --argjson idx "$INDEX" '.thermals | keys_unsorted[$idx]' 2>/dev/null)

                                                                    if [ -z "$MATCH_KEY" ] || [ "$MATCH_KEY" = "null" ]; then
                                                                                echo 0
                                                                                            return
                                                                                                fi

                                                                                                    VALUE=$(echo "$TEMPS_JSON" | jq -r --arg key "$MATCH_KEY" 'getpath(["thermals", $key, "Current Temp"]) // "0 C"')
                                                                                                        TEMP_VALUE=$(echo "$VALUE" | grep -oE '[0-9]+')

                                                                                                            if [ -z "$TEMP_VALUE" ]; then
                                                                                                                        echo 0
                                                                                                                                else
                                                                                                                                            echo "$TEMP_VALUE"
                                                                                                                                                    fi
                        }




function SystemModel {
        SYSTEM_JSON=$($ILOREST serverinfo -system -j 2>/dev/null | sed -n '/^{/,$p')
                echo "$SYSTEM_JSON" | jq -r '.system["Model"] // "N/A"'
        }

        function SystemServiceTag {
                SYSTEM_JSON=$($ILOREST serverinfo -system -j 2>/dev/null | sed -n '/^{/,$p')
                        echo "$SYSTEM_JSON" | jq -r '.system["Serial Number"] // "N/A"'
                }

function SystemBiosVersion {
        FW_JSON=$($ILOREST serverinfo -fw -j)
                echo "$FW_JSON" | jq -r '.firmware[] | select(startswith("System ROM:")) | split(": ")[1]'
}

function SystemIdracVersion {
        FW_JSON=$($ILOREST serverinfo -fw -j)
        echo "$FW_JSON" | jq -r '.firmware[] | select(startswith("iLO")) | split(": ")[1]'
}




function HandleArgs {
    case "$1" in
        fandiscovery)
            FanDiscovery
            ;;
        fanstatus)
            shift
            ITEM="${@: -1}"
            FAN="${@:1:$(($#-1))}"
            FanStatus "$FAN" "$ITEM"
            ;;
        psudiscovery)
            PsuDiscovery
            ;;
        psustatus)
            PsuStatus $2
            ;;
        ramdiscovery)
            RAMDiscovery
            ;;
        ramstatus)
            shift
            RAM="$*"
            RAMStatus "$RAM"
            ;;
        tempdiscovery)
            TempDiscovery
            ;;
        tempstatus)
            shift
            SENSOR="$*"
            TempStatus "$SENSOR"
            ;;
        model)
            SystemModel
            ;;
        stag)
            SystemServiceTag
            ;;
        bios)
            SystemBiosVersion
            ;;
        idrac)
            SystemIdracVersion
            ;;

        esac
}

HandleArgs $@
