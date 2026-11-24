import 'package:flutter_test/flutter_test.dart';
import 'package:odaklanma_zamani/util/turkce.dart';

void main() {
  test('Türkçe büyük harf', () {
    expect(trUpper('Disiplin'), 'DİSİPLİN');
    expect(trUpper('Kısa mola'), 'KISA MOLA');
    expect(trUpper('Arka plan görseli'), 'ARKA PLAN GÖRSELİ');
    expect(trUpper('Öğrenme'), 'ÖĞRENME');
  });
}
