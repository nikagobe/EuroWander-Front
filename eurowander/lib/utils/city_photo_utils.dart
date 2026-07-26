import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Builds a Wikimedia Commons thumb URL from a filename.
/// The URL structure is deterministic: MD5 hash of filename determines the path.
String buildWikimediaUrl(String filename, {int width = 800}) {
  final normalized = filename.replaceAll(' ', '_');
  final hash = md5.convert(utf8.encode(normalized)).toString();
  final encoded = Uri.encodeComponent(normalized);
  return 'https://upload.wikimedia.org/wikipedia/commons/thumb/'
      '${hash[0]}/${hash.substring(0, 2)}/$encoded/${width}px-$encoded';
}

/// Fetches a city photo URL from Wikidata using the city's wikidata_id.
/// Returns a Wikimedia Commons thumb URL, or null if no image exists.
Future<String?> fetchCityPhotoFromWikidata(String wikidataId, {int width = 800}) async {
  final url = Uri.parse(
    'https://www.wikidata.org/w/api.php'
    '?action=wbgetentities'
    '&ids=$wikidataId'
    '&props=claims'
    '&format=json'
    '&origin=*',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final claims = data['entities']?[wikidataId]?['claims'] as Map<String, dynamic>? ?? {};
    final p18 = claims['P18'] as List?;
    if (p18 == null || p18.isEmpty) return null;

    final filename = p18[0]['mainsnak']?['datavalue']?['value'] as String?;
    if (filename == null || filename.isEmpty) return null;

    return buildWikimediaUrl(filename, width: width);
  } catch (_) {
    return null;
  }
}
