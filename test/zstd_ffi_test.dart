import 'dart:io';
import 'dart:convert';

import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:zstd_ffi/zstd_ffi.dart';

void main() {
  test('library function', () {
    expect(versionNumber(), equals(10406));
    expect(versionString(), equals('1.4.6'));
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
    final ctx = CompressionContext.create();

    Uint8List src = utf8.encode('hello zstd');

    var dst;

    try {
      dst = ctx.compress(src);
    } finally {
      ctx.dispose();
    }

    expect(dst, isNotEmpty);

    final plain = decompress(dst);
    expect(plain, isNotEmpty);
    expect(plain, equals(src));
  });
}