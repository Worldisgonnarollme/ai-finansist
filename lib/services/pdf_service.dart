import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/transaction.dart';

class PdfService {
  static String lastExtractedText = '';

  static List<Transaction> parseBytes(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();

    lastExtractedText = text;
    // ignore: avoid_print
    print('=== PDF TEXT (first 3000) ===\n'
        '${text.substring(0, text.length.clamp(0, 3000))}\n=== END ===');

    return _parseText(text);
  }

  static List<Transaction> _parseText(String text) {
    // Try bank-specific parsers first
    if (_isGazprombank(text)) {
      final r = _parseGazpromMultiLine(text);
      if (r.isNotEmpty) return r;
    }
    if (_isSberbank(text)) {
      final r = _parseSberbankMultiLine(text);
      if (r.isNotEmpty) return r;
      final r2 = _parseSberbankSingleLine(text);
      if (r2.isNotEmpty) return r2;
    }
    // Universal fallbacks
    final r = _parseMultiLineBalanceTracking(text);
    if (r.isNotEmpty) return r;
    return _parseGenericSigned(text);
  }

  // ── Detection ──────────────────────────────────────────────────────────────

  static bool _isGazprombank(String text) =>
      text.contains('GAZPRUM') ||
      text.contains('gazprombank') ||
      text.contains('ГАЗПРОМБАНК') ||
      text.contains('Газпромбанк');

  static bool _isSberbank(String text) =>
      text.contains('sberbank.ru') ||
      text.contains('СберБанк') ||
      text.contains('Сбербанк') ||
      text.contains('платёжному счёту') ||
      text.contains('платежному счету');

  // ── Газпромбанк: multi-line format ────────────────────────────────────────
  // Syncfusion extracts each table cell on its own line:
  //   "DD.MM.YYYY"          ← date alone
  //   "Описание операции"   ← description alone
  //   "+X XXX,XX"           ← signed amount alone (+ income, - expense)
  //   "X XXX,XX"            ← balance alone
  static List<Transaction> _parseGazpromMultiLine(String text) {
    final txs = <Transaction>[];
    final lines = _lines(text);

    final dateSoloRe = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
    // Amount alone on a line, with mandatory +/- sign
    final signedAmtSoloRe =
        RegExp(r'^([+-])\s*([\d]+(?:[\s ][\d]{3})*[,.][\d]{2})$');

    int i = 0;
    while (i < lines.length) {
      if (!dateSoloRe.hasMatch(lines[i])) {
        i++;
        continue;
      }

      final date = _parseDate(lines[i]);
      if (date == null || i + 2 >= lines.length) {
        i++;
        continue;
      }

      final descLine = lines[i + 1]; // description
      final amtLine = lines[i + 2];  // signed amount

      // Description must not be a header keyword or another date
      if (_isHeaderText(descLine) || dateSoloRe.hasMatch(descLine)) {
        i++;
        continue;
      }

      final sm = signedAmtSoloRe.firstMatch(amtLine);
      if (sm == null) {
        i++;
        continue;
      }

      final sign = sm.group(1)!;
      final amount = _parseAmount(sm.group(2)!);
      if (amount == null || amount == 0) {
        i++;
        continue;
      }

      txs.add(_tx(
        date,
        amount,
        descLine.isNotEmpty ? descLine : 'Операция',
        sign == '+' ? TransactionType.income : TransactionType.expense,
      ));

      i += 4; // consume: date + description + amount + balance
    }

    return txs;
  }

