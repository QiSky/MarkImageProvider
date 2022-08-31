import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:palette_generator/palette_generator.dart';

import 'image_watermark_setting_model.dart';

///
/// * @ProjectName: combination_cached_network_image
/// * @Author: qifanxin
/// * @CreateDate: 2022/8/26 11:10
/// * @Description: 文件说明
///

class CombinationCachedImageProvider
    extends ImageProvider<CombinationCachedImageProvider>
    with ImageAddWaterMark {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const CombinationCachedImageProvider(
    this.url, {
    this.maxHeight,
    this.maxWidth,
    this.scale = 1.0,
    this.settingModel,
    this.fileName,
    this.errorListener,
    this.headers,
    this.cacheManager,
    this.cacheKey,
  });

  final BaseCacheManager? cacheManager;

  /// Web url of the image to load
  final String url;

  /// Cache key of the image to cache
  /// 此处改动：原始通过key获取的图片缓存无效
  final String? cacheKey;

  /// 文件名
  /// 当设置水印时，该参数为必填
  final String? fileName;

  /// Scale of the image
  final double scale;

  final ImageWaterMarkSettingModel? settingModel;

  /// Listener to be called when images fails to load.
  final ErrorListener? errorListener;

  /// Set headers for the image provider, for example for authentication
  final Map<String, String>? headers;

  final int? maxHeight;

  final int? maxWidth;

  @override
  ImageStreamCompleter load(
      CombinationCachedImageProvider key, DecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  Future<ui.Codec> _loadAsync(
    CombinationCachedImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) {
    assert(key == this);
    return _loadImageAsync(
      url,
      cacheKey,
      chunkEvents,
      decode,
      cacheManager ?? DefaultCacheManager(),
      maxHeight,
      maxWidth,
      headers,
      errorListener,
      () => PaintingBinding.instance.imageCache.evict(key),
    );
  }

  Future<ui.Codec> _loadImageAsync(
    String url,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
    BaseCacheManager cacheManager,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    Function()? errorListener,
    Function() evictImage,
  ) async {
    StreamSubscription? streamSubscription;
    try {
      assert(
          cacheManager is ImageCacheManager ||
              (maxWidth == null && maxHeight == null),
          'To resize the image with a CacheManager the '
          'CacheManager needs to be an ImageCacheManager. maxWidth and '
          'maxHeight will be ignored when a normal CacheManager is used.');

      final cacheDefine = "$url/cache=$cacheKey";
      Completer<ui.Codec> completer = Completer();

      /// if cacheKey is not null,first to get File from cache
      if (cacheKey != null) {
        FileInfo? cacheFile = await cacheManager.getFileFromCache(cacheDefine,
            ignoreMemCache: true);
        if (cacheFile != null && cacheFile.validTill.isAfter(DateTime.now())) {
          var bytes = await cacheFile.file.readAsBytes();
          if (!completer.isCompleted) completer.complete(await decode(bytes));
        }
      }

      /// if no data cached, get data from remote
      var stream = cacheManager is ImageCacheManager
          ? cacheManager.getImageFile(url,
              maxHeight: maxHeight,
              maxWidth: maxWidth,
              withProgress: true,
              headers: headers)
          : cacheManager.getFileStream(url,
              withProgress: true, headers: headers);
      streamSubscription = stream.listen((result) async {
        if (result is DownloadProgress) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: result.downloaded,
            expectedTotalBytes: result.totalSize,
          ));
        }
        if (result is FileInfo) {
          var file = result.file;
          var bytes = await file.readAsBytes();
          if (settingModel != null) {
            var image = await any2Image(Convert2ImageType.DATA, data: bytes);
            var waterCacheData =
                await generateWaterMaskData(image, settingModel!);
            var cacheBytes = waterCacheData!.buffer.asUint8List();
            cacheManager.putFile(cacheDefine, cacheBytes,
                maxAge: const Duration(days: 7),
                fileExtension: fileName?.getMine() ?? 'file');
            if (!completer.isCompleted) {
              await chunkEvents.close();
              completer.complete(await decode(cacheBytes));
            }
          } else {
            if (!completer.isCompleted) {
              await chunkEvents.close();
              completer.complete(await decode(bytes));
            }
          }
          streamSubscription?.cancel();
        }
      });
      return completer.future;
    } catch (e) {
      scheduleMicrotask(() {
        evictImage();
      });
      await chunkEvents.close();
      streamSubscription?.cancel();
      errorListener?.call();
      rethrow;
    }
  }

  @override
  Future<CombinationCachedImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<CombinationCachedImageProvider>(this);
  }

  @override
  bool operator ==(dynamic other) {
    if (other is CombinationCachedImageProvider) {
      return ((cacheKey ?? url) == (other.cacheKey ?? other.url)) &&
          url == other.url &&
          scale == other.scale &&
          maxHeight == other.maxHeight &&
          maxWidth == other.maxWidth;
    }
    return false;
  }

  @override
  int get hashCode =>
      hashValues(url, cacheKey ?? '', scale, maxHeight, maxWidth);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}

