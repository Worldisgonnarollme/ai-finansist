import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ai_financial_agent/models/opa_decision.dart';
import 'package:ai_financial_agent/models/opa_tax_policy_input.dart';
import 'package:ai_financial_agent/services/opa_client.dart';
import 'package:ai_financial_agent/services/tax_policy_input_validator.dart';

OpaTaxPolicyInput _validOsnoIncome() => const OpaTaxPolicyInput(
      user: OpaUser(taxMode: 'OSNO', isIp: true),
      transaction: OpaTransaction(
        id: 't-1',
        direction: 'income',
        amount: 1000,
        date: '2026-06-01',
        counterpartyType: 'company',
        relatedToBusiness: true,
        linkedDocument: true,
        hasVatInvoice: false,
      ),
    );

OpaTaxPolicyInput _incompleteInput() => const OpaTaxPolicyInput(
      user: OpaUser(taxMode: 'OSNO', isIp: true),
      transaction: OpaTransaction(
        id: 't-2',
        direction: 'income',
        amount: 1000,
        date: '2026-06-01',
        // counterparty_type/related_to_business/linked_document/
        // has_vat_invoice намеренно отсутствуют — это ровно случай
        // "Transaction пока не знает этих фактов" (opa_shadow_mapper.dart).
      ),
    );

void main() {
  late TaxPolicyInputValidator validator;

  setUpAll(() {
    final schemaJson =
        File('opa/tax_policy_input.schema.json').readAsStringSync();
    validator = TaxPolicyInputValidator.fromSchemaJson(schemaJson);
  });

  test('конструктор отклоняет non-HTTPS baseUrl', () {
    expect(
      () => OpaClient(baseUrl: Uri.parse('http://insecure.example'), validator: validator),
      throwsArgumentError,
    );
  });

  test('невалидный вход не уходит в сеть — сразу OpaShadowSkippedInvalidInput',
      () async {
    var called = false;
    final client = OpaClient(
      baseUrl: Uri.parse('https://opa.example'),
      validator: validator,
      httpClient: MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    final outcome = await client.evaluateShadow(_incompleteInput());

    expect(called, isFalse);
    expect(outcome, isA<OpaShadowSkippedInvalidInput>());
    expect(
      (outcome as OpaShadowSkippedInvalidInput).validationErrors,
      isNotEmpty,
    );
    // request_id генерируется даже для пропущенного вызова — иначе лог
    // "SKIP" нельзя было бы сопоставить с конкретной попыткой.
    expect(outcome.requestId, isNotEmpty);
  });

  test('валидный вход уходит на POST {url}/v1/data/tax/decision с {"input": ...}',
      () async {
    Uri? capturedUri;
    Map<String, dynamic>? capturedBody;
    String? capturedHeaderRequestId;

    final client = OpaClient(
      baseUrl: Uri.parse('https://opa.example'),
      validator: validator,
      httpClient: MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        capturedHeaderRequestId = request.headers['X-Request-Id'];
        return http.Response(
          jsonEncode({
            'result': {
              'needs_review': false,
              'reason': 'ok',
              'legal_basis': ['НК РФ ст. 210'],
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );

    final outcome = await client.evaluateShadow(_validOsnoIncome());

    expect(capturedUri.toString(), 'https://opa.example/v1/data/tax/decision');
    expect(capturedBody, containsPair('input', isA<Map>()));
    expect((capturedBody!['input'] as Map)['user'], {'tax_mode': 'OSNO', 'is_ip': true});
    // request_id уходит в заголовок (не в тело — схему не трогали) и
    // совпадает с тем, что возвращается в outcome для корреляции в логах.
    expect(capturedHeaderRequestId, isNotEmpty);
    expect(capturedHeaderRequestId, outcome.requestId);

    expect(outcome, isA<OpaShadowEvaluated>());
    final decision = (outcome as OpaShadowEvaluated).decision;
    expect(decision.needsReview, isFalse);
    expect(decision.legalBasis, ['НК РФ ст. 210']);
    expect(decision.isFlagged, isFalse);
  });

  test('каждый вызов получает уникальный request_id', () async {
    final client = OpaClient(
      baseUrl: Uri.parse('https://opa.example'),
      validator: validator,
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'result': {'needs_review': false}}),
          200,
          headers: const {'content-type': 'application/json'},
        ),
      ),
    );

    final first = await client.evaluateShadow(_validOsnoIncome());
    final second = await client.evaluateShadow(_validOsnoIncome());

    expect(first.requestId, isNotEmpty);
    expect(second.requestId, isNotEmpty);
    expect(first.requestId, isNot(second.requestId));
  });

  test('compliant:false помечается как isFlagged', () async {
    final client = OpaClient(
      baseUrl: Uri.parse('https://opa.example'),
      validator: validator,
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'result': {'compliant': false, 'reason': 'no'}}),
          200,
        );
      }),
    );

    final outcome = await client.evaluateShadow(_validOsnoIncome());
    final decision = (outcome as OpaShadowEvaluated).decision;
    expect(decision.isFlagged, isTrue);
  });

  test('HTTP-ошибка (500) превращается в OpaShadowError, не в exception',
      () async {
    final client = OpaClient(
      baseUrl: Uri.parse('https://opa.example'),
      validator: validator,
      httpClient: MockClient((request) async => http.Response('boom', 500)),
    );

    final outcome = await client.evaluateShadow(_validOsnoIncome());
    expect(outcome, isA<OpaShadowError>());
  });

  test('сетевое исключение превращается в OpaShadowError, не пробрасывается',
      () async {
    final client = OpaClient(
      baseUrl: Uri.parse('https://opa.example'),
      validator: validator,
      httpClient: MockClient((request) async => throw Exception('no network')),
    );

    final outcome = await client.evaluateShadow(_validOsnoIncome());
    expect(outcome, isA<OpaShadowError>());
  });
}
