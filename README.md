ClickOS toolchain
=================

There used to be a toolchain here. Currently this Makefile downloads and builds
the necessary libraries for building ClickOS, namely Newlib and Lwip.

Required packages for building on debian are:

 - build-essential  (automake and etc)
 - gcc	(up to 4.7)
 - texinfo  (newlibc)

You also need MiniOS sources. You can get them from https://github.com/sysml/mini-os.

The patches included in this repository are redistributed unmodified from the Xen 
sources under ```tools/stubdom```.

To build: 

```
$ EXPORT MINIOS_ROOT=<path_to_minios>
$ make all
```

This will install the libraries in
```./$(XEN_TARGET_ARCH)-root/$(XEN_TARGET_ARCH)-xen-elf```. Below is what you
should expect to see when the build completes

```
./$(XEN_TARGET_ARCH)-root
    |-- info
    `-- $(XEN_TARGET_ARCH)-xen-elf
        |-- include
        |-- lib
        `-- src
```

To use this libraries use the --with-newlib and --with-lwip options of configure
pointing to $(XEN_TARGET_ARCH)-xen-elf directory.

