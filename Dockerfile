ARG UBUNTU_VER="xenial"
FROM ubuntu:${UBUNTU_VER} as fetch-stage

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
		jq \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# fetch overlay
RUN \
	set -ex \
	&& mkdir -p \
		/overlay-src \
	&& OVERLAY_RELEASE=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" \
		| jq -r .tag_name) \
	&& curl -o \
	/tmp/overlay.tar.gz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_RELEASE}/s6-overlay-amd64.tar.gz" \
	&& tar xf \
	/tmp/overlay.tar.gz -C \
	/overlay-src --strip-components=1

FROM ubuntu:${UBUNTU_VER}

# environment variables
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/root" \
LANGUAGE="en_US.UTF-8" \
LANG="en_US.UTF-8" \
TERM="xterm"

# install runtime packages
RUN \
	set -ex \
	&& apt-get update \
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

# generate locale and enable multiverse repositories
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
