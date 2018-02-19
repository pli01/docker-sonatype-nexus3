#!/bin/bash

nexus=${nexus:-http://localhost:8081/nexus}
prefix=$(dirname $0)
res=1
RETRY_NB=60
RETRY_DELAY_IN_SEC=1
n=0
test_result=1
echo "Wait $RETRY_NB second for $nexus ready ?"
until [ $n -ge $RETRY_NB ] || [ $test_result -eq 0 ]
do
        if curl -L --output /dev/null --silent --fail --insecure --write-out "%{http_code}" --connect-timeout 1 --retry 1 --retry-delay 1 --retry-max-time 1 --max-time 1 $nexus ; then
	  echo
          echo "Test passed"
          test_result=0;
        else
	  echo
          echo "Test failed at $n try"
          sleep $RETRY_DELAY_IN_SEC
        fi
        ((n++))
done
exit $test_result
