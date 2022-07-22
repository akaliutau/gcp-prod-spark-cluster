#!/usr/bin/env bash
echo "Installing jaav 11"
sudo apt-get -y update
sudo apt install -y openjdk-11-jdk
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export PATH=$PATH:$JAVA_HOME/bin
echo $JAVA_HOME
java -version