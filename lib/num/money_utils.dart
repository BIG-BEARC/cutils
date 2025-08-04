
import 'money_unit.dart';
import 'num_utils.dart';

/// * @Author: chuxiong
/// * @Created at: 23-07-2025 17:29
/// * @Email:
/// * description
class MoneyUtils {
  MoneyUtils._();

  static final _ins = MoneyUtils._();

  factory MoneyUtils() => _ins;
  static const String YUAN = '¥';
  static const String YUAN_ZH = '元';
  static const String DOLLAR = '\$';

  /// fen to yuan, format output.
  /// 分 转 元, format格式输出.
  String changeF2Y(int amount, {MoneyFormat format = MoneyFormat.NORMAL}) {
    String moneyTxt;
    double yuan = numUtils.divideNum(amount, 100);
    switch (format) {
      case MoneyFormat.NORMAL:
        moneyTxt = yuan.toStringAsFixed(2);
        break;
      case MoneyFormat.END_INTEGER:
        if (amount % 100 == 0) {
          moneyTxt = yuan.toInt().toString();
        } else if (amount % 10 == 0) {
          moneyTxt = yuan.toStringAsFixed(1);
        } else {
          moneyTxt = yuan.toStringAsFixed(2);
        }
        break;
      case MoneyFormat.YUAN_INTEGER:
        moneyTxt = (amount % 100 == 0) ? yuan.toInt().toString() : yuan.toStringAsFixed(2);
        break;
    }
    return moneyTxt;
  }

  /// fen str to yuan, format & unit  output.
  /// 分字符串 转 元, format 与 unit 格式 输出.
  String changeFStr2YWithUnit(String amountStr, {MoneyFormat format = MoneyFormat.NORMAL, MoneyUnit unit = MoneyUnit.NORMAL}) {
    int amount = int.parse(amountStr);
    return changeF2YWithUnit(amount, format: format, unit: unit);
  }

  /// fen to yuan, format & unit  output.
  /// 分 转 元, format 与 unit 格式 输出.
  String changeF2YWithUnit(int amount, {MoneyFormat format = MoneyFormat.NORMAL, MoneyUnit unit = MoneyUnit.NORMAL}) {
    return withUnit(changeF2Y(amount, format: format), unit);
  }


  /// with unit.
  /// 拼接单位.
  String withUnit(String moneyTxt, MoneyUnit unit) {
    switch (unit) {
      case MoneyUnit.YUAN:
        moneyTxt = YUAN + moneyTxt;
        break;
      case MoneyUnit.YUAN_ZH:
        moneyTxt = moneyTxt + YUAN_ZH;
        break;
      case MoneyUnit.DOLLAR:
        moneyTxt = DOLLAR + moneyTxt;
        break;
      default:
        break;
    }
    return moneyTxt;
  }
}
