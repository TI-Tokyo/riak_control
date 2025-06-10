all: build

WWW_DEST = build
YARN     = $(shell which yarn || which yarnpkg)

clean:
	rm -rf $(WWW_DEST)/*

deps:
	@$(YARN) add -D parcel elm webpack elm-webpack-loader \
	  html-webpack-plugin copy-webpack-plugin \
	  html-loader postcss webpack-merge \
	  @webcomponents/webcomponentsjs \
	  bootstrap \
	  @popperjs/core \
	  web-component \
	  babel-loader

build: deps
	@mkdir -p $(WWW_DEST)
	@$(YARN) run build

.PHONY: clean deps build
