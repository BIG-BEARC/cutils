/// 金额展示的单位样式，用于 [MoneyUtils.withUnit] / [MoneyUtils.changeF2YWithUnit]。
enum MoneyUnit {
  /// 不带单位（`6.00`）。
  NORMAL, // 6.00

  /// 人民币符号前缀（`¥6.00`）。
  YUAN, // ¥6.00

  /// 中文「元」后缀（`6.00元`）。
  YUAN_ZH, // 6.00元

  /// 美元符号前缀（`$6.00`）。
  DOLLAR, // $6.00
}

/// 金额展示的小数格式策略，用于 [MoneyUtils.changeF2Y]。
enum MoneyFormat {
  /// 保留两位小数（`6.00`）。
  NORMAL, //保留两位小数(6.00元)

  /// 去掉末尾 0（`6.00` → `6`，`6.60` → `6.6`）。
  END_INTEGER, //去掉末尾'0'(6.00元 -> 6元, 6.60元 -> 6.6元)

  /// 整元去掉小数部分（`6.00` → `6`），非整元仍保留两位小数。
  YUAN_INTEGER, //整元(6.00元 -> 6元)
}
