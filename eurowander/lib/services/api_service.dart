import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/city.dart';
import '../models/flight.dart';

class ApiService {
  final String baseUrl = AppConstants.baseUrl;

  void _logRequest(String method, Uri uri, {Object? body}) {
    debugPrint('[API] → $method $uri');
    if (body != null) {
      debugPrint('[API]   Body: $body');
    }
  }

  void _logResponse(http.Response response) {
    debugPrint('[API] ← ${response.statusCode} ${response.request?.url}');
    debugPrint('[API]   Response: ${response.body}');
  }

  Future<List<City>> searchCities(String query, {int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/api/v1/cities/search').replace(
      queryParameters: {'q': query, 'limit': limit.toString()},
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => City.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<FlightOffer>> searchFlights({
    required String originId,
    required String destinationId,
    required String outboundDate,
    int adults = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/flights/search');
    final body = {
      'origin_id': originId,
      'destination_id': destinationId,
      'outbound_date': outboundDate,
      'adults': adults,
      'limit': limit,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
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

  Future<List<FlightOffer>> searchRegionalFlights({
    required String originCountry,
    required String destinationId,
    required String outboundDate,
    int adults = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/flights/regional-search');
    final body = {
      'origin_country': originCountry,
      'destination_id': destinationId,
      'outbound_date': outboundDate,
      'adults': adults,
      'limit': limit,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
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

  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    return await http.get(uri, headers: _headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    return await http.post(uri, headers: _headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    return await http.put(uri, headers: _headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    return await http.delete(uri, headers: _headers);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
