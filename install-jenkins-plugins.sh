#!/bin/bash

echo "Downloading plugins"
for plugin in "$@"
do
	echo "  downloading $plugin"
	curl -L https://updates.jenkins-ci.org/latest/$plugin.hpi -o /tmp/WEB-INF/plugins/$plugin.hpi
done

ls -l /tmp/WEB-INF/plugins/

cd /tmp
echo "Adding plugins"

for plugin in "$@"
do
	zip --grow /usr/share/jenkins/jenkins.war WEB-INF/plugins/$plugin.hpi
	ls -l /usr/share/jenkins/jenkins.war
done

