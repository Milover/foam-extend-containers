# Makefile

FOAM_VERSION	:= 4.1
FOAM_REPO		:= https://git.code.sf.net/p/foam-extend/foam-extend-$(FOAM_VERSION)
S4F_REPO		:= https://bitbucket.org/philip_cardiff/solids4foam-release

FOAM_COMMIT		:= $(shell git ls-remote $(FOAM_REPO) | grep master | awk '{print $$1}')
S4F_COMMIT		:= $(shell git ls-remote $(S4F_REPO) | grep master | awk '{print $$1}')

foam-extend:
	docker build -t foam-extend:$(FOAM_VERSION) \
	--build-arg FOAM_VERSION=$(FOAM_VERSION) \
	--build-arg FOAM_COMMIT=$(FOAM_COMMIT) \
	--file "$@.Dockerfile" .

solids4foam:
	docker build -t solids4foam \
	--build-arg FOAM_VERSION=$(FOAM_VERSION) \
	--build-arg S4F_COMMIT=$(S4F_COMMIT) \
	--file "$@.Dockerfile" .

.PHONY: foam-extend solids4foam
