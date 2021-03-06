#!/bin/bash
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eo pipefail

## Get the directory of the build script
scriptDir=$(realpath $(dirname "${BASH_SOURCE[0]}"))
## cd to the parent directory, i.e. the root of the git repo
cd ${scriptDir}/..

# Print out Java version
java -version
echo ${JOB_TYPE}

# if GOOGLE_APPLICATION_CREDIENTIALS is specified as a relative path prepend Kokoro root directory onto it
if [[ ! -z "${GOOGLE_APPLICATION_CREDENTIALS}" && "${GOOGLE_APPLICATION_CREDENTIALS}" != /* ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS=$(realpath ${KOKORO_ROOT}/src/${GOOGLE_APPLICATION_CREDENTIALS})
fi

case ${JOB_TYPE} in
test)
# this will not run IT tests, to run IT tests a profile must be enabled (see below)
    mvn verify -B -Dclirr.skip=true
    bash ${KOKORO_GFILE_DIR}/codecov.sh
    bash .kokoro/coerce_logs.sh
    ;;
lint)
    mvn com.coveo:fmt-maven-plugin:check
    ;;
javadoc)
    mvn javadoc:javadoc javadoc:test-javadoc
    ;;
integration)
# clean needed when running more than one IT profile
    mvn clean verify -B ${INTEGRATION_TEST_ARGS} -DtrimStackTrace=false -Dclirr.skip=true -fae
    bash .kokoro/coerce_logs.sh
    ;;
clirr)
    mvn -B clirr:check
    ;;
*)
    ;;
esac