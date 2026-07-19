import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_financial_agent/services/tax_policy_input_validator.dart';

Map<String, dynamic> _validIncome() => {
      'user': {'tax_mode': 'OSNO', 'is_ip': true},
      'transaction': {
        'id': 't-1',
        'direction': 'income',
        'amount': 1000.0,
        'date': '2026-06-01',
        'counterparty_type': 'company',
        'related_to_business': true,
        'linked_document': true,
        'has_vat_invoice': false,
      },
    };

Map<String, dynamic> _validExpense() => {
      'user': {'tax_mode': 'OSNO', 'is_ip': true},
      'transaction': {
        'id': 't-2',
        'direction': 'expense',
        'amount': 5000.0,
        'date': '2026-06-01',
        'counterparty_type': 'company',
        'related_to_business': true,
        'linked_document': true,
        'has_vat_invoice': false,
        'excluded_under_art_270': false,
      },
    };

Map<String, dynamic> _validAusnIncome() => {
      'user': {'tax_mode': 'AUSN_INCOME'},
      'transaction': {
        'id': 't-ausn-1',
        'direction': 'income',
        'amount': 10000.0,
        'date': '2026-06-01',
        'counterparty_type': 'company',
        'related_to_business': true,
        'linked_document': true,
        'has_vat_invoice': false,
        'confirmed_by': 'authorized_bank',
      },
      'context': {
        'ausn': {
          'pilot_region_confirmed': true,
          'annual_income': 10000000,
          'avg_headcount': 3,
          'residual_fixed_assets_value': 5000000,
          'has_branches': false,
          'excluded_activity': false,
        },
      },
    };

Map<String, dynamic> _validEshnIncome() => {
      'user': {'tax_mode': 'ESHN'},
      'transaction': {
        'id': 't-eshn-1',
        'direction': 'income',
        'amount': 10000.0,
        'date': '2026-06-01',
        'counterparty_type': 'company',
        'related_to_business': true,
        'linked_document': true,
        'has_vat_invoice': false,
        'is_own_production': true,
      },
      'context': {
        'eshn': {'agri_income_share': 0.85},
      },
    };

Map<String, dynamic> _validPsnIncome() => {
      'user': {'tax_mode': 'PSN', 'is_ip': true},
      'transaction': {
        'id': 't-psn-1',
        'direction': 'income',
        'amount': 10000.0,
        'date': '2026-06-01',
        'counterparty_type': 'company',
        'related_to_business': true,
        'linked_document': true,
        'has_vat_invoice': false,
        'activity_covered_by_patent': true,
      },
      'context': {
        'psn': {
          'regional_activity_allowed': true,
          'annual_income_all_patents': 10000000,
          'avg_headcount_all_patents': 5,
          'hall_area_applicable': false,
        },
      },
    };

Map<String, dynamic> _validNpdIncome() => {
      'user': {'tax_mode': 'NPD'},
      'transaction': {
        'id': 't-npd-1',
        'direction': 'income',
        'amount': 10000.0,
        'date': '2026-06-01',
        'counterparty_type': 'company',
        'related_to_business': true,
        'linked_document': true,
        'has_vat_invoice': false,
      },
      'context': {
        'npd': {
          'annual_income': 1000000,
          'has_employees': false,
          'is_resale': false,
          'sells_excisable_or_marked_goods': false,
          'mines_or_sells_minerals': false,
          'agent_scheme_without_exception': false,
          'combines_with_other_regime_same_activity': false,
        },
      },
    };

