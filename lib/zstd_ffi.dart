import 'package:zstd_ffi/_zstd.dart';

import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'package:zstd_ffi/uint8_list_utils.dart';

class Strategy {
  static const int fast = 1;
  static const int dfast = 2;
  static const int greedy = 3;
  static const int lazy = 4;
  static const int lazy2 = 5;
  static const int btlazy2 = 6;
  static const int btopt = 7;
  static const int btultra = 8;
  static const int btultra2 = 9;
}

class Level {
  static const int levelMin = 1;
  static const int levelDefault = 3;
  static const int levelMax = 22;
}

String _getPath() {
  var path = 'libzstd.so';
  if (Platform.isMacOS) {
    path = 'libzstd.dylib';
  }
  if (Platform.isWindows) {
    path = 'zstd.dll';
  }
  return path;
}

ZStd _lib;

ffi.DynamicLibrary _openLibrary() {
  return ffi.DynamicLibrary.open(_getPath());
}

///
class ZStdError extends Error {
  ZStdError({this.code, this.name});

  final int code;
  final String name;

  factory ZStdError.fromCode(int code) {
    return ZStdError(code: code, name: errorName(code));
  }

  String toString() {
    return 'ZStdError($code): $name';
  }
}

/// Version string of library, like '1.4.6'
String versionString() {
  _lib ??= ZStd(_openLibrary());

  return Utf8.fromUtf8(_lib.ZSTD_versionString().cast());
}

/// Version number of library, like 10406
int versionNumber() {
  _lib ??= ZStd(_openLibrary());

  return _lib.ZSTD_versionNumber();
}

/// Error
String errorName(int code) {
  _lib ??= ZStd(_openLibrary());
  return Utf8.fromUtf8(_lib.ZSTD_getErrorName(code).cast());
}

/// Simple compression and decompression
///
/// Compresses `src` content as a single zstd compressed frame into already allocated `dst`.
/// [ZStdError] throwed if failed. [level] is compression ratio 1-19, default 3
Uint8List compress(Uint8List src, {int level: Level.levelDefault}) {
  _lib ??= ZStd(_openLibrary());

  final csrc = Uint8ArrayUtils.toPointer(src);

  final dstlen = _lib.ZSTD_compressBound(src.length);
  final dst = allocate<ffi.Uint8>(count: dstlen);

  try {
    int reslen = _lib.ZSTD_compress(dst.cast(), dstlen, csrc.cast(), src.length, level);
    if (_lib.ZSTD_isError(reslen) > 0) {
      throw ZStdError.fromCode(reslen);
    }

    return Uint8ArrayUtils.fromPointer(dst, reslen);
  } finally {
    free(dst);
    free(csrc);
  }
}

///
/// Throw [ZStdError] if failed.
Uint8List decompress(Uint8List src) {
  _lib ??= ZStd(_openLibrary());

  final csrc = Uint8ArrayUtils.toPointer(src);

  final dstlen = _lib.ZSTD_getDecompressedSize(csrc.cast(), src.length);
  final dst = allocate<ffi.Uint8>(count: dstlen);

  try {
    int reslen = _lib.ZSTD_decompress(dst.cast(), dstlen, csrc.cast(), src.length);
    if (_lib.ZSTD_isError(reslen) > 0) {
      throw ZStdError.fromCode(reslen);
    }

    return Uint8ArrayUtils.fromPointer(dst, reslen);
  } finally {
    free(dst);
    free(csrc);
  }
}

///
///
class CompressionDict {
  CompressionDict({this.cdict});

  ffi.Pointer<ZSTD_CDict_s> cdict;

  factory CompressionDict.create(Uint8List dict, {int level: Level.levelDefault}) {
    final csrc = Uint8ArrayUtils.toPointer(dict);

    try {
      return CompressionDict(cdict: _lib.ZSTD_createCDict(csrc.cast(), dict.length, level));
    } finally {
      free(csrc);
    }
  }

  void dispose() {
    _lib.ZSTD_freeCDict(cdict);
    cdict = null;
  }
}

/// Compression context
/// When compressing many times,
/// it is recommended to allocate a context just once,
/// and re-use it for each successive compression operation.
/// This will make workload friendlier for system's memory.
/// Note : re-using context is just a speed / resource optimization.
///        It doesn't change the compression ratio, which remains identical.
/// Note 2 : In multi-threaded environments,
///        use one different context per thread for parallel execution.
///
///
/// Example:
///   final ctx = CompressionContext.create();
///   try {
///     ctx.compress(...);
///   } finally {
///     ctx.dispose(); // release
///   }
///
class CompressionContext {
  CompressionContext({this.ctx});

  ffi.Pointer<ZSTD_CCtx_s> ctx;

  factory CompressionContext.create() {
    _lib ??= ZStd(_openLibrary());

    return CompressionContext(ctx: _lib.ZSTD_createCCtx());
  }

  Uint8List compress(
    Uint8List src, {
    int level: Level.levelDefault,
    CompressionDict dict,
  }) {
    final csrc = Uint8ArrayUtils.toPointer(src);

    final dstlen = _lib.ZSTD_compressBound(src.length);
    final dst = allocate<ffi.Uint8>(count: dstlen);

    try {
      int reslen;

      if (dict != null) {
        reslen = _lib.ZSTD_compress_usingCDict(ctx, dst.cast(), dstlen, csrc.cast(), src.length, dict.cdict);
      } else {
        reslen = _lib.ZSTD_compressCCtx(ctx, dst.cast(), dstlen, csrc.cast(), src.length, level);
      }

      if (_lib.ZSTD_isError(reslen) > 0) {
        throw ZStdError.fromCode(reslen);
      }

      return Uint8ArrayUtils.fromPointer(dst, reslen);
    } finally {
      free(dst);
      free(csrc);
    }
  }

  void dispose() {
    _lib.ZSTD_freeCCtx(ctx);
    ctx = null;
  }
}
