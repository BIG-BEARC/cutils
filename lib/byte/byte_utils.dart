import 'dart:convert';
import 'dart:typed_data';

/// * @Author: chuxiong
/// * @Created at: 12-10-2026
/// * description 字节工具模块：可读字符串 ↔ Uint8List、base64 互转、
///   字节数组窗口操作（截取 / 拼接 / 插入 / 删除）与 16 / 32 位整数的
///   字节拆装。面向协议 / 报文解析场景。
///   依赖：仅 `dart:typed_data` 与 `dart:convert`，零平台 / 第三方依赖。

/// 可读字符串的进制（[ByteUtils.fromReadable] / [ByteUtils.toReadable]）。
enum Radix {
  /// 十六进制，每字节两位（`ff`），token 允许 `0x` 前缀。
  hex,

  /// 十进制（`255`）。
  dec,
}

/// 字节工具类（全静态）。
///
/// 所有窗口操作（extract / combine / insert / remove）均返回新数组，
/// 不修改入参；越界的 index / length 一律钳制到有效范围而非抛错。
class ByteUtils {
  ByteUtils._();

  /// hex 模式下合法 token：可选 `0x` 前缀 + 至少一位十六进制数字。
  static final RegExp _hexTokenRegExp = RegExp(r'^(?:0[xX])?[0-9a-fA-F]+$');

  /// 可读字符串 → 字节数组。
  ///
  /// token 以空白或逗号分隔（`'01 02, ff 0x10'`）；hex 模式下 token 可带
  /// `0x` 前缀、大小写均可，且不接受符号前缀；dec 模式接受可选 `+`/`-`
  /// 前缀（`'+255'` 可解析，负值随后被值域校验拒绝）。空 / 全空白输入
  /// 返回空数组。
  ///
  /// 值域校验：hex token 超 `0xFF`、dec token 超出 `0..255`、或出现无法
  /// 解析的 token 时抛 [ArgumentError]——不做静默截断。
  static Uint8List fromReadable(String readable, {Radix radix = Radix.hex}) {
    final tokens = readable
        .split(RegExp(r'[\s,]+'))
        .where((token) => token.isNotEmpty)
        .toList();
    final result = Uint8List(tokens.length);
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final value = radix == Radix.hex
          ? (_hexTokenRegExp.hasMatch(token)
              ? int.tryParse(token.replaceFirst(RegExp(r'^0[xX]'), ''),
                  radix: 16)
              : null)
          : int.tryParse(token, radix: 10);
      if (value == null || value < 0 || value > 0xFF) {
        throw ArgumentError(
          'fromReadable: token "$token" is not a valid $radix byte value',
        );
      }
      result[i] = value;
    }
    return result;
  }

  /// 字节数组 → 可读字符串。
  ///
  /// hex 模式每字节输出两位小写（`[1,255]` → `'01 ff'`），dec 模式输出
  /// 十进制；分隔符默认单个空格。
  static String toReadable(
    Uint8List bytes, {
    Radix radix = Radix.hex,
    String separator = ' ',
  }) {
    return bytes
        .map((b) => radix == Radix.hex
            ? b.toRadixString(16).padLeft(2, '0')
            : b.toString())
        .join(separator);
  }

  /// 字节数组 → base64 字符串。
  static String toBase64(Uint8List bytes) => base64.encode(bytes);

  /// base64 字符串 → 字节数组（非法输入由 `dart:convert` 抛
  /// [FormatException]）。
  static Uint8List fromBase64(String encoded) => base64.decode(encoded);

  /// 深拷贝字节数组。
  static Uint8List clone(Uint8List bytes) => Uint8List.fromList(bytes);

  /// 判断两个字节数组长度与逐字节内容是否一致。
  static bool same(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 从 [origin] 的 [indexStart] 起截取 [length] 字节。
  ///
  /// [indexStart] 为负按 0 处理；窗口超出尾部按尾部截断；完全越界或
  /// [length] 非正返回空数组。
  static Uint8List extract({
    required Uint8List origin,
    required int indexStart,
    required int length,
  }) {
    if (origin.isEmpty || length <= 0) return Uint8List(0);
    final start = indexStart.clamp(0, origin.length);
    final end = (start + length).clamp(0, origin.length);
    return Uint8List.fromList(origin.sublist(start, end));
  }

  /// 拼接两个字节数组（返回新数组，不修改入参）。
  static Uint8List combine({required Uint8List a, required Uint8List b}) {
    return Uint8List.fromList([...a, ...b]);
  }

  /// 在 [origin] 的 [indexStart] 处插入 [arrayInsert]。
  ///
  /// [indexStart] 钳制到 `0..origin.length`（越界分别按头插 / 尾插处理）。
  static Uint8List insert({
    required Uint8List origin,
    required int indexStart,
    required Uint8List arrayInsert,
  }) {
    final at = indexStart.clamp(0, origin.length);
    return Uint8List.fromList([
      ...origin.sublist(0, at),
      ...arrayInsert,
      ...origin.sublist(at),
    ]);
  }

  /// 从 [origin] 的 [indexStart] 起删除 [lengthRemove] 字节。
  ///
  /// [indexStart] / [lengthRemove] 越界按边界截断；[lengthRemove] 非正
  /// 返回原数组的拷贝。
  static Uint8List remove({
    required Uint8List origin,
    required int indexStart,
    required int lengthRemove,
  }) {
    if (lengthRemove <= 0) return Uint8List.fromList(origin);
    final start = indexStart.clamp(0, origin.length);
    final end = (start + lengthRemove).clamp(0, origin.length);
    return Uint8List.fromList(
      [...origin.sublist(0, start), ...origin.sublist(end)],
    );
  }
}

