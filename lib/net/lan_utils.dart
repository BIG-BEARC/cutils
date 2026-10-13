// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart' show visibleForTesting;

/// 局域网 IPv4 获取工具
///
/// 返回当前设备的首选局域网 IPv4：优先常见私网段
/// （192.168.x ＞ 10.x ＞ 172.16-31.x ＞ 其它公网地址），排除环回与
/// APIPA（169.254.x.x），虚拟网卡（Docker / VPN / 虚拟化平台等）仅降权
/// 垫底、不排除。能力吸收自 saas_pos 收银端同名实现并按本库基线重写。
///
/// 纯 `dart:io` 实现，无第三方依赖，可用于 Android / iOS / macOS /
/// Windows / Linux（web 不可用，`dart:io` 限制）。
///
/// **best-effort 说明**：虚拟网卡识别是接口名子串启发式
/// （`_virtualNameMarkers`），无法覆盖所有形态；多网卡设备上启发式结果
/// 未必符合预期，调用方不应将其用于安全决策。
class LanUtils {
  LanUtils._();

  /// 获取当前设备首选局域网 IPv4（完整点分四段地址）。
  ///
  /// 选择规则见类注释；接口枚举失败或无任何可用 IPv4 地址时返回 `null`
  /// （无网环境是合法结果，不抛错）。POS「用户只填第四段」类业务场景可
  /// 自行对返回值按 `.` 拆分取前三段。
  static Future<String?> getPreferredLanIpv4() async {
    try {
      final interfaces = await NetworkInterface.list(includeLoopback: false);
      final snapshots = <({String name, List<String> ipv4})>[
        for (final ni in interfaces)
          (
            name: ni.name,
            ipv4: [
              for (final addr in ni.addresses)
                if (addr.type == InternetAddressType.IPv4) addr.address,
            ],
          ),
      ];
      return pickBestLanIpv4(snapshots);
    } catch (_) {
      return null;
    }
  }

  /// 从接口快照中选出首选 IPv4 地址（纯函数，供 [getPreferredLanIpv4]
  /// 与测试共用）。
  ///
  /// [interfaces] 的每项为「接口名 + 该接口的 IPv4 地址串列表」；列表内
  /// 同优先级时保持先出现者；无任何可用地址时返回 `null`。
  @visibleForTesting
  static String? pickBestLanIpv4(
    List<({String name, List<String> ipv4})> interfaces,
  ) {
    String? best;
    var bestRank = -1;
    for (final ni in interfaces) {
      for (final addr in ni.ipv4) {
        if (!_isEligible(addr)) {
          continue;
        }
        final rank = _rank(ni.name, addr);
        if (rank > bestRank) {
          bestRank = rank;
          best = addr;
        }
      }
    }
    return best;
  }

  /// 地址级资格过滤：点分四段、非环回（127/8）、非 APIPA（169.254/16）。
  static bool _isEligible(String addr) {
    final parts = addr.split('.');
    if (parts.length != 4) {
      return false;
    }
    final o0 = int.tryParse(parts[0]);
    final o1 = int.tryParse(parts[1]);
    if (o0 == null || o1 == null) {
      return false;
    }
    if (o0 == 127 || (o0 == 169 && o1 == 254)) {
      return false;
    }
    return true;
  }

  /// 私网优先级，数值越大越优先；虚拟网卡降权到 0（垫底不排除）。
  static int _rank(String name, String addr) {
    if (_isVirtualInterface(name)) {
      return 0;
    }
    final parts = addr.split('.');
    final o0 = int.parse(parts[0]);
    final o1 = int.parse(parts[1]);
    if (o0 == 192 && o1 == 168) {
      return 4;
    }
    if (o0 == 10) {
      return 3;
    }
    if (o0 == 172 && o1 >= 16 && o1 <= 31) {
      return 2;
    }
    return 1;
  }

  /// 接口名子串启发式：命中即视为虚拟网卡（Docker / VPN / 虚拟化平台）。
  static const List<String> _virtualNameMarkers = [
    'docker',
    'veth',
    'br-',
    'tun',
    'tap',
    'vmware',
    'vnic',
    'hyper-v',
    'vethernet',
    'vpn',
    'utun',
  ];

  static bool _isVirtualInterface(String name) {
    final lower = name.toLowerCase();
    return _virtualNameMarkers.any(lower.contains);
  }
}
