#
# Makefile to build NEUTRINO
#
$(TARGETPREFIX)/var/etc/.version:
	echo "imagename=Neutrino" > $@
	echo "homepage=http://gitorious.org/open-duckbox-project-sh4" >> $@
	echo "creator=`id -un`" >> $@
	echo "docs=http://gitorious.org/open-duckbox-project-sh4/pages/Home" >> $@
	echo "forum=http://gitorious.org/open-duckbox-project-sh4" >> $@
	echo "version=0200`date +%Y%m%d%H%M`" >> $@
	echo "git=`git describe`" >> $@

NEUTRINO_DEPS  = $(D)/bootstrap $(D)/lirc $(D)/libcurl $(D)/libpng $(D)/libjpeg $(D)/libgif $(D)/libfreetype $(D)/openvpn
NEUTRINO_DEPS += $(D)/ffmpeg $(D)/libdvbsi++ $(D)/libsigc++ $(D)/libopenthreads $(D)/libusb $(D)/libalsa
NEUTRINO_DEPS += $(D)/lua $(D)/luaexpat $(D)/luacurl $(D)/luasocket $(D)/lua-feedparser $(D)/luasoap $(D)/luajson

ifeq ($(WLANDRIVER), wlandriver)
NEUTRINO_DEPS += $(D)/wpa_supplicant $(D)/wireless_tools
endif

NEUTRINO_DEPS2 = $(D)/libid3tag $(D)/libmad $(D)/libvorbisidec
N_CFLAGS       = -Wall -W -Wshadow
N_CFLAGS      += -g0 -pipe -Os -fno-strict-aliasing -DCPU_FREQ

N_CPPFLAGS     = -I$(DRIVER_DIR)/bpamem
N_CPPFLAGS    += -I$(TARGETPREFIX)/usr/include
N_CPPFLAGS    += -I$(KERNEL_DIR)/include
N_CPPFLAGS    += -D__STDC_CONSTANT_MACROS

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
N_CPPFLAGS += -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

N_CONFIG_OPTS  =
N_CONFIG_OPTS += --enable-freesatepg
N_CONFIG_OPTS += --enable-lua
N_CONFIG_OPTS += --enable-giflib
N_CONFIG_OPTS += --enable-ffmpegdec
#N_CONFIG_OPTS += --enable-pip

ifeq ($(EXTERNAL_LCD), externallcd)
N_CONFIG_OPTS += --enable-graphlcd
NEUTRINO_DEPS += $(D)/graphlcd
endif

OBJDIR = $(BUILD_TMP)
N_OBJDIR = $(OBJDIR)/neutrino-mp
LH_OBJDIR = $(OBJDIR)/libstb-hal

################################################################################
#
# libstb-hal-cst-next-max
#
NEUTRINO_MP_LIBSTB_CST_NEXT_MAX_PATCHES =

