REPO		 = riak_control

PKG_VERSION      = $(shell git describe --tags 2>/dev/null)
PKG_ID           = riak_control-$(PKG_VERSION)
BASE_DIR         = $(shell pwd)

REVISION = $(shell echo $(REPO_TAG) | sed -e 's/^$(REPO)-//')

all: compile

compile:
	@$(MAKE) -C app build

devcompile:
	@$(MAKE) -C app devbuild

clean:
	@$(MAKE) -C app clean

install:
	@rm -rf rel/out
	@mkdir -p rel/out/{bin,etc,www}
	@cp -a app/build/* rel/out/www
	@cp -a bin/riak-control bin/rctl*.py \
	   rel/out/bin
	@cp -a rel/files/rctl.conf rel/files/script-templates rel/files/script-templates.d \
	   rel/out/etc
	@echo "Release generated in rel/out"


rel: compile install

devrel: devcompile install

package:
	@echo "Assuming `make rel` has been run."
	@rm -rf rel/pkg/out
	@cp -a rel/out rel/pkg
	@cp -a doc rel/pkg/out
	@$(MAKE) -C rel/pkg


.PHONY: all compile clean package

export PKG_VERSION PKG_ID BASE_DIR
