# Makefile

FOAM_VERSION	:= 4.1
FOAM_REPO		:= https://git.code.sf.net/p/foam-extend/foam-extend/foam-extend-$(FOAM_VERSION)
S4F_REPO		:= https://bitbucket.org/philip_cardiff/solids4foam-release

FOAM_COMMIT		:= $(shell git ls-remote $(FOAM_REPO) | grep master | awk '{print $1}')
S4F_COMMIT		:= $(shell git ls-remote $(SOLIDS4FOAM_REPO) | grep master | awk '{print $1}')

foam-extend: foam-extend.Dockerfile
	docker build -t foam-extend:$(FOAM_VERSION) \
	--build-arg FOAM_VERSION=$(FOAM_VERSION) FOAM_COMMIT=$(FOAM_COMMIT) \
	--file foam-extend.Dockerfile .

solids4foam: solids4foam.Dockerfile
	docker build -t solids4foam \
	--build-arg FOAM_VERSION=$(FOAM_VERSION) S4F_COMMIT=$(S4F_COMMIT) \
	--file solids4foam.Dockerfile .

.PHONY:
foam-extend solids4foam
