import 'package:flutter/services.dart' show rootBundle;
import 'package:json_schema/json_schema.dart';

/// Результат проверки входа для OPA против opa/tax_policy_input.schema.json.
class TaxPolicyInputValidationResult {
  final bool isValid;
  final List<String> errors;

  TaxPolicyInputValidationResult(this.isValid, this.errors);
}

/// Закрывает лазейку, описанную в opa/tax_policy_input.schema.json, на
/// границе перед вызовом OPA: ни ИИ, ни разработчик не могут отправить на
/// классификацию вход без related_to_business/linked_document/has_vat_invoice
/// или с произвольными лишними полями — схема (additionalProperties: false)
/// валидируется здесь по-настоящему, а не только декларируется в .json.
///
/// Схема не дублируется в Dart-коде — этот класс всегда читает actual файл
/// opa/tax_policy_input.schema.json (как Flutter asset, см. pubspec.yaml),
/// поэтому правки схемы автоматически вступают в силу без риска расхождения.
class TaxPolicyInputValidator {
  static const String assetPath = 'opa/tax_policy_input.schema.json';

  final JsonSchema _schema;

  TaxPolicyInputValidator._(this._schema);

  /// Используется в работающем приложении — грузит канонический файл схемы
  /// как Flutter asset.
  static Future<TaxPolicyInputValidator> fromAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    return TaxPolicyInputValidator.fromSchemaJson(raw);
  }

  /// Используется в тестах и не-Flutter контекстах — принимает уже
  /// прочитанное содержимое файла схемы.
  factory TaxPolicyInputValidator.fromSchemaJson(String schemaJson) {
    return TaxPolicyInputValidator._(JsonSchema.create(schemaJson));
  }

  TaxPolicyInputValidationResult validate(Map<String, dynamic> input) {
    final result = _schema.validate(input);
    return TaxPolicyInputValidationResult(
      result.isValid,
      result.errors.map((e) => e.toString()).toList(),
    );
  }

  /// Бросает [TaxPolicyInputValidationException], если вход не проходит
  /// схему — для мест, где невалидный вход должен прервать пайплайн до
  /// вызова OPA, а не молча продолжить с дефолтами.
  void validateOrThrow(Map<String, dynamic> input) {
    final result = validate(input);
    if (!result.isValid) {
      throw TaxPolicyInputValidationException(result.errors);
    }
  }
}

class TaxPolicyInputValidationException implements Exception {
  final List<String> errors;

  TaxPolicyInputValidationException(this.errors);

  @override
  String toString() =>
      'TaxPolicyInputValidationException: вход не соответствует '
      'tax_policy_input.schema.json:\n${errors.join('\n')}';
}