  // ── Сбербанк: multi-line format ───────────────────────────────────────────
  // Extracted format (guessed; will confirm from console output):
  //   "DD.MM.YYYY"
  //   "HH:MM"
  //   "Категория"
  //   "Описание операции"
  //   "[+]Amount"
  //   "Balance"
  static List<Transaction> _parseSberbankMultiLine(String text) {
    final txs = <Transaction>[];
    final lines = _lines(text);

    final dateSoloRe = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
    final timeSoloRe = RegExp(r'^\d{2}:\d{2}$');
    // Unsigned or signed amount alone
    final amtSoloRe =
        RegExp(r'^([+-]?)([\d]+(?:[\s ][\d]{3})*[,.][\d]{2})$');
    final authCodeRe = RegExp(r'^\d{4,6}$');

    int i = 0;
    while (i < lines.length) {
      if (!dateSoloRe.hasMatch(lines[i])) {
        i++;
        continue;
      }

      final date = _parseDate(lines[i]);
      if (date == null) {
        i++;
        continue;
      }

      // Skip time line if present
      int j = i + 1;
      if (j < lines.length && timeSoloRe.hasMatch(lines[j])) j++;

      // Next non-trivial lines should be category / description
      String desc = '';
      int amtIdx = -1;

      // Scan up to 5 lines ahead for an amount
      for (int k = j; k < lines.length && k < j + 6; k++) {
        final m = amtSoloRe.firstMatch(lines[k]);
        if (m != null) {
          amtIdx = k;
          break;
        }
        // Skip auth codes and dates
        if (authCodeRe.hasMatch(lines[k])) continue;
        if (dateSoloRe.hasMatch(lines[k])) break;
        // Accumulate description (skip header keywords)
        if (!_isHeaderText(lines[k]) && lines[k].length > 1) {
          desc = desc.isEmpty ? lines[k] : '$desc ${lines[k]}';
        }
      }

      if (amtIdx < 0) {
        i++;
        continue;
      }

      final m = amtSoloRe.firstMatch(lines[amtIdx])!;
      final sign = m.group(1)!;
      final amount = _parseAmount(m.group(2)!);
      if (amount == null || amount == 0) {
        i++;
        continue;
      }

      // For Сбербанк: income marked with +, expense has no sign
      final isIncome = sign == '+';

      // Clean description
      desc = desc
          .replaceAll(RegExp(r'Операция по счету[\s\*\d]+'), '')
          .trim();
      if (desc.isEmpty) desc = 'Операция';

      txs.add(_tx(date, amount, desc,
          isIncome ? TransactionType.income : TransactionType.expense));

      i = amtIdx + 2; // skip amount + balance
    }

    return txs;
  }

  // ── Сбербанк: single-line format (fallback) ───────────────────────────────
  // "DD.MM.YYYY HH:MM  Category  [+]Amount  Balance"
  static List<Transaction> _parseSberbankSingleLine(String text) {
    final txs = <Transaction>[];
    final lines = _lines(text);
    final hRe = RegExp(r'^(\d{2}\.\d{2}\.\d{4})\s+\d{2}:\d{2}\s+(.+)$');
    final dRe = RegExp(r'^\d{2}\.\d{2}\.\d{4}\s+\d{4,6}\s+(.+)$');
    final numRe = RegExp(r'([+-]?)([\d]+(?:[\s ][\d]{3})*[,.][\d]{2})');

    for (int i = 0; i < lines.length; i++) {
      final hm = hRe.firstMatch(lines[i]);
      if (hm == null) continue;
      final date = _parseDate(hm.group(1)!);
      final rest = hm.group(2)!;
      if (date == null) continue;

      final nums = numRe.allMatches(rest).toList();
      if (nums.isEmpty) continue;

      final amtM = nums.first;
      final sign = amtM.group(1)!;
      final amount = _parseAmount(amtM.group(2)!);
      if (amount == null || amount == 0) continue;

      String desc = rest.substring(0, amtM.start).trim();
      if (i + 1 < lines.length) {
        final dm = dRe.firstMatch(lines[i + 1]);
        if (dm != null) {
          final detail = dm
              .group(1)!
              .trim()
              .replaceAll(RegExp(r'\.\s*Операция по счету[\s\*\d]+$'), '')
              .trim();
          if (detail.isNotEmpty) desc = detail;
          i++;
        }
      }
      if (desc.isEmpty) desc = 'Операция';

      txs.add(_tx(date, amount, desc,
          sign == '+' ? TransactionType.income : TransactionType.expense));
    }

    return txs;
  }

