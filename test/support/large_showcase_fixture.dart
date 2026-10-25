import 'dart:io';
import 'dart:typed_data';

/// A genuine decodable H.264 fixture with mdat before moov. Add unreferenced
/// mdat padding after its real samples: chunk offsets and all sample bytes stay
/// unchanged. Exercises disk-backed multipart uploads without a 3MB binary in Git.
Uint8List largeShowcaseBytes() {
  final input = File(
    'test/fixtures/clinic_media/android_layout_showcase.mp4',
  ).readAsBytesSync();
  final data = ByteData.sublistView(input);
  var offset = 0;
  while (offset + 8 <= input.length) {
    final size = data.getUint32(offset);
    final type = String.fromCharCodes(input.sublist(offset + 4, offset + 8));
    if (size < 8 || offset + size > input.length) {
      throw StateError('Invalid MP4 fixture');
    }
    if (type == 'mdat') {
      const padding = 3 * 1024 * 1024;
      final output = Uint8List(input.length + padding);
      output.setRange(0, offset + size, input);
      output.setRange(
        offset + size + padding,
        output.length,
        input.sublist(offset + size),
      );
      ByteData.sublistView(output).setUint32(offset, size + padding);
      return output;
    }
    offset += size;
  }
  throw StateError('Missing mdat fixture');
}
