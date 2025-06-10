PWD = $(shell pwd)

# No hyphens are allowed in the _version field in RPM
PKG_VERSION_NO_H ?= $(shell echo $(PKG_VERSION) | tr - .)

default:
	tar czf $(PKG_ID).tar.gz bin www doc && rm -rf bin www
	rpmbuild --define "_rpmfilename %%{NAME}-%%{VERSION}$(DISTRO).%%{ARCH}.rpm" \
		--define '_topdir $(BASE_DIR)/rel/pkg/out/' \
		--define '_sourcedir $(BASE_DIR)/rel/pkg/out/' \
		--define '_specdir $(BASE_DIR)/rel/pkg/out/' \
		--define '_rpmdir $(BASE_DIR)/rel/pkg/packages' \
		--define '_srcrpmdir $(BASE_DIR)/rel/pkg/packages' \
		--define "_revision $(PKG_VERSION)" \
		--define "_version $(PKG_VERSION_NO_H)" \
		--define "_tarname $(PKG_ID).tar.gz" \
		--define "_tarname_base $(PKG_ID)" \
		-bb $(BASE_DIR)/rel/pkg/rpm/specfile
	cd $(BASE_DIR)/rel/pkg/packages && \
		for rpmfile in *.rpm; do \
			sha256sum $${rpmfile} > $${rpmfile}.sha \
		; done
