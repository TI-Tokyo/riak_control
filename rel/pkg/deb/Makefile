export

DEBEMAIL = $(shell git config user.email)

default:
	cp -R ../deb/debian .

	dch  --create --package riak-control -v "$(PKG_VERSION)" \
             "Build from $(PKG_ID)";\
	debuild	-e REVISION=$(PKG_VERSION) \
		-e RELEASE=$(PKG_BUILD) \
		-i -uc -us -b

	mkdir -p $(BASE_DIR)/rel/pkg/packages
	mv ../*.deb $(BASE_DIR)/rel/pkg/packages
	cd $(BASE_DIR)/rel/pkg/packages && \
		for debfile in *.deb; do \
			sha256sum $${debfile} > $${debfile}.sha \
		; done
