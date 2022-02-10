# syntax=docker/dockerfile:1

# TODO:
# - label foam-extend version and commit hash
# - label solids4foam commit hash
# - add a runtime supplyable volume

# --------------------------------------------------------------------------- #
# Build args

ARG FOAM_VERSION=4.1

# --------------------------------------------------------------------------- #
# Base image

FROM foam-extend:$FOAM_VERSION as build
ARG FOAM_DIR

# Grab runtime dependencies
USER root:root
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && apt-get -y install --no-install-recommends \
	apt-utils file wget ca-certificates libnss-wrapper \
	git-core build-essential binutils-dev bc \
 && rm -rf /var/lib/apt/lists/*

# Set user
USER app:app

# Grab solids4foam sources
RUN git clone --depth 1 --branch=master \
	https://bitbucket.org/philip_cardiff/solids4foam-release \
	"$FOAM_DIR/solids4foam"

# Move the work directory to the foam directory
WORKDIR "$FOAM_DIR/solids4foam"

# Build foam and solids4foam
RUN source "$FOAM_DIR/etc/bashrc" \
 && ./Allwmake \
 && cd .. \
 && wmake/wcleanAllButLibBinLnInclude || :

# Tag the build
RUN echo $(git rev-parse HEAD) > .build

# Remove unnecessary stuff
RUN rm -rf \
	".git"* \
	"Dockerfile" \
	"README"* \
	"bitbucket"* \
	"documentation" \
	"tutorials"

# --------------------------------------------------------------------------- #
# Runtime image

FROM foam-extend:$FOAM_VERSION as runtime
ARG FOAM_VERSION
ARG FOAM_DIR
ARG S4F_COMMIT="unknown"

# Copy over user libraries and executables
COPY --chown=app:app --from=build \
	"home/app/foam/app-$FOAM_VERSION" \
	"/home/app/foam/app-$FOAM_VERSION/"
COPY --chown=app:app --from=build \
	"$FOAM_DIR/solids4foam" \
	"$FOAM_DIR/solids4foam/"

# Set some labels
LABEL solids4foam-commit="$S4F_COMMIT"

# --------------------------------------------------------------------------- #
