import 'dart:io';

import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:zstd_ffi/zstd_ffi.dart';

void main() {
  test('library function', () {
    expect(versionNumber(), equals(10406));
    expect(versionString(), equals('1.4.6'));
  });

  test('compress and decompress', () {
    Uint8List src = Uint8List.fromList([104, 101, 108, 108, 111, 32, 122, 115, 116, 100]);
    final dst = compress(src, level: 1);
    print('${dst.length} ${dst}');
    expect(dst, isNotEmpty);

    final plain = decompress(dst);
    expect(plain, isNotEmpty);
    expect(plain, equals(src));
  });

  test('decompress', () {
    Uint8List src = File('README.md.zst').readAsBytesSync();

    final plain = decompress(src);

    File('README.md').writeAsBytesSync(plain);

    expect(plain, isNotEmpty);
  });
}
