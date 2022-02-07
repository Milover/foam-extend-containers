# syntax=docker/dockerfile:1

# TODO:
# - label foam-extend version and commit hash
# - label solids4foam commit hash
# - add a runtime supplyable volume

# REWORK:
# 1.) grab all base dependencies (img: 1)
# 2.) build foam and s4f (from 1 -> img: 2)
# 3.) grab (only) runtime dependencies and do user setup (img: 3)
# 4.) use 3 as base, and copy over binaries/sources from 2 (from 3,2 -> img: 4)

# --------------------------------------------------------------------------- #

# Set the base image
FROM debian:bullseye-slim as base

# Set some variables
ARG DEBIAN_FRONTEND=noninteractive

# Add contrib and non-free repos
RUN echo "deb http://deb.debian.org/debian bullseye main contrib non-free" > /etc/apt/sources.list \
 && echo "deb http://deb.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list \
 && echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list

# Grab basic dependencies first
RUN apt-get update && apt-get -y install --no-install-recommends \
	#apt-utils passwd sudo bash wget
	apt-utils wget ca-certificates libnss-wrapper

# Grab foam dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
	git-core build-essential binutils-dev cmake flex zlib1g-dev \
	#libncurses5-dev curl bison libxt-dev rpm mercurial graphviz \
	curl bison vim \
	&& rm -rf /var/lib/apt/lists/*

# Grab foam third-party stuff
RUN apt-get update && apt-get -y install --no-install-recommends \
	libscotch-dev libparmetis-dev libtrilinos-zoltan-dev libhwloc-dev \
	&& rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------- #

# Set the runtime base image
FROM base as runtime

# Set some variables
ARG FOAM_VERSION=4.1

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Add and change user
RUN useradd -m -s '/bin/bash' app
USER app:app

# Grab foam sources
RUN git clone --depth 1 --branch=master \
	"https://git.code.sf.net/p/foam-extend/foam-extend-$FOAM_VERSION" \
	"/home/app/foam/foam-extend-$FOAM_VERSION"

# Move the work directory to the foam directory
WORKDIR "/home/app/foam/foam-extend-$FOAM_VERSION"

# Copy over build prefs
COPY --chown=app:app prefs.sh etc

# Build foam
RUN sed -i -e 's/^export WM_NCOMPPROCS=1$/#export WM_NCOMPPROCS=1/' \
		   -e 's/^( cd \$WM_THIRD_PARTY_DIR && \.\/AllMake\.pre )$/#( cd $WM_THIRD_PARTY_DIR \&\& .\/AllMake.pre )/' \
		   -e 's/^( cd \$WM_THIRD_PARTY_DIR && \.\/AllMake\.post )$/#( cd $WM_THIRD_PARTY_DIR \&\& .\/AllMake.post )/' \
			   Allwmake.firstInstall \
	&& source etc/bashrc \
	&& ./Allwmake.firstInstall <<< y

# Grab and build solids4foam
RUN git clone --depth 1 --branch=master \
	https://bitbucket.org/philip_cardiff/solids4foam-release \
	&& cd solids4foam-release \
	&& ./Allwmake

# --------------------------------------------------------------------------- #
