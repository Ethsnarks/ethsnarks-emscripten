ROOT_DIR := $(shell dirname "$(realpath $(lastword $(MAKEFILE_LIST)))")

GMP_VERSION ?= 6.1.2
GMP_DIR=gmp-$(GMP_VERSION)
GMP_TAR=$(GMP_DIR).tar.bz2
GMP_URL=https://ftp.gnu.org/pub/gnu/gmp/$(GMP_TAR)
GMP_MAKE_BINS=$(addprefix $(GMP_DIR)/, gen-fib gen-fac gen-bases gen-trialdivtab gen-jacobitab gen-psqr)

FASTCOMP ?= emsdk/fastcomp
WORKING_LLVM_AR ?= /usr/local/opt/llvm/bin/llvm-ar 

OS := $(shell uname)

all: git-submodules gmp ethsnarks

installroot:
	mkdir -p $@

build:
	mkdir -p $@

git-submodules:
	git submodule update --init --recursive

clean:
	rm -rf build build.emscripten installroot gmp-*


#######################################################################
# emscripten

emscripten: $(FASTCOMP)/emscripten/emcc

.PHONY: $(FASTCOMP)/emscripten/emcc
$(FASTCOMP)/emscripten/emcc:
	./emsdk/emsdk install latest
	./emsdk/emsdk activate latest
	#source emsdk/emsdk_env.sh

# On OSX, the `llvm-ar` executable which comes with emscripten is broken on some versions of OSX
# It relies upon an unexported symbol, probably from a newer version of OSX
# This is solved by installing `llvm` via Brew, then using that version of `llvm-ar`
ifeq ($(OS), Darwin)
emscripten: $(FASTCOMP)/bin/llvm-ar.old $(FASTCOMP)/fastcomp/bin/llvm-ar.old

$(FASTCOMP)/bin/llvm-ar.old: $(FASTCOMP)/bin/llvm-ar
	cd $(dir $@) && mv $(basename $<) $(basename $@) && ln -s $(WORKING_LLVM_AR) $(basename $<)

$(FASTCOMP)/fastcomp/bin/llvm-ar.old: $(FASTCOMP)/fastcomp/bin/llvm-ar
	cd $(dir $@) && mv $(basename $<) $(basename $@) && ln -s $(WORKING_LLVM_AR) $(basename $<)
endif


#######################################################################
# ethsnarks

ethsnarks-patches:
	cd ./ethsnarks/depends/libsnark/depends/libff && patch -Ntp1 < $(ROOT_DIR)/libff.patch || true
	cd ./ethsnarks/depends/libsnark/depends/libfqfft/depends/libff && patch -Ntp1 < $(ROOT_DIR)/libff.patch || true

ethsnarks: build.emscripten/test_sha256_full_gadget.js

build.emscripten/test_sha256_full_gadget.js: build/cmake_install.cmake ethsnarks-patches
	make -C build -j 4

build/cmake_install.cmake: build
	cd build && emcmake cmake .. -DWITH_PROCPS=OFF -DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=ON -DCMAKE_PREFIX_PATH=`pwd`/../installroot/ 


#######################################################################
# GMP

gmp-bins: $(GMP_MAKE_BINS)

.PHONY: gmp
gmp: installroot/lib/libgmp.a

installroot/lib/libgmp.a: $(GMP_DIR) $(GMP_MAKE_BINS) $(GMP_DIR)/Makefile
	make -C $(GMP_DIR) -j 2
	make -C $(GMP_DIR) install

$(GMP_DIR)/Makefile: $(GMP_DIR)
	cd $< && sed -i.bak -e 's/^# Only do the GMP_ASM .*/gmp_asm_syntax_testing=no/' configure.ac && autoconf
	cd $< && emcmake ./configure ABI=standard CFLAGS="-O3 --llvm-lto 1" --prefix=`pwd`/../installroot/ ABI=standard --host=none --disable-assembly --disable-shared || cat config.log

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
