import 'package:flutter/material.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/2/15 3:37 下午
/// * @Email:
/// * description 图片工具类
class ImageUtils {
  static ImageProvider assetImage(String name, {String assetPath = 'assets/images/',ImageFormat format = ImageFormat.png}) {
    var path = '$assetPath$name.${format.value}';
    return AssetImage(path);
  }

  static Widget getAssetImg({
    required String imagePath,
    BoxFit boxFit = BoxFit.cover,
    double? height,
    double? width,
    Widget? errorWidget,
    Color? color,
    ImageFormat format = ImageFormat.png,
  }) {
    return Image.asset(
      'assets/images/$imagePath.${format.value}',
      fit: boxFit,
      height: height,
      width: width,
      color: color,
      cacheHeight: height?.toInt(),
      cacheWidth: width?.toInt(),
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        return errorWidget ?? const Icon(Icons.broken_image);
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(seconds: 1),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }

}

enum ImageFormat {
  png(value: 'png'),
  jpg(value: 'jpg'),
  gif(value: 'gif'),
  webp(value: 'webp');

  final String value;

  const ImageFormat({required this.value});
}
