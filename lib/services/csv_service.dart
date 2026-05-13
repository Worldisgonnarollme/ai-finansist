import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/transaction.dart';

class CsvService {
  /// Entry point — pass raw file bytes for correct encoding handling.
  static List<Transaction> parseBytes(List<int> bytes) {
    final content = utf8.decode(bytes, allowMalformed: true);
    return parse(content);
  }

  static List<Transaction> parse(String content) {
    if (_isTBankStatement(content)) return _parseTBankStatement(content);
    return _parseCsvFormat(content);
  }

  // ── T-Bank / Tinkoff "Справка о движении денежных средств" ───────────────
  static bool _isTBankStatement(String content) =>
      content.contains('Движение средств за период') ||
      content.contains('Справка о движении') ||
      content.contains('Пополнения:');

  static List<Transaction> _parseTBankStatement(String content) {
    final lines = content
        .split('\n')
        .map((l) {
          final t = l.trim();
          return (t.startsWith('"') && t.endsWith('"'))
              ? t.substring(1, t.length - 1).trim()
              : t;
        })
        .where((l) => l.isNotEmpty)
        .toList();

    // Matches transaction line: DD.MM.YYYY  DD.MM.YYYY  [+-]amount ₽
    final txRe = RegExp(
      r'^(\d{2}\.\d{2}\.\d{4})\s+\d{2}\.\d{2}\.\d{4}\s+([+-][\d\s]+[.,]\d{2})\s*₽',
    );
    // Matches continuation line starting with HH:MM
    final contRe = RegExp(r'^\d{2}:\d{2}\s');

    final txs = <Transaction>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final m = txRe.firstMatch(line);
      if (m == null) continue;

      final date = _parseDate(m.group(1)!);
      final rawAmt =
          m.group(2)!.replaceAll(' ', '').replaceAll(',', '.');
      final amount = double.tryParse(rawAmt);
      if (date == null || amount == null) continue;

      // Description: after second ₽ in the line
      String desc = _descFromMain(line);

      // Check next line for description continuation
      if (i + 1 < lines.length && contRe.hasMatch(lines[i + 1])) {
        final cont = _descFromCont(lines[i + 1]);
        if (cont.isNotEmpty) desc = '$desc $cont'.trim();
        i++; // skip continuation line in next iteration
      }

      if (desc.isEmpty) desc = 'Операция';

      txs.add(Transaction(
        date: date,
        amount: amount.abs(),
        description: desc,
        type: amount >= 0 ? TransactionType.income : TransactionType.expense,
        source: TransactionSource.csv,
      ));
    }
    return txs;
  }

  static String _descFromMain(String line) {
    // Text after the SECOND ₽ symbol, trimmed, card number at end removed
    int idx = line.indexOf('₽');
    if (idx < 0) return '';
    idx = line.indexOf('₽', idx + 1);
    if (idx < 0) return '';
    String rest = line.substring(idx + 1).trim();
    // Remove trailing card identifier (4 digits or "нет"), separated by 3+ spaces
    rest = rest.replaceFirst(RegExp(r'\s{3,}\S+\s*$'), '').trim();
    return rest;
  }

  static String _descFromCont(String line) {
    // "HH:MM  HH:MM  ...description..." — strip leading time fields
    return line
        .replaceFirst(RegExp(r'^\d{2}:\d{2}\s+(?:\d{2}:\d{2}\s*)?'), '')
        .trim();
  }

  // ── Regular CSV (comma or semicolon separated) ────────────────────────────
  static List<Transaction> _parseCsvFormat(String content) {
    // Auto-detect field separator
    final firstLine = content.split('\n').first;
    final sep = firstLine.contains(';') ? ';' : ',';

    final rows = CsvToListConverter(
      fieldDelimiter: sep,
      eol: '\n',
    ).convert(content);

    if (rows.length < 2) return [];

    final headers = rows[0].map((h) => h.toString().trim()).toList();
    final isTinkoffExport = headers.contains('Дата операции') ||
        headers.contains('Дата платежа');

    final txs = <Transaction>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      try {
        final tx = isTinkoffExport
            ? _parseTinkoffExportRow(row, headers)
            : _parseGenericRow(row);
        if (tx != null) txs.add(tx);
      } catch (_) {}
    }
    return txs;
  }

  // Tinkoff/T-Bank CSV export (semicolon-separated, column names in row 0)
  static Transaction? _parseTinkoffExportRow(
      List<dynamic> row, List<String> headers) {
    int idx(String name) => headers.indexOf(name);

    final dateIdx = idx('Дата операции');
    final amtIdx = idx('Сумма операции');
    final descIdx = idx('Описание');
    final statusIdx = idx('Статус');

    if (dateIdx < 0 || amtIdx < 0 || row.length <= amtIdx) return null;

    // Skip pending / cancelled
    if (statusIdx >= 0 && row.length > statusIdx) {
      final status = row[statusIdx].toString().trim();
      if (status.isNotEmpty && status != 'OK') return null;
    }

    final date = _parseDate(row[dateIdx].toString().trim());
    final amount = double.tryParse(
        row[amtIdx].toString().replaceAll(',', '.').replaceAll(' ', ''));
    final desc = (descIdx >= 0 && row.length > descIdx)
        ? row[descIdx].toString().trim()
        : 'Операция';

    if (date == null || amount == null) return null;

    return Transaction(
      date: date,
      amount: amount.abs(),
      description: desc.isNotEmpty ? desc : 'Операция',
      type: amount >= 0 ? TransactionType.income : TransactionType.expense,
      source: TransactionSource.csv,
    );
  }

  // Generic: date, [description,] amount
  static Transaction? _parseGenericRow(List<dynamic> row) {
    if (row.length < 2) return null;

    final date = _parseDate(row[0].toString().trim());
    double? amount;
    String description = '';

    if (row.length >= 3) {
      description = row[1].toString().trim();
      amount = double.tryParse(
          row[2].toString().replaceAll(',', '.').replaceAll(' ', ''));
    } else {
      amount = double.tryParse(
          row[1].toString().replaceAll(',', '.').replaceAll(' ', ''));
    }

    if (date == null || amount == null) return null;

    return Transaction(
      date: date,
      amount: amount.abs(),
      description: description.isNotEmpty ? description : 'Операция',
      type: amount >= 0 ? TransactionType.income : TransactionType.expense,
      source: TransactionSource.csv,
    );
  }

  static DateTime? _parseDate(String s) {
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})').firstMatch(s);
    if (m != null) {
      return DateTime(
        int.parse(m.group(3)!),
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
      );
    }
    return DateTime.tryParse(s);
  }
}
