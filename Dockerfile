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
# Build args

ARG FOAM_VERSION=4.1

# --------------------------------------------------------------------------- #
# Build-base image

FROM debian:bullseye-slim as build-base
ARG DEBIAN_FRONTEND=noninteractive

# Grab basic dependencies first
RUN apt-get update && apt-get -y install --no-install-recommends \
	apt-utils wget ca-certificates libnss-wrapper

# Grab foam dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
	git-core build-essential binutils-dev cmake zlib1g-dev \
	libncurses5-dev curl libxt-dev rpm mercurial graphviz \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------- #
# Build image

FROM build-base as build
ARG FOAM_VERSION

# Shell and user setup
SHELL ["/bin/bash", "-c"]
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
RUN sed -i -e 's/rpmbuild --define/rpmbuild --define "_build_id_links none" --define/' \
			  ThirdParty/tools/makeThirdPartyFunctionsForRPM \
 && sed -i -e 's/^export WM_NCOMPPROCS=1$/#export WM_NCOMPPROCS=1/' \
		   -e 's/^( cd \$WM_THIRD_PARTY_DIR && \.\/AllMake\.post )$/#( cd $WM_THIRD_PARTY_DIR \&\& .\/AllMake.post )/' \
			   Allwmake.firstInstall \
 && source etc/bashrc \
 && ./Allwmake.firstInstall <<< y

# Grab and build solids4foam
RUN git clone --depth 1 --branch=master https://bitbucket.org/philip_cardiff/solids4foam-release \
 && cd solids4foam-release \
 && ./Allwmake

# Clean build files
RUN cd ../ && wmake/wcleanAllButLibBinLnInclude

# --------------------------------------------------------------------------- #
# Runtime-base image

FROM debian:bullseye-slim as runtime-base
ARG DEBIAN_FRONTEND=noninteractive

# Grab runtime dependencies and dev tools
RUN apt-get update && apt-get -y install --no-install-recommends \
	g++ make ccache flex zlib1g-dev bison \
 && rm -rf /var/lib/apt/lists/*

# Shell and user setup
SHELL ["/bin/bash", "-c"]
RUN useradd -m -s '/bin/bash' app
USER app:app
WORKDIR "/home/app"

# --------------------------------------------------------------------------- #
# Runtime image

FROM runtime-base as runtime
ARG FOAM_VERSION

# Copy over binaries and sources
COPY --chown=app:app --from=build \
	applications bin etc lib src wmake .build ThirdParty/packages \
	"/home/app/foam/foam-extend-$FOAM_VERSION/"

# Copy over solids4foam stuff

# --------------------------------------------------------------------------- #
