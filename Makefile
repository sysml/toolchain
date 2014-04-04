######################### -*- Mode: Makefile-Gmake -*- ########################
### Makefile --- 
## 
## Filename: Makefile
## Description: ClickOS toolchain makefile
## Author: Mohamed Ahmed <m.ahmed@cs.ucl.ac.uk>
## Created: Tue Jun 19 13:44:08 2012 (+0200)
## Version: 
## Last-Updated: Sun Feb 17 12:47:03 2013 (+0100)
##     Update #: 74
## $HeadURL$
## 
######################################################################
## 
### Change log:
## $Date$
## $Revision$
## $Id$
## 
######################################################################
export XEN_ROOT?=$(realpath ../xen-4.2.1)


####################################################
# Should not need to edit below here ...
####################################################

# used for xen tree Makefile rewrites
export XEN_ROOT_T=$(XEN_ROOT)
export XEN_STORE= $(XEN_ROOT)/tools/xenstore
export XEN_COMMON=$(XEN_ROOT)/xen/common
export XEN_INCLUDE=$(XEN_ROOT)/xen/include

#
MINI_OS = $(XEN_ROOT)/extras/mini-os
export XEN_OS=MiniOS
export stubdom=y
export debug=y
include $(XEN_ROOT)/Config.mk

###################################################
#
# files 
#
###################################################
#-------------------------------
# XEN CROSS ROOT
#-------------------------------
#ZLIB_URL?=http://www.zlib.net
ZLIB_URL=$(XEN_EXTFILES_URL)
ZLIB_VERSION=1.2.3

#LIBPCI_URL?=http://www.kernel.org/pub/software/utils/pciutils
LIBPCI_URL?=$(XEN_EXTFILES_URL)
LIBPCI_VERSION=2.2.9

#NEWLIB_URL?=ftp://sources.redhat.com/pub/newlib
NEWLIB_URL?=$(XEN_EXTFILES_URL)
NEWLIB_VERSION=1.16.0

#LWIP_URL?=http://download.savannah.gnu.org/releases/lwip
LWIP_URL?=$(XEN_EXTFILES_URL)
LWIP_VERSION=1.3.0

#-------------------------------
# CPP CROSS ROOT
#-------------------------------
##
## http://ftp.gnu.org/gnu/m4/
M4=m4
M4_VERSION=1.4.17
M4_URL=http://ftp.gnu.org/gnu/m4/

##
## http://ftp.sunet.se/pub/gnu/gmp/gmp-$(GMP_VERSION)/GMP-GMP_VERSION.tar.bz2
GMP=gmp
GMP_VERSION=5.0.1
GMP_URL=http://ftp.sunet.se/pub/gnu/gmp
# GMP_URL=http://ftp.sunet.se/pub/gnu/gmp

##
## http://ftp.sunet.se/pub/gnu/mpfr/mpfr-$(MPFR_VERSION)/MPFR-MPFR_VERSION.tar.bz2
MPFR=mpfr
MPFR_VERSION=2.4.2
MPFR_URL=http://ftp.sunet.se/pub/gnu/mpfr

##
##
MPC=mpc
MPC_VERSION=0.8.1
MPC_URL=http://ftp.sunet.se/pub/gnu/gcc/infrastructure

##
## http://ftp.sunet.se/pub/gnu/binutils/binutils/BINUTILS-BINUTILS_VERSION.tar.bz2
BINUTILS=binutils
BINUTILS_VERSION=2.20.1
# BINUTILS_URL=http://ftp.sunet.se/pub/gnu/binutils
BINUTILS_URL=http://ftp.sunet.se/pub/gnu/binutils

NEWLIB_URL?=$(XEN_EXTFILES_URL)
NEWLIB_VERSION=1.16.0

##
## http://ftp.sunet.se/pub/gnu/binutils/binutils/BINUTILS-BINUTILS_VERSION.tar.bz2
GCC=gcc-core
GPP=gcc-g++
GCC_VERSION=4.5.0
GCC_URL=http://ftp.sunet.se/pub/gnu/gcc/releases/gcc-$(GCC_VERSION)

##
## ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/
PCRE=pcre
PCRE_VERSION=8.32
PCRE_URL=http://switch.dl.sourceforge.net/project/pcre/pcre/8.32
#ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/
#pcre-8.32.tar.gz

###################################################
WGET=wget -c
RM=rm -f
RMDIR=rm -rf
MKDIR=mkdir -p
CP=cp -ap
MV =mv
###################################################

###################################################
#
# flags 
#
###################################################
GNU_TARGET_ARCH:=$(XEN_TARGET_ARCH)
ifeq ($(XEN_TARGET_ARCH),x86_32)
GNU_TARGET_ARCH:=i686
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

