import 'package:flutter/material.dart';

/// Оборачивает интерактивный НЕ-кнопочный элемент (карточку, строку
/// настроек, текстовую ссылку) в hand-курсор для desktop/web — Material-
/// кнопки (FilledButton и т.п.) уже получают его от темы (Этап 5 сборки
/// дизайн-системы, prompt_design_cleanup.md). На тач-устройствах
/// MouseRegion не стреляет — платформенных проверок не требуется.
class HoverCursor extends StatelessWidget {
  const HoverCursor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click, child: child);
  }
}
