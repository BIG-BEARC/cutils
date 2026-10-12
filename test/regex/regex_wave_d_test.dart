// Wave D — absorb the file-type / hash-format / hexadecimal validator
// family into `regex/` (15 constants + 15 methods).
//
// Strict TDD: this suite was written first and observed to fail with
// compile errors (methods not defined) before the constants and methods
// were added. Patterns absorbed from YCFlutterUtils were normalized:
// anchored at both ends and with the extension dot escaped (the source
// patterns like `.(jpeg|jpg)$` also matched `foojpeg`), and the SHA1 /
// SHA256 alternations were re-anchored (the source patterns reported a
// match for any string *containing* 40/64 hex chars). `REGEX_HEXADECIMAL`
// is defined as a plain hex-string pattern (`^[0-9a-fA-F]+$`), which is
// distinct from `isHexColor` (#-prefixed color format). All hash methods
// validate FORMAT only (length + hex charset) — they are not checksums.

import 'package:cutils/regex/regex_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('D1 file-type methods (extension heuristic, anchored)', () {
    test('isImage accepts common image extensions', () {
      expect(RegexUtils.isImage('photo.jpeg'), isTrue);
      expect(RegexUtils.isImage('photo.jpg'), isTrue);
      expect(RegexUtils.isImage('photo.PNG'), isTrue);
      expect(RegexUtils.isImage('photo.bmp'), isTrue);
    });

    test('isImage rejects non-image and unanchored lookalikes', () {
      expect(RegexUtils.isImage('photo.mp3'), isFalse);
      expect(RegexUtils.isImage('photo.jpegx'), isFalse);
      expect(RegexUtils.isImage('jpeg'), isFalse);
      expect(RegexUtils.isImage('photo.jpeg '), isFalse);
    });

    test('isAudio / isVideo accept their extension sets', () {
      expect(RegexUtils.isAudio('song.mp3'), isTrue);
      expect(RegexUtils.isAudio('song.OGG'), isTrue);
      expect(RegexUtils.isAudio('song.mp4'), isFalse);
      expect(RegexUtils.isVideo('movie.mp4'), isTrue);
      expect(RegexUtils.isVideo('clip.3gp'), isTrue);
      expect(RegexUtils.isVideo('movie.mp3'), isFalse);
    });

    test('isTxt / isVector / isPdf / isApk / isHtml', () {
      expect(RegexUtils.isTxt('readme.txt'), isTrue);
      expect(RegexUtils.isTxt('readme.txtx'), isFalse);
      expect(RegexUtils.isVector('icon.svg'), isTrue);
      expect(RegexUtils.isVector('icon.png'), isFalse);
      expect(RegexUtils.isPdf('doc.pdf'), isTrue);
      expect(RegexUtils.isApk('app.apk'), isTrue);
      expect(RegexUtils.isApk('app.apk.1'), isFalse);
      expect(RegexUtils.isHtml('index.html'), isTrue);
      expect(RegexUtils.isHtml('index.htm'), isFalse);
    });

    test('isDoc / isExcel / isPpt with and without the x suffix', () {
      expect(RegexUtils.isDoc('a.doc'), isTrue);
      expect(RegexUtils.isDoc('a.docx'), isTrue);
      expect(RegexUtils.isDoc('a.xls'), isFalse);
      expect(RegexUtils.isExcel('a.xls'), isTrue);
      expect(RegexUtils.isExcel('a.XLSX'), isTrue);
      expect(RegexUtils.isExcel('a.doc'), isFalse);
      expect(RegexUtils.isPpt('a.ppt'), isTrue);
      expect(RegexUtils.isPpt('a.pptx'), isTrue);
    });

    test('null / empty input returns false across the family', () {
      expect(RegexUtils.isImage(null), isFalse);
      expect(RegexUtils.isImage(''), isFalse);
      expect(RegexUtils.isApk(null), isFalse);
      expect(RegexUtils.isApk(''), isFalse);
    });
  });

  group('D2 hash-format methods (format only, not checksums)', () {
    test('isMD5 accepts 32 hex chars in either case', () {
      expect(RegexUtils.isMD5('900150983cd24fb0d6963f7d28e17f72'), isTrue);
      expect(RegexUtils.isMD5('900150983CD24FB0D6963F7D28E17F72'), isTrue);
    });

    test('isMD5 rejects wrong length, bad charset, embedded input', () {
      expect(RegexUtils.isMD5('900150983cd24fb0d6963f7d28e17f7'), isFalse);
      expect(
        RegexUtils.isMD5('900150983cd24fb0d6963f7d28e17f722'),
        isFalse,
      );
      expect(RegexUtils.isMD5('g00150983cd24fb0d6963f7d28e17f72'), isFalse);
      expect(
        RegexUtils.isMD5('x900150983cd24fb0d6963f7d28e17f72x'),
        isFalse,
      );
    });

    test('isSHA1 accepts plain 40-hex and colon-separated forms', () {
      expect(
        RegexUtils.isSHA1('a9993e364706816aba3e25717850c26c9cd0d89d'),
        isTrue,
      );
      expect(
        RegexUtils.isSHA1(
          'a9:99:3e:36:47:06:81:6a:ba:3e:25:71:78:50:c2:6c:9c:d0:d8:9d',
        ),
        isTrue,
      );
    });

    test('isSHA1 rejects 39/41 hex and embedded input (anchored)', () {
      expect(RegexUtils.isSHA1('a9993e364706816aba3e25717850c26c9cd0d89'),
          isFalse);
      expect(RegexUtils.isSHA1('a9993e364706816aba3e25717850c26c9cd0d89d0'),
          isFalse);
      expect(
        RegexUtils.isSHA1('zzza9993e364706816aba3e25717850c26c9cd0d89dzzz'),
        isFalse,
      );
    });

    test('isSHA256 accepts plain 64-hex and colon-separated forms', () {
      expect(
        RegexUtils.isSHA256(
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        ),
        isTrue,
      );
      expect(
        RegexUtils.isSHA256(
          'ba:78:16:bf:8f:01:cf:ea:41:41:40:de:5d:ae:22:23:b0:03:61:a3'
          ':96:17:7a:9c:b4:10:ff:61:f2:00:15:ad',
        ),
        isTrue,
      );
    });

    test('isSHA256 rejects 63 hex and embedded input (anchored)', () {
      expect(
        RegexUtils.isSHA256(
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015a',
        ),
        isFalse,
      );
      expect(
        RegexUtils.isSHA256(
          'xba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015adx',
        ),
        isFalse,
      );
    });

    test('null / empty input returns false', () {
      expect(RegexUtils.isMD5(null), isFalse);
      expect(RegexUtils.isMD5(''), isFalse);
      expect(RegexUtils.isSHA1(null), isFalse);
      expect(RegexUtils.isSHA256(''), isFalse);
    });
  });

  group('D3 isHexadecimal (plain hex string, distinct from isHexColor)', () {
    test('accepts hex strings in either case', () {
      expect(RegexUtils.isHexadecimal('DEADBEEF'), isTrue);
      expect(RegexUtils.isHexadecimal('deadbeef'), isTrue);
      expect(RegexUtils.isHexadecimal('0a1B'), isTrue);
    });

    test('rejects prefix, bad charset, empty and null', () {
      expect(RegexUtils.isHexadecimal('0x1A'), isFalse);
      expect(RegexUtils.isHexadecimal('12g4'), isFalse);
      expect(RegexUtils.isHexadecimal(''), isFalse);
      expect(RegexUtils.isHexadecimal(null), isFalse);
    });
  });
}
