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
    sorted=($(cat $log_file | grep -v ^$ | sort -n -t: -k3))
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
    sorted=($(cat $log_file | grep -v ^$ | sort -n -t: -k3))
    hours_in_log=( $(cat $log_file | cut -b -10 | uniq) )
    
        for h in ${hours_in_log[@]}; do
    
            for e in ${sorted[@]}; do
    
                if [ $h == $(echo $e | cut -b -10) ]; then
                    hour_list+=($e)
                    #echo "$h is $(echo $e | cut -b -10)"
                fi
                #echo "$e is not $(echo $h | cut -b -10)"
            done
    
            #echo ${hour_list[@]}
            perc=$(echo \(${#hour_list[@]}*0.95\) / 1 | bc )
            echo "${h}: $(echo ${hour_list[$perc]} | awk -F: '{ print $3 }' )"
            hour_list=()
    
        done
}


### 3 - The value at the 95th percentile of all response times abovei 1500 for just Entity4 across the whole log file ###
function check_by_request()
{
    top_list=()
    sorted=($(cat $log_file | grep -v ^$ | grep $request_type | sort -n -t: -k3 | awk -F: '{ print $3 }'))

    for i in ${sorted[@]}; do
        if [ $i -gt $response_limit ]; then
            top_list+=($i)
        fi
    done
    
    #echo "top list ${top_list[@]}"
    
    perc=$(echo \(${#top_list[@]}*0.95\) / 1 | bc )
    
    #echo "95th percentile line: $perc"
    
    if [ ${top_list[0]} ]; then
        echo "${top_list[$perc]}"
    elif [ $verbose = True ]; then
        echo "No times above $response_limit found."
    fi

}


### 4 - The value at the 95th percentile of all response times above 1500 for just Entity4 every hour ###
function check_by_request_hourly()
{
    sorted=($(cat $log_file | grep -v ^$ | grep $request_type | sort -n -t: -k3 ) )
    #echo ${sorted[@]}
    hours_in_log=( $(cat $log_file | cut -b -10 | uniq) )

    for h in ${hours_in_log[@]}; do
        full_hour_list=$(cat $log_file | grep "$request_type" | grep "$h" | sort -n -t: -k3 )
        #echo ${full_hour_list[@]}
        for f in ${full_hour_list[@]}; do
            entry=$(echo $f | awk -F: '{print $3}')
            #echo $entry
            if [ $entry -gt $response_limit ]; then
                hour_list+=($f)
            fi
        done
        #echo $hour_list
        perc=$(echo \(${#hour_list[@]}*0.95\) / 1 | bc )
        echo "${h}: $(echo ${hour_list[$perc]} | awk -F: '{ print $3 }' )"
        hour_list=()
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
