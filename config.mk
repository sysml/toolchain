NEWLIB_VERSION      := 1.16.0
NEWLIB_URL          := ftp://sourceware.org/pub/newlib/newlib-$(NEWLIB_VERSION).tar.gz
NEWLIB_ARCHIVE		:= newlib-$(NEWLIB_VERSION).tar.gz
NEWLIB_DIR			:= newlib-$(NEWLIB_VERSION)

LWIP_TAG		:= EXPERIMENTAL-1_4_1_GSOv4
LWIP_ARCHIVE		:= ${LWIP_TAG}.tar.gz
LWIP_URL			:= https://github.com/cnplab/lwip/archive/$(LWIP_ARCHIVE)
LWIP_DIR			:= lwip-${LWIP_TAG}
