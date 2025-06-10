REPO		 = riak_control

PKG_VERSION      = $(shell git describe --tags 2>/dev/null)
PKG_ID           = riak_control-$(PKG_VERSION)
BASE_DIR         = $(shell pwd)

REVISION = $(shell echo $(REPO_TAG) | sed -e 's/^$(REPO)-//')

all: compile

compile:
	@$(MAKE) -C app build

clean:
	@$(MAKE) -C app clean

rel: compile
	@rm -rf rel/out || :
	@mkdir -p rel/out/www rel/out/bin
	@cp -a app/build/* rel/out/www
	@cp -a bin/riak-control rel/out/bin
	@echo "Release generated in rel/out"

package:
	@echo "Assuming `make rel` has been run."
	@rm -rf rel/pkg/out
	@cp -a rel/out rel/pkg
	@cp -a doc rel/pkg/out
	@$(MAKE) -C rel/pkg


.PHONY: all compile clean package

export PKG_VERSION PKG_ID BASE_DIR
