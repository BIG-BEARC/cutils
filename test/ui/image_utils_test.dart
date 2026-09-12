// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/ui/image_utils.dart';

void main() {
  group('ImageUtils.assetImage', () {
    test('默认路径与 png 扩展名', () {
      final provider = ImageUtils.assetImage('logo');
      expect(provider, isA<AssetImage>());
      expect((provider as AssetImage).assetName, 'assets/images/logo.png');
    });

    test('自定义路径与扩展名', () {
      final provider = ImageUtils.assetImage('banner',
          assetPath: 'assets/banners/', format: ImageFormat.webp);
      expect((provider as AssetImage).assetName, 'assets/banners/banner.webp');
    });

    test('ImageFormat 枚举值映射扩展名', () {
      expect(ImageFormat.png.value, 'png');
      expect(ImageFormat.jpg.value, 'jpg');
      expect(ImageFormat.gif.value, 'gif');
      expect(ImageFormat.webp.value, 'webp');
    });
  });

  group('ImageUtils.getAssetImg', () {
    testWidgets('返回 Image.asset 且参数透传（fit/尺寸/color/缓存尺寸）', (tester) async {
      final widget = ImageUtils.getAssetImg(
        imagePath: 'logo',
        boxFit: BoxFit.contain,
        height: 48,
        width: 48,
        color: Colors.red,
      );

      expect(widget, isA<Image>());
      final image = widget as Image;
      expect(image.fit, BoxFit.contain);
      expect(image.height, 48);
      expect(image.width, 48);
      expect(image.color, Colors.red);
      // 传了 height/width 时 provider 会被包成 ResizeImage（解码尺寸缓存），
      // 内层才是按约定路径拼接的 AssetImage。
      final provider = image.image;
      expect(provider, isA<ResizeImage>());
      expect(
        (provider as ResizeImage).imageProvider,
        isA<AssetImage>()
            .having((p) => p.assetName, 'assetName', 'assets/images/logo.png'),
      );
    });

    testWidgets('加载失败时显示 errorWidget，默认 broken_image 图标', (tester) async {
      // 用不存在的 asset 触发 errorBuilder。
      final widget = ImageUtils.getAssetImg(
        imagePath: 'definitely_missing',
        errorWidget: const Text('fallback'),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      expect(find.text('fallback'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsNothing);
    });

    testWidgets('未传 errorWidget 时默认显示 broken_image 图标', (tester) async {
      final widget = ImageUtils.getAssetImg(imagePath: 'definitely_missing');

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });
  });
}
