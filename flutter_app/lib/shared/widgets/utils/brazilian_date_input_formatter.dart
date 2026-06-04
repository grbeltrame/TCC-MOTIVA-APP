import 'package:flutter/services.dart';

class BrazilianDateInputFormatter extends TextInputFormatter {
  const BrazilianDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final selectionEnd =
        newValue.selection.end.clamp(0, newValue.text.length).toInt();
    final digitsBeforeCursor =
        newValue.text
            .substring(0, selectionEnd)
            .replaceAll(RegExp(r'\D'), '')
            .length;
    final allDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = allDigits.length > 8 ? allDigits.substring(0, 8) : allDigits;

    final formatted = _formatDigits(digits);
    final cursor = _cursorOffsetForDigitCount(
      formatted,
      digitsBeforeCursor.clamp(0, digits.length),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  String _formatDigits(String digits) {
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  int _cursorOffsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;

    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted.codeUnitAt(i))) seen++;
      if (seen == digitCount) return i + 1;
    }

    return formatted.length;
  }

  bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
