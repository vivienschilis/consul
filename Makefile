DEPS = $(shell go list -f '{{range .TestImports}}{{.}} {{end}}' ./...)
PACKAGES = $(shell go list ./...)
VERSION = 0.4.0
PREFIX = "/usr/local"

all: deps format
	@mkdir -p bin/
	@bash --norc -i ./scripts/build.sh

cov:
	gocov test ./... | gocov-html > /tmp/coverage.html
	open /tmp/coverage.html

deps:
	@echo "--> Installing build dependencies"
	@go get -d -v ./...
	@echo $(DEPS) | xargs -n1 go get -d

test: deps
	go list ./... | xargs -n1 go test

integ:
	go list ./... | INTEG_TESTS=yes xargs -n1 go test

format: deps
	@echo "--> Running go fmt"
	@go fmt $(PACKAGES)

web:
	./scripts/website_run.sh

web-push:
	./scripts/website_push.sh

deb: deps
	@echo "--> Building a Debian package"
	@mkdir -p pkg
	@mkdir -p tmp/bin/ && cp bin/consul tmp/bin
	@cd ui && bundle install
	@cd ui && make dist
	@mkdir -p tmp/share/consul/ui && cp -r ui/dist/* tmp/share/consul/ui
	@fpm -C tmp/ -t deb -s dir -n consul -p pkg/ -v $(VERSION) --prefix $(PREFIX) --provides consul --url https://github.com/hashicorp/consul --force .
	@rm -r tmp/

.PHONY: all cov deps integ test web web-push
