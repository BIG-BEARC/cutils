import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// 加密和解密工具类
class CryptoUtils {
  CryptoUtils._();

  /// md5 加密字符串
  static String encodeMd5(String data) {
    var content = Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// md5 加密file
  ///
  /// 以原始字节计算哈希（不经过字符串解码），保证二进制文件（含非 UTF-8 字节）
  /// 的哈希正确，且不被 UTF-8 解码破坏。
  static String encodeMd5File(File file) {
    var bytes = file.readAsBytesSync();
    var digest = md5.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// 解析并校验 XOR 密钥。
  ///
  /// 非整数分段抛出 [ArgumentError]（带清晰信息），避免 [FormatException] 外泄。
  static List<int> _parseXorKey(String key) {
    List<String> keyList = key.split(',');
    List<int> keyInts = [];
    for (final seg in keyList) {
      final parsed = int.tryParse(seg);
      if (parsed == null) {
        throw ArgumentError.value(
            seg, 'key segment', 'not a valid integer (full key: "$key")');
      }
      keyInts.add(parsed);
    }
    if (keyInts.isEmpty) {
      throw ArgumentError.value(key, 'key', 'XOR key must not be empty');
    }
    return keyInts;
  }

  /// 对原始字节做 XOR（密钥循环使用；密钥截取低 8 位，保证结果仍是合法字节）。
  static List<int> _xorBytes(List<int> data, List<int> keyInts) {
    List<int> out = List<int>.filled(data.length, 0);
    for (int i = 0; i < data.length; i++) {
      out[i] = data[i] ^ (keyInts[i % keyInts.length] & 0xFF);
    }
    return out;
  }

  /// 异或对称加密（按 UTF-16 码元；自反）。
  ///
  /// 密钥为逗号分隔的整数；非整数分段抛出 [ArgumentError]。
  static String xorCode(String res, String key) {
    List<int> keyInts = _parseXorKey(key);
    List<int> codeUnits = res.codeUnits;
    List<int> codes = [];
    for (int i = 0, length = codeUnits.length; i < length; i++) {
      int code = codeUnits[i] ^ keyInts[i % keyInts.length];
      codes.add(code);
    }
    return String.fromCharCodes(codes);
  }

  /// 异或对称 Base64 加密
  ///
  /// 端到端在原始字节（UTF-8）上做 XOR，再 base64；不经过中间 String，避免 XOR
  /// 落入代理对区间（0xD800–0xDFFF）导致 [String.fromCharCodes] 产生非良构 UTF-16，
  /// 进而破坏 [xorBase64Decode] 往返。
  static String xorBase64Encode(String res, String key) {
    List<int> keyInts = _parseXorKey(key);
    List<int> data = utf8.encode(res);
    List<int> xored = _xorBytes(data, keyInts);
    return base64Encode(xored);
  }

  /// 异或对称 Base64 解密
  ///
  /// 与 [xorBase64Encode] 对称：base64 解码→字节级 XOR→UTF-8 解码。
  static String xorBase64Decode(String res, String key) {
    List<int> keyInts = _parseXorKey(key);
    List<int> bytes = base64Decode(res);
    List<int> xored = _xorBytes(bytes, keyInts);
    return utf8.decode(xored);
  }

  /// Base64加密字符串
  static String encodeBase64(String data) {
    var content = utf8.encode(data);
    var digest = base64Encode(content);
    return digest;
  }

  /// Base64解密字符串
  static String decodeBase64(String data) {
    List<int> bytes = base64Decode(data);
    String result = utf8.decode(bytes);
    return result;
  }
}
