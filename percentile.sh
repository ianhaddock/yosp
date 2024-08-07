#!/bin/bash -e

# Ian Haddock Aug 5 2024
# Provided "AS IS" and without warranty of any kind.
#


function usage() 
{
    echo ""
    echo "###########"
    echo "## Parse log file for 95th percentile values"
    echo "##"
    echo "## Options:"
    echo "## -h: find 95th percentile hourly"
    echo "## -t: find 95th percentile per request-type"
    echo "## -v: enable verbose results"
    echo "##"
    echo "## Usage: $(basename $0) [-v] [-h] [-t request_type ] logfile.log"
    echo "###########"
    echo ""
}


### getops
check_by_hour=False
check_by_request=False
verbose=False

while getopts 'hvt:' option; do
    case "$option" in
        h)
            check_by_hour=True
            #echo "check by hour is set"
            ;;
        t)
            check_by_request=True
            request_type="${OPTARG}"
            #echo "check by request type is set to ${request_type}"
            ;;    
        v)
            verbose=True
            #echo "verbose is set"
            ;;    
        ?)
            usage;
            exit 1;
            ;;
    esac
done
shift "$(($OPTIND -1))"


### sanity checks
if [ ! command -v bc &> /dev/null ]; then
    echo "ERROR: This script requires bc to be installed."
    exit 1;
fi
if [ $# -eq 0 ] || [ ! -f $1 ]; then
    usage
    echo "ERROR: Please provide a valid log file."
    exit 1;
else
    #echo "Log file: $1"
    log_file="$1"
fi


### 1 - The value at the 95th percentile of response time across the whole log file ###
function check_full_log_file() 
{
    sorted=($(cat $log_file | grep -v ^$ | grep SUCCESS | sort -n -t: -k3))
    #echo ${sorted[@]}
    
    lines=${#sorted[@]} 
    #echo "lines in log: $lines"
    
    perc=$(echo \(${lines}*0.95\) / 1 | bc )
    #echo "95th percentile line: $perc"
    
    echo "$(echo ${sorted[$perc]} | awk -F: '{ print $3 }' )"
    
}


### 2 - The value at the 95th percentile for every hour of the day in question ###
function check_full_log_file_hourly()
{

    hours_in_log=( $(cat $log_file | cut -b -10 | uniq) )

    for hour in ${hours_in_log[@]}; do
        full_hour_list=( $(cat $log_file | grep "$hour" | grep SUCCESS |  sort -n -t: -k3 ) )
        list_end=$(( ${#full_hour_list[@]}  ))

        percentile=$(echo \(${list_end}*0.95\) / 1 | bc )
        echo "${hour}: $(echo ${full_hour_list[${percentile}]} | awk -F: '{ print $3 }' )"

    done 

}


### 3 - The value at the 95th percentile of all response times above 1500 for just Entity4 across the whole log file ###
function check_by_request()
{

    sorted=($(cat $log_file | grep -v ^$ | grep $request_type | sort -n -t: -k3 | awk -F: '{ print $3 }'))
    list_end=$(( ${#sorted[@]} -1 ))

    # b sort 
    last=$list_end
    first=0
    middle=0
    while [ $(( $last - $first )) -ne 1 ]; do
        middle=$(( ${first} + (${last} - ${first}) / 2 ))
        item=$(echo ${sorted[${middle}]} )

        #echo "first: ${first}, middle: ${middle}, last: ${last}, item: ${item}"

        if [ ${item} -eq ${response_limit} ]; then
            #item=$(echo ${full_hour_list[$(( ${middle} -1 ))]} | awk -F: '{ print $3 }' )
            #middle=$(( ${middle} -1 ))
            break
        elif [ ${item} -lt ${response_limit} ]; then
            first=$(( ${middle} )) #+ 1 ))
        elif [ ${item} -gt ${response_limit} ]; then
            last=$(( ${middle} )) #- 1 ))
        fi

    done

    list_size=$(( ${list_end} - ${middle} + 1 )) 
    percentile=$(echo \(${list_size}*0.95\) / 1 | bc )
    offset=$(( ${middle} + ${percentile} ))
    #echo "percentile: ${percentile} offset: ${offset}"
    echo "$(echo ${sorted[${offset}]} )"

}


### 4 - The value at the 95th percentile of all response times above 1500 for just Entity4 every hour ###
function check_by_request_hourly()
{

    hours_in_log=( $(cat $log_file | cut -b -10 | uniq) )

    for hour in ${hours_in_log[@]}; do
        full_hour_list=( $(cat $log_file | grep "$request_type" | grep "$hour" | grep SUCCESS |  sort -n -t: -k3 ) )
        list_end=$(( ${#full_hour_list[@]} -1 ))
        #echo "list end: $list_end"

        # b sort 
        last=$list_end
        first=0
        middle=0
        while [ $(( $last - $first )) -ne 1 ]; do
            middle=$(( ${first} + (${last} - ${first}) / 2 ))
            item=$(echo ${full_hour_list[${middle}]} | awk -F: '{ print $3 }' )

            #echo "first: ${first}, middle: ${middle}, last: ${last}, item: ${item}"

            if [ ${item} -eq ${response_limit} ]; then
                #item=$(echo ${full_hour_list[$(( ${middle} -1 ))]} | awk -F: '{ print $3 }' )
                #middle=$(( ${middle} -1 ))
                break
            elif [ ${item} -lt ${response_limit} ]; then
                first=$(( ${middle} )) #+ 1 ))
            elif [ ${item} -gt ${response_limit} ]; then
                last=$(( ${middle} )) #- 1 ))
            fi

        done

        #echo "###first: ${first}, middle: ${middle}, last: ${last}, item: ${item}"

        list_size=$(( ${list_end} - ${middle} + 1 )) 
        percentile=$(echo \(${list_size}*0.95\) / 1 | bc )
        offset=$(( ${middle} + ${percentile} ))
        # echo "percentile: ${percentile} offset: ${offset}"
        echo "${hour}: $(echo ${full_hour_list[${offset}]} | awk -F: '{ print $3 }' )"

    done 

}


### main ###

response_limit=1500

if [ $check_by_request = True ]; then

    if [ $check_by_hour = True ]; then
        check_by_request_hourly
    else
        check_by_request
    fi

else

    if [ $check_by_hour = True ]; then
        check_full_log_file_hourly
    else
        check_full_log_file
    fi
fi

exit 0
