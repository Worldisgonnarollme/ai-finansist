import 'dart:convert';

class TaxSettings {
  final double usn6Rate;
  final double usn15Rate;
  final double eshnRate;
  final double patentAnnualCost;
  final int employeeCount;
  final DateTime? registrationDate;
  // Остаточная стоимость основных средств (только УСН) — лимит
  // 218 млн ₽, ст. 346.12 НК РФ.
  final double fixedAssetsValue;
  // Дата начала действия патента и его срок в месяцах (1–12) — только
  // ПСН. Определяют график уплаты (единым платежом до 6 мес.,
  // двумя частями от 6 до 12 мес.).
  final DateTime? patentStartDate;
  final int patentDurationMonths;

  bool get hasEmployees => employeeCount > 0;

  const TaxSettings({
    this.usn6Rate = 6.0,
    this.usn15Rate = 15.0,
    this.eshnRate = 6.0,
    this.patentAnnualCost = 0.0,
    this.employeeCount = 0,
    this.registrationDate,
    this.fixedAssetsValue = 0.0,
    this.patentStartDate,
    this.patentDurationMonths = 12,
  });

  TaxSettings copyWith({
    double? usn6Rate,
    double? usn15Rate,
    double? eshnRate,
    double? patentAnnualCost,
    int? employeeCount,
    DateTime? registrationDate,
    bool clearRegistrationDate = false,
    double? fixedAssetsValue,
    DateTime? patentStartDate,
    bool clearPatentStartDate = false,
    int? patentDurationMonths,
  }) => TaxSettings(
    usn6Rate: usn6Rate ?? this.usn6Rate,
    usn15Rate: usn15Rate ?? this.usn15Rate,
    eshnRate: eshnRate ?? this.eshnRate,
    patentAnnualCost: patentAnnualCost ?? this.patentAnnualCost,
    employeeCount: employeeCount ?? this.employeeCount,
    registrationDate: clearRegistrationDate
        ? null
        : (registrationDate ?? this.registrationDate),
    fixedAssetsValue: fixedAssetsValue ?? this.fixedAssetsValue,
    patentStartDate: clearPatentStartDate
        ? null
        : (patentStartDate ?? this.patentStartDate),
    patentDurationMonths: patentDurationMonths ?? this.patentDurationMonths,
  );

  Map<String, dynamic> toJson() => {
    'usn6Rate': usn6Rate,
    'usn15Rate': usn15Rate,
    'eshnRate': eshnRate,
    'patentAnnualCost': patentAnnualCost,
    'employeeCount': employeeCount,
    'registrationDate': registrationDate?.toIso8601String(),
    'fixedAssetsValue': fixedAssetsValue,
    'patentStartDate': patentStartDate?.toIso8601String(),
    'patentDurationMonths': patentDurationMonths,
  };

  factory TaxSettings.fromJson(Map<String, dynamic> json) => TaxSettings(
    usn6Rate: (json['usn6Rate'] as num?)?.toDouble() ?? 6.0,
    usn15Rate: (json['usn15Rate'] as num?)?.toDouble() ?? 15.0,
    eshnRate: (json['eshnRate'] as num?)?.toDouble() ?? 6.0,
    patentAnnualCost: (json['patentAnnualCost'] as num?)?.toDouble() ?? 0.0,
    // backward compat: старый формат хранил hasEmployees:bool
    employeeCount:
        (json['employeeCount'] as int?) ??
        ((json['hasEmployees'] as bool? ?? false) ? 1 : 0),
    registrationDate: (json['registrationDate'] as String?) == null
        ? null
        : DateTime.parse(json['registrationDate'] as String),
    fixedAssetsValue: (json['fixedAssetsValue'] as num?)?.toDouble() ?? 0.0,
    patentStartDate: (json['patentStartDate'] as String?) == null
        ? null
        : DateTime.parse(json['patentStartDate'] as String),
    patentDurationMonths: (json['patentDurationMonths'] as int?) ?? 12,
  );

  static TaxSettings fromJsonString(String raw) =>
      TaxSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
