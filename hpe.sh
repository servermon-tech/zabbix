#!/bin/bash
#v1.0 20251028 via junohpark
ILORESTBIN="/usr/sbin/ilorest"
SSABIN="/usr/sbin/ssacli"

function PhysicalDisksDiscovery {

#Get Controller Num
for CONTROLLER in "$($SSABIN ctrl all show | cut -d "(" -f1 | awk '{print $NF}' | tr -d '\12')"
do

IFS=$'\n' read -r -d '' -a DISKS <<< "$($SSABIN ctrl slot=$CONTROLLER show config | grep physicaldrive | awk '{print $2}')"   
for DISK in "${DISKS[@]}"; do
    RESULT+=$(echo -e "\n{\n\"{#PDISK}\": \"$DISK\",\n\"{#CONTROLLER}\": \"$CONTROLLER\" \n},")
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
    echo "$($SSABIN ctrl slot=$CONTROLLER pd $PDISK show | grep -v "Authentication" | grep Status | awk '{print $2}')"
    ;;  
#    pfailure)
#    echo "$($SSABIN storage pdisk controller=$CONTROLLER pdisk=$PDISK | grep "^Failure Predicted" | awk '{print $4}')"
#    ;;  
    size)
    echo "$($SSABIN ctrl slot=$CONTROLLER pd $PDISK show | grep -v "Block" | grep Size | awk '{print $2 $3}')"
    ;;  

    esac
}

function VirtualDiskDiscovery {

for CONTROLLER in "$($SSABIN ctrl all show | cut -d "(" -f1 | awk '{print $NF}' | tr -d '\12')"
do

IFS=$'\n' read -r -d '' -a VDISKS <<< "$($SSABIN ctrl slot=$CONTROLLER show config | grep -v Array | grep logicaldrive | awk '{print $2}')"

for VDISK in "${VDISKS[@]}"
do
    RESULT+=$(echo -e "\n{\n\"{#VDISK}\": \"$VDISK\",\n\"{#CONTROLLER}\": \"$CONTROLLER\" \n},")
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
    echo "$($SSABIN ctrl slot=$CONTROLLER ld $VDISK show | grep "Status" | grep -v MultiDomain | grep -v "Parity Initialization" | awk '{print $2}')"
    ;;  
    raid)
    echo "$($SSABIN ctrl slot=$CONTROLLER ld $VDISK show | grep "Fault Tolerance" | awk '{print $3}')"
    ;;  
    size)
    echo "$($SSABIN ctrl slot=$CONTROLLER ld $VDISK show | grep Size | grep -v Strip | awk '{print $2 $3}')"
    ;;  
    members)
    echo "$($SSABIN ctrl slot=$CONTROLLER ld $VDISK show | grep physical | awk '{print $2}'
    ;;  
    inttype)
    echo "$($SSABIN ctrl slot=$CONTROLLER ld $VDISK show | grep physical | awk '{print $7, $8}' | sed 's/,$//'
    ;;  
    memsize)
    echo "$($SSABIN ctrl slot=$CONTROLLER ld $VDISK show | grep physical | awk '{print $9, $10}' | sed 's/,$//'
    ;; 
    memstatus)
    echo "$($SSABIN ctrl slot=$CONTROLLER ld $VDISK show | grep physical | awk '{print $11}' | sed 's/)//'
    ;; 
    *)  
    exit
    ;;  
    esac
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
    fandiscovery)
        FanDiscovery
        ;;
    fanstatus)
        FanStatus $2 $3
        ;;
    psudiscovery)
        PsuDiscovery
        ;;
    esac
}

HandleArgs $@

