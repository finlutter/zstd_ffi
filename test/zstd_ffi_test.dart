import 'dart:io';
import 'dart:convert';

import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:zstd_ffi/zstd_ffi.dart';
import 'package:zstd_ffi/_zstd.dart' show ZSTD_VERSION_STRING, ZSTD_VERSION_NUMBER;

void main() {
  test('library function', () {
    expect(versionNumber(), equals(ZSTD_VERSION_NUMBER));
    expect(versionString(), equals(ZSTD_VERSION_STRING));
  });

  test('compress and decompress', () {
    Uint8List src = utf8.encode('hello zstd');
    final dst = compress(src, level: 1);
    print('${dst.length} ${dst}');
    expect(dst, isNotEmpty);

    final plain = decompress(dst);
    expect(plain, isNotEmpty);
    expect(plain, equals(src));
  });

  test('decompress big file', () {
    Uint8List src = File('README.md.zst').readAsBytesSync();

    final plain = decompress(src);

    expect(plain.length, 1891);
  });

  test('bulk compress', () {
    final ctx = Context.create();

    Uint8List src = utf8.encode('hello zstd');

    var dst;

    try {
      dst = ctx.compress(src);
    } finally {
      ctx.dispose();
    }

    expect(dst, isNotEmpty);
    expect(dst.length, equals(19));

    final plain = decompress(dst);
    expect(plain, isNotEmpty);
    expect(plain, equals(src));
  });

  test('with dict', () {
    final ctx = Context.create();
    final dctx = DecContext.create();

    Uint8List src = utf8.encode('hello zstd');

    var dst;

    final dict = Dict.create(File('dict/k500-d8.dict').readAsBytesSync());
    final decdict = DecDict.create(File('dict/k500-d8.dict').readAsBytesSync());

    try {
      dst = ctx.compress(src, dict: dict);
    } finally {
      ctx.dispose();
      dict.dispose();
    }

    expect(dst, isNotEmpty);
    expect(dst.length, equals(23));

    final plain = dctx.decompress(dst, dict: decdict);
    expect(plain, isNotEmpty);
    expect(plain, equals(src));
  });
}
