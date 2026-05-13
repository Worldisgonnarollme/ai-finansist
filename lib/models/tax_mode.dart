enum TaxMode { npd, usn6 }

extension TaxModeExt on TaxMode {
  String get displayName {
    switch (this) {
      case TaxMode.npd:
        return 'Самозанятый (НПД)';
      case TaxMode.usn6:
        return 'ИП на УСН 6%';
    }
  }

  String get shortName {
    switch (this) {
      case TaxMode.npd:
        return 'НПД';
      case TaxMode.usn6:
        return 'УСН 6%';
    }
  }

  String get description {
    switch (this) {
      case TaxMode.npd:
        return '4% с физлиц · 6% с юрлиц';
      case TaxMode.usn6:
        return '6% от всех доходов';
    }
  }
}
