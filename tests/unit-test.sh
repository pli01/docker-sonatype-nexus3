#!/bin/bash
set -x

image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
version=${2:-latest}

ret=0
echo "Check tests/docker-compose.yml config"
docker-compose config
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] docker-compose config"
else
  echo "[FAILED] docker-compose config"
  ret=1
fi

echo "Check nexus installed"
docker-compose run --name "test-nexus" --rm nexus ls -l /opt/sonatype/nexus/
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
test_config=nexus-test.sh
docker-compose -f $test_compose up -d --no-build nexus
docker-compose  -f $test_compose ps
container=$(docker-compose  -f $test_compose ps  | awk ' NR > 2 { print $1 }')
echo docker cp $test_config ${container}:/opt
docker cp $test_config ${container}:/opt

# run test
echo "# run test:"
docker-compose  -f $test_compose exec -T nexus /bin/bash -c "/opt/$test_config"
test_result=$?

# teardown
echo "# teardown:"
docker-compose  -f $test_compose stop
docker-compose  -f $test_compose rm -fv
docker system prune -f

if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] nexus url check [$test_config]"
else
  echo "[FAILED] nexus url check [$test_config]"
  ret=1
fi

exit $ret
