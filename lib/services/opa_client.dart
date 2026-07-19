import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/opa_decision.dart';
import '../models/opa_tax_policy_input.dart';
import 'tax_policy_input_validator.dart';

const _uuid = Uuid();

/// HTTPS-клиент к OPA (data.tax.decision) для shadow-mode.
///
/// Shadow-mode семантика: вызов НИКОГДА не блокирует и не меняет основной
/// флоу приложения. Результат используется только для логирования и
/// последующего анализа расхождений между Dart-калькулятором и
/// юридической квалификацией OPA — ни одна ветка UI не должна спрашивать
/// `result.isFlagged` для принятия решения. Любая ошибка (сеть, таймаут,
/// невалидный вход) превращается в [OpaShadowOutcome], а не в exception,
/// чтобы вызывающий код физически не мог случайно сделать на ней
/// decision-branching через try/catch вокруг бизнес-логики.
class OpaClient {
  final Uri _decisionEndpoint;
  final http.Client _httpClient;
  final Duration _timeout;
  final TaxPolicyInputValidator _validator;

  OpaClient({
    required Uri baseUrl,
    required TaxPolicyInputValidator validator,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 5),
  }) : _decisionEndpoint = baseUrl.replace(
         path: '${baseUrl.path}/v1/data/tax/decision',
       ),
       _httpClient = httpClient ?? http.Client(),
       _timeout = timeout,
       _validator = validator {
    if (_decisionEndpoint.scheme != 'https') {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'OPA shadow-mode endpoint must be HTTPS',
      );
    }
  }

  /// Валидирует вход против канонической схемы и, если он валиден,
  /// выполняет POST {"input": ...} -> data.tax.decision. Никогда не
  /// бросает исключение наружу.
  ///
  /// Каждый вызов получает собственный request_id (UUID v4), отправляемый
  /// в заголовке `X-Request-Id` — не в теле input, чтобы не трогать
  /// tax_policy_input.schema.json. Возвращается в любом [OpaShadowOutcome]
  /// (включая skip/error) для сквозной корреляции в логах.
  Future<OpaShadowOutcome> evaluateShadow(OpaTaxPolicyInput input) async {
    final requestId = _uuid.v4();
    final inputJson = input.toJson();
    final validation = _validator.validate(inputJson);
    if (!validation.isValid) {
      return OpaShadowSkippedInvalidInput(requestId, validation.errors);
    }

    try {
      final response = await _httpClient
          .post(
            _decisionEndpoint,
            headers: {
              'Content-Type': 'application/json',
              'X-Request-Id': requestId,
            },
            body: jsonEncode({'input': inputJson}),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OpaShadowError(
          requestId,
          'OPA HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['result'] is! Map) {
        return OpaShadowError(
          requestId,
          'OPA response missing "result" object',
        );
      }

      return OpaShadowEvaluated(
        requestId,
        OpaDecision.fromJson(decoded['result'] as Map<String, dynamic>),
      );
    } catch (e) {
      return OpaShadowError(requestId, e.toString());
    }
  }

  void close() => _httpClient.close();
}
