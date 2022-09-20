#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

if [ -z "$VERSION_QUALIFIER_OPT" ]; then
  RELEASE=1 rake artifact:all
else
  VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:all
fi

STACK_VERSION=`cat versions.yml | sed -n 's/^logstash\:\s\([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\)$/\1/p'`

echo "Saving tar.gz for docker images"
docker save docker.elastic.co/logstash/logstash:${STACK_VERSION}-SNAPSHOT | gzip -c > build/logstash-${STACK_VERSION}-docker-image-x86_64.tar.gz
docker save docker.elastic.co/logstash/logstash-oss:${STACK_VERSION}-SNAPSHOT | gzip -c > build/logstash-oss-${STACK_VERSION}-docker-image-x86_64.tar.gz
docker save docker.elastic.co/logstash/logstash-ubi8:${STACK_VERSION}-SNAPSHOT | gzip -c > build/logstash-ubi8-${STACK_VERSION}-docker-image-x86_64.tar.gz

echo "GENERATED ARTIFACTS"
for file in build/logstash-*; do shasum $file;done

echo "Creating dependencies report for ${STACK_VERSION}"
mkdir -p build/distributions/dependencies-reports/
bin/dependencies-report --csv=build/distributions/dependencies-reports/logstash-${STACK_VERSION}.csv

echo "Saving tar.gz for docker images"
docker save docker.elastic.co/logstash/logstash-full:${STACK_VERSION}-SNAPSHOT | gzip -c > build/logstash-${STACK_VERSION}-SNAPSHOT-docker-image.tar.gz

echo "GENERATED DEPENDENCIES REPORT"
shasum build/reports/dependencies-reports/logstash-${STACK_VERSION}.csv

# set required permissions on artifacts and directory
chmod -R a+r build/*
chmod -R a+w build

# ensure the latest image has been pulled
docker pull docker.elastic.co/infra/release-manager:latest

# collect the artifacts for use with the unified build
docker run --rm \
  --name release-manager \
  -e VAULT_ADDR \
  -e VAULT_ROLE_ID \
  -e VAULT_SECRET_ID \
  --mount type=bind,readonly=false,src="$PWD",target=/artifacts \
  docker.elastic.co/infra/release-manager:latest \
    cli collect \
      --project logstash \
      --branch 8.4 \
      --commit "$(git rev-parse HEAD)" \
      --workflow "staging" \
      --version "${STACK_VERSION}" \
      --artifact-set main
