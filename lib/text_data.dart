import 'package:flutter/material.dart';
//import 'package:uuid/uuid.dart';

class TextData {
  String? id;
  String text;
  Color textColor;
  double textSize;
  double positionX;
  double positionY;
  String fontFamily;

  TextData({
    this.id,
    required this.text,
    required this.textColor,
    required this.textSize,
    required this.positionX,
    required this.positionY,
    required this.fontFamily,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'textColor': textColor.value,
      'textSize': textSize,
      'positionX': positionX,
      'positionY': positionY,
      'fontFamily': fontFamily,
    };
  }

  static TextData fromMap(Map<String, dynamic> map) {
    return TextData(
      text: map['text'],
      textColor: Color(map['textColor']),
      textSize: map['textSize'],
      positionX: map['positionX'],
      positionY: map['positionY'],
      fontFamily: map['fontFamily'],
    );
  }
}
