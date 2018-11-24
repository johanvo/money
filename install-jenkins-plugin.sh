#!/bin/bash

echo "Downloading plugins"
for plugin in "$@"
do
	echo "Downloading $plugin"
	curl -L https://updates.jenkins-ci.org/latest/ansicolor.hpi -o /tmp/WEB-INF/plugins/$plugin.hpi
done

cd /tmp;
echo "Adding plugins"

for plugin in "$@"
do
	echo "Adding $plugin"
	zip --grow /usr/share/jenkins/jenkins.war WEB-INF/plugins/$plugin.hpi
done

