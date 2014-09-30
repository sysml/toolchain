NEWLIB_VERSION      := 1.16.0
NEWLIB_URL          := ftp://sourceware.org/pub/newlib/newlib-$(NEWLIB_VERSION).tar.gz
NEWLIB_ARCHIVE		:= newlib-$(NEWLIB_VERSION).tar.gz
NEWLIB_DIR			:= newlib-$(NEWLIB_VERSION)

# lwip: master branch at 27 Feb 2015
LWIP_COMMIT         := a310bc1
LWIP_URL			:= http://git.savannah.gnu.org/gitweb/\?p\=lwip.git\;a\=snapshot\;h\=$(LWIP_COMMIT)\;sf\=tgz
LWIP_ARCHIVE		:= lwip-$(LWIP_COMMIT).tar.gz
LWIP_DIR			:= lwip-$(LWIP_COMMIT)