  // ── Universal multi-line balance-tracking ─────────────────────────────────
  // Handles any bank where each cell is on its own line.
  // Determines income/expense from whether balance went up or down.
  static List<Transaction> _parseMultiLineBalanceTracking(String text) {
    final txs = <Transaction>[];
    final lines = _lines(text);

    final dateSoloRe = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
    final amtSoloRe =
        RegExp(r'^([+-]?)([\d]+(?:[\s ][\d]{3})*[,.][\d]{2})$');

    double? prevBalance;
    int i = 0;

    while (i < lines.length) {
      if (!dateSoloRe.hasMatch(lines[i])) {
        i++;
        continue;
      }

      final date = _parseDate(lines[i]);
      if (date == null || i + 2 >= lines.length) {
        i++;
        continue;
      }

      final descLine = lines[i + 1];
      if (_isHeaderText(descLine) || dateSoloRe.hasMatch(descLine)) {
        i++;
        continue;
      }

      // Find amount and balance in the next few lines
      double? amount;
      double? balance;
      String? sign;
      int consumed = 2;

      for (int k = i + 2; k < lines.length && k < i + 6; k++) {
        final m = amtSoloRe.firstMatch(lines[k]);
        if (m == null) break;
        consumed = k - i + 1;
        if (amount == null) {
          sign = m.group(1)!;
          amount = _parseAmount(m.group(2)!);
        } else {
          balance = _parseAmount(m.group(2)!);
          break;
        }
      }

      if (amount == null || amount == 0) {
        i++;
        continue;
      }

      TransactionType type;
      if (sign == '+') {
        type = TransactionType.income;
      } else if (sign == '-') {
        type = TransactionType.expense;
      } else if (prevBalance != null && balance != null) {
        type = balance >= prevBalance - 0.005
            ? TransactionType.income
            : TransactionType.expense;
      } else {
        type = _guessType(descLine);
      }

      if (balance != null) prevBalance = balance;

      txs.add(_tx(date, amount, descLine, type));
      i += consumed + 1;
    }

    return txs;
  }

  // ── Generic signed-amount on same line as date (fallback) ─────────────────
  static List<Transaction> _parseGenericSigned(String text) {
    final txs = <Transaction>[];
    final lines = _lines(text);
    final txRe = RegExp(
        r'^(\d{2}\.\d{2}\.\d{4})\s+(.{2,80}?)\s+([+-]\s*[\d]+(?:[\s ][\d]{3})*[,.][\d]{2})');
    for (final line in lines) {
      final m = txRe.firstMatch(line);
      if (m == null) continue;
      final date = _parseDate(m.group(1)!);
      final desc = m.group(2)!.trim();
      final rawAmt =
          m.group(3)!.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
      final amount = double.tryParse(rawAmt);
      if (date == null || amount == null) continue;
      txs.add(_tx(date, amount.abs(), desc.isNotEmpty ? desc : 'Операция',
          amount >= 0 ? TransactionType.income : TransactionType.expense));
    }
    return txs;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<String> _lines(String text) => text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  static bool _isHeaderText(String s) =>
      s.startsWith('Дата') ||
      s.startsWith('Содержание') ||
      s.startsWith('Приход') ||
      s.startsWith('Расход') ||
      s.startsWith('Остаток') ||
      s.startsWith('ДАТА') ||
      s.startsWith('КАТЕГОРИЯ') ||
      s.startsWith('СУММА') ||
      s.startsWith('*без');

  static TransactionType _guessType(String text) {
    final l = text.toLowerCase();
    if (l.contains('пополнен') ||
        l.contains('зачислен') ||
        l.contains('поступлен') ||
        l.contains('стипендия') ||
        l.contains('зарплата') ||
        l.contains('доход')) {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }

  static double? _parseAmount(String raw) => double.tryParse(
      raw.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.'));

  static Transaction _tx(
          DateTime date, double amount, String desc, TransactionType type) =>
      Transaction(
        date: date,
        amount: amount,
        description: desc,
        type: type,
        source: TransactionSource.csv,
      );

  static DateTime? _parseDate(String s) {
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})').firstMatch(s);
    if (m != null) {
      return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!),
          int.parse(m.group(1)!));
    }
    return DateTime.tryParse(s);
  }
}
