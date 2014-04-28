################################################################################
# Basics
################################################################################
MINIOS_ROOT	?= $(realpath ../mini-os)

ifndef MINIOS_ROOT
$(error "Please define MINIOS_ROOT")
endif

include config.mk

.PHONY: all
all: cross-newlib cross-lwip cross-pcre


################################################################################
# Xen basics
################################################################################
XEN_COMPILE_ARCH	?= $(shell uname -m | sed -e s/i.86/x86_32/ \
                         -e s/i86pc/x86_32/ -e s/amd64/x86_64/ \
                         -e s/armv7.*/arm32/ -e s/armv8.*/arm64/)

XEN_TARGET_ARCH		?= $(XEN_COMPILE_ARCH)


GNU_TARGET_ARCH:=$(XEN_TARGET_ARCH)
ifeq ($(XEN_TARGET_ARCH),x86_32)
GNU_TARGET_ARCH:=i686
endif

ifeq ($(findstring x86_,$(XEN_TARGET_ARCH)),x86_)
TARGET_ARCH_FAM = x86
else
TARGET_ARCH_FAM = $(XEN_TARGET_ARCH)
endif

ifeq ($(GNU_TARGET_ARCH), i686)
TARGET_CFLAGS=
NEWLIB_CFLAGS+=-D_I386MACH_ALLOW_HW_INTERRUPTS
STUBDOM_SUPPORTED=1
endif
ifeq ($(GNU_TARGET_ARCH), x86_64)
TARGET_CFLAGS=-mno-red-zone
NEWLIB_CFLAGS+=-D_I386MACH_ALLOW_HW_INTERRUPTS
STUBDOM_SUPPORTED=1
endif
ifeq ($(GNU_TARGET_ARCH), ia64)
TARGET_CFLAGS=-mconstant-gp
endif


################################################################################
# Build configuration
################################################################################
# Directory structure
PREFIX	 = $(realpath .)/$(XEN_TARGET_ARCH)-root
TARGET	 = $(XEN_TARGET_ARCH)-xen-elf


################################################################################
# Commands and functions
################################################################################
CC			?= gcc-4.7
CXX			?= g++-4.7
AR			?= ar
LD			?= ld
RANLIB		?= ranlib
READELF		?= readelf
STRIP		?= strip

FETCHER		?= wget -c -O


################################################################################
# mini-os
################################################################################
.PHONY: minios clean-minios
minios:
	$(MAKE) -C $(MINIOS_ROOT) links

clean-minios:
	$(MAKE) -C $(MINIOS_ROOT) clean


################################################################################
# Cross-newlib
################################################################################
NEWLIB_SRC		 = newlib-$(NEWLIB_VERSION)
NEWLIB_BUILD	 = newlib-$(XEN_TARGET_ARCH)

NEWLIB_CFLAGS	+= -D__MINIOS__
NEWLIB_CFLAGS	+= -DHAVE_LIBC
NEWLIB_CFLAGS	+= -DHAVE_LWIP
NEWLIB_CFLAGS	+= -isystem $(MINIOS_ROOT)/include/posix
NEWLIB_CFLAGS	+= -isystem $(MINIOS_ROOT)/include
NEWLIB_CFLAGS	+= -isystem $(MINIOS_ROOT)/include/arch
NEWLIB_CFLAGS	+= -isystem $(MINIOS_ROOT)/include/$(TARGET_ARCH_FAM)
NEWLIB_CFLAGS	+= -isystem $(MINIOS_ROOT)/include/$(TARGET_ARCH_FAM)/$(XEN_TARGET_ARCH)
NEWLIB_CFLAGS	+= -fno-stack-protector

download: $(NEWLIB_ARCHIVE)
$(NEWLIB_ARCHIVE):
	$(FETCHER) $@ $(NEWLIB_URL)

_newlib-src: $(NEWLIB_ARCHIVE)
	rm -rf $(NEWLIB_DIR) $(NEWLIB_SRC)
	tar xzf $<
	[ "$(NEWLIB_DIR)" != "$(NEWLIB_SRC)" ] && mv $(NEWLIB_DIR) $(NEWLIB_SRC) || true
	patch -d $(NEWLIB_SRC) -p0 < patches/newlib.patch
	patch -d $(NEWLIB_SRC) -p0 < patches/newlib-chk.patch
	patch -d $(NEWLIB_SRC) -p1 < patches/newlib-stdint-size_max-fix-from-1.17.0.patch
	find $(NEWLIB_SRC) -type f | xargs perl -i.bak \
		-pe 's/\b_(tzname|daylight|timezone)\b/$$1/g'
	touch $@

