[Zstandard library(zstd)](https://github.com/facebook/zstd) ffi binding for Dart

![build](https://github.com/finlutter/zstd_ffi/workflows/CI/badge.svg)


# Features
- [x] Simple compress/decrompress
- [] Dict
- [] Context
- [] Add Linux/Windows library

# Upgrade zstd
```shell
# replace lib/zstd.h

pub run ffigen

pub run test

pub publish
```
