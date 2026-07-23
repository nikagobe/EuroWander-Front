import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/template.dart';
import '../models/flight.dart';
import '../models/bus.dart';
import '../models/hotel.dart';

class TemplateService {
  final String baseUrl = AppConstants.baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _logRequest(String method, Uri uri, {Object? body}) {
    debugPrint('[TemplateAPI] → $method $uri');
    if (body != null) {
      debugPrint('[TemplateAPI]   Body: $body');
    }
  }

  void _logResponse(http.Response response) {
    debugPrint('[TemplateAPI] ← ${response.statusCode} ${response.request?.url}');
    debugPrint('[TemplateAPI]   Response: ${response.body}');
  }

  // ─── Browse Templates ─────────────────────────────────────────────

  Future<List<TemplateListItem>> getTemplates({
    int skip = 0,
    int limit = 20,
    String? tags,
    String? destination,
    String sortBy = 'newest',
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_by': sortBy,
    };
    if (tags != null && tags.isNotEmpty) params['tags'] = tags;
    if (destination != null && destination.isNotEmpty) {
      params['destination'] = destination;
    }

    final uri = Uri.parse('$baseUrl/api/v1/templates')
        .replace(queryParameters: params);
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => TemplateListItem.fromJson(j)).toList();
    }
    throw Exception('Failed to load templates: ${response.statusCode}');
  }

  // ─── My Templates ─────────────────────────────────────────────────

  Future<List<TemplateListItem>> getMyTemplates({
    required String authorId,
    int skip = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/mine').replace(
      queryParameters: {
        'author_id': authorId,
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => TemplateListItem.fromJson(j)).toList();
    }
    throw Exception('Failed to load my templates: ${response.statusCode}');
  }

  // ─── Template Detail ──────────────────────────────────────────────

  Future<TemplateResponse> getTemplate(String templateId) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      return TemplateResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load template: ${response.statusCode}');
  }

  // ─── Create Template ──────────────────────────────────────────────

  Future<TemplateResponse> createTemplate(CreateTemplateRequest request) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates');
    final body = jsonEncode(request.toJson());
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _headers, body: body);
    _logResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TemplateResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create template: ${response.statusCode}');
  }

  // ─── Update Template ──────────────────────────────────────────────

  Future<TemplateResponse> updateTemplate({
    required String templateId,
    required String userId,
    required UpdateTemplateRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId').replace(
      queryParameters: {'user_id': userId},
    );
    final body = jsonEncode(request.toJson());
    _logRequest('PUT', uri, body: body);
    final response = await http.put(uri, headers: _headers, body: body);
    _logResponse(response);

    if (response.statusCode == 200) {
      return TemplateResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update template: ${response.statusCode}');
  }

  // ─── Publish Template ─────────────────────────────────────────────

  Future<TemplateResponse> publishTemplate({
    required String templateId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId/publish')
        .replace(queryParameters: {'user_id': userId});
    _logRequest('PATCH', uri);
    final response = await http.patch(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      return TemplateResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to publish template: ${response.statusCode}');
  }

  // ─── Archive Template ─────────────────────────────────────────────

  Future<TemplateResponse> archiveTemplate({
    required String templateId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId/archive')
        .replace(queryParameters: {'user_id': userId});
    _logRequest('PATCH', uri);
    final response = await http.patch(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      return TemplateResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to archive template: ${response.statusCode}');
  }

  // ─── Delete Template ──────────────────────────────────────────────

  Future<void> deleteTemplate({
    required String templateId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId')
        .replace(queryParameters: {'user_id': userId});
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete template: ${response.statusCode}');
    }
  }

  // ─── Like Template ────────────────────────────────────────────────

  Future<Map<String, dynamic>> likeTemplate({
    required String templateId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId/like')
        .replace(queryParameters: {'user_id': userId});
    _logRequest('POST', uri);
    final response = await http.post(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to like template: ${response.statusCode}');
  }

  // ─── Fork Guide ───────────────────────────────────────────────────

  Future<ForkGuide> getForkGuide({
    required String templateId,
    required String startDate,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId/fork-guide')
        .replace(queryParameters: {'start_date': startDate});
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      return ForkGuide.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get fork guide: ${response.statusCode}');
  }

  // ─── Register Fork ────────────────────────────────────────────────

  Future<void> registerFork({
    required String templateId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/templates/$templateId/fork')
        .replace(queryParameters: {'user_id': userId});
    _logRequest('POST', uri);
    final response = await http.post(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to register fork: ${response.statusCode}');
    }
  }

  // ─── Flight Search by IATA ────────────────────────────────────────

  Future<List<FlightOffer>> searchFlightsByIata({
    required String originIata,
    required String destinationIata,
    required String outboundDate,
    int adults = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/flights/search-by-iata');
    final body = {
      'origin_iata': originIata,
      'destination_iata': destinationIata,
      'outbound_date': outboundDate,
      'adults': adults,
      'limit': limit,
    };
    _logRequest('POST', uri, body: body);
    final response =
        await http.post(uri, headers: _headers, body: jsonEncode(body));
    _logResponse(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((f) => FlightOffer.fromJson(f)).toList();
      }
      final List<FlightOffer> flights = [];
      if (data is Map) {
        if (data['best_flights'] != null) {
          for (final f in data['best_flights']) {
            flights.add(FlightOffer.fromJson(f));
          }
        }
        if (data['other_flights'] != null) {
          for (final f in data['other_flights']) {
            flights.add(FlightOffer.fromJson(f));
          }
        }
      }
      return flights;
    }
    return [];
  }

  // ─── Hotel Details (availability check) ───────────────────────────

  Future<HotelOffer?> getHotelDetails({
    required int hotelId,
    required String arrivalDate,
    required String departureDate,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/hotels/details/$hotelId').replace(
      queryParameters: {
        'arrival_date': arrivalDate,
        'departure_date': departureDate,
      },
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);

    if (response.statusCode == 200) {
      return HotelOffer.fromJson(jsonDecode(response.body));
    }
    // 404 = not available for those dates
    return null;
  }

  // ─── Bus Search (reuses existing endpoint) ────────────────────────

  Future<List<BusOffer>> searchBuses({
    required String fromCity,
    required String toCity,
    required String date,
    int adults = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/buses/search');
    final body = {
      'from_city': fromCity,
      'to_city': toCity,
      'date': date,
      'adults': adults,
    };
    _logRequest('POST', uri, body: body);
    final response =
        await http.post(uri, headers: _headers, body: jsonEncode(body));
    _logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => BusOffer.fromJson(j)).toList();
    }
    return [];
  }
}
