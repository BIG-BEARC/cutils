// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Package imports:
import 'package:archive/archive_io.dart';
import 'package:dartx/dartx.dart';

// Flutter imports:
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:cutils/date/date_utils.dart';
import 'package:cutils/log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 2022/10/31 11:02 上午
/// * @Email:
/// * description 文件工具类
class FileUtils {
  factory FileUtils() {
    return _ins;
  }

  FileUtils._internal();

  static final FileUtils _ins = FileUtils._internal();
  final String TAG = "FileUtils";

  /// 获取文档目录文件,用于存储只能由该应用访问的文件，系统不会清除该目录，只有在删除应用时才会消失。
  Future<File?> getLocalDocumentFile({required String fileName, String? filePath}) async {
    try {

      final dir = await getApplicationDocumentsDirectory();
      return _getFile(dir, filePath, fileName);
    } catch (e) {
      logger.e(tag: TAG, e);
      return null;
    }
  }
  /// 获取应用程序的目录，用于存储只有它可以访问的文件。只有当应用程序被删除时，系统才会清除目录。
  /// 在iOS上，它使用“NSDocumentDirectory”API。如果数据不是用户生成的，请考虑使用[GetApplicationSupportDirectory]。
  /// 在Android上，这在上下文中使用了“getDataDirectory”API。如果数据对用户可见，请考虑改用getExternalStorageDirectory。
  /// 文档目录: /data/user/0/com.xx.xxx/xxx
  Future<String?> getLocalDocumentDir() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    } catch (e) {
      logger.e(tag: TAG, e);
      return null;
    }
  }
  /// 获取临时目录文件,只能由该应用访问，系统可随时清除的临时目录（缓存）
  /// 指向设备上临时目录的路径，该目录没有备份，适合存储下载文件的缓存。
  /// 此目录中的文件可以随时清除。这不会返回一个新的临时目录。
  /// 相反，调用者负责在这个目录中创建(和清理)文件或目录。这个目录的作用域是调用应用程序。
  /// 在iOS上，它使用“NSCachesDirectory”API。
  /// 在Android上，它在上下文中使用“getCacheDir”API。
  ///  临时目录: /data/user/0/com.xx.xxx/cache
  Future<File?> getLocalTemporaryFile({required String fileName, String? filePath}) async {
    try {
      final dir = await getTemporaryDirectory();
      return _getFile(dir, filePath, fileName);
    } catch (e) {
      logger.e(tag: TAG, e);
      return null;
    }
  }
  /// 获取本地临时文件路径
  Future<String?> getLocalTemporaryDir() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      return tempDir.path;
    } catch (e) {
      logger.e(tag: TAG, e);
      return null;
    }
  }
  /// 获取应用程序支持目录,只能由该应用访问，用于不想向用户公开的文件，也就是你不想给用户看到的文件可放置在该目录中，
  /// 系统不会清除该目录，只有在删除应用时才会消失。
  /// 应用程序可以放置应用程序支持文件的目录的路径。
  /// 对不希望向用户公开的文件使用此选项。您的应用程序不应将此目录用于用户数据文件。
  /// 在iOS上，它使用“NSApplicationSupportDirectory”API。如果此目录不存在，则自动创建。
  /// 在Android上，此函数抛出一个[UnsupportedError]。
  /// windows 和sp 同目录
  Future<File?> getLocalSupportFile({required String fileName, String? filePath}) async {
    if (Platform.isAndroid) {
      return null;
    }
    try {
      final dir = await getApplicationSupportDirectory();
      return _getFile(dir, filePath, fileName);
    } catch (e) {
      logger.e(tag: TAG, e);
      return null;
    }
  }

  /// 获取应用程序支持路径
  Future<String?> getLocalSupportDir() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    } catch (e) {
      logger.e(tag: TAG, e);
      return null;
    }
  }


  ///外部存储目录,Android 特有，删除应用不会删除该目录
  /// 应用程序可以访问顶层存储的目录的路径。在发出这个函数调用之前，应该确定当前操作系统，因为这个功能只在Android上可用。
  /// 在iOS上，这个函数抛出一个[UnsupportedError]，因为它不可能访问应用程序的沙箱之外。
  /// 在Android上，它使用“getExternalStorageDirectory”API。
  Future<File?> getExternalStorageFile({required String fileName, String? filePath}) async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) {
        return null;
      }
      return _getFile(extDir, filePath, fileName);
    } catch (e) {
      logger.e(tag: TAG, e);
      return null;
    }
  }

  File _getFile(Directory dir, String? filePath, String fileName) {
    if (filePath.isNullOrEmpty) {
      return File('${dir.path}/$fileName');
    } else {
      return File('${dir.path}/$filePath/$fileName');
    }
  }




  /// 同步创建文件
  Directory? createDir(String path) {
    if (path.isEmpty) {
      return null;
    }
    Directory dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
  /// 异步创建文件
   Future<Directory?> createDirSync(String path) async {
     if (path.isEmpty) {
       return null;
     }
    Directory dir = Directory(path);
    bool exist = await dir.exists();
    if (!exist) {
      dir = await dir.create(recursive: true);
    }
    return dir;
  }
  ///为文件创建一个IOSink,使用结束需要释放资源
  ///mode: FileMode.append,// 写入的模式
  ///append(追加写入，如果文件存在在末尾追加，如果文件不存在创建)
  ///read(只读)
  ///write(读写，如果文件存在覆盖，如果文件不存在创建)
  ///writeOnly(只写，如果文件存在覆盖，如果文件不存在创建)
  ///writeOnlyAppend(只追加，如果文件存在在末尾追加，如果文件不存在创建)
  void writeBySink(File file, String content, FileMode? fileMode) async {
    try {
      //检查文件是否存在 existsSync() 同步检查文件是否存在
      final fileExists = await file.exists();

      ///如果文件不存在，创建文件
      if (!fileExists) {
        await file.create(recursive: true);
      }
      final sink = file.openWrite(mode: fileMode ?? FileMode.append);
      sink.write('$content\n');
      await sink.flush();
      await sink.close();
    } catch (e) {
      logger.d(tag: TAG, e.toString());
    }
  }

  Future<IOSink?> getWriteIoSink({required File file, FileMode? fileMode}) async {
    try {
      //检查文件是否存在 existsSync() 同步检查文件是否存在
      final fileExists = await file.exists();

      ///如果文件不存在，创建文件
      if (!fileExists) {
        await file.create(recursive: true);
      }
      return file.openWrite(mode: fileMode ?? FileMode.append);
    } catch (e) {
      logger.e(tag: TAG, e.toString());
      return null;
    }
  }

  ///文件是否存在
  Future<bool> fileExist({required String fileName, String? filePath, FileMode? fileMode}) async {
    // create({bool recursive: false})创建文件
    // createSync({bool recursive: false}) 同步创建文件
    // 可选命名参数:recursive 默认false,
    // 若为true  则路径中有目录不存在时 会递归创建目录
    // 若为false 则路径中的目录不存在时 会报错
    try {
      File? file;
      if (Platform.isWindows) {
        file = await getLocalSupportFile(fileName: fileName, filePath: filePath);
      } else if (Platform.isAndroid) {
        final exFile = await getExternalStorageFile(fileName: fileName, filePath: filePath);
        if (exFile == null) {
          file = await getLocalTemporaryFile(fileName: fileName, filePath: filePath);
        } else {
          file = exFile;
        }
      } else {
        file = await getLocalDocumentFile(fileName: fileName, filePath: filePath);
      }
      if (file == null) {
        return false;
      }
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  ///文件是否存在
  Future<File?> getFile({required String fileName, String? filePath, FileMode? fileMode}) async {
    // create({bool recursive: false})创建文件
    // createSync({bool recursive: false}) 同步创建文件
    // 可选命名参数:recursive 默认false,
    // 若为true  则路径中有目录不存在时 会递归创建目录
    // 若为false 则路径中的目录不存在时 会报错
    try {
      File? file;
      if (Platform.isWindows) {
        file = await getLocalSupportFile(fileName: fileName, filePath: filePath);
      } else if (Platform.isAndroid) {
        final exFile = await getExternalStorageFile(fileName: fileName, filePath: filePath);
        if (exFile == null) {
          file = await getLocalTemporaryFile(fileName: fileName, filePath: filePath);
        } else {
          file = exFile;
        }
      } else {
        file = await getLocalDocumentFile(fileName: fileName, filePath: filePath);
      }
      if (file == null) {
        return null;
      }
      final fileExists = await file.exists();
      if (!fileExists) {
        await file.create(recursive: true);
      }
      return file;
    } catch (e) {
      logger.e(tag: TAG, e.toString());
      return null;
    }
  }

  /// 写入数据
  Future<File?> writeString({required String str, required String fileName, String? filePath, FileMode? fileMode}) async {
    // create({bool recursive: false})创建文件
    // createSync({bool recursive: false}) 同步创建文件
    // 可选命名参数:recursive 默认false,
    // 若为true  则路径中有目录不存在时 会递归创建目录
    // 若为false 则路径中的目录不存在时 会报错
    File? file;
    if (Platform.isWindows) {
      file = await getLocalSupportFile(fileName: fileName, filePath: filePath);
    } else if (Platform.isAndroid) {
      final exFile = await getExternalStorageFile(fileName: fileName, filePath: filePath);
      if (exFile == null) {
        file = await getLocalTemporaryFile(fileName: fileName, filePath: filePath);
      } else {
        file = exFile;
      }
    } else {
      file = await getLocalDocumentFile(fileName: fileName, filePath: filePath);
    }

    if (file == null) {
      return null;
    }

    try {
      final fileExists = await file.exists();

      if (!fileExists) {
        await file.create(recursive: true);
      }

      //以字符串方式写入
      return await file.writeAsString(str,
          flush: true,
          // 如果flush设置为`true` 则写入的数据将在返回之前刷新到文件系统
          mode: fileMode ?? FileMode.append,
          // 写入的模式 append(追加写入) read(只读) write(读写) writeOnly(只写)  writeOnlyAppend(只追加)
          encoding: utf8); // 设置编码
    } catch (e) {
      logger.e(tag: TAG, e.toString());
      return null;
    }
  }

  /// 写入数据
  Future<void> writeBytes(List<int> bytes, File file, FileMode? fileMode) async {
    // create({bool recursive: false})创建文件
    // createSync({bool recursive: false}) 同步创建文件
    // 可选命名参数:recursive 默认false,
    // 若为true  则路径中有目录不存在时 会递归创建目录
    // 若为false 则路径中的目录不存在时 会报错
    final fileExists = await file.exists();
    if (!fileExists) {
      await file.create(recursive: true);
    }
    //写入字节数组
    await file.writeAsBytes(bytes,
        flush: true, // 如果flush设置为`true` 则写入的数据将在返回之前刷新到文件系统
        mode: fileMode ?? FileMode.append); // 写入的模式 append(追加写入) read(只读) write(读写) writeOnly(只写)  writeOnlyAppend(只追加)
  }

  /// 以字节形式读取   readAsBytesSync() 同步读取
  /// 一次性读取整个文件，缺点就是如果文件太大的话，可能造成内存空间的压力。
  Future<List<int>> readBytes(File file) async {
    // readAsString()以字符串形式读取 readAsStringSync() 同步读取
    List<int> contentStr = [];
    final fileExists = await file.exists();
    if (fileExists) {
      contentStr = await file.readAsBytes();
    }
    return contentStr;
  }

  /// 按行读取 返回字符串数组 readAsLinesSync() 同步读取
  /// 一次性读取整个文件，缺点就是如果文件太大的话，可能造成内存空间的压力。
  Future<List<String>> readLines(File file) async {
    // readAsString()以字符串形式读取 readAsStringSync() 同步读取
    List<String> contentStr = [];
    final fileExists = await file.exists();
    if (fileExists) {
      contentStr = await file.readAsLines();
    }
    return contentStr;
  }

  /// 读取值 以字符串形式读取 readAsStringSync() 同步读取
  /// 一次性读取整个文件，缺点就是如果文件太大的话，可能造成内存空间的压力。
  Future<String> readString(File file) async {
    var contentStr = "";
    final fileExists = await file.exists();
    if (fileExists) {
      contentStr = await file.readAsString();
    }
    return contentStr;
  }

  ///以流的方式读取文件
  Future<String> readBySink(File file, FileMode? fileMode) async {
    String content = "";
    //检查文件是否存在 existsSync() 同步检查文件是否存在
    final fileExists = await file.exists();

    ///如果文件不存在，创建文件
    if (!fileExists) {
      return content;
    }
    final StringBuffer buffer = StringBuffer();
    final Stream<List<int>> inputStream = file.openRead();

    inputStream.transform(utf8.decoder).transform(const LineSplitter()).listen((data) {
      buffer.write(data);
    }, onDone: () {
      content = buffer.toString();
      logger.d(content);
    }, onError: (e) {
      content = "";
      logger.e(tag: TAG, e);
    });
    return content;
  }

  ///获取平台默认存储路径
  Future<String?> getPlatformPath() async {
    final String? path;
    if (Platform.isWindows) {
      path = await getLocalSupportDir();
    } else if (Platform.isAndroid) {
      final esdTemp = await getExternalStorageDirectory();
      if (esdTemp != null) {
        path = esdTemp.path;
      } else {
        final tdTemp = await getTemporaryDirectory();
        path = tdTemp.path;
      }
    } else {
      path = await getLocalDocumentDir();
    }
    return path;
  }

  ///创建file文件
  File readFile(String filePath) {
    return File(filePath);
  }

  ///删除缓存文件
  Future<bool> deleteFileData(String filePath) async {
    try {
      final file = readFile(filePath);
      file.delete();
      return true;
    } catch (err) {
      logger.e(err, tag: TAG);
      return false;
    }
  }

  /// 写入json文件，自定义路径
  Future<File?> writeJsonCustomFile(Object obj, String filePath) async {
    try {
      final file = readFile(filePath);
      return await file.writeAsString(json.encode(obj));
    } catch (err) {
      logger.e(err, tag: TAG);
      return null;
    }
  }

  ///利用文件存储字符串，自定义路径
  Future<File?> writeStringFile(String string, String filePath) async {
    try {
      final file = readFile(filePath);
      return await file.writeAsString(string);
    } catch (err) {
      logger.e(err, tag: TAG);
      return null;
    }
  }

  ///获取自定义路径文件存中的数据
  ///使用async、await，返回是一个Future对象
  Future<String?> readStringCustomFile(String filePath) async {
    try {
      final file = readFile(filePath);
      return await file.readAsString();
    } catch (err) {
      logger.e(err, tag: TAG);
      return null;
    }
  }

  /// 清除过期log
  /// file：文件
  // directory：文件夹
  // link：链接文件
  // notFound：未知
  void cleanExpiredLog(String logPath, int retentionTime) async {
    final curTime = dateUtils.getNowDateMs();
    // 根据路径字符串创建目录对象
    // recursive是否递归列出子目录 followLinks是否允许link
    Directory(logPath).list(followLinks: false).forEach((file) {
      final FileSystemEntityType type = FileSystemEntity.typeSync(file.path);
      if (type == FileSystemEntityType.file) {
        final lastModified = (file as File).lastModifiedSync();
        if (curTime - lastModified.millisecond > retentionTime) {
          file.delete();
        }
      }
    });
  }

  Future<List<File>> getFileList() async {
    final List<File> listFile = [];
    final String? dir;
    if (Platform.isWindows) {
      dir = await getLocalSupportDir();
    } else if (Platform.isAndroid) {
      final esdTemp = await getExternalStorageDirectory();
      if (esdTemp != null) {
        dir = esdTemp.path;
      } else {
        final tdTemp = await getTemporaryDirectory();
        dir = tdTemp.path;
      }
    } else {
      dir = await getLocalDocumentDir();
    }
    if (dir == null) {
      return [];
    }

    final list = Directory(dir).listSync(followLinks: false);
    final filterLogList = list.filter((fileSystemEntity) {
      if (fileSystemEntity.path.contains(".log") || fileSystemEntity.path.contains(".dmp")) {
        final fileDateTime = FileStat.statSync(fileSystemEntity.path).changed;
        final differDays = DateTime.now().difference(fileDateTime).inDays;
        if (differDays > 3) {
          return false;
        }
        return true;
      } else {
        return false;
      }
    }).toList();
    filterLogList.sort((a, b) {
      final timeA = FileStat.statSync(a.path).changed.millisecondsSinceEpoch;
      final timeB = FileStat.statSync(b.path).changed.millisecondsSinceEpoch;
      return timeA.compareTo(timeB);
    });
    final iterable = filterLogList.map((fileSystemEntity) => File(fileSystemEntity.path));
    listFile.addAll(iterable);
    return listFile;
  }

  /// 压缩日志文件
  Future<File?> zipFiles(String? zipName) async {
    final fileList = await getFileList();
    if (fileList.isNotEmpty) {
      final path = await getPlatformPath();
      final encoder = ZipFileEncoder();
      File zipFile;
      if (zipName != null) {
        zipFile = File('$path/$zipName.zip');
      } else {
        zipFile = File('$path/logs.zip');
      }

      final exists = await zipFile.exists();
      if (exists) {
        await zipFile.delete();
      }
      if (zipName != null) {
        encoder.create('$path/$zipName.zip');
      } else {
        encoder.create('$path/logs.zip');
      }

      for (var element in fileList) {
        await encoder.addFile(File(element.path));
      }
      encoder.close();
      return zipFile;
    }
    return null;
  }

  ///清除缓存数据
  Future<bool> clearFileData(String filePath) async {
    try {
      final file = readFile(filePath);
      file.writeAsStringSync("");
      return true;
    } catch (err) {
      logger.e(err, tag: TAG);
      return false;
    }
  }

  void cleanLog() async {
    // final dir = await getLocalSupportDir();
    final String? dir;
    if (Platform.isWindows) {
      dir = await getLocalSupportDir();
    } else if (Platform.isAndroid) {
      final esdTemp = await getExternalStorageDirectory();
      if (esdTemp != null) {
        dir = esdTemp.path;
      } else {
        final tdTemp = await getTemporaryDirectory();
        dir = tdTemp.path;
      }
    } else {
      dir = await getLocalDocumentDir();
    }
    if (dir == null) {
      return;
    }
    Directory(dir).list(followLinks: false).forEach((file) {
      if (path.extension(file.path) == ".log" || path.extension(file.path) == ".dmp") {
        file.delete();
      }
    });
  }

  /// 删除日志 默认保留3天
  void deleteLog({int saveDays = 3}) async {
    try {
      final String? dir;
      if (Platform.isWindows) {
        dir = await getLocalSupportDir();
      } else if (Platform.isAndroid) {
        final esdTemp = await getExternalStorageDirectory();
        if (esdTemp != null) {
          dir = esdTemp.path;
        } else {
          final tdTemp = await getTemporaryDirectory();
          dir = tdTemp.path;
        }
      } else {
        dir = await getLocalDocumentDir();
      }
      if (dir == null) {
        return;
      }
      Directory(dir).listSync(followLinks: false).forEach((fileSystemEntity) {
        if (fileSystemEntity.path.contains(".log") || fileSystemEntity.path.contains(".dmp")) {
          final fileDateTime = FileStat.statSync(fileSystemEntity.path).changed;
          final differDays = DateTime.now().difference(fileDateTime).inDays;
          if (differDays > 3) {
            fileSystemEntity.deleteSync();
          }
        }
      });
    } catch (e) {
      logger.e(tag: TAG, "deleteLog:${e.toString()}");
    }
  }

  String getFileName(String path) {
    final split = path.split("/");
    final fileName = split.last.split(".").first;
    return fileName;
  }

  // base64转本地图片
  Future<File> createFileFromBase64(String base64Str) async {
    final Uint8List bytes = const Base64Decoder().convert(base64Str);
    final tempDir = await getTemporaryDirectory();
    final targetPath = "${tempDir.absolute.path}/temp_${DateTime.now().microsecondsSinceEpoch}_base64.jpg";
    File file = File(targetPath);
    file = await file.writeAsBytes(bytes);
    return file;
  }

  // 本地图片转base64
  Future<String> createBase64FromFile(File file) async {
    final List<int> bytes = await file.readAsBytes();
    final String base64 = base64Encode(bytes);
    return base64;
  }
}
