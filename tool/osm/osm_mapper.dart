// OpenStreetMap etiketlerini Travixx mekan kaydına çeviren saf mantık.
// tool/import_osm.dart tarafından kullanılır; test/osm_mapper_test.dart ile test edilir.

import 'dart:math' as math;

/// 81 il: plaka kodu → il adı. Overpass'ta il sınırı `ISO3166-2=TR-NN`.
const Map<String, String> provinces = {
  '01': 'Adana', '02': 'Adıyaman', '03': 'Afyonkarahisar', '04': 'Ağrı',
  '05': 'Amasya', '06': 'Ankara', '07': 'Antalya', '08': 'Artvin',
  '09': 'Aydın', '10': 'Balıkesir', '11': 'Bilecik', '12': 'Bingöl',
  '13': 'Bitlis', '14': 'Bolu', '15': 'Burdur', '16': 'Bursa',
  '17': 'Çanakkale', '18': 'Çankırı', '19': 'Çorum', '20': 'Denizli',
  '21': 'Diyarbakır', '22': 'Edirne', '23': 'Elazığ', '24': 'Erzincan',
  '25': 'Erzurum', '26': 'Eskişehir', '27': 'Gaziantep', '28': 'Giresun',
  '29': 'Gümüşhane', '30': 'Hakkari', '31': 'Hatay', '32': 'Isparta',
  '33': 'Mersin', '34': 'İstanbul', '35': 'İzmir', '36': 'Kars',
  '37': 'Kastamonu', '38': 'Kayseri', '39': 'Kırklareli', '40': 'Kırşehir',
  '41': 'Kocaeli', '42': 'Konya', '43': 'Kütahya', '44': 'Malatya',
  '45': 'Manisa', '46': 'Kahramanmaraş', '47': 'Mardin', '48': 'Muğla',
  '49': 'Muş', '50': 'Nevşehir', '51': 'Niğde', '52': 'Ordu',
  '53': 'Rize', '54': 'Sakarya', '55': 'Samsun', '56': 'Siirt',
  '57': 'Sinop', '58': 'Sivas', '59': 'Tekirdağ', '60': 'Tokat',
  '61': 'Trabzon', '62': 'Tunceli', '63': 'Şanlıurfa', '64': 'Uşak',
  '65': 'Van', '66': 'Yozgat', '67': 'Zonguldak', '68': 'Aksaray',
  '69': 'Bayburt', '70': 'Karaman', '71': 'Kırıkkale', '72': 'Batman',
  '73': 'Şırnak', '74': 'Bartın', '75': 'Ardahan', '76': 'Iğdır',
  '77': 'Yalova', '78': 'Karabük', '79': 'Kilis', '80': 'Osmaniye',
  '81': 'Düzce',
};

/// Bir il için Overpass sorgusu. Turizm açısından anlamlı noktaları çeker.
/// Çok sayıda olan türlerde (kalıntı, anıt, göl, dağ, ibadethane) kalite
/// için Wikidata/Wikipedia bağlantısı şartı aranır.
String overpassQuery(String plate) => '''
[out:json][timeout:300];
area["ISO3166-2"="TR-$plate"]->.a;
(
  nwr["natural"="beach"]["name"](area.a);
  nwr["leisure"="beach_resort"]["name"](area.a);
  nwr["tourism"="museum"]["name"](area.a);
  nwr["historic"~"^(archaeological_site|castle|fort|caravanserai|aqueduct|city_gate)\$"]["name"](area.a);
  nwr["historic"~"^(ruins|monument|tomb|bridge)\$"]["name"]["wikidata"](area.a);
  nwr["amenity"="place_of_worship"]["name"]["wikidata"](area.a);
  nwr["natural"~"^(waterfall|cave_entrance|gorge|canyon|hot_spring|volcano|arch)\$"]["name"](area.a);
  nwr["waterway"="waterfall"]["name"](area.a);
  nwr["natural"="water"]["water"="lake"]["name"]["wikidata"](area.a);
  nwr["natural"~"^(peak|valley|rock|stone|earth_pillar)\$"]["name"]["wikidata"](area.a);
  nwr["boundary"~"^(national_park|protected_area)\$"]["name"]["wikidata"](area.a);
  nwr["tourism"="viewpoint"]["name"](area.a);
  nwr["tourism"="attraction"]["name"]["wikidata"](area.a);
);
out center tags;
''';

