ARG UBUNTU_VER="focal"
FROM ubuntu:${UBUNTU_VER} as fetch-stage

############## fetch stage ##############

# overlay arch
ARG OVERLAY_ARCH="x86_64"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# install fetch packages
RUN \
	apt-get update \
	&& apt-get install -y \
	--no-install-recommends \
		ca-certificates \
		curl \
		xz-utils \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# fetch version file
RUN \
	set -ex \
	&& curl -o \
	/tmp/version.txt -L \
	"https://raw.githubusercontent.com/sparklyballs/versioning/master/version.txt"

# fetch overlay
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		/overlay-src \
	&& curl -o \
	/tmp/overlay.tar.xz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_RELEASE}/s6-overlay-${OVERLAY_ARCH}-${S6_OVERLAY_RELEASE}.tar.xz" \
	&& curl -o \
	/tmp/noarch.tar.xz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_RELEASE}/s6-overlay-noarch-${S6_OVERLAY_RELEASE}.tar.xz" \
	&& curl -o \
	/tmp/symlinks.tar.xz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_RELEASE}/s6-overlay-symlinks-noarch-${S6_OVERLAY_RELEASE}.tar.xz" \
	&& tar xf \
	/tmp/overlay.tar.xz -C \
	/overlay-src \
	&& tar xf \
	/tmp/noarch.tar.xz -C \
	/overlay-src \
	&& tar xf \
	/tmp/symlinks.tar.xz -C \
	/overlay-src \
	&& sed -i 's#/command:/usr/bin:/bin#/command:/usr/bin:/bin:/usr/sbin#g' /overlay-src/etc/s6-overlay/config/global_path

FROM ubuntu:${UBUNTU_VER}

############## runtime stage ##############

# environment variables
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/root" \
LANGUAGE="en_US.UTF-8" \
LANG="en_US.UTF-8" \
TERM="xterm"

# install runtime packages
RUN \
	apt-get update \
	&& apt-get install -y \
	--no-install-recommends \
		apt-utils \
		ca-certificates \
		curl \
		gnupg2 \
		locales \
		tzdata \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# generate locale and enable multiverse repository
RUN \
	set -ex \
	&& locale-gen en_US.UTF-8 \
	&& sed -i '/^#.*multiverse$/s/^# //g' /etc/apt/sources.list

# create user and folders
RUN \
	set -ex \
	&& useradd -u 911 -U -d /config -s /bin/false abc \
	&& usermod -G users abc \
	&& mkdir -p \
		/app \
		/config \
		/defaults

# add artifacts from fetch stage
COPY --from=fetch-stage /overlay-src/ /

# add local files
COPY root/ /

ENTRYPOINT ["/init"]
