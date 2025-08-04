import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// 加密和解密工具类
final encryptUtils = EncryptUtils();

class EncryptUtils {
  EncryptUtils._();

  static final EncryptUtils _instance = EncryptUtils._();

  factory EncryptUtils() => _instance;

  /// md5 加密字符串
  String encodeMd5(String data) {
    var content = Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// md5 加密file
  String encodeMd5File(File file) {
    var readAsStringSync = file.readAsStringSync();
    var content = Utf8Encoder().convert(readAsStringSync);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// 异或对称加密
  String xorCode(String res, String key) {
    List<String> keyList = key.split(',');
    List<int> codeUnits = res.codeUnits;
    List<int> codes = [];
    for (int i = 0, length = codeUnits.length; i < length; i++) {
      int code = codeUnits[i] ^ int.parse(keyList[i % keyList.length]);
      codes.add(code);
    }
    return String.fromCharCodes(codes);
  }

  /// 异或对称 Base64 加密
  String xorBase64Encode(String res, String key) {
    String encode = xorCode(res, key);
    encode = encodeBase64(encode);
    return encode;
  }

  /// 异或对称 Base64 解密
  String xorBase64Decode(String res, String key) {
    String encode = decodeBase64(res);
    encode = xorCode(encode, key);
    return encode;
  }

  /// Base64加密字符串
  String encodeBase64(String data) {
    var content = utf8.encode(data);
    var digest = base64Encode(content);
    return digest;
  }

  /// Base64解密字符串
  String decodeBase64(String data) {
    List<int> bytes = base64Decode(data);
    String result = utf8.decode(bytes);
    return result;
  }
}