/// Kategori + alt kategori + emoji.
class OsmKind {
  final String category;
  final String subcategory;
  final String emoji;
  const OsmKind(this.category, this.subcategory, this.emoji);
}

/// Etiketlerden mekan türünü çıkarır. Uygun değilse null.
OsmKind? classify(Map<String, String> t) {
  final natural = t['natural'];
  final historic = t['historic'];
  final tourism = t['tourism'];

  if (natural == 'beach' || t['leisure'] == 'beach_resort') {
    return const OsmKind('Plaj', 'Plaj', '🏖️');
  }
  if (tourism == 'museum') return const OsmKind('Müze', 'Müze', '🏛️');

  switch (historic) {
    case 'archaeological_site':
      return const OsmKind('Tarihi', 'Antik Kent / Ören Yeri', '🏺');
    case 'castle':
    case 'fort':
      return const OsmKind('Tarihi', 'Kale', '🏰');
    case 'caravanserai':
      return const OsmKind('Tarihi', 'Kervansaray / Han', '🐪');
    case 'aqueduct':
      return const OsmKind('Tarihi', 'Su Kemeri', '🏛️');
    case 'city_gate':
      return const OsmKind('Tarihi', 'Kent Kapısı', '🚪');
    case 'ruins':
      return const OsmKind('Tarihi', 'Kalıntı', '🏛️');
    case 'monument':
      return const OsmKind('Tarihi', 'Anıt', '🗿');
    case 'tomb':
      return const OsmKind('Tarihi', 'Türbe / Mezar', '🕌');
    case 'bridge':
      return const OsmKind('Tarihi', 'Tarihi Köprü', '🌉');
  }

  if (t['amenity'] == 'place_of_worship') {
    switch (t['religion']) {
      case 'muslim':
        return const OsmKind('Dini', 'Cami', '🕌');
      case 'christian':
        return const OsmKind('Dini', 'Kilise', '⛪');
      case 'jewish':
        return const OsmKind('Dini', 'Sinagog', '🕍');
      default:
        return const OsmKind('Dini', 'İbadethane', '🛐');
    }
  }

  if (natural == 'waterfall' || t['waterway'] == 'waterfall') {
    return const OsmKind('Doğa', 'Şelale', '💧');
  }
  switch (natural) {
    case 'cave_entrance':
      return const OsmKind('Doğa', 'Mağara', '🕳️');
    case 'gorge':
    case 'canyon':
      return const OsmKind('Doğa', 'Kanyon', '🏞️');
    case 'valley':
      return const OsmKind('Doğa', 'Vadi', '🏞️');
    case 'hot_spring':
      return const OsmKind('Doğa', 'Kaplıca', '♨️');
    case 'volcano':
    case 'peak':
      return const OsmKind('Doğa', 'Dağ', '⛰️');
    case 'water':
      return const OsmKind('Doğa', 'Göl', '🏞️');
    case 'arch':
    case 'rock':
    case 'stone':
    case 'earth_pillar':
      return const OsmKind('Doğa', 'Doğal Oluşum', '🪨');
  }
  final boundary = t['boundary'];
  if (boundary == 'national_park' ||
      (boundary == 'protected_area' && t['protect_class'] == '2')) {
    return const OsmKind('Doğa', 'Milli Park', '🌲');
  }
  if (tourism == 'viewpoint') return const OsmKind('Manzara', 'Seyir Noktası', '🌅');
  if (tourism == 'attraction') return const OsmKind('Kültür', 'Turistik Nokta', '📍');
  return null;
}

/// Türkçe karakterleri indirger + küçük harf (eşleştirme için).
String fold(String s) {
  const map = {
    'İ': 'i', 'I': 'i', 'ı': 'i', 'Ş': 's', 'ş': 's', 'Ğ': 'g', 'ğ': 'g',
    'Ü': 'u', 'ü': 'u', 'Ö': 'o', 'ö': 'o', 'Ç': 'c', 'ç': 'c',
    'Â': 'a', 'â': 'a', 'Î': 'i', 'î': 'i', 'Û': 'u', 'û': 'u',
  };
  final sb = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    sb.write(map[ch] ?? ch.toLowerCase());
  }
  return sb.toString();
}

