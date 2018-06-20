#!/bin/bash

# set -x

. `dirname $0`/brodos-env.sh

if [ -z "$1" ]; then
    # read timestamp from file
    since=`readTimestamp priceUpdate`
    echo "Since: $since"
else
    # timestamp given as parameter
    since=$1
fi

baseUrl="https://tajet1.brodos.net:8443/cxf/article/price"

size=100
macaddress="00:22:f4:f9:aa:20"
systemid=1
uuid="null"

outer=true
count=0
updateTimestamp=$since

while [ $outer == "true" ] ; do
    # do query url
    response=`curl -XGET "${baseUrl}?count=${size}&timestamp=${since}&macaddress=${macaddress}&systemid=${systemid}&uuid=${uuid}"`
    cp .lastResponse .nextToLastResponse
    echo $response > .lastResponse

    name=`printf "%05d\n" $count`
    count=`echo $count + 1 | bc`

    success=`echo $response | jq -c ".result"`
    if [ $success == "true" ]; then
        # successful response
        filename=prices_$name.json
        echo $response | jq -c ".data[]" > $filename
        echo $response | jq ".data[].uuid" > .uuids
        numElements=`cat .uuids | wc -l`
        if [ "$numElements" -gt 0 ] ; then
            uuid=`cat .uuids | tail -1 | sed "s/\"//g"`        
        else
            outer=false
        fi
        
        # read latest updateTimestamp
        timestamp=`cat $filename | jq -c '.lastUpdatedDate' | sort | tail -1`
        [ $timestamp > $updateTimestamp ] \
            && updateTimestamp=$timestamp \
            && writeTimestamp priceUpdate $updateTimestamp
    else
        echo "Received error: " `echo $response | jq -c ".message"`
        outer=false
    fi
    
done

