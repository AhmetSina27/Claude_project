import 'dart:math';

/// Sözlerin temaları; tebrik ekranında sözün üstünde küçük bir etiket olarak görünür.
enum QuoteTheme {
  ogrenme('Öğrenme'),
  emek('Emek'),
  sabir('Sabır'),
  disiplin('Disiplin'),
  baslangic('Başlangıç'),
  cesaret('Cesaret');

  const QuoteTheme(this.label);
  final String label;
}

class Quote {
  const Quote(this.text, this.author, this.theme);
  final String text;
  final String author;
  final QuoteTheme theme;
}

/// Odak sonunda gösterilen motivasyon sözleri.
/// Kime ait olduğu tartışmalı olan popüler sözler bilerek listeye alınmadı.
const quotes = <Quote>[
  // Öğrenme
  Quote('Hayatta en hakiki mürşit ilimdir.', 'Mustafa Kemal Atatürk', QuoteTheme.ogrenme),
  Quote('Öğrenmek zihni asla yormaz.', 'Leonardo da Vinci', QuoteTheme.ogrenme),
  Quote('Eğitim, dünyayı değiştirmek için kullanabileceğin en güçlü silahtır.', 'Nelson Mandela', QuoteTheme.ogrenme),
  Quote('Hayal gücü bilgiden daha önemlidir.', 'Albert Einstein', QuoteTheme.ogrenme),
  Quote('Bilgi güçtür.', 'Francis Bacon', QuoteTheme.ogrenme),
  Quote('İlim ilim bilmektir, ilim kendin bilmektir.', 'Yunus Emre', QuoteTheme.ogrenme),
  Quote('Okumak zihin için neyse, egzersiz de beden için odur.', 'Joseph Addison', QuoteTheme.ogrenme),
  Quote('Ne kadar çok okursan, o kadar çok şey bilirsin.', 'Dr. Seuss', QuoteTheme.ogrenme),
  Quote('Eğitimin kökleri acı, meyveleri tatlıdır.', 'Aristoteles', QuoteTheme.ogrenme),
  Quote('Hayatta hiçbir şeyden korkulmamalı, yalnızca anlaşılmalı.', 'Marie Curie', QuoteTheme.ogrenme),
  Quote('Öğrenmenin yaşı yoktur.', 'Türk atasözü', QuoteTheme.ogrenme),

  // Emek
  Quote('Dâhilik yüzde bir ilham, yüzde doksan dokuz terdir.', 'Thomas Edison', QuoteTheme.emek),
  Quote(
    'Hiçbir şeye ihtiyacımız yok, yalnız bir şeye ihtiyacımız vardır: Çalışkan olmak.',
    'Mustafa Kemal Atatürk',
    QuoteTheme.emek,
  ),
  Quote('Başarı, her gün tekrarlanan küçük çabaların toplamıdır.', 'Robert Collier', QuoteTheme.emek),
  Quote('İlham vardır ama seni çalışırken bulmalıdır.', 'Pablo Picasso', QuoteTheme.emek),
  Quote('İşleyen demir ışıldar.', 'Türk atasözü', QuoteTheme.emek),
  Quote('Emek olmadan yemek olmaz.', 'Türk atasözü', QuoteTheme.emek),
  Quote('Ne ekersen onu biçersin.', 'Türk atasözü', QuoteTheme.emek),
  Quote(
    'Bin farklı tekmeyi bir kez çalışandan değil, tek bir tekmeyi bin kez çalışandan korkarım.',
    'Bruce Lee',
    QuoteTheme.emek,
  ),
  Quote('Hayatımda defalarca başarısız oldum. İşte bu yüzden başarılıyım.', 'Michael Jordan', QuoteTheme.emek),

  // Sabır
  Quote('Sabır acıdır ama meyvesi tatlıdır.', 'Jean-Jacques Rousseau', QuoteTheme.sabir),
  Quote('Ne kadar yavaş gittiğin önemli değil, yeter ki durma.', 'Konfüçyüs', QuoteTheme.sabir),
  Quote('Damla, taşı gücüyle değil, sürekli düşerek deler.', 'Ovidius', QuoteTheme.sabir),
  Quote('Büyük işler güçle değil, azimle başarılır.', 'Samuel Johnson', QuoteTheme.sabir),
  Quote('Damlaya damlaya göl olur.', 'Türk atasözü', QuoteTheme.sabir),
  Quote('Sabırla koruk helva olur, dut yaprağı atlas.', 'Türk atasözü', QuoteTheme.sabir),
  Quote('Gülü seven dikenine katlanır.', 'Türk atasözü', QuoteTheme.sabir),

  // Disiplin
  Quote('Disiplin, hedeflerle başarı arasındaki köprüdür.', 'Jim Rohn', QuoteTheme.disiplin),
  Quote('Odaklanmak, hayır demektir.', 'Steve Jobs', QuoteTheme.disiplin),
  Quote('Kendini yenmek, zaferlerin en büyüğüdür.', 'Platon', QuoteTheme.disiplin),
  Quote('Zaman, en çok istediğimiz ama en kötü kullandığımız şeydir.', 'William Penn', QuoteTheme.disiplin),
  Quote('Gelecek, ona bugünden hazırlananlarındır.', 'Malcolm X', QuoteTheme.disiplin),
  Quote('Bugünün işini yarına bırakma.', 'Türk atasözü', QuoteTheme.disiplin),
  Quote('Vakit nakittir.', 'Türk atasözü', QuoteTheme.disiplin),

  // Başlangıç
  Quote('Bin kilometrelik bir yolculuk tek bir adımla başlar.', 'Lao Tzu', QuoteTheme.baslangic),
  Quote('Başlamanın yolu, konuşmayı bırakıp yapmaya koyulmaktır.', 'Walt Disney', QuoteTheme.baslangic),
  Quote('İyi başlamak, işin yarısıdır.', 'Aristoteles', QuoteTheme.baslangic),
  Quote('İlerlemenin sırrı başlamaktır.', 'Mark Twain', QuoteTheme.baslangic),
  Quote('Olduğun yerden başla. Elindekini kullan. Yapabildiğini yap.', 'Arthur Ashe', QuoteTheme.baslangic),

  // Cesaret
  Quote('Yapabileceğine inan, yolun yarısını geçmiş olursun.', 'Theodore Roosevelt', QuoteTheme.cesaret),
  Quote('Yapabileceğini de düşünsen, yapamayacağını da düşünsen, haklısın.', 'Henry Ford', QuoteTheme.cesaret),
  Quote('Zor olduğu için cesaret etmiyor değiliz; cesaret etmediğimiz için zordur.', 'Seneca', QuoteTheme.cesaret),
  Quote('Şans, hazırlığın fırsatla buluştuğu andır.', 'Seneca', QuoteTheme.cesaret),
  Quote('Ya bir yol bulacağız ya da bir yol açacağız.', 'Hannibal', QuoteTheme.cesaret),
  Quote('Yaşamak bir ağaç gibi tek ve hür ve bir orman gibi kardeşçesine.', 'Nâzım Hikmet', QuoteTheme.cesaret),
  Quote('Umut, uyanık insanların rüyasıdır.', 'Aristoteles', QuoteTheme.cesaret),
];

int? _lastIndex;

/// Rastgele bir söz; art arda aynı söz gelmez.
Quote randomQuote([Random? r]) {
  final rand = r ?? Random();
  var i = rand.nextInt(quotes.length);
  if (i == _lastIndex) i = (i + 1 + rand.nextInt(quotes.length - 1)) % quotes.length;
  _lastIndex = i;
  return quotes[i];
}
