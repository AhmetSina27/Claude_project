/// Türkçe kurallarına göre büyük harf: "i" → "İ", "ı" → "I".
/// (Dart'ın toUpperCase() metodu dile duyarlı değildir ve "i"yi "I" yapar.)
String trUpper(String s) => s.replaceAll('i', 'İ').toUpperCase();
