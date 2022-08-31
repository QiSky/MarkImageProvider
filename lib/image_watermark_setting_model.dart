///
/// * @ProjectName: combination_cached_network_image
/// * @Author: qifanxin
/// * @CreateDate: 2022/8/28 23:16
/// * @Description: 文件说明
///
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

///水印设置类
class ImageWaterMarkSettingModel {
  ///水印类型
  late WaterMarkType type;

  ///文本水印内容
  String? text;

  ///文本水印内容样式
  ui.TextStyle? textStyle;

  Color lightColor;

  Color darkColor;

  double fontSize;

  ///旋转角度倍数
  ///单位为1弧（1弧=60度）
  double radians;

  ///文本最大宽度
  double textWidth;

  ///水印图片资源(本地）
  ///type == WaterMarkType.IMAGE时专属属性
  AssetImage? asset;

  ///水印对于图片的x轴偏移
  ///由于图片加载时无法暴露到外部，所以偏移属性为：图片宽 / 等分数，dx <= 等分数
  double dx;

  ///水印对于图片的y轴偏移
  ///由于图片加载时无法暴露到外部，所以偏移属性为：图片高 / 等分数，dy <= 等分数
  double dy;

  ///等分数
  ///默认100
  int divided;

  ImageWaterMarkSettingModel({
    this.type = WaterMarkType.TEXT,
    this.text = '',
    this.textStyle,
    this.radians = 0,
    this.asset,
    this.dx = 0,
    this.dy = 0,
    this.divided = 100,
    this.textWidth = 300,
    this.lightColor = const Color.fromRGBO(255, 255, 255, 0.25),
    this.darkColor = const Color.fromRGBO(0, 0, 0, 0.25),
    this.fontSize = 14,
  });

  factory ImageWaterMarkSettingModel.fromJson(Map<String, dynamic> json) {
    return ImageWaterMarkSettingModel(
      type: json['type'],
      text: json['text'],
      textStyle: json['textStyle'],
      radians: json['radians'],
      asset: json['path'],
      dx: json['dx'],
      dy: json['dy'],
      divided: json['divided'],
      textWidth: json['textWidth'],
    );
  }

  Map<String, dynamic> toJson(ImageWaterMarkSettingModel model) =>
      <String, dynamic>{
        'type': model.type,
        'text': model.text,
        'textStyle': model.textStyle,
        'radians': model.radians,
        'asset': model.asset,
        'dx': model.dx,
        'dy': model.dy,
        'divided': model.divided,
        'textWidth': model.textWidth,
      };
}

enum WaterMarkType { TEXT, IMAGE }

enum Convert2ImageType { FILE, DATA }
