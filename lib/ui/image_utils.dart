import 'package:flutter/material.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/2/15 3:37 下午
/// * @Email:
/// * description 图片工具类
class ImageUtils {
  /// 构建 assets 图片的 [ImageProvider]，路径为 `$assetPath$name.$ext`。
  ///
  /// [assetPath] 默认 `'assets/images/'`；[format] 默认 [ImageFormat.png]。
  static ImageProvider assetImage(String name,
      {String assetPath = 'assets/images/',
      ImageFormat format = ImageFormat.png}) {
    final path = '$assetPath$name.${format.value}';
    return AssetImage(path);
  }

  /// 构建一个 asset [Image] widget，带淡入动画、加载占位与解码尺寸缓存。
  ///
  /// 图片路径为 `assets/images/$imagePath.${format.value}`。
  /// [errorWidget] 为加载失败时的占位（默认 broken_image 图标）。
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
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
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

/// 图片格式枚举，用于 [ImageUtils.assetImage] / [ImageUtils.getAssetImg] 的扩展名。
enum ImageFormat {
  /// `.png`。
  png(value: 'png'),

  /// `.jpg`。
  jpg(value: 'jpg'),

  /// `.gif`。
  gif(value: 'gif'),

  /// `.webp`。
  webp(value: 'webp');

  /// 扩展名字符串（不含点）。
  final String value;

  const ImageFormat({required this.value});
}