CROSS_ROOT=cross-root-$(GNU_TARGET_ARCH)
CROSS_PREFIX=$(CURDIR)/$(CROSS_ROOT)

PATCH_DIR=$(CURDIR)/patches
ARCHIVE_DIR=$(CURDIR)/archive
BUILD_DIR=$(CURDIR)/build

# Disable PIE/SSP if GCC supports them. They can break us.
TARGET_CFLAGS += $(CFLAGS)
TARGET_CPPFLAGS += $(CPPFLAGS)
$(call cc-options-add,TARGET_CFLAGS,CC,$(EMBEDDED_EXTRA_CFLAGS))

# Do not use host headers and libs
GCC_INSTALL = $(shell LANG=C gcc -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')
TARGET_CPPFLAGS += -U __linux__ -U __FreeBSD__ -U __sun__
TARGET_CPPFLAGS += -nostdinc
TARGET_CPPFLAGS += -isystem $(MINI_OS)/include/posix
TARGET_CPPFLAGS += -isystem $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/include
TARGET_CPPFLAGS += -isystem $(GCC_INSTALL)include
TARGET_CPPFLAGS += -isystem $(BUILD_DIR)/include/lwip-$(XEN_TARGET_ARCH)/src/include
TARGET_CPPFLAGS += -isystem $(BUILD_DIR)/include/lwip-$(XEN_TARGET_ARCH)/src/include/ipv4
TARGET_CPPFLAGS += -I $(BUILD_DIR)/include
TARGET_CPPFLAGS += -I$(XEN_ROOT)/xen/include

TARGET_LDFLAGS += -nostdlib -L$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib
CROSS_MAKE := $(MAKE) -j16 DESTDIR=

##################################################################################
##   main
##################################################################################
all: cross-xen cross-cpp
cross-xen: cross-newlib cross-zlib cross-libpci cross-lwip libxc cross-pcre


##################################################################################
##    _  _  ____  _  _ 
##   ( \/ )( ___)( \( )
##    )  (  )__)  )  ( 
##   (_/\_)(____)(_)\_)
##   
##################################################################################

#-------------------------------
# Links
#-------------------------------
$(BUILD_DIR)/mk-headers-$(XEN_TARGET_ARCH): 
	mkdir -p $(BUILD_DIR)/include/xen && \
					ln -sf $(wildcard $(XEN_ROOT)/xen/include/public/*.h) $(BUILD_DIR)/include/xen && \
					ln -sf $(addprefix $(XEN_ROOT)/xen/include/public/,arch-ia64 arch-x86 hvm io xsm) $(BUILD_DIR)/include/xen && \
					( [ -h $(BUILD_DIR)/include/xen/sys ] || ln -sf $(XEN_ROOT)/tools/include/xen-sys/MiniOS $(BUILD_DIR)/include/xen/sys ) && \
					( [ ! -d $(XEN_ROOT)/tools/include/xen ] || rm -rf $(XEN_ROOT)/tools/include/xen ) && \
					$(CROSS_MAKE) -C $(XEN_ROOT)/tools/include/ xen/.dir && \
					( [ -h $(BUILD_DIR)/include/xen/libelf ] || ln -sf $(XEN_ROOT)/tools/include/xen/libelf $(BUILD_DIR)/include/xen/libelf ) && \
	mkdir -p $(BUILD_DIR)/include/xen-foreign && \
					ln -sf $(wildcard $(XEN_ROOT)/tools/include/xen-foreign/*) $(BUILD_DIR)/include/xen-foreign/ && \
					$(CP) $(BUILD_DIR)/include/xen-foreign/Makefile $(BUILD_DIR)/include/xen-foreign/Makefile.mod && \
					sed -i -e 's/^\(XEN_ROOT\=\)\(.\)*/# \0\nXEN_ROOT\=$$(XEN_ROOT_T)/g' $(BUILD_DIR)/include/xen-foreign/Makefile.mod  && \
					$(CROSS_MAKE) -C $(BUILD_DIR)/include/xen-foreign/ -f Makefile.mod  && \
					( [ -h $(BUILD_DIR)/include/xen/foreign ] ||  ln -sf ../xen-foreign $(BUILD_DIR)/include/xen/foreign  ) && \
	mkdir -p $(BUILD_DIR)/libxc-$(XEN_TARGET_ARCH)
					[ -h $(BUILD_DIR)/libxc-$(XEN_TARGET_ARCH)/Makefile ] || ( \
						cd $(BUILD_DIR)/libxc-$(XEN_TARGET_ARCH) && \
						ln -sf $(XEN_ROOT)/tools/libxc/*.h . && \
						ln -sf $(XEN_ROOT)/tools/libxc/*.c . && \
						ln -sf $(XEN_ROOT)/tools/libxc/Makefile . && \
					  echo "XEN_ROOT=$(XEN_ROOT_T)" >> Makefile.mod  && \
						echo "XEN_COMMON=$(XEN_COMMON)"  >> Makefile.mod && \
						echo "XEN_STORE=$(XEN_STORE)"  >> Makefile.mod && \
						echo "XEN_INCLUDE=$(XEN_INCLUDE)"  >> Makefile.mod  && \
				  	tail -n +2 Makefile >> Makefile.mod.f  && \
						sed -i -e 's/\(..\/..\/xen\/common\)/$$(XEN_COMMON)/g' Makefile.mod.f  && \
						sed -i -e 's/\(..\/xenstore\)/ $$(XEN_STORE)/g' Makefile.mod.f && \
						sed -i -e 's/\(..\/include\)/ $$(XEN_INCLUDE)/g' Makefile.mod.f && \
						cat Makefile.mod.f  >> Makefile.mod && \
						rm -f Makefile.mod.f && mv Makefile Makefile.org && \
						ln -sf Makefile.mod Makefile  )  
		$(CROSS_MAKE) -C $(MINI_OS) links
		touch $(BUILD_DIR)/mk-headers-$(XEN_TARGET_ARCH)


#-------------------------------
# Cross-newlib
#-------------------------------
$(ARCHIVE_DIR)/newlib-$(NEWLIB_VERSION).tar.gz:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(NEWLIB_URL)/newlib-$(NEWLIB_VERSION).tar.gz  -O $@ ;\
	fi; \

$(BUILD_DIR)/newlib-$(NEWLIB_VERSION)-patched: $(ARCHIVE_DIR)/newlib-$(NEWLIB_VERSION).tar.gz
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	[ ! -d $(BUILD_DIR)/newlib-$(NEWLIB_VERSION) ] || $(RMDIR) $(BUILD_DIR)/newlib-$(NEWLIB_VERSION)
	tar xzf $< -C $(BUILD_DIR)/
	patch -d $(BUILD_DIR)/newlib-$(NEWLIB_VERSION) -p0 < $(PATCH_DIR)/newlib.patch
	patch -d $(BUILD_DIR)/newlib-$(NEWLIB_VERSION) -p0 < $(PATCH_DIR)/newlib-chk.patch
	patch -d $(BUILD_DIR)/newlib-$(NEWLIB_VERSION) -p1 < $(PATCH_DIR)/newlib-stdint-size_max-fix-from-1.17.0.patch
	find $(BUILD_DIR)/newlib-$(NEWLIB_VERSION) -type f | xargs perl -i.bak \
		-pe 's/\b_(tzname|daylight|timezone)\b/$$1/g'
	touch $@

NEWLIB_STAMPFILE_PATCHED=$(BUILD_DIR)/newlib-$(NEWLIB_VERSION)-patched
NEWLIB_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libc.a

.PHONY: cross-newlib
cross-newlib: $(NEWLIB_STAMPFILE)
$(NEWLIB_STAMPFILE): $(BUILD_DIR)/mk-headers-$(XEN_TARGET_ARCH) $(NEWLIB_STAMPFILE_PATCHED)
	$(MKDIR) $(BUILD_DIR)/newlib-$(NEWLIB_VERSION)/build
	( cd $(BUILD_DIR)/newlib-$(NEWLIB_VERSION)/build && \
	  CC_FOR_TARGET="$(CC) $(TARGET_CPPFLAGS) $(TARGET_CFLAGS) $(NEWLIB_CFLAGS)" \
		AR_FOR_TARGET=$(AR) LD_FOR_TARGET=$(LD) RANLIB_FOR_TARGET=$(RANLIB) \
		../configure --prefix=$(CROSS_PREFIX) \
		--target=$(GNU_TARGET_ARCH)-xen-elf \
		--verbose \
		--enable-newlib-io-long-long \
		--enable-newlib-io-long-double \
		--disable-multilib && \
	  $(CROSS_MAKE) && \
	  $(CROSS_MAKE) install )

#-------------------------------
# Cross-zlib
#-------------------------------
$(ARCHIVE_DIR)/zlib-$(ZLIB_VERSION).tar.gz:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(ZLIB_URL)/zlib-$(ZLIB_VERSION).tar.gz -O $@ ;\
	fi; \

## it seems we have to build zlib inplace
$(BUILD_DIR)/zlib-$(XEN_TARGET_ARCH): $(ARCHIVE_DIR)/zlib-$(ZLIB_VERSION).tar.gz
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xzf $< -C $(BUILD_DIR)/
	$(CP) $(BUILD_DIR)/zlib-$(ZLIB_VERSION) $(BUILD_DIR)/zlib-$(XEN_TARGET_ARCH)
	touch $@

ZLIB_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libz.a
.PHONY: cross-zlib
cross-zlib: $(ZLIB_STAMPFILE)
$(ZLIB_STAMPFILE): $(BUILD_DIR)/zlib-$(XEN_TARGET_ARCH) cross-newlib
	( cd $(BUILD_DIR)/zlib-$(XEN_TARGET_ARCH) && \
		CFLAGS="$(TARGET_CPPFLAGS) $(TARGET_CFLAGS)" CC=$(CC) \
		./configure --prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf && \
		$(CROSS_MAKE) libz.a && \
		$(CROSS_MAKE) install )  && \
	touch  $@

#-------------------------------
# Cross-libpci
#-------------------------------
$(ARCHIVE_DIR)/pciutils-$(LIBPCI_VERSION).tar.bz2:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(LIBPCI_URL)/pciutils-$(LIBPCI_VERSION).tar.bz2  -O $@ ;\
	fi; \

$(BUILD_DIR)/pciutils-$(XEN_TARGET_ARCH): $(ARCHIVE_DIR)/pciutils-$(LIBPCI_VERSION).tar.bz2
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xjf $< -C $(BUILD_DIR)/
	$(CP) $(BUILD_DIR)/pciutils-$(LIBPCI_VERSION) $@
	patch -d $@ -p1 < $(PATCH_DIR)/pciutils.patch
	touch $@

LIBPCI_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libpci.a
.PHONY: cross-libpci
cross-libpci: $(LIBPCI_STAMPFILE)
$(LIBPCI_STAMPFILE): $(BUILD_DIR)/pciutils-$(XEN_TARGET_ARCH) cross-newlib cross-zlib
	( cd $(BUILD_DIR)/pciutils-$(XEN_TARGET_ARCH) && \
		$(CP) $(PATCH_DIR)/libpci.config.h lib/config.h && \
		chmod u+w lib/config.h && \
		echo '#define PCILIB_VERSION "$(LIBPCI_VERSION)"' >> lib/config.h && \
		ln -sf $(PATCH_DIR)/libpci.config.mak lib/config.mk && \
		sed -i -e 's/^\(XEN_ROOT\=\)\(.\)*/# \0\nXEN_ROOT\=$$(XEN_ROOT_T)/g' lib/Makefile  && \
		$(CROSS_MAKE) CC="$(CC) $(TARGET_CPPFLAGS) $(TARGET_CFLAGS) -I$(realpath $(MINI_OS)/include)" lib/libpci.a && \
		$(INSTALL_DATA) lib/libpci.a $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/ && \
		$(INSTALL_DIR) $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/include/pci && \
		$(INSTALL_DATA) lib/config.h lib/header.h lib/pci.h lib/types.h $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/include/pci/ \
	)


#-------------------------------
# Cross-pcre
#-------------------------------
$(ARCHIVE_DIR)/pcre-$(PCRE_VERSION).tar.gz:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(PCRE_URL)/pcre-$(PCRE_VERSION).tar.gz -O $@ ;\
	fi; \

## it seems we have to build pcre inplace
$(BUILD_DIR)/pcre-$(XEN_TARGET_ARCH): $(ARCHIVE_DIR)/pcre-$(PCRE_VERSION).tar.gz
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xzf $< -C $(BUILD_DIR)/
	$(CP) $(BUILD_DIR)/pcre-$(PCRE_VERSION) $(BUILD_DIR)/pcre-$(XEN_TARGET_ARCH)
	touch $@

PCRE_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libpcre.a
.PHONY: cross-pcre
cross-pcre: $(PCRE_STAMPFILE)
$(PCRE_STAMPFILE): $(BUILD_DIR)/pcre-$(XEN_TARGET_ARCH)
	( cd $(BUILD_DIR)/pcre-$(XEN_TARGET_ARCH) && \
		CFLAGS="" CC=$(CC) \
		./configure --prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf --enable-shared=no --enable-silent-rules=no  && \
		$(CROSS_MAKE) && \
		$(CROSS_MAKE) install )  && \
	touch  $@

#-------------------------------
# lwIP
#-------------------------------
$(ARCHIVE_DIR)/lwip-$(LWIP_VERSION).tar.gz:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(LWIP_URL)/lwip-$(LWIP_VERSION).tar.gz  -O $@ ;\
	fi; \

.PHONY: cross-lwip
cross-lwip: $(BUILD_DIR)/lwip-$(XEN_TARGET_ARCH)
$(BUILD_DIR)/lwip-$(XEN_TARGET_ARCH): $(ARCHIVE_DIR)/lwip-$(LWIP_VERSION).tar.gz
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xzf $< -C $(BUILD_DIR)/
	mv $(BUILD_DIR)/lwip $@
	patch -d $@ -p0 < $(PATCH_DIR)/lwip.patch-cvs
	$(CP) $@ $(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/include/
	touch $@

#-------------------------------
# libxc
#-------------------------------
LIBXC_XENGUEST_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libxenguest.a
LIBXC_XENCTRL_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libxenctrl.a

.PHONY: libxc
libxc: $(LIBXC_XENCTRL_STAMPFILE)  $(LIBXC_XENGUEST_STAMPFILE)

$(LIBXC_XENCTRL_STAMPFILE):  $(BUILD_DIR)/mk-headers-$(XEN_TARGET_ARCH) cross-zlib
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	CPPFLAGS="$(TARGET_CPPFLAGS)" CFLAGS="$(TARGET_CFLAGS)" $(CROSS_MAKE) CONFIG_LIBXC_MINIOS=y -C $(BUILD_DIR)/libxc-$(XEN_TARGET_ARCH) &&\
	$(CP)  $(BUILD_DIR)/libxc-$(XEN_TARGET_ARCH)/libxenctrl.a $@
	touch $@

$(LIBXC_XENGUEST_STAMPFILE): $(LIBXC_XENCTRL_STAMPFILE)
	$(CP) $(BUILD_DIR)/libxc-$(XEN_TARGET_ARCH)/libxenguest.a $@
	touch $@


##################################################################################
##     ___  _  _     ___  ____  ____ 
##    / __)( \/ )   / __)(  _ \(  _ \
##   ( (__  )  (   ( (__  )___/ )___/
##    \___)(_/\_)   \___)(__)  (__)  
##   
##################################################################################

#-------------------------------
# Cross-m4
#-------------------------------
$(ARCHIVE_DIR)/m4-$(M4_VERSION).tar.bz2:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(M4_URL)/m4-$(M4_VERSION).tar.bz2  -O $@ ;\
	fi; \

$(BUILD_DIR)/m4-$(M4_VERSION): $(ARCHIVE_DIR)/m4-$(M4_VERSION).tar.bz2
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xjf $< -C $(BUILD_DIR)/
	touch $@

M4_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/bin/m4
.PHONY: cross-m4
cross-m4:  $(M4_STAMPFILE)
$(M4_STAMPFILE): $(BUILD_DIR)/m4-$(M4_VERSION)
	mkdir -p $(BUILD_DIR)/m4-$(M4_VERSION)/build
	( cd $(BUILD_DIR)/m4-$(M4_VERSION)/build && \
			../configure  --prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf \
			 	--target=$(GNU_TARGET_ARCH)-xen-elf \
				 --verbose --disable-shared --with-included-regex --enable-static && \
		$(CROSS_MAKE) && \
		$(CROSS_MAKE) install )

#-------------------------------
# Cross-binutils
#-------------------------------
$(ARCHIVE_DIR)/binutils-$(BINUTILS_VERSION).tar.bz2:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(BINUTILS_URL)/binutils-$(BINUTILS_VERSION).tar.bz2  -O $@ ;\
	fi; \

$(BUILD_DIR)/binutils-$(BINUTILS_VERSION): $(ARCHIVE_DIR)/binutils-$(BINUTILS_VERSION).tar.bz2
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xjf $< -C $(BUILD_DIR)/
	touch $@

BINUTILS_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/bin/$(GNU_TARGET_ARCH)-xen-elf-ld
.PHONY: cross-binutils
cross-binutils: $(BINUTILS_STAMPFILE)
$(BINUTILS_STAMPFILE): cross-m4 $(BUILD_DIR)/binutils-$(BINUTILS_VERSION)
	mkdir -p $(BUILD_DIR)/binutils-$(BINUTILS_VERSION)/build
	( cd $(BUILD_DIR)/binutils-$(BINUTILS_VERSION)/build && \
		CFLAGS=-Wno-error  ../configure \
			--prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf  \
			--target=$(GNU_TARGET_ARCH)-xen-elf	\
			--enable-interwork \
			--enable-multilib \
			--disable-nls \
			--disable-shared \
			--disable-threads \
			--with-gcc \
			--with-gnu-as \
			--with-gnu-ld && \
		echo "MAKEINFO = :" >> Makefile && \
		$(CROSS_MAKE) && \
		$(CROSS_MAKE) install )


#-------------------------------
# Cross-newlib unpatched 
#-------------------------------
$(BUILD_DIR)/newlib-$(NEWLIB_VERSION)-cx: $(ARCHIVE_DIR)/newlib-$(NEWLIB_VERSION).tar.gz
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)	
	[ ! -d $(BUILD_DIR)/newlib-$(NEWLIB_VERSION) ] || $(RMDIR) $(BUILD_DIR)/newlib-$(NEWLIB_VERSION)
	tar xzf $< -C $(BUILD_DIR)/
	touch $@

PATH := ${PATH}:$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/bin
NEWLIB_STAMPFILE_GPP=$(CROSS_ROOT)/$(GNU_TARGET_ARCH)-xen-elf/x86_64-xen-elf/lib/libc.a
.PHONY: cross-newlib
cross-newlib-gpp:  $(NEWLIB_STAMPFILE_GPP)
$(NEWLIB_STAMPFILE_GPP): $(BUILD_DIR)/newlib-$(NEWLIB_VERSION)-cx
	mkdir -p $(BUILD_DIR)/newlib-$(NEWLIB_VERSION)/build
	( cd  $(BUILD_DIR)/newlib-$(NEWLIB_VERSION)/build && \
			../configure \
			--prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf  \
			--target=$(GNU_TARGET_ARCH)-xen-elf	--verbose \
			--enable-interwork \
			--enable-multilib \
			--enable-newlib-io-long-long  \
			--enable-newlib-io-long-double \
			--with-gnu-as \
			--with-gnu-ld \
			--disable-nls && \
		$(CROSS_MAKE) && \
		$(CROSS_MAKE) install )  

##################################################
##
## GCC with gmp mpfr mpc 
##
##################################################

#-------------------------------
# gmp
#----------------------------
$(ARCHIVE_DIR)/gmp-$(GMP_VERSION).tar.bz2:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(GMP_URL)/gmp-$(GMP_VERSION).tar.bz2  -O $@ ;\
	fi; \

 $(BUILD_DIR)/gcc-$(GCC_VERSION)/gmp: $(ARCHIVE_DIR)/gmp-$(GMP_VERSION).tar.bz2 $(BUILD_DIR)/gcc-$(GCC_VERSION)
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	@-if [ -d $(BUILD_DIR)/gmp-$(GMP_VERSION) ]; then \
			$(CP) $(BUILD_DIR)/gmp-$(GMP_VERSION)  $(BUILD_DIR)/gcc-$(GCC_VERSION)/gmp ;\
	else  \
			tar xjf $(ARCHIVE_DIR)/gmp-$(GMP_VERSION).tar.bz2 -C $(BUILD_DIR)/   ;\
			$(CP) $(BUILD_DIR)/gmp-$(GMP_VERSION) $(BUILD_DIR)/gcc-$(GCC_VERSION)/gmp ;\
	fi; \
	touch $@

# GMP_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libgmp.a

# $(BUILD_DIR)/gmp-$(GMP_VERSION): $(ARCHIVE_DIR)/gmp-$(GMP_VERSION).tar.bz2
# 	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
# 	tar xjf $< -C $(BUILD_DIR)/
# 	touch $@

# $(GMP_STAMPFILE):  $(BUILD_DIR)/gmp-$(GMP_VERSION)
# 	$(MKDIR) $(BUILD_DIR)/gmp-$(GMP_VERSION)/build
# 	( cd $(BUILD_DIR)/gmp-$(GMP_VERSION)/build && \
# 			../configure \
# 			--prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf  \
# 			--disable-shared \
# 			--enable-static && \
# 		$(CROSS_MAKE) && \
# 		$(CROSS_MAKE) install )

# #			--enable-decimal-float 
# gmp: $(GMP_STAMPFILE)

#-------------------------------
# mpfr
#-------------------------------
$(ARCHIVE_DIR)/mpfr-$(MPFR_VERSION).tar.bz2:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(MPFR_URL)/mpfr-$(MPFR_VERSION).tar.bz2  -O $@ ;\
	fi; \

 $(BUILD_DIR)/gcc-$(GCC_VERSION)/mpfr: $(ARCHIVE_DIR)/mpfr-$(MPFR_VERSION).tar.bz2 $(BUILD_DIR)/gcc-$(GCC_VERSION) 
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	@-if [ -d $(BUILD_DIR)/mpfr-$(MPFR_VERSION) ]; then \
			$(CP) $(BUILD_DIR)/mpfr-$(MPFR_VERSION)  $(BUILD_DIR)/gcc-$(GCC_VERSION)/mpfr ;\
	else  \
			tar xjf $(ARCHIVE_DIR)/mpfr-$(MPFR_VERSION).tar.bz2 -C $(BUILD_DIR)/   ;\
			$(CP) $(BUILD_DIR)/mpfr-$(MPFR_VERSION) $(BUILD_DIR)/gcc-$(GCC_VERSION)/mpfr ;\
	fi; \
	touch $@

# MPFR_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libmpfr.a

# $(BUILD_DIR)/mpfr-$(MPFR_VERSION): $(ARCHIVE_DIR)/mpfr-$(MPFR_VERSION).tar.bz2
# 	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
# 	tar xjf $< -C $(BUILD_DIR)/
# 	touch $@

# $(MPFR_STAMPFILE):  $(BUILD_DIR)/mpfr-$(MPFR_VERSION)
# 	$(MKDIR) $(BUILD_DIR)/mpfr-$(MPFR_VERSION)/build
# 	( cd $(BUILD_DIR)/mpfr-$(MPFR_VERSION)/build && \
# 			../configure \
# 			--prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf  \
# 			--with-gmp-build=$(BUILD_DIR)/gmp-$(GMP_VERSION)/	--disable-shared \
# 			--enable-static && \
# 		$(CROSS_MAKE) && \
# 		$(CROSS_MAKE) install )

# # --enable-decimal-float 
# mpfr: $(MPFR_STAMPFILE)

#-------------------------------
# mpc
#-------------------------------
$(ARCHIVE_DIR)/mpc-$(MPC_VERSION).tar.gz:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(MPC_URL)/mpc-$(MPC_VERSION).tar.gz  -O $@ ;\
	fi; \

$(BUILD_DIR)/gcc-$(GCC_VERSION)/mpc: $(ARCHIVE_DIR)/mpc-$(MPC_VERSION).tar.gz $(BUILD_DIR)/gcc-$(GCC_VERSION)
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	@-if [ -d $(BUILD_DIR)/mpc-$(MPC_VERSION) ]; then \
			$(CP) $(BUILD_DIR)/mpc-$(MPC_VERSION)  $(BUILD_DIR)/gcc-$(GCC_VERSION)/mpc ;\
	else  \
			tar xzf $(ARCHIVE_DIR)/mpc-$(MPC_VERSION).tar.gz -C $(BUILD_DIR)/   ;\
			$(CP) $(BUILD_DIR)/mpc-$(MPC_VERSION) $(BUILD_DIR)/gcc-$(GCC_VERSION)/mpc ;\
	fi; \
	touch $@

# MPC_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/lib/libmpc.a

# $(BUILD_DIR)/mpc-$(MPC_VERSION): $(ARCHIVE_DIR)/mpc-$(MPC_VERSION).tar.gz
# 	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
# 	tar xzf $< -C $(BUILD_DIR)/
# 	touch $@

# $(MPC_STAMPFILE): $(BUILD_DIR)/mpc-$(MPC_VERSION)
# 	$(MKDIR) $(BUILD_DIR)/mpc-$(MPC_VERSION)/build
# 	( cd $(BUILD_DIR)/mpc-$(MPC_VERSION)/build && \
# 			../configure \
# 			--prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf  \
# 			--with-gmp-build=$(BUILD_DIR)/gmp-$(GMP_VERSION)/build	\
# 			--with-mpfr-build=$(BUILD_DIR)/mpc-$(MPC_VERSION)/build \
# 			--disable-shared \
# 			--enable-static && \
# 		$(CROSS_MAKE) && \
# 		$(CROSS_MAKE) install )

# # --enable-decimal-float 
# mpc: $(MPC_STAMPFILE)
#-------------------------------
# gcc
#-------------------------------
$(ARCHIVE_DIR)/gcc-core-$(GCC_VERSION).tar.bz2:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(GCC_URL)/gcc-core-$(GCC_VERSION).tar.bz2  -O $@ ;\
	fi; \

$(BUILD_DIR)/gcc-$(GCC_VERSION): $(ARCHIVE_DIR)/gcc-core-$(GCC_VERSION).tar.bz2
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xjf $< -C $(BUILD_DIR)/
	touch $@

GCC_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/bin/$(GNU_TARGET_ARCH)-xen-elf-gcc
.PHONY: cross-gcc
cross-gcc: $(GCC_STAMPFILE) 
$(GCC_STAMPFILE) : 	cross-binutils $(BUILD_DIR)/gcc-$(GCC_VERSION) \
										$(BUILD_DIR)/gcc-$(GCC_VERSION)/gmp  \
										$(BUILD_DIR)/gcc-$(GCC_VERSION)/mpfr \
										$(BUILD_DIR)/gcc-$(GCC_VERSION)/mpc
	$(MKDIR) $(BUILD_DIR)/gcc-$(GCC_VERSION)/build 
	( cd $(BUILD_DIR)/gcc-$(GCC_VERSION)/build && \
			../configure \
			--prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf \
	    --target=$(GNU_TARGET_ARCH)-xen-elf \
			-enable-interwork \
			--disable-multilib --enable-languages=c --with-newlib --disable-nls \
			--disable-shared --disable-threads --with-gnu-as --with-gnu-ld \
			--without-headers && \
		echo "MAKEINFO = :" >> Makefile && \
		$(CROSS_MAKE) all-gcc && \
		$(CROSS_MAKE) install-gcc )  

#-------------------------------
# cpp
#-------------------------------
$(ARCHIVE_DIR)/gcc-g++-$(GCC_VERSION).tar.bz2:
	[ -d $(ARCHIVE_DIR) ] || $(MKDIR) $(ARCHIVE_DIR) 
	@-if [ ! -f $@ ]; then \
		echo "download $@ ";\
		$(WGET) $(GCC_URL)/gcc-g++-$(GCC_VERSION).tar.bz2  -O $@ ;\
	fi; \

$(BUILD_DIR)/gcc-$(GCC_VERSION)/libstdc++-v3: $(ARCHIVE_DIR)/gcc-g++-$(GCC_VERSION).tar.bz2
	[ -d $(BUILD_DIR) ] || $(MKDIR) $(BUILD_DIR)
	tar xjf $< -C $(BUILD_DIR)/
	touch $@

GPP_STAMPFILE=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf/bin/$(GNU_TARGET_ARCH)-xen-elf-g++
.PHONY: cross-cpp
cross-cpp: $(GPP_STAMPFILE) 
$(GPP_STAMPFILE) : cross-gcc cross-newlib-gpp $(BUILD_DIR)/gcc-$(GCC_VERSION)/libstdc++-v3
	[ -d $(BUILD_DIR)/gcc-$(GCC_VERSION)/build  ] || mkdir -p $(BUILD_DIR)/gcc-$(GCC_VERSION)/build 
	( cd $(BUILD_DIR)/gcc-$(GCC_VERSION)/build  && \
		 $(RMDIR) * && \
		 ../configure \
		 	--prefix=$(CROSS_PREFIX)/$(GNU_TARGET_ARCH)-xen-elf \
		 	--target=$(GNU_TARGET_ARCH)-xen-elf \
		  --disable-multilib --enable-languages=c,c++ --with-newlib  --disable-nls \
			--disable-shared --disable-threads --with-gnu-as --with-gnu-ld && \
		echo "MAKEINFO = :" >> Makefile && \
		$(CROSS_MAKE) && \
		$(CROSS_MAKE) install )

info:
	@echo "ARCHIVE_DIR = $(ARCHIVE_DIR)"
	@echo "BUILD_DIR = $(BUILD_DIR)"
	@echo "CROSS_PREFIX = $(CROSS_PREFIX)"
	@echo "GNU_TARGET_ARCH = $(GNU_TARGET_ARCH)"
	@echo "gmp $(BUILD_DIR)/gcc-$(GCC_VERSION)/gmp"
	@echo "libc = $(CROSS_ROOT)/$(GNU_TARGET_ARCH)-xen-elf/x86_64-xen-elf/lib/libc.a"


.PHONY: cross-xen-clean
cross-xen-clean: 
	$(RM) $(LIBXC_XENGUEST_STAMPFILE)
	$(RM) $(LIBXC_XENCTRL_STAMPFILE)
	$(RM) $(NEWLIB_STAMPFILE_PATCHED)
	$(RM) $(NEWLIB_STAMPFILE)
	$(RM) $(ZLIB_STAMPFILE)
	$(RM) $(LIBPCI_STAMPFILE)
	$(RM) $(BUILD_DIR)/mk-headers-$(XEN_TARGET_ARCH)
	$(RMDIR) $(BUILD_DIR)/include

.PHONY: clean
clean: 
	$(RM) $(BUILD_DIR)/mk-headers-$(XEN_TARGET_ARCH)
	-[ ! -d $(BUILD_DIR) ]  || $(RMDIR) $(BUILD_DIR) 
	-[ ! -d $(CROSS_ROOT) ]  || $(RMDIR) $(CROSS_ROOT)

# clean downloads
.PHONY: downloadclean
downloadclean: 
	-[ ! -d $(ARCHIVE_DIR) ]  || $(RM) $(ARCHIVE_DIR)

# .PHONY: distclean
# distclean: downloadclean clean

######################################################################
### Makefile ends here
