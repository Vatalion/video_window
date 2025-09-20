import 'package:equatable/equatable.dart';

enum OverlayTextAlignment { left, center, right }

enum OverlayTextAnimation { none, fadeIn, slideUp, typewriter }

class TextOverlaySettings extends Equatable {
  const TextOverlaySettings({
    this.content = '',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontSize = 16,
    this.alignment = OverlayTextAlignment.center,
    this.animation = OverlayTextAnimation.none,
  });

  final String content;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final double fontSize;
  final OverlayTextAlignment alignment;
  final OverlayTextAnimation animation;

  TextOverlaySettings copyWith({
    String? content,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    double? fontSize,
    OverlayTextAlignment? alignment,
    OverlayTextAnimation? animation,
  }) {
    return TextOverlaySettings(
      content: content ?? this.content,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      fontSize: fontSize ?? this.fontSize,
      alignment: alignment ?? this.alignment,
      animation: animation ?? this.animation,
    );
  }

  @override
  List<Object?> get props => [
    content,
    isBold,
    isItalic,
    isUnderline,
    fontSize,
    alignment,
    animation,
  ];
}

class CaptionBlock extends Equatable {
  const CaptionBlock({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
  }) : assert(!start.isNegative && !end.isNegative),
       assert(end >= start);

  final String id;
  final Duration start;
  final Duration end;
  final String text;

  CaptionBlock copyWith({
    String? id,
    Duration? start,
    Duration? end,
    String? text,
  }) {
    return CaptionBlock(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
    );
  }

  @override
  List<Object?> get props => [id, start, end, text];
}