$(D)/libstb-hal-cst-next-max.do_prepare:
	rm -rf $(SOURCE_DIR)/libstb-hal-cst-next-max
	rm -rf $(SOURCE_DIR)/libstb-hal-cst-next-max.org
	rm -rf $(LH_OBJDIR)
	[ -d "$(ARCHIVE)/libstb-hal-cst-next-max.git" ] && \
	(cd $(ARCHIVE)/libstb-hal-cst-next-max.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/libstb-hal-cst-next-max.git" ] || \
	git clone git://github.com/MaxWiesel/libstb-hal-cst-next-max.git $(ARCHIVE)/libstb-hal-cst-next-max.git; \
	cp -ra $(ARCHIVE)/libstb-hal-cst-next-max.git $(SOURCE_DIR)/libstb-hal-cst-next-max;\
	cp -ra $(SOURCE_DIR)/libstb-hal-cst-next-max $(SOURCE_DIR)/libstb-hal-cst-next-max.org
	for i in $(NEUTRINO_MP_LIBSTB_CST_NEXT_MAX_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/libstb-hal-cst-next-max && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/libstb-hal-cst-next-max.config.status: | $(NEUTRINO_DEPS)
	rm -rf $(LH_OBJDIR); \
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR); \
	cd $(LH_OBJDIR); \
		$(SOURCE_DIR)/libstb-hal-cst-next-max/autogen.sh; \
		export PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config; \
		export PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig; \
		$(BUILDENV) \
		$(SOURCE_DIR)/libstb-hal-cst-next-max/configure --enable-silent-rules \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(BOXTYPE) \
			CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"

$(D)/libstb-hal-cst-next-max.do_compile: $(D)/libstb-hal-cst-next-max.config.status
	cd $(SOURCE_DIR)/libstb-hal-cst-next-max; \
		$(MAKE) -C $(LH_OBJDIR) all DESTDIR=$(TARGETPREFIX)
	touch $@

$(D)/libstb-hal-cst-next-max: $(D)/libstb-hal-cst-next-max.do_prepare $(D)/libstb-hal-cst-next-max.do_compile
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(TARGETPREFIX)
	touch $@

libstb-hal-cst-next-max-clean:
	rm -f $(D)/libstb-hal-cst-next-max
	cd $(LH_OBJDIR); \
		$(MAKE) -C $(LH_OBJDIR) distclean

libstb-hal-cst-next-max-distclean:
	rm -rf $(LH_OBJDIR)
	rm -f $(D)/libstb-hal-cst-next-max*

################################################################################
#
# neutrino-mp-cst-next-max
#
NEUTRINO_MP_CST_NEXT_MAX_PATCHES =

yaud-neutrino-mp-cst-next-max: yaud-none \
		$(D)/neutrino-mp-cst-next-max $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

yaud-neutrino-mp-cst-next-max-plugins: yaud-none \
		$(D)/neutrino-mp-cst-next-max $(D)/neutrino-mp-plugins $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

$(D)/neutrino-mp-cst-next-max.do_prepare: | $(NEUTRINO_DEPS) $(D)/libstb-hal-cst-next-max
	rm -rf $(SOURCE_DIR)/neutrino-mp-cst-next-max
	rm -rf $(SOURCE_DIR)/neutrino-mp-cst-next-max.org
	rm -rf $(N_OBJDIR)
	[ -d "$(ARCHIVE)/cst-public-gui-neutrino-max.git" ] && \
	(cd $(ARCHIVE)/cst-public-gui-neutrino-max.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/cst-public-gui-neutrino-max.git" ] || \
	git clone -b duckbox git://github.com/MaxWiesel/cst-public-gui-neutrino.git $(ARCHIVE)/cst-public-gui-neutrino-max.git; \
	cp -ra $(ARCHIVE)/cst-public-gui-neutrino-max.git $(SOURCE_DIR)/neutrino-mp-cst-next-max; \
	cp -ra $(SOURCE_DIR)/neutrino-mp-cst-next-max $(SOURCE_DIR)/neutrino-mp-cst-next-max.org
	for i in $(NEUTRINO_MP_CST_NEXT_MAX_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/neutrino-mp-cst-next-max && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/neutrino-mp-cst-next-max.config.status:
	rm -rf $(N_OBJDIR)
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR); \
	cd $(N_OBJDIR); \
		$(SOURCE_DIR)/neutrino-mp-cst-next-max/autogen.sh; \
		export PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config; \
		export PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig; \
		$(BUILDENV) \
		$(SOURCE_DIR)/neutrino-mp-cst-next-max/configure --enable-silent-rules \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--enable-upnp \
			--with-tremor \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-iconsdir=/usr/share/tuxbox/neutrino/icons \
			--with-localedir=/usr/share/tuxbox/neutrino/locale \
			--with-private_httpddir=/usr/share/tuxbox/neutrino/httpd \
			--with-themesdir=/usr/share/tuxbox/neutrino/themes \
			--with-stb-hal-includes=$(SOURCE_DIR)/libstb-hal-cst-next-max/include \
			--with-stb-hal-build=$(LH_OBJDIR) \
			CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"

$(SOURCE_DIR)/neutrino-mp-cst-next-max/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(SOURCE_DIR)/libstb-hal-cst-next-max ; then \
		pushd $(SOURCE_DIR)/libstb-hal-cst-next-max ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(SOURCE_DIR)/neutrino-mp-cst-next-max ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(CDK_DIR) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'_NMP-rev'$$NMP_REV'"' >> $@ ; \
	fi

$(D)/neutrino-mp-cst-next-max.do_compile: $(D)/neutrino-mp-cst-next-max.config.status $(SOURCE_DIR)/neutrino-mp-cst-next-max/src/gui/version.h
	cd $(SOURCE_DIR)/neutrino-mp-cst-next-max; \
		$(MAKE) -C $(N_OBJDIR) all DESTDIR=$(TARGETPREFIX)
	touch $@

$(D)/neutrino-mp-cst-next-max: $(D)/neutrino-mp-cst-next-max.do_prepare $(D)/neutrino-mp-cst-next-max.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGETPREFIX); \
	rm -f $(TARGETPREFIX)/var/etc/.version
	make $(TARGETPREFIX)/var/etc/.version
	touch $@

neutrino-mp-cst-next-max-clean:
	rm -f $(D)/neutrino-mp-cst-next-max
	rm -f $(SOURCE_DIR)/neutrino-mp-cst-next-max/src/gui/version.h
	cd $(N_OBJDIR); \
		$(MAKE) -C $(N_OBJDIR) distclean

neutrino-mp-cst-next-max-distclean:
	rm -rf $(N_OBJDIR)
	rm -f $(D)/neutrino-mp-cst-next-max*

################################################################################
#
# libstb-hal-cst-next
#
NEUTRINO_MP_LIBSTB_CST_NEXT_PATCHES =

$(D)/libstb-hal-cst-next.do_prepare:
	rm -rf $(SOURCE_DIR)/libstb-hal-cst-next
	rm -rf $(SOURCE_DIR)/libstb-hal-cst-next.org
	rm -rf $(LH_OBJDIR)
	[ -d "$(ARCHIVE)/libstb-hal-cst-next.git" ] && \
	(cd $(ARCHIVE)/libstb-hal-cst-next.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/libstb-hal-cst-next.git" ] || \
	git clone https://github.com/Duckbox-Developers/libstb-hal-cst-next.git $(ARCHIVE)/libstb-hal-cst-next.git; \
	cp -ra $(ARCHIVE)/libstb-hal-cst-next.git $(SOURCE_DIR)/libstb-hal-cst-next;\
	cp -ra $(SOURCE_DIR)/libstb-hal-cst-next $(SOURCE_DIR)/libstb-hal-cst-next.org
	for i in $(NEUTRINO_MP_LIBSTB_CST_NEXT_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/libstb-hal-cst-next && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/libstb-hal-cst-next.config.status: | $(NEUTRINO_DEPS)
	rm -rf $(LH_OBJDIR); \
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR); \
	cd $(LH_OBJDIR); \
		$(SOURCE_DIR)/libstb-hal-cst-next/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/libstb-hal-cst-next/configure --enable-silent-rules \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(BOXTYPE) \
			PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
			PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig \
			CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"

$(D)/libstb-hal-cst-next.do_compile: $(D)/libstb-hal-cst-next.config.status
	cd $(SOURCE_DIR)/libstb-hal-cst-next; \
		$(MAKE) -C $(LH_OBJDIR) all DESTDIR=$(TARGETPREFIX)
	touch $@

$(D)/libstb-hal-cst-next: $(D)/libstb-hal-cst-next.do_prepare $(D)/libstb-hal-cst-next.do_compile
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(TARGETPREFIX)
	touch $@

libstb-hal-cst-next-clean:
	rm -f $(D)/libstb-hal-cst-next
	cd $(LH_OBJDIR); \
		$(MAKE) -C $(LH_OBJDIR) distclean

libstb-hal-cst-next-distclean:
	rm -rf $(LH_OBJDIR)
	rm -f $(D)/libstb-hal-cst-next*

################################################################################
#
# neutrino-mp-cst-next
#
yaud-neutrino-mp-cst-next: yaud-none \
		neutrino-mp-cst-next $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

yaud-neutrino-mp-cst-next-plugins: yaud-none \
		$(D)/neutrino-mp-cst-next $(D)/neutrino-mp-plugins $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

NEUTRINO_MP_CST_NEXT_PATCHES =

$(D)/neutrino-mp-cst-next.do_prepare: | $(NEUTRINO_DEPS) $(D)/libstb-hal-cst-next
	rm -rf $(SOURCE_DIR)/neutrino-mp-cst-next
	rm -rf $(SOURCE_DIR)/neutrino-mp-cst-next.org
	rm -rf $(N_OBJDIR)
	[ -d "$(ARCHIVE)/neutrino-mp-cst-next.git" ] && \
	(cd $(ARCHIVE)/neutrino-mp-cst-next.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/neutrino-mp-cst-next.git" ] || \
	git clone https://github.com/Duckbox-Developers/neutrino-mp-cst-next.git $(ARCHIVE)/neutrino-mp-cst-next.git; \
	cp -ra $(ARCHIVE)/neutrino-mp-cst-next.git $(SOURCE_DIR)/neutrino-mp-cst-next; \
	cp -ra $(SOURCE_DIR)/neutrino-mp-cst-next $(SOURCE_DIR)/neutrino-mp-cst-next.org
	for i in $(NEUTRINO_MP_CST_NEXT_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/neutrino-mp-cst-next && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/neutrino-mp-cst-next.config.status:
	rm -rf $(N_OBJDIR)
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR); \
	cd $(N_OBJDIR); \
		$(SOURCE_DIR)/neutrino-mp-cst-next/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/neutrino-mp-cst-next/configure --enable-silent-rules \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--enable-upnp \
			--enable-ffmpegdec \
			--enable-giflib \
			--with-tremor \
			--enable-lua \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-iconsdir=/usr/share/tuxbox/neutrino/icons \
			--with-localedir=/usr/share/tuxbox/neutrino/locale \
			--with-private_httpddir=/usr/share/tuxbox/neutrino/httpd \
			--with-themesdir=/usr/share/tuxbox/neutrino/themes \
			--with-stb-hal-includes=$(SOURCE_DIR)/libstb-hal-cst-next/include \
			--with-stb-hal-build=$(LH_OBJDIR) \
			PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
			PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig \
			CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"

$(SOURCE_DIR)/neutrino-mp-cst-next/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(SOURCE_DIR)/libstb-hal-cst-next ; then \
		pushd $(SOURCE_DIR)/libstb-hal-cst-next ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(SOURCE_DIR)/neutrino-mp-cst-next ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(CDK_DIR) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'_NMP-rev'$$NMP_REV'"' >> $@ ; \
	fi

$(D)/neutrino-mp-cst-next.do_compile: $(D)/neutrino-mp-cst-next.config.status $(SOURCE_DIR)/neutrino-mp-cst-next/src/gui/version.h
	cd $(SOURCE_DIR)/neutrino-mp-cst-next; \
		$(MAKE) -C $(N_OBJDIR) all
	touch $@

$(D)/neutrino-mp-cst-next: $(D)/neutrino-mp-cst-next.do_prepare $(D)/neutrino-mp-cst-next.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGETPREFIX); \
	rm -f $(TARGETPREFIX)/var/etc/.version
	make $(TARGETPREFIX)/var/etc/.version
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/neutrino
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/pzapit
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/sectionsdcontrol
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/sbin/udpstreampes
	touch $@

neutrino-mp-cst-next-clean:
	rm -f $(D)/neutrino-mp-cst-next
	rm -f $(SOURCE_DIR)/neutrino-mp-cst-next/src/gui/version.h
	cd $(N_OBJDIR); \
		$(MAKE) -C $(N_OBJDIR) distclean

neutrino-mp-cst-next-distclean:
	rm -rf $(N_OBJDIR)
	rm -f $(D)/neutrino-mp-cst-next*

################################################################################
#
# yaud-neutrino-mp-next
#
yaud-neutrino-mp-next: yaud-none \
		$(D)/neutrino-mp-next $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

yaud-neutrino-mp-next-plugins: yaud-none \
		$(D)/neutrino-mp-next $(D)/neutrino-mp-plugins $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

yaud-neutrino-mp-next-all: yaud-none \
		$(D)/neutrino-mp-next $(D)/neutrino-mp-plugins shairport $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

#
# libstb-hal-next
#
NEUTRINO_MP_LIBSTB_NEXT_PATCHES =

$(D)/libstb-hal-next.do_prepare:
	rm -rf $(SOURCE_DIR)/libstb-hal-next
	rm -rf $(SOURCE_DIR)/libstb-hal-next.org
	rm -rf $(LH_OBJDIR)
	[ -d "$(ARCHIVE)/libstb-hal-next.git" ] && \
	(cd $(ARCHIVE)/libstb-hal-next.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/libstb-hal-next.git" ] || \
	git clone https://github.com/Duckbox-Developers/libstb-hal-next.git $(ARCHIVE)/libstb-hal-next.git; \
	cp -ra $(ARCHIVE)/libstb-hal-next.git $(SOURCE_DIR)/libstb-hal-next;\
	cp -ra $(SOURCE_DIR)/libstb-hal-next $(SOURCE_DIR)/libstb-hal-next.org
	for i in $(NEUTRINO_MP_LIBSTB_NEXT_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/libstb-hal-next && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/libstb-hal-next.config.status: bootstrap
	rm -rf $(LH_OBJDIR); \
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR); \
	cd $(LH_OBJDIR); \
		$(SOURCE_DIR)/libstb-hal-next/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/libstb-hal-next/configure --enable-silent-rules \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(BOXTYPE) \
			PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
			PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig \
			CPPFLAGS="$(N_CPPFLAGS)"

$(D)/libstb-hal-next.do_compile: $(D)/libstb-hal-next.config.status
	cd $(SOURCE_DIR)/libstb-hal-next; \
		$(MAKE) -C $(LH_OBJDIR)
	touch $@

$(D)/libstb-hal-next: $(D)/libstb-hal-next.do_prepare $(D)/libstb-hal-next.do_compile
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(TARGETPREFIX)
	touch $@

libstb-hal-next-clean:
	rm -f $(D)/libstb-hal-next
	cd $(LH_OBJDIR); \
		$(MAKE) -C $(LH_OBJDIR) distclean

libstb-hal-next-distclean:
	rm -rf $(LH_OBJDIR)
	rm -f $(D)/libstb-hal-next*

#
# neutrino-mp-next
#
NEUTRINO_MP_NEXT_PATCHES =

$(D)/neutrino-mp-next.do_prepare: | $(NEUTRINO_DEPS) $(D)/libstb-hal-next
	rm -rf $(SOURCE_DIR)/neutrino-mp-next
	rm -rf $(SOURCE_DIR)/neutrino-mp-next.org
	rm -rf $(N_OBJDIR)
	[ -d "$(ARCHIVE)/neutrino-mp-next.git" ] && \
	(cd $(ARCHIVE)/neutrino-mp-next.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/neutrino-mp-next.git" ] || \
	git clone https://github.com/Duckbox-Developers/neutrino-mp-next.git $(ARCHIVE)/neutrino-mp-next.git; \
	cp -ra $(ARCHIVE)/neutrino-mp-next.git $(SOURCE_DIR)/neutrino-mp-next; \
	cp -ra $(SOURCE_DIR)/neutrino-mp-next $(SOURCE_DIR)/neutrino-mp-next.org
	for i in $(NEUTRINO_MP_NEXT_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/neutrino-mp-next && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/neutrino-mp-next.config.status:
	rm -rf $(N_OBJDIR)
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR); \
	cd $(N_OBJDIR); \
		$(SOURCE_DIR)/neutrino-mp-next/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/neutrino-mp-next/configure --enable-silent-rules \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--with-tremor \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-stb-hal-includes=$(SOURCE_DIR)/libstb-hal-next/include \
			--with-stb-hal-build=$(LH_OBJDIR) \
			PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
			PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig \
			CPPFLAGS="$(N_CPPFLAGS)"

$(SOURCE_DIR)/neutrino-mp-next/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(SOURCE_DIR)/libstb-hal-next ; then \
		pushd $(SOURCE_DIR)/libstb-hal-next ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(SOURCE_DIR)/neutrino-mp-next ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(CDK_DIR) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'-next_NMP-rev'$$NMP_REV'-next"' >> $@ ; \
	fi


$(D)/neutrino-mp-next.do_compile: $(D)/neutrino-mp-next.config.status $(SOURCE_DIR)/neutrino-mp-next/src/gui/version.h
	cd $(SOURCE_DIR)/neutrino-mp-next; \
		$(MAKE) -C $(N_OBJDIR) all
	touch $@

$(D)/neutrino-mp-next: $(D)/neutrino-mp-next.do_prepare $(D)/neutrino-mp-next.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGETPREFIX); \
	rm -f $(TARGETPREFIX)/var/etc/.version
	make $(TARGETPREFIX)/var/etc/.version
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/neutrino
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/pzapit
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/sectionsdcontrol
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/sbin/udpstreampes
	touch $@

neutrino-mp-next-clean:
	rm -f $(D)/neutrino-mp-next
	rm -f $(SOURCE_DIR)/neutrino-mp-next/src/gui/version.h
	cd $(N_OBJDIR); \
		$(MAKE) -C $(N_OBJDIR) distclean

neutrino-mp-next-distclean:
	rm -rf $(N_OBJDIR)
	rm -f $(D)/neutrino-mp-next*

################################################################################
neutrino-cdkroot-clean:
	[ -e $(TARGETPREFIX)/usr/local/bin ] && cd $(TARGETPREFIX)/usr/local/bin && find -name '*' -delete || true
	[ -e $(TARGETPREFIX)/usr/local/share/iso-codes ] && cd $(TARGETPREFIX)/usr/local/share/iso-codes && find -name '*' -delete || true
	[ -e $(TARGETPREFIX)/usr/share/tuxbox/neutrino ] && cd $(TARGETPREFIX)/usr/share/tuxbox/neutrino && find -name '*' -delete || true
	[ -e $(TARGETPREFIX)/usr/share/fonts ] && cd $(TARGETPREFIX)/usr/share/fonts && find -name '*' -delete || true
################################################################################
#
# yaud-neutrino-hd2
#
yaud-neutrino-hd2: yaud-none \
		$(D)/neutrino-hd2 $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

yaud-neutrino-hd2-plugins: yaud-none \
		$(D)/neutrino-hd2 $(D)/neutrino-hd2-plugins $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

ifeq ($(BOXTYPE), spark)
NHD2_OPTS = --enable-4digits
else ifeq ($(BOXTYPE), spark7162)
NHD2_OPTS =
else
NHD2_OPTS = --enable-ci
endif

#
# neutrino-hd2
#
NEUTRINO_HD2_PATCHES =

$(D)/neutrino-hd2.do_prepare: | $(NEUTRINO_DEPS) $(NEUTRINO_DEPS2) $(D)/libflac
	rm -rf $(SOURCE_DIR)/nhd2-exp
	[ -d "$(ARCHIVE)/neutrino-hd2.git" ] && \
	(cd $(ARCHIVE)/neutrino-hd2.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/neutrino-hd2.git" ] || \
	git clone -b nhd2-exp https://github.com/mohousch/neutrinohd2.git $(ARCHIVE)/neutrino-hd2.git; \
	cp -ra $(ARCHIVE)/neutrino-hd2.git $(SOURCE_DIR)/nhd2-exp
	for i in $(NEUTRINO_HD2_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/nhd2-exp && patch -p1 -i $$i; \
	done;
	touch $@

$(SOURCE_DIR)/nhd2-exp/config.status:
	cd $(SOURCE_DIR)/nhd2-exp; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(N_CONFIG_OPTS) \
			--with-boxtype=$(BOXTYPE) \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-isocodesdir=/usr/share/iso-codes \
			$(NHD2_OPTS) \
			--enable-scart \
			PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
			PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig \
			CPPFLAGS="$(N_CPPFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)"
	touch $@

$(D)/neutrino-hd2: $(D)/neutrino-hd2.do_prepare $(D)/neutrino-hd2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/nhd2-exp install DESTDIR=$(TARGETPREFIX); \
	rm -f $(TARGETPREFIX)/var/etc/.version
	make $(TARGETPREFIX)/var/etc/.version
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/neutrino
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/pzapit
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/sectionsdcontrol
	touch $@

$(D)/neutrino-hd2.do_compile: $(SOURCE_DIR)/nhd2-exp/config.status
	cd $(SOURCE_DIR)/nhd2-exp; \
		$(MAKE) all
	touch $@

neutrino-hd2-clean: neutrino-cdkroot-clean
	rm -f $(D)/neutrino-hd2
	cd $(SOURCE_DIR)/nhd2-exp; \
		$(MAKE) clean

neutrino-hd2-distclean: neutrino-cdkroot-clean
	rm -f $(D)/neutrino-hd2
	rm -f $(D)/neutrino-hd2.do_compile
	rm -f $(D)/neutrino-hd2.do_prepare
	rm -f $(D)/neutrino-hd2-plugins*

################################################################################
#
# yaud-neutrino-mp-tangos
#
yaud-neutrino-mp-tangos: yaud-none \
		$(D)/neutrino-mp-tangos $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

yaud-neutrino-mp-tangos-plugins: yaud-none \
		$(D)/neutrino-mp-tangos $(D)/neutrino-mp-plugins $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

yaud-neutrino-mp-tangos-all: yaud-none \
		$(D)/neutrino-mp-tangos $(D)/neutrino-mp-plugins shairport $(D)/release_neutrino
	$(TUXBOX_YAUD_CUSTOMIZE)

#
# neutrino-mp-tangos
#
NEUTRINO_MP_TANGOS_PATCHES =

$(D)/neutrino-mp-tangos.do_prepare: | $(NEUTRINO_DEPS) $(D)/libstb-hal-cst-next
	rm -rf $(SOURCE_DIR)/neutrino-mp-tangos
	rm -rf $(SOURCE_DIR)/neutrino-mp-tangos.org
	rm -rf $(N_OBJDIR)
	[ -d "$(ARCHIVE)/neutrino-mp-tangos.git" ] && \
	(cd $(ARCHIVE)/neutrino-mp-tangos.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/neutrino-mp-tangos.git" ] || \
	git clone https://github.com/TangoCash/neutrino-mp-cst-next.git $(ARCHIVE)/neutrino-mp-tangos.git; \
	cp -ra $(ARCHIVE)/neutrino-mp-tangos.git $(SOURCE_DIR)/neutrino-mp-tangos; \
	cp -ra $(SOURCE_DIR)/neutrino-mp-tangos $(SOURCE_DIR)/neutrino-mp-tangos.org
	for i in $(NEUTRINO_MP_TANGOS_PATCHES); do \
		echo "==> Applying Patch: $(subst $(PATCHES)/,'',$$i)"; \
		set -e; cd $(SOURCE_DIR)/neutrino-mp-tangos && patch -p1 -i $$i; \
	done;
	touch $@

$(D)/neutrino-mp-tangos.config.status:
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR); \
	cd $(N_OBJDIR); \
		$(SOURCE_DIR)/neutrino-mp-tangos/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/neutrino-mp-tangos/configure --enable-silent-rules \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(N_CONFIG_OPTS) \
			--disable-upnp \
			--with-boxtype=$(BOXTYPE) \
			--with-tremor \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			--with-configdir=/var/tuxbox/config \
			--with-gamesdir=/var/tuxbox/games \
			--with-plugindir=/var/tuxbox/plugins \
			--with-iconsdir=/usr/share/tuxbox/neutrino/icons \
			--with-localedir=/usr/share/tuxbox/neutrino/locale \
			--with-private_httpddir=/usr/share/tuxbox/neutrino/httpd \
			--with-themesdir=/usr/share/tuxbox/neutrino/themes \
			--with-stb-hal-includes=$(SOURCE_DIR)/libstb-hal-cst-next/include \
			--with-stb-hal-build=$(LH_OBJDIR) \
			PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
			PKG_CONFIG_PATH=$(TARGETPREFIX)/usr/lib/pkgconfig \
			CPPFLAGS="$(N_CPPFLAGS)"

$(SOURCE_DIR)/neutrino-mp-tangos/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(SOURCE_DIR)/libstb-hal-cst-next ; then \
		pushd $(SOURCE_DIR)/libstb-hal-cst-next ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(SOURCE_DIR)/neutrino-mp-tangos ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(CDK_DIR) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'-next_NMP-rev'$$NMP_REV'-tangos"' >> $@ ; \
	fi


$(D)/neutrino-mp-tangos.do_compile: $(D)/neutrino-mp-tangos.config.status $(SOURCE_DIR)/neutrino-mp-tangos/src/gui/version.h
	cd $(SOURCE_DIR)/neutrino-mp-tangos; \
		$(MAKE) -C $(N_OBJDIR) all
	touch $@

$(D)/neutrino-mp-tangos: $(D)/neutrino-mp-tangos.do_prepare $(D)/neutrino-mp-tangos.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGETPREFIX); \
	rm -f $(TARGETPREFIX)/var/etc/.version
	make $(TARGETPREFIX)/var/etc/.version
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/neutrino
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/pzapit
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/bin/sectionsdcontrol
	$(TARGET)-strip $(TARGETPREFIX)/usr/local/sbin/udpstreampes
	touch $@

neutrino-mp-tangos-clean:
	rm -f $(D)/neutrino-mp-tangos
	rm -f $(SOURCE_DIR)/neutrino-mp-tangos/src/gui/version.h
	cd $(N_OBJDIR); \
		$(MAKE) -C $(N_OBJDIR) distclean

neutrino-mp-tangos-distclean:
	rm -rf $(N_OBJDIR)
	rm -f $(D)/neutrino-mp-tangos*
