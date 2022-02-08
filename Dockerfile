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
ARG FOAM_DIR="/home/app/foam/foam-extend-$FOAM_VERSION"

# --------------------------------------------------------------------------- #
# Build-base image

FROM debian:bullseye-slim as build-base
ARG DEBIAN_FRONTEND=noninteractive

# Grab basic dependencies first
RUN apt-get update && apt-get -y install --no-install-recommends \
	apt-utils file wget ca-certificates libnss-wrapper

# Grab foam dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
	git-core build-essential gfortran binutils-dev cmake zlib1g-dev \
	libncurses5-dev curl libxt-dev rpm mercurial graphviz \
	libfl-dev bison bc \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------- #
# Build image

FROM build-base as build
ARG FOAM_VERSION
ARG FOAM_DIR

# Shell and user setup
SHELL ["/bin/bash", "-c"]
RUN useradd -m -s '/bin/bash' app
USER app:app

# Grab foam and solids4foam sources
RUN git clone --depth 1 --branch=master \
	"https://git.code.sf.net/p/foam-extend/foam-extend-$FOAM_VERSION" \
	"$FOAM_DIR" \
 && git clone --depth 1 --branch=master \
	https://bitbucket.org/philip_cardiff/solids4foam-release \
	"$FOAM_DIR/solids4foam"

# Move the work directory to the foam directory
WORKDIR "$FOAM_DIR"

# Copy over build prefs
COPY --chown=app:app prefs.sh etc

# Build foam and solids4foam
RUN sed -i -e 's/rpmbuild --define/rpmbuild --define "_build_id_links none" --define/' \
			  ThirdParty/tools/makeThirdPartyFunctionsForRPM \
 && sed -i -e 's/^export WM_NCOMPPROCS=1$/#export WM_NCOMPPROCS=1/' \
		   -e 's/^( cd \$WM_THIRD_PARTY_DIR && \.\/AllMake\.post )$/#( cd $WM_THIRD_PARTY_DIR \&\& .\/AllMake.post )/' \
			   Allwmake.firstInstall \
 && source etc/bashrc \
 && ./Allwmake.firstInstall <<< "y" \
 && source etc/bashrc \
 && cd solids4foam \
 && ./Allwmake \
 && cd .. \
 && wmake/wcleanAllButLibBinLnInclude

# --------------------------------------------------------------------------- #
# Runtime-base image

FROM debian:bullseye-slim as runtime-base
ARG DEBIAN_FRONTEND=noninteractive

# Grab runtime dependencies and dev tools
RUN apt-get update && apt-get -y install --no-install-recommends \
	g++ make ccache zlib1g-dev bison libfl-dev \
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
ARG FOAM_DIR

# Copy over binaries and sources
COPY --chown=app:app --from=build "$FOAM_DIR" "$FOAM_DIR"

# Copy over user libraries and executables
COPY --chown=app:app --from=build "home/app/foam" "/home/app/foam/"

# Remove unnecessary stuff
RUN rm -rf \
	"$FOAM_DIR/.git"* \
	"$FOAM_DIR/.hg"* \
	"$FOAM_DIR/All"* \
	"$FOAM_DIR/CTestConfig.cmake" \
	"$FOAM_DIR/Changelog"* \
	"$FOAM_DIR/ExtendProjectPreamble" \
	"$FOAM_DIR/Macros" \
	"$FOAM_DIR/README"* \
	"$FOAM_DIR/Release"* \
	"$FOAM_DIR/cmake" \
	"$FOAM_DIR/doc" \
	"$FOAM_DIR/extend-bazaar" \
	"$FOAM_DIR/testHarness" \
	"$FOAM_DIR/tutorials" \
	"$FOAM_DIR/vagrantSandbox" \
	"$FOAM_DIR/validationAndVerificationSuite" \
	"$FOAM_DIR/ThirdParty/.git"* \
	"$FOAM_DIR/ThirdParty/All"* \
	"$FOAM_DIR/ThirdParty/LocalDev" \
	"$FOAM_DIR/ThirdParty/PyFoamSiteScripts" \
	"$FOAM_DIR/ThirdParty/README"* \
	"$FOAM_DIR/ThirdParty/mingwBuild" \
	"$FOAM_DIR/ThirdParty/rpmBuild" \
	"$FOAM_DIR/ThirdParty/tools" \
	"$FOAM_DIR/solids4foam/.git"* \
	"$FOAM_DIR/solids4foam/Dockerfile" \
	"$FOAM_DIR/solids4foam/README"* \
	"$FOAM_DIR/solids4foam/bitbucket"* \
	"$FOAM_DIR/solids4foam/documentation" \
	"$FOAM_DIR/solids4foam/filesToReplaceInOF" \
	"$FOAM_DIR/solids4foam/tutorials"

# --------------------------------------------------------------------------- #
