C++ Toolchain
=============

Main toolchain ClickOS toolchain. This build the cpp cross compiler and the xen
libs required to build ClickOS.

Required packages on debian: 

 - build-essential  (automake and etc)
 - libelf-dev  (xen)
 - libppl-pwl-dev  (gcc)
 - libppl-pwl (gcc)
 - libppl-dev (gcc)
 - libppl-c-dev  (gcc)
 - libcloog-ppl0  (gcc)
 - libcloog-ppl-dev  (gcc)
 - texinfo  (newlibc)
 - tree  (clickos)

The patches included in this repository are redistributed unmodified from the Xen 
sources under ```tools/stubdom```.

To build: 

```
$ make all
```

This will install the toolchain in
```./crossroot-$(XEN_TARGET_ARCH)/$(XEN_TARGET_ARCH)-xen-elf```. Below is what you
should expect to see when the build completes

```
./crossroot-$(GNU_ARCH)/$(GNU_ARCH)-xen-elf
        |-- [1009            4096]  info
        `-- [1009            4096]  x86_64-xen-elf
            |-- [1009            4096]  bin
            |-- [1009            4096]  include
            |-- [1009            4096]  info
            |-- [1009            4096]  lib
            |-- [1009            4096]  libexec
            |-- [1009            4096]  share
            `-- [1009            4096]  x86_64-xen-elf
```

To use the toolchain, you must set the $(TOOLCHAIN_ROOT) in your environment pointing 
to the root toolchain directory.

```
export TOOLCHAIN_ROOT ?= $(realpath ../../toolchain/)
```
