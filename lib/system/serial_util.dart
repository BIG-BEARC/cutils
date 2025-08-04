// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter_libserialport/flutter_libserialport.dart';
//
//
//
// class SerialUtil {
//   factory SerialUtil() => _ins ??= SerialUtil._();
//
//   SerialUtil._() {
//     _init();
//   }
//
//   static SerialUtil? _ins;
//
//   SerialPort? _port;
//
//   SerialPortConfig? _configs;
//
//   int retryCunt = 3;
//
//   StreamSubscription<ClearDigitalDisplayObject>? listen;
//
//   bool _init({String? tmpCom, String? tmpBaudRate}) {
//     if (!(Platform.isWindows || Platform.isAndroid)) {
//       return false;
//     }
//
//     final isOpen = SpUtil.getBool(Constants.SP_DIGITAL_DISPLAY_SWITCH, defValue: false) ?? false;
//     if (!isOpen) {
//       return false;
//     }
//     String? com;
//     String? baudRate;
//
//     if (tmpCom != null && tmpBaudRate != null) {
//       com = tmpCom;
//       baudRate = tmpBaudRate;
//     } else {
//       final model = getLocalSaveDigitalDisplayModel();
//       if (model == null) {
//         return false;
//       }
//
//       /// com口为空
//       if (model.com == null) {
//         return false;
//       }
//
//       /// 波特率为空
//       if (model.baudRate == null) {
//         return false;
//       }
//       com = model.com!;
//       baudRate = model.baudRate!;
//     }
//     try {
//       // 1. 创建串口对象
//       _port = SerialPort(com);
//       // 2. 创建配置对象
//       _configs = SerialPortConfig();
//       _configs!
//         ..baudRate = baudRate.toInt() ?? 2400
//         ..bits = 8
//         ..stopBits = 1
//         ..parity = SerialPortParity.none
//         ..xonXoff = 0
//         ..rts = 1
//         ..cts = 0
//         ..dsr = 0
//         ..dtr = 1;
//
//
//       return true;
//     } on SerialPortError catch (_, err) {
//       LogWork().writeLog(log: '数字客显获取串口失败,err: ${err.toString()}', logType: LogErrorType.exceptionError);
//       return false;
//     }
//   }
//
//   /// 更改配置 重新创建对象
//   void disposeRecourse({bool isClearObj = true}) {
//     _port?.close();
//     if (isClearObj) {
//       _port?.dispose();
//       _port = null;
//       listen?.cancel();
//     }
//   }
//
//   /// 数字客显连接 isClearPreObj 是否需要清空之前的连接对象，设置页面修改端口是需要
//   Future<bool> connect({String? price, String? tmpCom, String? tmpBaudRate, bool isClearPreObj = false}) async {
//     if (isClearPreObj) {
//       disposeRecourse(isClearObj: true);
//     }
//     if (_port == null) {
//       final isInit = _init(tmpCom: tmpCom, tmpBaudRate: tmpBaudRate);
//       if (isInit == false) {
//         return false;
//       }
//     }
//
//     // 3. 串口为打开状态 直接返回
//     if (_port != null && _port!.isOpen) {
//       return true;
//     }
//     if (_port == null) {
//       return false;
//     }
//     try {
//       // 1. 打开串口
//       var openReadWrite = _port!.openWrite();
//       while (!openReadWrite && retryCunt > 0) {
//         await Future.delayed(const Duration(milliseconds: 500), () async {
//           openReadWrite = _port!.openWrite();
//         });
//         retryCunt--;
//       }
//
//       if (openReadWrite == true) {
//         try {
//           // 设置串口配置
//           if (_port != null && _port!.isOpen) {
//             final config = _port!.config;
//             final baudRate = config.baudRate;
//             final bits = config.bits;
//             final stopBits = config.stopBits;
//             final parity = config.parity;
//             if (baudRate != _configs!.baudRate || parity != _configs!.parity) {
//               _port!.config = _configs!;
//               //_configs!.dispose();
//             }
//           }
//           openReadWrite = true;
//         } on SerialPortError catch (e) {
//           LogWork().writeLog(log: '数字客显设置config失败:$e', logType: LogErrorType.exceptionError);
//           openReadWrite = false;
//         }
//       }
//       return openReadWrite;
//     } on SerialPortError catch (_, err) {
//       LogWork().writeLog(log: '数字客显打开串口失败,err: ${err.toString()}', logType: LogErrorType.exceptionError);
//       return false;
//     }
//   }
//
//   /// 显示金额入口方法
//   Future<void> writeByteLEDByAddress(String price, {String? tmpCom, String? tmpBaudRate, VoidCallback? result}) async {
//     if (!(Platform.isWindows || Platform.isAndroid)) {
//       return;
//     }
//     final connectResult = await SerialUtil().connect(price: price, tmpCom: tmpCom, tmpBaudRate: tmpBaudRate);
//     if (connectResult == true) {
//       // 串口打开成功
//       final port = _port;
//       if (port != null) {
//         SerialUtil()._writeByteLED(port, price);
//       }
//
//       // 写入操作后回调
//       if (result != null) {
//         result();
//       }
//     }
//   }
//
//   void _writeByteLED(SerialPort port, String price) {
//     final validPrice = isValidPrice(price) ? price : "0.00";
//     final list = validPrice.split("");
//     final content = list.map((e) => xy[e]!).toList();
//     final contentByte = Uint8List.fromList(List.from([0x1B, 0x51, 0x41])
//       ..addAll(content)
//       ..add(0x0D));
//     try {
//       if (port.isOpen) {
//         // 显示数据
//         port.write(contentByte, timeout: 1000);
//       }
//     } on SerialPortError catch (_, err) {
//       LogWork().writeLog(log: '金额显示失败,未写入!err:${err.toString()}', logType: LogErrorType.exceptionError);
//       // 释放资源
//       disposeRecourse(isClearObj: false);
//     }
//   }
//
//   /// 重置为0.00
//   resetZero({bool isCloseDigitalDisplay = false}) {
//     writeByteLEDByAddress("0.00", result: () async {
//       await Future.delayed(const Duration(milliseconds: 100), () {
//         // 重置为0 是否关闭数字客显
//         if (isCloseDigitalDisplay) {
//           disposeRecourse(isClearObj: true);
//         }
//       });
//     });
//   }
//
//   /// 清屏命令 清除屏幕上的所有字符
//   Future<void> clearScreen({String? tmpCom, String? tmpBaudRate}) async {
//     if (!(Platform.isWindows || Platform.isAndroid)) {
//       LogWork().writeLog(log: "清屏失败，该平台未实现数字客显功能");
//       return;
//     }
//     final result = await SerialUtil().connect(tmpCom: tmpCom, tmpBaudRate: tmpBaudRate);
//     if (result == true) {
//       final port = _port;
//       if (port != null && port.isOpen) {
//         final content = Uint8List.fromList([0x0C]);
//         port.write(content, timeout: 1000);
//       }
//     }
//   }
//
//   /// 关闭串口
//   void close() {
//     if (!(Platform.isWindows || Platform.isAndroid)) {
//       return;
//     }
//     if (_port != null && _port!.isOpen) {
//       _port!.close();
//     }
//   }
//
//   /// 获取可用端口 安卓为类似 /dev/ttyS0
//   static List<String> availablePorts() {
//     try {
//       final availablePorts = SerialPort.availablePorts;
//       return availablePorts;
//     } catch (_, err) {
//       LogWork().writeLog(log: '获取可用串口失败,err:${err.toString()}', logType: LogErrorType.exceptionError);
//       return [];
//     }
//   }
//
//   bool isValidPrice(String input) {
//     final RegExp mobile = RegExp(r'^([1-9]\d*\.?\d*)|(0\.\d*[1-9])$');
//     return mobile.hasMatch(input);
//   }
//
//   /// 获取数字客显本地保存参数设置
//   DigitalDisplayModel? getLocalSaveDigitalDisplayModel() {
//     try {
//       // 获取本地已存储数字客显设置
//       final localDeviceJson = SPUtil().getJson(Constants.SP_DIGITAL_DISPLAY_SAVE_KEY);
//       if (localDeviceJson != null) {
//         final model = DigitalDisplayModel.fromJson(localDeviceJson);
//         return model;
//       }
//       return null;
//     } catch (e) {
//       logWork.writeExceptionLog(log: "getLocalSaveDigitalDisplayModel:${e.toString()}");
//       return null;
//     }
//   }
// }
//
// class SerialPortResult {
//   SerialPortResult({required this.connect, required this.msg});
//
//   bool connect;
//   String msg;
// }
//
// var xy = {
//   "0": 0x30,
//   "1": 0x31,
//   "2": 0x32,
//   "3": 0x33,
//   "4": 0x34,
//   "5": 0x35,
//   "6": 0x36,
//   "7": 0x37,
//   "8": 0x38,
//   "9": 0x39,
//   ".": 0x2e,
// };
