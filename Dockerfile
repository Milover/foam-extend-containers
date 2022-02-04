# syntax=docker/dockerfile:1

# TODO:
# - label foam-extend version and commit hash
# - label solids4foam commit hash
# - add a runtime supplyable volume

# Set the base image
FROM debian:bullseye-slim

# Set some variables
ARG FOAM_VERSION=4.1

# Set default shell to bash
SHELL ["/usr/bin/bash", "-c"]

# Grab dependencies
RUN apt-get update && apt-get -y install \
	sudo wget git-core build-essential binutils-dev cmake flex zlib1g-dev \
	libncurses5-dev curl bison libxt-dev rpm mercurial graphviz

# Change user
USER app

# Set the work directory
WORKDIR /home/app

# Grab sources and prep for build
RUN git clone https://git.code.sf.net/p/foam-extend/foam-extend-${FOAM_VERSION} \
	cd /home/app/foam-extend-${FOAM_VERSION} \
	sed -i -e 's/rpmbuild --define/rpmbuild --define "_build_id_links none" --define/' \
			  ThirdParty/tools/makeThirdPartyFunctionsForRPM \
	sed -i -e 's/^export WM_NCOMPPROCS=1$/#export WM_NCOMPPROCS=1/' \
		   -e 's/^( cd \$WM_THIRD_PARTY_DIR && \.\/AllMake\.post )$/#( cd $WM_THIRD_PARTY_DIR \&\& .\/AllMake.post )/' \
			  Allwmake.firstInstall \
	sed -i -e 's/^export WM_THIRD_PARTY_USE_OPENMPI_188=1/#export WM_THIRD_PARTY_USE_OPENMPI_188=1/' \
		   -e 's/^#export WM_THIRD_PARTY_USE_OPENMPI_400=1/export WM_THIRD_PARTY_USE_OPENMPI_400=1/' \
		   -e 's/^export WM_THIRD_PARTY_USE_PYFOAM_069=1/export WM_THIRD_PARTY_USE_PYFOAM_069=0/' \
			  etc/bashrc

# Build foam-extend
RUN source etc/bashrc && Allwmake.firstInstall <<< y

# Grab and build solids4foam
RUN git clone https://bitbucket.org/philip_cardiff/solids4foam-release && \
	cd solids4foam-release && ./Allwmake
