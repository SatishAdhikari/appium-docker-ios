# These are default values, you can override them on the command line by
# specifying them on the command line, e.g. make DEVELOPER_PROFILE_PATH={your value}
DEVELOPER_PROFILE_PATH=/etc/quamotion/quamotion.developerprofile
LICENSE_PATH=/etc/quamotion/.license
DEVELOPER_DISK_PATH=/etc/quamotion/devimg
DEVELOPER_PROFILE_PASSWORD=quamotion
UDID=$(shell idevice_id -l)

docker: Dockerfile start.sh
	sudo docker build . -t quamotion/appium-docker-ios:dev
	docker image ls -q quamotion/appium-docker-ios:dev > docker_id

docker_id: docker

run: docker_id
	docker stop appium-docker-ios || true && docker rm appium-docker-ios || true

	if [ -d /var/run/usbmuxd ]; then \
		echo The usbmuxd socket should exist at /var/run/usbmuxd, but is currently a directory. This can happen if you mount /var/run/usbmuxd in a container and the file does not exist. Please delete the /var/run/usbmuxd directory.; \
		exit 1; \
	fi

	if [ ! -S /var/run/usbmuxd ]; then \
		echo Could not find the usbmuxd socket. Make sure an iOS device is connected to your PC, and you have installed usbmuxd.; \
		exit 1; \
	fi

	sudo docker run \
		-p 4723:4723 \
		-v /var/run/usbmuxd:/var/run/usbmuxd \
		-v ${DEVELOPER_PROFILE_PATH}:/etc/quamotion/quamotion.developerprofile \
		-v ${LICENSE_PATH}:/etc/quamotion/.license \
		-v ${DEVELOPER_DISK_PATH}:/etc/quamotion/devimg \
		-e DEVELOPER_PROFILE_PASSWORD=${DEVELOPER_PROFILE_PASSWORD} \
		--rm \
		--name appium-docker-ios \
		`cat docker_id`

debug: docker_id
	docker stop appium-docker-ios || true && docker rm appium-docker-ios || true

	if [ -d /var/run/usbmuxd ]; then \
		echo The usbmuxd socket should exist at /var/run/usbmuxd, but is currently a directory. This can happen if you mount /var/run/usbmuxd in a container and the file does not exist. Please delete the /var/run/usbmuxd directory.; \
		exit 1; \
	fi

	if [ ! -S /var/run/usbmuxd ]; then \
		echo Could not find the usbmuxd socket. Make sure an iOS device is connected to your PC, and you have installed usbmuxd.; \
		exit 1; \
	fi

	sudo docker run \
		-p 4723:4723 \
		-v /var/run/usbmuxd:/var/run/usbmuxd \
		-v ${DEVELOPER_PROFILE_PATH}:/etc/quamotion/quamotion.developerprofile \
		-v ${LICENSE_PATH}:/etc/quamotion/.license \
		-v ${DEVELOPER_DISK_PATH}:/etc/quamotion/devimg \
		-e DEVELOPER_PROFILE_PASSWORD=${DEVELOPER_PROFILE_PASSWORD} \
		--rm \
		--name appium-docker-ios \
		-it `cat docker_id` \
		/bin/bash

test:
	jq ".desiredCapabilities.udid=\"${UDID}\"" session.json | curl -X POST http://localhost:4723/wd/hub/session -H "Content-Type: application/json" -d @-
