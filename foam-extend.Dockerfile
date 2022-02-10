# syntax=docker/dockerfile:1

# TODO:
# - label foam-extend version and commit hash
# - label solids4foam commit hash
# - add a runtime supplyable volume

# --------------------------------------------------------------------------- #
# Build args

ARG FOAM_VERSION=4.1
ARG FOAM_DIR="/home/app/foam/foam-extend-$FOAM_VERSION"

# --------------------------------------------------------------------------- #
# Build image

FROM debian:bullseye-slim as build
ARG DEBIAN_FRONTEND=noninteractive
ARG FOAM_VERSION
ARG FOAM_DIR

# Grab dependencies first
RUN apt-get update && apt-get -y install --no-install-recommends \
	apt-utils file wget ca-certificates libnss-wrapper \
	git-core build-essential gfortran binutils-dev cmake zlib1g-dev \
	libncurses5-dev curl libxt-dev rpm mercurial graphviz \
	libfl-dev bison bc \
 && rm -rf /var/lib/apt/lists/*

# Shell and user setup
SHELL ["/bin/bash", "-c"]
RUN useradd -m -s '/bin/bash' app
USER app:app

# Grab foam sources
RUN git clone --depth 1 --branch=master \
	"https://git.code.sf.net/p/foam-extend/foam-extend-$FOAM_VERSION" \
	"$FOAM_DIR"

# Move the work directory to the foam directory
WORKDIR "$FOAM_DIR"

# Copy over build prefs
COPY --chown=app:app share/prefs.sh etc

# Build foam and solids4foam
RUN sed -i -e 's/rpmbuild --define/rpmbuild --define "_build_id_links none" --define/' \
			  ThirdParty/tools/makeThirdPartyFunctionsForRPM \
 && sed -i -e 's/^export WM_NCOMPPROCS=1$/#export WM_NCOMPPROCS=1/' \
		   -e 's/^( cd \$WM_THIRD_PARTY_DIR && \.\/AllMake\.post )$/#( cd $WM_THIRD_PARTY_DIR \&\& .\/AllMake.post )/' \
			   Allwmake.firstInstall \
 && source etc/bashrc \
 && ./Allwmake.firstInstall <<< "y" \
 && wmake/wcleanAllButLibBinLnInclude

# Remove unnecessary stuff
RUN rm -rf \
	".git"* \
	".hg"* \
	"All"* \
	"CTestConfig.cmake" \
	"Changelog"* \
	"ExtendProjectPreamble" \
	"Macros" \
	"README"* \
	"Release"* \
	"cmake" \
	"doc" \
	"extend-bazaar" \
	"testHarness" \
	"tutorials" \
	"vagrantSandbox" \
	"validationAndVerificationSuite" \
	"ThirdParty/.git"* \
	"ThirdParty/All"* \
	"ThirdParty/LocalDev" \
	"ThirdParty/PyFoamSiteScripts" \
	"ThirdParty/README"* \
	"ThirdParty/mingwBuild" \
	"ThirdParty/rpmBuild" \
	"ThirdParty/tools"

# --------------------------------------------------------------------------- #
# Runtime image

FROM debian:bullseye-slim as runtime
ARG FOAM_VERSION
ARG FOAM_DIR
ARG FOAM_COMMIT="unknown"

# Grab runtime dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && apt-get -y install --no-install-recommends \
	#g++ make ccache zlib1g-dev bison libfl-dev \
	zlib1g-dev bison libfl-dev \
 && rm -rf /var/lib/apt/lists/*

# User and shell setup
SHELL ["/bin/bash", "-c"]
RUN useradd -m -s '/bin/bash' app
USER app:app
WORKDIR "/home/app"

# Copy over user libraries and executables
COPY --chown=app:app --from=build "home/app/foam" "/home/app/foam/"

# Set environment vairables
ENV FOAM_DIR="$FOAM_DIR"

# Set some labels
LABEL foam-version="$FOAM_VERSION" \
	  foam-commit="$FOAM_COMMIT" \
	  author="milovic.ph@gmail.com"

# --------------------------------------------------------------------------- #