/// Anlamlı kelimeler (eşleştirme için; kısa ve genel kelimeler atılır).
Set<String> nameTokens(String name) {
  const stop = {
    'plaji', 'plaj', 'beach', 'muzesi', 'muze', 'museum', 'kalesi', 'kale',
    'camii', 'cami', 'antik', 'kenti', 'kent', 'oren', 'yeri', 'selalesi',
    'magarasi', 'golu', 'dagi', 'milli', 'parki', 'park', 'koprusu',
    'the', 'and', 've',
  };
  return fold(name)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 2 && !stop.contains(w))
      .toSet();
}

/// Overpass öğesini `places` satırına çevirir. Uygun değilse null.
Map<String, dynamic>? toPlaceRow(Map<String, dynamic> el, String cityId) {
  final tags = <String, String>{
    for (final e in ((el['tags'] as Map?) ?? const {}).entries)
      e.key.toString(): e.value.toString(),
  };
  final name = (tags['name:tr'] ?? tags['name'] ?? '').trim();
  if (name.isEmpty) return null;

  final kind = classify(tags);
  if (kind == null) return null;

  double? lat, lng;
  if (el['lat'] != null) {
    lat = (el['lat'] as num).toDouble();
    lng = (el['lon'] as num).toDouble();
  } else if (el['center'] is Map) {
    lat = ((el['center'] as Map)['lat'] as num?)?.toDouble();
    lng = ((el['center'] as Map)['lon'] as num?)?.toDouble();
  }
  if (lat == null || lng == null) return null;

  String? nz(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
  final street = [tags['addr:street'], tags['addr:housenumber']]
      .whereType<String>()
      .join(' ');
  final address = [
    nz(street),
    nz(tags['addr:district'] ?? tags['addr:suburb']),
    nz(tags['addr:city']),
  ].whereType<String>().join(', ');

  final fee = tags['fee'];
  return {
    'osm_ref': '${el['type']}/${el['id']}',
    'source': 'osm',
    'city_id': cityId,
    'name': name,
    'name_en': nz(tags['name:en']) ?? '',
    'category': kind.category,
    'subcategory': kind.subcategory,
    'emoji': kind.emoji,
    'latitude': lat,
    'longitude': lng,
    'address': nz(address),
    'website': nz(tags['website'] ?? tags['contact:website'] ?? tags['url']),
    'phone': nz(tags['phone'] ?? tags['contact:phone']),
    'opening_hours': nz(tags['opening_hours']),
    'admission_fee': nz(tags['charge']),
    'is_free': fee == 'no',
    'wikidata': nz(tags['wikidata']),
    'wikipedia': nz(tags['wikipedia']),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

/// Mesafe (km), Haversine.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// [row], [others] içindeki bir kayıtla aynı yer mi?
/// Aynı yer: [maxKm] içinde ve adlarında ortak anlamlı kelime var
/// (ya da ikisinin de anlamlı kelimesi yok ve çok yakınlar).
bool isDuplicateOf(Map<String, dynamic> row, Iterable<Map<String, dynamic>> others,
    {double maxKm = 0.5}) {
  final lat = row['latitude'] as double, lng = row['longitude'] as double;
  final tokens = {
    ...nameTokens(row['name'] as String),
    ...nameTokens((row['name_en'] as String?) ?? ''),
  };
  for (final o in others) {
    final olat = (o['latitude'] as num?)?.toDouble();
    final olng = (o['longitude'] as num?)?.toDouble();
    if (olat == null || olng == null) continue;
    if (distanceKm(lat, lng, olat, olng) > maxKm) continue;
    final ot = {
      ...nameTokens((o['name'] as String?) ?? ''),
      ...nameTokens((o['name_en'] as String?) ?? ''),
    };
    if (tokens.intersection(ot).isNotEmpty) return true;
    if (tokens.isEmpty && ot.isEmpty && distanceKm(lat, lng, olat, olng) < 0.1) {
      return true;
    }
  }
  return false;
}
