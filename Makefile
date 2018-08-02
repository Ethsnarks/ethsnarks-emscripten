ROOT_DIR := $(shell dirname "$(realpath $(lastword $(MAKEFILE_LIST)))")

GMP_VERSION=6.1.2
GMP_DIR=gmp-$(GMP_VERSION)
GMP_TAR=$(GMP_DIR).tar.bz2
GMP_URL=https://ftp.gnu.org/pub/gnu/gmp/$(GMP_TAR)
GMP_MAKE_BINS=$(addprefix $(GMP_DIR)/, gen-fib gen-fac gen-bases gen-trialdivtab gen-jacobitab gen-psqr)

BOOST_VERSION=1_67_0
BOOST_DIR=boost_$(BOOST_VERSION)
BOOST_TAR=$(BOOST_DIR).tar.bz2
BOOST_URL=https://dl.bintray.com/boostorg/release/$(subst _,.,$(BOOST_VERSION))/source/$(BOOST_TAR)

OPENSSL_VER=1.1.0h
OPENSSL_DIR=openssl-$(OPENSSL_VER)
OPENSSL_TAR=$(OPENSSL_DIR).tar.gz
OPENSSL_URL=https://www.openssl.org/source/$(OPENSSL_TAR)


all: git-submodules gmp openssl boost ethsnarks
	echo ...

installroot:
	mkdir -p $@

build:
	mkdir -p $@

git-submodules:
	git submodule update --init --recursive


#######################################################################
# ethsnarks

ethsnarks-patches:
	echo $(ROOT_DIR)
	cd ./ethsnarks/depends/libsnark/depends/libff && patch -p1 < $(ROOT_DIR)/libff.patch
	cd ./ethsnarks/depends/libsnark/depends/libfqfft/depends/libff && patch -p1 < $(ROOT_DIR)/libff.patch
	cd ./ethsnarks/depends/libsnark/depends/libfqfft && patch -p1 < $(ROOT_DIR)/libqfft.patch

ethsnarks: build.emscripten/test_hashpreimage.js

build.emscripten/test_hashpreimage.js: build/cmake_install.cmake ethsnarks-patches
	make -C build -j 4

build/cmake_install.cmake: build
	cd build && emcmake cmake .. -DWITH_PROCPS=OFF -DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=ON -DCMAKE_PREFIX_PATH=`pwd`/../installroot/ 


#######################################################################
# GMP

gmp-bins: $(GMP_MAKE_BINS)

.PHONY: gmp
gmp: installroot/lib/libgmp.a

installroot/lib/libgmp.a: $(GMP_MAKE_BINS) $(GMP_DIR)/Makefile 
	make -C $(GMP_DIR) -j 4
	make -C $(GMP_DIR) install

$(GMP_DIR)/Makefile: $(GMP_DIR)
	cd $< && sed -i.bak -e 's/^# Only do the GMP_ASM .*/gmp_asm_syntax_testing=no/' configure.ac && autoconf
	cd $< && emcmake ./configure --prefix=`pwd`/../installroot/ ABI=64 --disable-assembly --disable-shared

$(GMP_DIR): $(GMP_TAR)
	tar -xf $<

$(GMP_TAR):
	wget -O $@ $(GMP_URL)

$(GMP_DIR)/gen-fib: $(GMP_DIR)/gen-fib.c

$(GMP_DIR)/gen-fac: $(GMP_DIR)/gen-fac.c

$(GMP_DIR)/gen-bases: $(GMP_DIR)/gen-bases.c

$(GMP_DIR)/gen-trialdivtab: $(GMP_DIR)/gen-trialdivtab.c

$(GMP_DIR)/gen-jacobitab: $(GMP_DIR)/gen-jacobitab.c

$(GMP_DIR)/gen-psqr: $(GMP_DIR)/gen-psqr.c


#######################################################################
# OpenSSL

.PHONY: openssl
openssl: installroot/lib/libcrypto.a

installroot/lib/libcrypto.a: $(OPENSSL_DIR)/Makefile
	make -C $(OPENSSL_DIR) -j4
	make -C $(OPENSSL_DIR) install_dev

$(OPENSSL_DIR)/Makefile: $(OPENSSL_DIR)
	cd $< && emconfigure ./Configure linux-generic64 -no-asm -no-shared -no-hw -no-threads -no-dso --prefix=`pwd`/../installroot/
	cd $< && sed -i.bak -e 's/^CROSS_COMPILE=.*/CROSS_COMPILE=/' Makefile

$(OPENSSL_TAR):
	wget -O $@ $(OPENSSL_URL)

$(OPENSSL_DIR): $(OPENSSL_TAR)
	tar -xf $<


#######################################################################
# Boost

.PHONY: boost

boost: installroot/lib/libboost_program_options.a

$(BOOST_TAR):
	wget -O $@ $(BOOST_URL)

$(BOOST_DIR): $(BOOST_TAR)
	tar -xf $<

.PHONY: $(BOOST_DIR)/project-config.jam
$(BOOST_DIR)/project-config.jam: $(BOOST_DIR)
	cd $< && emconfigure ./bootstrap.sh --prefix=`pwd`/../installroot/ --without-icu --with-libraries=program_options
	# force boost to use the Emscripten compilers
	cd $< && sed -i.bak -e 's/^    using gcc ;/# using gcc ;/' project-config.jam
	cd $< && echo -e "using gcc : :\n \"$(realpath $(shell which em++))\" :\n <archiver>\"$(realpath $(shell which emar))\"\n <ranlib>\"$(realpath $(shell which emranlib))\"\n ;" >> project-config.jam	

installroot/lib/libboost_program_options.a: $(BOOST_DIR)/project-config.jam
	cd $(BOOST_DIR) && ./b2 link=static variant=release runtime-link=static program_options install
