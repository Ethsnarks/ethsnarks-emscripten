# ethSNARKs for Emscripten / WebAssembly

This project is part of [ethsnarks](http://github.com/HarryR/ethsnarks), but targets WebAssembly by building ethsnarks and its dependencies using the [Emscripten](http://kripken.github.io/emscripten-site/index.html) compiler.

**WARNING: this is a work-in-progress, may be slow and isn't generally usable yet, but watch this space!**

## Building

The Emscripten SDK is included as a git submodule; the compiler must be downloaded, activated then added to the environment before performing the build:

```
./emsdk/emsdk install latest
./emsdk/emsdk activate latest
source emsdk/emsdk_env.sh
```

Then run `make`