void main() {
  late TaxPolicyInputValidator validator;

  setUpAll(() {
    // Тест читает actual файл схемы с диска (не дублирует его содержимое),
    // поэтому правки opa/tax_policy_input.schema.json сразу видны здесь.
    final schemaJson =
        File('opa/tax_policy_input.schema.json').readAsStringSync();
    validator = TaxPolicyInputValidator.fromSchemaJson(schemaJson);
  });

  test('валидный вход проходит без ошибок', () {
    final result = validator.validate(_validIncome());
    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('related_to_business обязателен', () {
    final input = _validIncome();
    (input['transaction'] as Map).remove('related_to_business');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('linked_document обязателен', () {
    final input = _validIncome();
    (input['transaction'] as Map).remove('linked_document');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('has_vat_invoice обязателен', () {
    final input = _validIncome();
    (input['transaction'] as Map).remove('has_vat_invoice');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('валидный расход (с excluded_under_art_270) проходит без ошибок', () {
    final result = validator.validate(_validExpense());
    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('excluded_under_art_270 обязателен для расходных операций', () {
    final input = _validExpense();
    (input['transaction'] as Map).remove('excluded_under_art_270');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('excluded_under_art_270 не требуется для доходных операций', () {
    final input = _validIncome();
    expect((input['transaction'] as Map).containsKey('excluded_under_art_270'),
        isFalse);
    expect(validator.validate(input).isValid, isTrue);
  });

  test('is_ip обязателен при tax_mode=OSNO', () {
    final input = _validIncome();
    (input['user'] as Map).remove('is_ip');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('is_ip не требуется для не-ОСНО/не-ПСН режимов', () {
    final input = _validNpdIncome();
    expect((input['user'] as Map).containsKey('is_ip'), isFalse);
    expect(validator.validate(input).isValid, isTrue);
  });

  test('валидный вход НПД проходит без ошибок', () {
    expect(validator.validate(_validNpdIncome()).isValid, isTrue);
  });

  test('context.npd обязателен для tax_mode=NPD', () {
    final input = _validNpdIncome();
    input.remove('context');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('context.npd.has_employees обязателен внутри npd', () {
    final input = _validNpdIncome();
    (input['context']['npd'] as Map).remove('has_employees');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('валидный вход АУСН проходит без ошибок', () {
    expect(validator.validate(_validAusnIncome()).isValid, isTrue);
  });

  test('confirmed_by обязателен для операций на АУСН', () {
    final input = _validAusnIncome();
    (input['transaction'] as Map).remove('confirmed_by');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('context.ausn обязателен для tax_mode=AUSN_INCOME', () {
    final input = _validAusnIncome();
    input.remove('context');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('context.ausn.avg_headcount обязателен внутри ausn', () {
    final input = _validAusnIncome();
    (input['context']['ausn'] as Map).remove('avg_headcount');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('валидный вход ЕСХН проходит без ошибок', () {
    expect(validator.validate(_validEshnIncome()).isValid, isTrue);
  });

  test('is_own_production обязателен для доходных операций на ЕСХН', () {
    final input = _validEshnIncome();
    (input['transaction'] as Map).remove('is_own_production');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('context.eshn.agri_income_share обязателен для tax_mode=ESHN', () {
    final input = _validEshnIncome();
    input.remove('context');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('валидный вход ПСН проходит без ошибок', () {
    expect(validator.validate(_validPsnIncome()).isValid, isTrue);
  });

  test('is_ip обязателен при tax_mode=PSN', () {
    final input = _validPsnIncome();
    (input['user'] as Map).remove('is_ip');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('activity_covered_by_patent обязателен для доходных операций на ПСН',
      () {
    final input = _validPsnIncome();
    (input['transaction'] as Map).remove('activity_covered_by_patent');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('context.psn обязателен для tax_mode=PSN', () {
    final input = _validPsnIncome();
    input.remove('context');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('лишнее поле в transaction запрещено (additionalProperties: false)',
      () {
    final input = _validIncome();
    (input['transaction'] as Map)['unexpected_field'] = 'sneaky';
    expect(validator.validate(input).isValid, isFalse);
  });

  test('лишнее поле в корне запрещено (additionalProperties: false)', () {
    final input = _validIncome();
    input['unexpected_root_field'] = 'sneaky';
    expect(validator.validate(input).isValid, isFalse);
  });

  test('лишнее поле в context запрещено (additionalProperties: false)', () {
    final input = _validIncome();
    input['context'] = {'unexpected_context_field': true};
    expect(validator.validate(input).isValid, isFalse);
  });

  test('недопустимый tax_mode отклоняется', () {
    final input = _validIncome();
    (input['user'] as Map)['tax_mode'] = 'NOT_A_REAL_MODE';
    expect(validator.validate(input).isValid, isFalse);
  });

  test('недопустимый direction отклоняется', () {
    final input = _validIncome();
    (input['transaction'] as Map)['direction'] = 'sideways';
    expect(validator.validate(input).isValid, isFalse);
  });

  test('amount должен быть строго больше нуля', () {
    final input = _validIncome();
    (input['transaction'] as Map)['amount'] = 0;
    expect(validator.validate(input).isValid, isFalse);
  });

  test('отсутствие transaction целиком отклоняется', () {
    final input = _validIncome();
    input.remove('transaction');
    expect(validator.validate(input).isValid, isFalse);
  });

  test('validateOrThrow бросает исключение на невалидном входе', () {
    final input = _validIncome();
    (input['transaction'] as Map).remove('has_vat_invoice');
    expect(
      () => validator.validateOrThrow(input),
      throwsA(isA<TaxPolicyInputValidationException>()),
    );
  });

  test('validateOrThrow не бросает на валидном входе', () {
    expect(() => validator.validateOrThrow(_validIncome()), returnsNormally);
  });

  test('fromAsset реально грузит canonical-файл схемы как Flutter asset',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final assetValidator = await TaxPolicyInputValidator.fromAsset();
    expect(assetValidator.validate(_validIncome()).isValid, isTrue);
  });
}
