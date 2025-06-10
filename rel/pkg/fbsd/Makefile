export

BUILDDIR        = $(shell pwd)
BUILD_STAGE_DIR = $(BUILDDIR)/$(PKG_ID)

PBIN_DIR         = $(BUILD_STAGE_DIR)/usr/local/bin
PMAN_DIR         = $(BUILD_STAGE_DIR)/usr/local/share/man
PWWW_DIR         = $(BUILD_STAGE_DIR)/usr/local/var/lib/rc_www

PKGNAME = $(PKG_VERSION)-$(OSNAME)-$(ARCH).tbz
PKG_SHORT_VERSION = $(PKG_VERSION)

build: packing_list_files
	@echo "Building package $(PKGNAME)"

	cd $(BUILD_STAGE_DIR) && \
	mkdir -p ../../packages && \
	pkg create -m . -r . -o ../../packages

	cd ../packages && \
	    for f in *.pkg; do shasum -a 256 $${f} > $${f}.sha; done

packing_list_files: $(BUILD_STAGE_DIR)
	cp ../fbsd/+MANIFEST ${BUILD_STAGE_DIR}
	cd $(BUILD_STAGE_DIR) && \
	        echo "version: \"${PKG_SHORT_VERSION}\"" >> +MANIFEST && \
	        echo "files: {" >> +MANIFEST

	@echo "Copying Man pages to staging directory"
	cd $(BUILDDIR) && \
	if [ -d doc/man/man1 ]; then \
		mkdir -p $(PMAN_DIR) && \
		cp -R doc/man/man1 $(PMAN_DIR); fi

	@echo "Packaging /usr/local files"
	cd $(BUILD_STAGE_DIR) && \
	find usr/local -type f | while read file ; do \
	    mode=$$(stat -f%p "$$file" | cut -c 3-) && \
	    sum=$$(sha256 -q $$file) && \
			echo "  \"/$$file\": { sum: \"$$sum\", perm: \"$$mode\", uname: \"root\", gname: \"wheel\" }," >> +MANIFEST; \
	done && \
	sed -i -e '$$s/,$$//' +MANIFEST && \
	echo " }" >> +MANIFEST && \
	echo "directories: {" >> +MANIFEST && \
	echo "  /usr/local/bin: \"y\"," >> +MANIFEST && \
	echo "  /usr/local/var/lib/rc_www: \"y\"," >> +MANIFEST && \
	echo "  /usr/local/share/man/man1: \"y\"," >> +MANIFEST && \
	echo "}" >> +MANIFEST
	cat $(BUILD_STAGE_DIR)/+MANIFEST

# Copy the app rel directory to the staging directory to build our
# package structure and move the directories into the right place
# for the package
$(BUILD_STAGE_DIR): buildrel
	@echo "Copying rel directory to staging directory"
	mkdir -p $@
	mkdir -p $(PBIN_DIR) $(PWWW_DIR) $(PMAN_DIR)
	cp -R bin/riak-control $(PBIN_DIR);
	cp -R www/* $(PWWW_DIR)

# nothing to build. `build rel` has been run on that MBP I got from Basho in 2016.
buildrel:
	sed -i -e 's/.set_me_from_distro_packaging/\/usr\/local\/var\/lib\/rc_www/' bin/riak-control
	sed -i -e 's/python3/python/' bin/riak-control

$(BUILDDIR):
	mkdir -p $@

$(PKGERDIR)/pkgclean:
	rm -rf $(BUILD_STAGE_DIR) $(BUILDDIR)
