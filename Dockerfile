FROM library/ubuntu:16.04

# https://github.com/facebook/react-native/blob/8c7b32d5f1da34613628b4b8e0474bc1e185a618/ContainerShip/Dockerfile.android-base

# set default build arguments
ARG ANDROID_TOOLS_VERSION=27.0.3
ENV NPM_CONFIG_LOGLEVEL info


# set default environment variables
ENV ADB_INSTALL_TIMEOUT=10
ENV PATH=${PATH}:/opt/buck/bin/
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools

ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=\"-Xmx512m -XX:+HeapDumpOnOutOfMemoryError\""

# install system dependencies
RUN apt-get update -y && \
	apt-get install -y \
		autoconf \
		automake \
		expect \
		curl \
		g++ \
		gcc \
		git \
		libqt5widgets5 \
		lib32z1 \
		lib32stdc++6 \
		make \
		maven \
		openjdk-8-jdk \
		python-dev \
		python3-dev \
		qml-module-qtquick-controls \
		qtdeclarative5-dev \
		unzip \
		xz-utils \
		locales \
	&& \
	rm -rf /var/lib/apt/lists/* && \
	apt-get autoremove -y && \
	apt-get clean && \
	echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p --system

# fix crashing gradle because of non ascii characters in ENV variables: https://github.com/gradle/gradle/issues/3117
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# install nodejs
# https://github.com/nodejs/docker-node/blob/a5141d841167d109bcad542c9fb636607dabc8b1/6.10/Dockerfile
# gpg keys listed at https://github.com/nodejs/node#release-team
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
# configure npm
RUN npm config set spin=false
RUN npm config set progress=false

RUN npm install -g react-native-cli
RUN npm install -g yarn

# Full reference at https://dl.google.com/android/repository/repository2-1.xml
# download and unpack android
RUN mkdir -p /opt/android && mkdir -p /opt/tools
WORKDIR /opt/android
RUN curl --silent https://dl.google.com/android/repository/tools_r25.2.5-linux.zip > android.zip && \
	unzip android.zip && \
	rm android.zip

# copy tools folder
COPY tools/android-accept-licenses.sh /opt/tools/android-accept-licenses.sh
ENV PATH ${PATH}:/opt/tools

RUN mkdir -p $ANDROID_HOME/licenses/ \
	&& echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > $ANDROID_HOME/licenses/android-sdk-license \
	&& echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

# sdk
RUN /opt/tools/android-accept-licenses.sh "$ANDROID_HOME/tools/bin/sdkmanager \
	tools \
	\"platform-tools\" \
	\"build-tools;27.0.3\" \
	\"platforms;android-23\" \
	\"platforms;android-25\" \
	\"platforms;android-26\" \
	\"platforms;android-27\" \
	\"extras;android;m2repository\" \
	\"extras;google;m2repository\" \
	\"add-ons;addon-google_apis-google-24\" \
	\"extras;google;google_play_services\"" \
	&& $ANDROID_HOME/tools/bin/sdkmanager --update

VOLUME ["/app"]
WORKDIR /app
