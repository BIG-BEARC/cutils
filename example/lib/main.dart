// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demos/crypto_demo.dart';
import 'demos/datetime_demo.dart';
import 'demos/ext_demo.dart';
import 'demos/identifier_demo.dart';
import 'demos/json_demo.dart';
import 'demos/log_demo.dart';
import 'demos/num_demo.dart';
import 'demos/regex_demo.dart';
import 'demos/storage_demo.dart';

void main() => runApp(const MyApp());

/// cutils 演示应用：按领域分组的工具库用法入口。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cutils 演示',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final demos = <_DemoEntry>[
      _DemoEntry(
        Icons.calculate,
        '数值与金额',
        'NumUtils / MoneyUtils / int_ext',
        const NumDemo(),
      ),
      _DemoEntry(
        Icons.schedule,
        '日期时间',
        'DateTimeUtils / TimelineUtil',
        const DatetimeDemo(),
      ),
      _DemoEntry(
        Icons.verified,
        '正则校验',
        'RegexUtils / String 扩展',
        const RegexDemo(),
      ),
      _DemoEntry(
        Icons.data_object,
        'JSON',
        'JsonUtils 编解码',
        const JsonDemo(),
      ),
      _DemoEntry(
        Icons.enhanced_encryption,
        '加解密',
        'CryptoUtils MD5/Base64/XOR',
        const CryptoDemo(),
      ),
      _DemoEntry(
        Icons.storage,
        '存储',
        'SpUtil (SharedPreferences)',
        const StorageDemo(),
      ),
      _DemoEntry(
        Icons.text_fields,
        '字符串扩展',
        'StringExt reverse/mask/千分位',
        const ExtDemo(),
      ),
      _DemoEntry(
        Icons.tag,
        '标识生成',
        'RandomUtils / UUIDUtils',
        const IdentifierDemo(),
      ),
      _DemoEntry(
        Icons.article,
        '日志',
        'logger / logCollector',
        const LogDemo(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('cutils 演示')),
      body: ListView.separated(
        itemCount: demos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final d = demos[i];
          return ListTile(
            leading: Icon(d.icon),
            title: Text(d.title),
            subtitle: Text(d.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => d.screen),
            ),
          );
        },
      ),
    );
  }
}

class _DemoEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  const _DemoEntry(this.icon, this.title, this.subtitle, this.screen);
}
