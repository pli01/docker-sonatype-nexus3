#!/bin/bash
set -x

export image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
export VERSION=${2:-latest}
namespace=nexus

ret=0
echo "Check tests/docker-compose.yml config"
docker-compose -p ${namespace} config
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] docker-compose -p ${namespace} config"
else
  echo "[FAILED] docker-compose -p ${namespace} config"
  ret=1
fi

echo "Check nexus installed"
docker-compose -p ${namespace} run --name "test-nexus" --rm nexus ls -l /opt/sonatype/nexus/
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] nexus installed"
else
  echo "[FAILED] nexus installed"
  ret=1
fi

# test a small nginx config
echo "Check nexus running"

# setup test
echo "# setup env test:"
test_compose=docker-compose.yml
test_service=nexus
test_config=nexus-test.sh
docker-compose -p ${namespace} -f $test_compose up -d --no-build $test_service
docker-compose -p ${namespace} -f $test_compose ps $test_service
container=$(docker-compose -p ${namespace}  -f $test_compose ps -q $test_service)
echo docker cp $test_config ${container}:/opt
docker cp $test_config ${container}:/opt

# run test
echo "# run test:"
docker-compose -p ${namespace}  -f $test_compose exec -T $test_service /bin/bash -c "/opt/$test_config"
test_result=$?

# teardown
echo "# teardown:"
docker-compose -p ${namespace}  -f $test_compose stop
docker-compose -p ${namespace}  -f $test_compose rm -fv

if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] nexus url check [$test_config]"
else
  echo "[FAILED] nexus url check [$test_config]"
  ret=1
fi

exit $ret