/// 16 位字（word）：高低字节拆装。
///
/// 值对象，构造时校验值域（`0..0xFFFF`，越界抛 [ArgumentError]）；
/// 序列化端序在 [bytes] 处显式指定，默认 little-endian。
class ByteWord {
  /// 0..0xFFFF。
  final int value;

  ByteWord(this.value) {
    if (value < 0 || value > 0xFFFF) {
      throw ArgumentError('ByteWord value must be in 0..0xFFFF (got: $value)');
    }
  }

  /// 高 8 位。
  int get high => (value >> 8) & 0xFF;

  /// 低 8 位。
  int get low => value & 0xFF;

  /// 按指定端序序列化为 2 字节。
  Uint8List bytes({Endian endian = Endian.little}) => endian == Endian.little
      ? Uint8List.fromList([low, high])
      : Uint8List.fromList([high, low]);

  @override
  String toString() => '0x${value.toRadixString(16).padLeft(4, '0')}';
}

/// 32 位双字（double word）：四字节拆装。
///
/// 值对象，构造时校验值域（`0..0xFFFFFFFF`，越界抛 [ArgumentError]）；
/// 序列化端序在 [bytes] 处显式指定，默认 little-endian。
class ByteDoubleWord {
  /// 0..0xFFFFFFFF。
  final int value;

  ByteDoubleWord(this.value) {
    if (value < 0 || value > 0xFFFFFFFF) {
      throw ArgumentError(
        'ByteDoubleWord value must be in 0..0xFFFFFFFF (got: $value)',
      );
    }
  }

  /// 按指定端序序列化为 4 字节。
  Uint8List bytes({Endian endian = Endian.little}) {
    final b0 = value & 0xFF;
    final b1 = (value >> 8) & 0xFF;
    final b2 = (value >> 16) & 0xFF;
    final b3 = (value >> 24) & 0xFF;
    return endian == Endian.little
        ? Uint8List.fromList([b0, b1, b2, b3])
        : Uint8List.fromList([b3, b2, b1, b0]);
  }

  @override
  String toString() => '0x${value.toRadixString(16).padLeft(8, '0')}';
}
