#!/bin/sh
#
# Copyright © 2015-2021 the original authors.
# SPDX-License-Identifier: Apache-2.0
#
APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`
APP_HOME="`pwd -P`"
CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

set -e
die () { echo; echo "ERROR: $*"; echo; exit 1; } >&2
warn () { echo "$*"; } >&2

JAVA_HOME_CANDIDATES="$JAVA_HOME $JRE_HOME /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/default-java"
for DIR in $JAVA_HOME_CANDIDATES; do
    if [ -x "$DIR/bin/java" ]; then JAVA_EXE="$DIR/bin/java"; break; fi
done
[ -z "${JAVA_EXE}" ] && die "JAVA_HOME is not set and no java found in path."

exec "$JAVA_EXE" $DEFAULT_JVM_OPTS $JAVA_OPTS -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
