import 'package:flutter/foundation.dart' show debugPrint;
import '../models/opa_decision.dart';
import '../models/transaction.dart';

/// Логирует расхождения между Dart-калькулятором (taxRelevance) и OPA
/// (shadow-mode) — никогда не меняет transaction, никогда не влияет на UI.
///
/// Три различаемых случая (см. OpaShadowOutcome): согласие/несогласие,
/// "недостаточно данных" (вход не прошёл схему до отправки в OPA) и
/// "OPA недоступен" (сеть/таймаут) — смешивать их в одну метрику "процент
/// расхождений" даёт ложную картину, поэтому они логируются отдельно.
void logOpaShadowOutcome(Transaction transaction, OpaShadowOutcome outcome) {
  final dartTaxable = transaction.taxRelevance == TaxRelevance.taxable;

  final requestId = outcome.requestId;
  switch (outcome) {
    case OpaShadowSkippedInvalidInput(validationErrors: final errors):
      debugPrint(
        '[opa-shadow] SKIP tx=${transaction.id} request_id=$requestId: '
        'недостаточно структурных данных для вызова OPA '
        '(${errors.length} ошибок схемы)',
      );
    case OpaShadowError(message: final message):
      debugPrint(
        '[opa-shadow] ERROR tx=${transaction.id} request_id=$requestId: $message',
      );
    case OpaShadowEvaluated(decision: final decision):
      final disagreement = dartTaxable && decision.isFlagged;
      final level = disagreement ? 'MISMATCH' : 'OK';
      debugPrint(
        '[opa-shadow] $level tx=${transaction.id} request_id=$requestId: '
        'dart.taxable=$dartTaxable '
        'opa.needs_review=${decision.needsReview} '
        'opa.compliant=${decision.compliant} '
        'reason="${decision.reason}"',
      );
  }
}