_newlib-build: _newlib-src | minios
	rm -rf $(NEWLIB_BUILD)
	mkdir -p $(NEWLIB_BUILD)
	@(	cd $(NEWLIB_BUILD) && \
		CC_FOR_TARGET="$(CC) $(NEWLIB_CFLAGS)" \
		CXX_FOR_TARGET=$(CXX)                  \
		AR_FOR_TARGET=$(AR)                    \
		LD_FOR_TARGET=$(LD)                    \
		RANLIB_FOR_TARGET=$(RANLIB)            \
		READELF_FOR_TARGET=$(READELF)          \
		STRIP_FOR_TARGET=$(STRIP)              \
		../$(NEWLIB_SRC)/configure             \
			--prefix=$(PREFIX)                 \
			--target=$(TARGET)                 \
			--verbose                          \
			--enable-newlib-io-long-long       \
			--enable-newlib-io-long-double     \
			--disable-multilib                 \
	)
	$(MAKE) DESTDIR= -C $(NEWLIB_BUILD)
	touch $@

_newlib-install: _newlib-build
	$(MAKE) DESTDIR= -C $(NEWLIB_BUILD) install
	touch $@

.PHONY: cross-newlib clean-newlib distclean-newlib
cross-newlib: _newlib-install

clean-newlib:
	rm -rf $(NEWLIB_SRC)
	rm -f  _newlib-src
	rm -rf $(NEWLIB_BUILD)
	rm -f  _newlib-build

distclean: distclean-newlib
distclean-newlib: clean-newlib
	rm -rf $(NEWLIB_ARCHIVE)
	rm -f  _newlib-install


################################################################################
# lwip
################################################################################
LWIP_SRC	 = lwip-$(LWIP_VERSION)

download: $(LWIP_ARCHIVE)
$(LWIP_ARCHIVE):
	$(FETCHER) $@ $(LWIP_URL)

_lwip-src: $(LWIP_ARCHIVE)
	rm -rf $(LWIP_DIR) $(LWIP_SRC)
	tar xzf $<
	[ "$(LWIP_DIR)" != "$(LWIP_SRC)" ] && mv $(LWIP_DIR) $(LWIP_SRC) || true
	patch -d $(LWIP_SRC) -p0 < patches/lwip.patch-cvs
	touch $@

_lwip-install: _lwip-src
	mkdir -p $(PREFIX)/$(TARGET)/src/lwip
	mkdir -p $(PREFIX)/$(TARGET)/include/lwip
	cp -a $(LWIP_SRC)/src/api $(PREFIX)/$(TARGET)/src/lwip/
	cp -a $(LWIP_SRC)/src/core $(PREFIX)/$(TARGET)/src/lwip/
	cp -a $(LWIP_SRC)/src/netif $(PREFIX)/$(TARGET)/src/lwip/
	cp -a $(LWIP_SRC)/src/include/* $(PREFIX)/$(TARGET)/include/lwip/
	touch $@

.PHONY: cross-lwip clean-lwip distclean-lwip
cross-lwip: _lwip-install

clean-lwip:
	rm -rf $(LWIP_SRC)
	rm -f  _lwip-src

distclean: distclean-lwip
distclean-lwip: clean-lwip
	rm -rf $(LWIP_ARCHIVE)
	rm -f  _lwip-install

################################################################################
# pcre
################################################################################
PCRE_SRC	= pcre-$(PCRE_VERSION)
PCRE_BUILD	= pcre-$(XEN_TARGET_ARCH)


download: $(PCRE_ARCHIVE)
$(PCRE_ARCHIVE):
		$(FETCHER) $@ $(PCRE_URL)

_pcre-src: $(PCRE_ARCHIVE)
		rm -rf $(PCRE_DIR) $(PCRE_SRC)
		tar xzf $<
		[ "$(PCRE_DIR)" != "$(PCRE_SRC)" ] && mv $(PCRE_DIR) $(PCRE_SRC) || true
		touch $@


_pcre-install: _pcre-build
		$(MAKE) DESTDIR= -C $(PCRE_BUILD) install
		touch $@


_pcre-build: _pcre-src
		rm -rf $(PCRE_BUILD)
		mkdir -p $(PCRE_BUILD)
		@(      cd $(PCRE_BUILD) && 					\
				CC_FOR_TARGET="$(CC) $(NEWLIB_CFLAGS)"		\
				CXX_FOR_TARGET=$(CXX)				\
				AR_FOR_TARGET=$(AR)				\
				LD_FOR_TARGET=$(LD)				\
				RANLIB_FOR_TARGET=$(RANLIB)			\
				READELF_FOR_TARGET=$(READELF)			\
				STRIP_FOR_TARGET=$(STRIP)			\
				../$(PCRE_SRC)/configure			\
						--prefix=$(PREFIX)/$(TARGET)	\
						--target=$(TARGET)		\
						--verbose			\
						--disable-shared		\
						--enable-utf8			\
						--enable-unicode-properties	\
		)
		$(MAKE) DESTDIR= -C $(PCRE_BUILD)
		touch $@

.PHONY: cross-pcre clean-pcre distclean-pcre
cross-pcre: _pcre-install

clean-pcre:
		rm -rf $(PCRE_SRC)
		rm -f  _pcre-src

distclean: distclean-pcre
distclean-pcre: clean-pcre
		rm -rf $(PCRE_ARCHIVE)
		rm -f  _pcre-install

################################################################################
# clean
################################################################################
.PHONY: download
download:


.PHONY: clean distclean
clean:

distclean:
	rm -rf $(PREFIX)