typedef ErrorListener = void Function();

extension FileExtension on String {
  String getMine() {
    List<String> str = split('.');
    return str.isNotEmpty ? str.last : '';
  }
}

class _MarkTask {
  final String path;

  final ImageWaterMarkSettingModel settings;

  final ui.Image image;

  _MarkTask(this.path, this.settings, this.image);
}

mixin ImageAddWaterMark {
  Future<ui.Image> any2Image(Convert2ImageType type,
      {String? path,
      Uint8List? data,
      int? width,
      int? height,
      double scaleRatio = 0.85}) async {
    late Uint8List codecData;
    if (type == Convert2ImageType.DATA) {
      codecData = data!;
    } else {
      codecData = File(path!).readAsBytesSync();
    }
    late ui.Codec codec;
    if (width != null && width != 0 && height != null && height != 0) {
      codec = await ui.instantiateImageCodec(codecData,
          targetWidth: width * scaleRatio ~/ 1,
          targetHeight: height * scaleRatio ~/ 1);
    } else {
      codec = await ui.instantiateImageCodec(codecData);
    }
    ui.FrameInfo fi =
        await codec.getNextFrame().whenComplete(() => codec.dispose());
    return fi.image;
  }

  // 生成水印
  _generateWaterMask(ui.Image originImage, File outFile,
      ImageWaterMarkSettingModel settingModel) async {
    var data = await generateWaterMaskData(originImage, settingModel);
    await _dataWrite(data, outFile.path);
  }

  Future<ByteData?> generateWaterMaskData(
      ui.Image originImage, ImageWaterMarkSettingModel settingModel) async {
    PaletteGenerator? res = await PaletteGenerator.fromImage(originImage,
        region: Rect.fromCenter(
            center: Offset((originImage.width / 4), (originImage.height / 4)),
            width: (originImage.width / 4),
            height: (originImage.height / 4)));
    PaletteColor? paletteColor = res.dominantColor;
    var i = 0;
    if ((paletteColor?.color.red ?? 0) < 128) {
      i++;
    }
    if ((paletteColor?.color.blue ?? 0) < 128) {
      i++;
    }
    if ((paletteColor?.color.green ?? 0) < 128) {
      i++;
    }
    Color renderColor =
        i >= 2 ? settingModel.lightColor : settingModel.darkColor;

    ///首先根据图片宽度分为四等份
    settingModel.textWidth = originImage.width / 4;

    ///根据配置第一项生成水印（为了获取水印渲染高度）
    var paragraph = _generateText(settingModel!, renderColor);

    ///startPosition 水印第一个元素与x、y轴间距
    ///verticalDistance 水印行y轴间距
    double startPosition = 25, verticalDistance = 200;
    late int height;

    ///获取图片高度
    height = paragraph.height ~/ 1;

    verticalDistance += (height / 600).ceil() * 50;

    ///计算图片可以配置多少行水印（当配置的角度非0时，由于倾斜的问题，可能会导致边角出现空余，所以角度不为0时，需要多渲染一行）
    var heightNumber = settingModel.radians != 0
        ? (originImage.height - height) ~/ (height + verticalDistance) + 2
        : (originImage.height - height) ~/ (height + verticalDistance) + 1;
    ImageWaterMarkSettingModel tempSetting = settingModel;
    double widthUnit = originImage.width / tempSetting.divided;
    double heightUnit = originImage.height / tempSetting.divided;

    var scaleFont = (originImage.width / 800) * settingModel.fontSize;

    var textWidth = (originImage.width - startPosition) / 4;

    var templateParagraph = _generateText(
        ImageWaterMarkSettingModel(
            fontSize: scaleFont,
            textStyle: tempSetting.textStyle,
            text: tempSetting.text,
            textWidth: textWidth),
        renderColor);

    ///再创建canvas
    ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    ui.Canvas canvas = ui.Canvas(pictureRecorder);
    ui.Paint paint = ui.Paint();

    ///原图大小绘制在最底层
    canvas.drawImage(originImage, ui.Offset.zero, paint);

    ///一行默认渲染4个
    for (var i = -1; i < 5; i++) {
      for (var j = 0; j < heightNumber; j++) {
        ImageWaterMarkSettingModel settings = ImageWaterMarkSettingModel();
        settings.asset = tempSetting.asset;
        settings.divided = tempSetting.divided;
        settings.radians = tempSetting.radians;
        settings.text = tempSetting.text;
        settings.fontSize = scaleFont;
        settings.textStyle = tempSetting.textStyle;
        settings.textWidth = textWidth;
        settings.type = tempSetting.type;

        ///由于要形成交错效果，所以每行的间距都会出现一段距离
        settings.dx = (startPosition +
                i * ((originImage.width - startPosition) / 2) +
                (j % 2 == 0 ? 0 : 0 - (originImage.width - startPosition) / 2) /
                    2) /
            widthUnit;
        settings.dy =
            (startPosition + j * (height + verticalDistance)) / heightUnit;

        ///如果是隔行，且为第一个元素，且角度为0，则该元素不需要渲染
        if (j % 2 != 0 && i == 0 && settings.radians == 0) continue;

        canvas.rotate(-settings.radians);
        // if (waterMarkList[i].runtimeType == ui.Paragraph) {
        ///canvas以左上角点为原点建立坐标系
        //以下出现2次rotate，因为旋转canvas后，整个画布坐标系会一起旋转，如不重置回原来，则下一次旋转的角度将根据此次角度叠加
        canvas.drawParagraph(templateParagraph,
            Offset(widthUnit * settings.dx, heightUnit * settings.dy));
        // }
        canvas.rotate(settings.radians);
      }
    }

    ///生成与原图尺寸一样的合成图片
    ui.Image generateImage = await pictureRecorder
        .endRecording()
        .toImage(originImage.width * 0.9 ~/ 1, originImage.height * 0.9 ~/ 1);
    ByteData? data = await generateImage
        .toByteData(format: ui.ImageByteFormat.png)
        .whenComplete(() {
      originImage.dispose();
      generateImage.dispose();
    });
    return Future.value(data);
  }

  ui.Paragraph _generateText(
      ImageWaterMarkSettingModel settingModel, Color? mainColor) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
      ..pushStyle(settingModel.textStyle ??
          ui.TextStyle(fontSize: settingModel.fontSize, color: mainColor))
      ..addText(settingModel.text ?? '');
    var paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: settingModel.textWidth));
    return paragraph;
  }

  ///数据转文件
  Future<dynamic> _dataWrite(ByteData? data, String path) async {
    await File(path).writeAsBytes(data!.buffer.asUint8List(), flush: true);
    return path;
  }
}
