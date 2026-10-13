// Dart imports:
import 'dart:math' as math;

/// 版本号比较工具
///
/// 提供点分十进制版本号（如 `1.2.0`）的通用三态比较与「服务端是否更新」
/// 便捷判断。吸收自 saas_pos 收银端同名能力并按本库基线重写：
/// 非法输入抛 [ArgumentError]（原实现静默返回 `false`），仅**纯数字段**
/// 参与数值比较——非纯数字段整段视为 `0`（不解析预发布标签，
/// `1.0.0-beta` 与 `1.0.0` 视为相等；带符号段 `-1` / `+1` 亦视为 `0`），
/// 纯数字但溢出 int 范围的段同样视为 `0`。
class VersionUtils {
  VersionUtils._();

  /// 纯数字段判定（严格：带符号 / 含杂段一律视为非数字）。
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  /// 比较两个版本号，返回 `a` 相对 `b` 的顺序：
  /// `-1`（a 更旧）、`0`（相等）、`1`（a 更新）。
  ///
  /// 规则：
  /// - 自动剥离 `v` / `V` 前缀并 trim 空白（剥前缀后为空同样抛错）；
  /// - 逐段按**数值**比较（`1.10.0 > 1.9.0`，非字典序）；
  /// - 剥离尾部全零段后按长度差兜底（尾零等价：`1.0 == 1`；缺段视为更小：
  ///   `1.0 < 1.0.1`）；
  /// - 非纯数字段整段视为 `0`，纯数字段溢出 int 范围亦视为 `0`
  ///   （不解析预发布标签，见类注释）；
  /// - [a] 或 [b] 为空（trim 后）抛 [ArgumentError]。
  static int compare(String a, String b) {
    final sa = _normalize(a, 'a');
    final sb = _normalize(b, 'b');
    final segsA = sa.split('.');
    final segsB = sb.split('.');
    final common = math.min(segsA.length, segsB.length);
    for (var i = 0; i < common; i++) {
      final c = _segmentValue(segsA[i]).compareTo(_segmentValue(segsB[i]));
      if (c != 0) {
        return c;
      }
    }
    // 尾零段等价（1.0 == 1.0.0 == 1）：剥离尾部全零段后长度才有比较意义
    while (segsA.length > 1 && _segmentValue(segsA.last) == 0) {
      segsA.removeLast();
    }
    while (segsB.length > 1 && _segmentValue(segsB.last) == 0) {
      segsB.removeLast();
    }
    return segsA.length.compareTo(segsB.length);
  }

  /// 判断服务端版本 [serverVersion] 是否高于客户端版本 [clientVersion]。
  ///
  /// 语义与 [compare] 一致：`compare(server, client) > 0` 时返回 `true`。
  static bool isNewer({
    required String serverVersion,
    required String clientVersion,
  }) {
    return compare(serverVersion, clientVersion) > 0;
  }

  /// 单段取值：仅纯数字段参与数值比较；非纯数字段 / 溢出段统一视为 `0`。
  static int _segmentValue(String seg) {
    if (!_digitsOnly.hasMatch(seg)) return 0;
    return int.tryParse(seg) ?? 0;
  }

  /// 归一化：trim → 剥离 `v`/`V` 前缀（含单字符 `v` 本身）→ 空值校验。
  static String _normalize(String raw, String argName) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    if (s.isEmpty) {
      throw ArgumentError.value(raw, argName, 'version must not be empty');
    }
    return s;
  }
}
