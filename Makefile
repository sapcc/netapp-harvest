GOFILES := $(wildcard *.go)

IMAGE=keppel.eu-de-1.cloud.sap/ccloud/netapp-harvester
BRANCH=$(shell  git branch | sed -n '/\* /s///p')
HASH := $(shell git rev-parse HEAD | head -c 7)

VERSION:=v$(shell date -u +%Y%m%d%M%S)-$(BRANCH)-$(HASH)

docker:
	docker build -t $(IMAGE):$(VERSION) .
	docker push $(IMAGE):$(VERSION)
