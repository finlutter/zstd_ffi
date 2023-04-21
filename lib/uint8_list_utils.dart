import 'dart:ffi';

import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class Uint8ArrayUtils {
  static Uint8List fromPointer(Pointer<Uint8> ptr, int length,
      {bool copy = true}) {
    final view = ptr.asTypedList(length);
    final builder = BytesBuilder(copy: copy);
    builder.add(view);
    return builder.takeBytes();
  }

  static Pointer<Uint8> toPointer(Uint8List bytes) {
    final ptr = calloc<Uint8>(bytes.length);
    final byteList = ptr.asTypedList(bytes.length);
    byteList.setAll(0, bytes);
    return ptr.cast();
  }
}
