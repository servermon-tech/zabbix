#!/bin/bash
# 2025-11-05 edit for StorCLI (HPE MR Storeage For Gen11)
# Replacement for OMSA storage discovery
# Require storcli command

STORCLI="/opt/MegaRAID/storcli/storcli64"
RESULT=""
function PhysicalDisksDiscovery {
# Controller 목록 가져오기
for CONTROLLER in $($STORCLI /call show j | jq -r '.Controllers[]."Response Data"."Device Number"')
do

IFS=$'\n' read -r -d '' -a DISKS <<< "$($STORCLI /c${CONTROLLER} show j | jq -r '.Controllers[]."Response Data"."Drive LIST"[]."EID:Slt"')"

for DISK in "${DISKS[@]}"; do
if [ -n "$DISK" ]; then
RESULT+=$(echo -e "\n{\n\"{#PDISK}\": \"$DISK\",\n\"{#CONTROLLER}\": \"$CONTROLLER\" \n},")
fi
done
done

echo -e "{"
echo -e "\"data\":["

JSON=$(echo "$RESULT" | sed '$s/,$//')

echo "$JSON"
echo "]}"
}

function PhysicalDiskStatus {

PDISK="$1"
CONTROLLER="$2"

    case "$3" in
        status)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg pdisk "$PDISK" '.Controllers[]."Response Data"."Drive LIST"[] | select(."EID:Slt"==$pdisk) | .State')"
            ;;  
        size)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg pdisk "$PDISK" '.Controllers[]."Response Data"."Drive LIST"[] | select(."EID:Slt"==$pdisk) | .Size')"
            ;;  
        media)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg pdisk "$PDISK" '.Controllers[]."Response Data"."Drive LIST"[] | select(."EID:Slt"==$pdisk) | .Med')"
            ;;  
        type)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg pdisk "$PDISK" '.Controllers[]."Response Data"."Drive LIST"[] | select(."EID:Slt"==$pdisk) | .Intf')"
            ;;  
        product)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg pdisk "$PDISK" '.Controllers[]."Response Data"."Drive LIST"[] | select(."EID:Slt"==$pdisk) | .Model')"
            ;;  
        pfailure)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg pdisk "$PDISK" '.Controllers[]."Response Data"."Drive LIST"[] | select(."EID:Slt"==$pdisk) | .PI')"
            ;;  
        esac
}

function VirtualDiskDiscovery {

for CONTROLLER in $($STORCLI /call show j | jq -r '.Controllers[]."Response Data"."Device Number"')
do

IFS=$'\n' read -r -d '' -a VDISKS <<< "$($STORCLI /c${CONTROLLER} show j | jq -r '.Controllers[]."Response Data"."VD LIST"[]."DG/VD"')"

for VDISK in "${VDISKS[@]}"; do
if [ -n "$VDISK" ]; then
RESULT+=$(echo -e "\n{\n\"{#VDISK}\": \"$VDISK\",\n\"{#CONTROLLER}\": \"$CONTROLLER\" \n},")
fi
done
done

echo -e "{"
echo -e "\"data\":["

JSON=$(echo "$RESULT" | sed '$s/,$//')

echo "$JSON"
echo "]}"
}


function VirtualDiskStatus {

VDISK="$1"
CONTROLLER="$2"

    case "$3" in
        status)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg vdisk "$VDISK" '.Controllers[]."Response Data"."VD LIST"[]  | select(."DG/VD"==$vdisk) | .State')"
            ;;
        raid)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg vdisk "$VDISK" '.Controllers[]."Response Data"."VD LIST"[]  | select(."DG/VD"==$vdisk) | .TYPE')"
            ;;
        size)
            echo "$($STORCLI /c${CONTROLLER} show j | jq -r --arg vdisk "$VDISK" '.Controllers[]."Response Data"."VD LIST"[]  | select(."DG/VD"==$vdisk) | .Size')"
            ;;
        *)
            exit
            ;;
        esac

}

function BatteryStatus {

    if [[ -z "$($OMSABIN storage battery grep ":" | grep Status | cut -d':' -f2 | grep Ok)" ]]; then
            echo "Ok"
    else
            echo "Failure"
                fi

}


function HandleArgs {

    case "$1" in
        pddiscovery)
            PhysicalDisksDiscovery
            ;;
        pdstatus)
            PhysicalDiskStatus $2 $3 $4
            ;;
        vddiscovery)
            VirtualDiskDiscovery
            ;;
        vdstatus)
            VirtualDiskStatus $2 $3 $4
            ;;
        esac
}

HandleArgs $@
