ROOT_DIR := $(shell dirname "$(realpath $(lastword $(MAKEFILE_LIST)))")

GMP_VERSION=6.1.2
GMP_DIR=gmp-$(GMP_VERSION)
GMP_TAR=$(GMP_DIR).tar.bz2
GMP_URL=https://ftp.gnu.org/pub/gnu/gmp/$(GMP_TAR)
GMP_MAKE_BINS=$(addprefix $(GMP_DIR)/, gen-fib gen-fac gen-bases gen-trialdivtab gen-jacobitab gen-psqr)

FASTCOMP = emsdk/fastcomp

$(FASTCOMP)/emscripten/emcc:
	./emsdk/emsdk install latest
	./emsdk/emsdk activate latest
	# For OSX:
	# cd $(FASTCOMP)/bin && mv llvm-ar llvm-ar.old && ln -s /usr/local/opt/llvm/bin/llvm-ar llvm-ar
	# cd $(FASTCOMP)/fastcomp/bin && mv llvm-ar llvm-ar.old && ln -s /usr/local/opt/llvm/bin/llvm-ar llvm-ar
	source emsdk/emsdk_env.sh

all: git-submodules $(FASTCOMP)/emscripten/emcc gmp ethsnarks
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
	cd ./ethsnarks/depends/libsnark/depends/libff && patch -tp1 < $(ROOT_DIR)/libff.patch || true
	cd ./ethsnarks/depends/libsnark/depends/libfqfft/depends/libff && patch -tp1 < $(ROOT_DIR)/libff.patch || true
	cd ./ethsnarks/depends/libsnark/depends/libfqfft && patch -tp1 < $(ROOT_DIR)/libqfft.patch || true

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

installroot/lib/libgmp.a: $(GMP_DIR) $(GMP_MAKE_BINS) $(GMP_DIR)/Makefile 
	./emsdk/emsdk_env.sh
	make -C $(GMP_DIR) -j 2
	make -C $(GMP_DIR) install

$(GMP_DIR)/Makefile: $(GMP_DIR)
	cd $< && sed -i.bak -e 's/^# Only do the GMP_ASM .*/gmp_asm_syntax_testing=no/' configure.ac && autoconf
	cd $< && emcmake ./configure ABI=standard --prefix=`pwd`/../installroot/ ABI=standard --host=none --disable-assembly --disable-shared || cat config.log

$(GMP_DIR): $(GMP_TAR)
	tar -xf $<

$(GMP_TAR):
	curl -L -o $@ $(GMP_URL)

$(GMP_DIR)/gen-fib: $(GMP_DIR)/gen-fib.c

$(GMP_DIR)/gen-fac: $(GMP_DIR)/gen-fac.c

$(GMP_DIR)/gen-bases: $(GMP_DIR)/gen-bases.c

$(GMP_DIR)/gen-trialdivtab: $(GMP_DIR)/gen-trialdivtab.c

$(GMP_DIR)/gen-jacobitab: $(GMP_DIR)/gen-jacobitab.c

$(GMP_DIR)/gen-psqr: $(GMP_DIR)/gen-psqr.c
