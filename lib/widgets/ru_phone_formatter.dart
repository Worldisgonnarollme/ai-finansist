import 'package:flutter/services.dart';

/// Маска российского номера: "+7 (925) 858-34-56".
///
/// В отличие от наивной "пересобрать с нуля и поставить курсор в конец"
/// реализации, эта версия сохраняет позицию курсора при правке в середине
/// номера. Без этого правка/удаление цифры не в самом конце была
/// невозможна: если пользователь кликал в середину номера и жал
/// backspace, курсор из-за форматирования предыдущего нажатия мог
/// оказаться не на той цифре, а стирание автоматически вставленного
/// разделителя (пробела/скобки/дефиса) форматтер тут же откатывал
/// обратно — видимо ничего не менялось, и казалось, что стереть нельзя.
class RuPhoneFormatter extends TextInputFormatter {
  static final _digit = RegExp(r'\d');
  static final _nonDigit = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.end;
    if (cursor < 0) cursor = text.length;

    // Одиночный backspace/delete, стёрший разделитель, а не цифру —
    // считаем, что на самом деле нужно было удалить ближайшую цифру.
    final isBackspace =
        newValue.text.length == oldValue.text.length - 1 &&
        newValue.selection.isCollapsed &&
        oldValue.selection.isCollapsed &&
        newValue.selection.end == oldValue.selection.end - 1;
    final isForwardDelete =
        newValue.text.length == oldValue.text.length - 1 &&
        newValue.selection.isCollapsed &&
        oldValue.selection.isCollapsed &&
        newValue.selection.end == oldValue.selection.end;

    if (isBackspace) {
      final removedIndex = newValue.selection.end;
      if (removedIndex < oldValue.text.length &&
          !_digit.hasMatch(oldValue.text[removedIndex])) {
        final before = text.substring(0, cursor);
        final digitMatches = _digit.allMatches(before).toList();
        if (digitMatches.isNotEmpty) {
          final last = digitMatches.last;
          text =
              before.substring(0, last.start) +
              before.substring(last.end) +
              text.substring(cursor);
          cursor = last.start;
        }
      }
    } else if (isForwardDelete) {
      final removedIndex = oldValue.selection.end;
      if (removedIndex < oldValue.text.length &&
          !_digit.hasMatch(oldValue.text[removedIndex])) {
        final after = text.substring(cursor);
        final digitMatch = _digit.firstMatch(after);
        if (digitMatch != null) {
          text =
              text.substring(0, cursor) +
              after.substring(0, digitMatch.start) +
              after.substring(digitMatch.end);
        }
      }
    }

    if (text.startsWith('+7')) {
      text = text.substring(2);
      cursor = (cursor - 2).clamp(0, text.length);
    }

    // Сколько цифр расположено до курсора в "сыром" тексте — логическая
    // позиция курсора, которую нужно сохранить после переформатирования.
    var digitsBeforeCursor = 0;
    for (var i = 0; i < cursor && i < text.length; i++) {
      if (_digit.hasMatch(text[i])) digitsBeforeCursor++;
    }

    var digits = text.replaceAll(_nonDigit, '');

    if (digits.length == 11 &&
        (digits.startsWith('7') || digits.startsWith('8'))) {
      digits = digits.substring(1);
      digitsBeforeCursor = (digitsBeforeCursor - 1).clamp(0, digits.length);
    } else if (digits.length > 10) {
      digits = digits.substring(0, 10);
      digitsBeforeCursor = digitsBeforeCursor.clamp(0, digits.length);
    } else {
      digitsBeforeCursor = digitsBeforeCursor.clamp(0, digits.length);
    }

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final part1 = digits.substring(0, digits.length < 3 ? digits.length : 3);
    final buffer = StringBuffer('+7 ($part1');
    if (digits.length >= 3) buffer.write(')');

    if (digits.length > 3) {
      final part2 = digits.substring(3, digits.length < 6 ? digits.length : 6);
      buffer.write(' $part2');
    }
    if (digits.length > 6) {
      final part3 = digits.substring(6, digits.length < 8 ? digits.length : 8);
      buffer.write('-$part3');
    }
    if (digits.length > 8) {
      final part4 = digits.substring(
        8,
        digits.length < 10 ? digits.length : 10,
      );
      buffer.write('-$part4');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetForDigitCount(digits.length, digitsBeforeCursor),
      ),
    );
  }

  /// Позиция в отформатированной строке сразу после n-й цифры. Разделители
  /// (скобка/пробел/дефисы) вставляются, только когда их "заслуживает"
  /// полная длина номера (totalLen) — так же, как при сборке строки выше,
  /// поэтому курсор корректно перепрыгивает через них.
  static int _offsetForDigitCount(int totalLen, int n) {
    var offset = 4; // "+7 ("
    if (n <= 0) return offset;
    offset += n < 3 ? n : 3;
    if (n < 3) return offset;
    if (totalLen >= 3) offset += 1; // ")"
    if (n <= 3) return offset;
    if (totalLen > 3) offset += 1; // " "
    offset += (n < 6 ? n : 6) - 3;
    if (n <= 6) return offset;
    if (totalLen > 6) offset += 1; // "-"
    offset += (n < 8 ? n : 8) - 6;
    if (n <= 8) return offset;
    if (totalLen > 8) offset += 1; // "-"
    offset += (n < 10 ? n : 10) - 8;
    return offset;
  }

  /// Итоговый номер в формате E.164 (+7XXXXXXXXXX) для отправки в Firebase —
  /// без пробелов/скобок/дефисов, которые нужны только для отображения.
  static String toE164(String formatted) {
    var digits = formatted.replaceAll(_nonDigit, '');
    if (digits.length == 11 && digits.startsWith('7')) {
      digits = digits.substring(1);
    }
    return '+7$digits';
  }
}
