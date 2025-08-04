// ignore_for_file: non_constant_identifier_names
/// * @Author: chuxiong
/// * @Created at: 23-07-2025 16:56
/// * @Email:
/// * description 一些常用格式参照。如果下面格式不够，你可以自定义
// ignore: constant_identifier_names
class DateFormats {
  static final String FULL = 'yyyy-MM-dd HH:mm:ss';
  static final String Y_M_D_H_M = 'yyyy-MM-dd HH:mm';
  static final String Y_M_D = 'yyyy-MM-dd';
  static final String Y_M = 'yyyy-MM';
  static final String M_D = 'MM-dd';
  static final String M_D_H_M = 'MM-dd HH:mm';
  static final String H_M_S = 'HH:mm:ss';
  static final String H_M = 'HH:mm';

  static final String ZH_FULL = 'yyyy年MM月dd日 HH时mm分ss秒';
  static final String ZH_Y_M_D_H_M = 'yyyy年MM月dd日 HH时mm分';
  static final String ZH_Y_M_D = 'yyyy年MM月dd日';
  static final String ZH_Y_M = 'yyyy年MM月';
  static final String ZH_M_D = 'MM月dd日';
  static final String ZH_M_D_H_M = 'MM月dd日 HH时mm分';
  static final String ZH_H_M_S = 'HH时mm分ss秒';
  static final String ZH_H_M = 'HH时mm分';

  static const String PARAM_FULL = 'yyyy/MM/dd HH:mm:ss';
  static const String PARAM_Y_M_D_H_M = 'yyyy/MM/dd HH:mm';
  static const String PARAM_Y_M_D = "yyyy/MM/dd";
  static const String PARAM_Y_M = 'yyyy/MM';
  static final String PARAM_M_D = 'MM/dd';
  static final String PARAM_M_D_H_M = 'MM/dd HH:mm';

}
/// month->days.
Map<int, int> MONTH_DAY = {
  1: 31,
  2: 28,
  3: 31,
  4: 30,
  5: 31,
  6: 30,
  7: 31,
  8: 31,
  9: 30,
  10: 31,
  11: 30,
  12: 31,
};