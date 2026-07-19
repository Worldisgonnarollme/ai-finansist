/// Типизированное решение OPA (data.tax.decision) для shadow-mode.
///
/// Форма ответа НЕ единообразна между режимами (см. docs/adr/0007, 0008):
/// ОСНО/УСН/НПД возвращают needs_review, АУСН/ЕСХН/ПСН — compliant. Эта
/// модель не навязывает единую форму (это было бы ложью о контракте),
/// а явно различает оба словаря и считает агрегированный сигнал
/// [isFlagged] для сравнения с решением Dart-калькулятора.
class OpaDecision {
  final bool? needsReview;
  final bool? compliant;
  final String? reason;
  final List<String> legalBasis;
  final Map<String, dynamic> raw;

  const OpaDecision({
    this.needsReview,
    this.compliant,
    this.reason,
    this.legalBasis = const [],
    required this.raw,
  });

  /// true — OPA не подтверждает безопасность автоматического решения:
  /// либо явно needs_review, либо явно not compliant. Ничего из этого не
  /// должно использоваться для блокировки UI — только для логирования.
  bool get isFlagged => needsReview == true || compliant == false;

  factory OpaDecision.fromJson(Map<String, dynamic> json) {
    final legalBasisRaw = json['legal_basis'];
    return OpaDecision(
      needsReview: json['needs_review'] as bool?,
      compliant: json['compliant'] as bool?,
      reason: json['reason'] as String?,
      legalBasis: legalBasisRaw is List
          ? legalBasisRaw.map((e) => e.toString()).toList()
          : const [],
      raw: json,
    );
  }
}

/// Результат попытки shadow-evaluation — намеренно НЕ просто
/// `Future<OpaDecision>`: "не удалось спросить OPA" (сеть/таймаут) и
/// "не хватило структурных данных, чтобы вообще сформировать вход"
/// (Transaction пока не содержит related_to_business/linked_document/
/// counterparty_type и т.п.) — это два разных, одинаково важных для
/// аналитики случая, которые нельзя путать с "OPA согласен".
///
/// [requestId] — сгенерирован клиентом на каждый вызов [OpaClient.
/// evaluateShadow] и отправлен в заголовке `X-Request-Id` (не в теле
/// input — это транспортный/observability-факт, не часть юридического
/// контракта tax_policy_input.schema.json, поэтому схему трогать не
/// пришлось). Позволяет сопоставить строку в логах приложения с записью
/// в decision log самого OPA-сервера при отладке конкретного вызова.
sealed class OpaShadowOutcome {
  final String requestId;
  const OpaShadowOutcome(this.requestId);
}

class OpaShadowEvaluated extends OpaShadowOutcome {
  final OpaDecision decision;
  const OpaShadowEvaluated(super.requestId, this.decision);
}

/// Вход не прошёл TaxPolicyInputValidator до отправки — OPA не вызывался
/// вообще (ноль сетевых запросов на заведомо невалидный вход).
class OpaShadowSkippedInvalidInput extends OpaShadowOutcome {
  final List<String> validationErrors;
  const OpaShadowSkippedInvalidInput(super.requestId, this.validationErrors);
}

/// Сетевая ошибка, таймаут или не-2xx ответ — OPA недоступен. Не влияет
/// на основной флоу приложения.
class OpaShadowError extends OpaShadowOutcome {
  final String message;
  const OpaShadowError(super.requestId, this.message);
}
