import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/bus.dart';
import '../models/city.dart';
import '../models/document.dart';
import '../models/finance.dart';
import '../models/flight.dart';
import '../models/hotel.dart';
import '../models/photo.dart';
import '../models/saved_trip.dart';
import '../models/user.dart';

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

  Future<List<BusOffer>> searchBuses({
    required String originFreebaseId,
    required String destinationFreebaseId,
    required String date,
    int adults = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/buses/search');
    final body = {
      'origin_freebase_id': originFreebaseId,
      'destination_freebase_id': destinationFreebaseId,
      'date': date,
      'adults': adults,
      'currency': 'EUR',
      'limit': limit,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((b) => BusOffer.fromJson(b)).toList();
    }
    return [];
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

  Future<List<SavedTrip>> getTrips({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SavedTrip.fromJson(json)).toList();
    }
    return [];
  }

  Future<String> getBookingLink({
    required String token,
    required String tripId,
    required String flight,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/booking-link')
        .replace(queryParameters: {'flight': flight});
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['booking_url'] as String;
    }
    throw Exception('Failed to get booking link: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> saveTrip({
    required String token,
    required String name,
    required FlightOffer outboundFlight,
    FlightOffer? returnFlight,
    BusOffer? busOffer,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips');

    Map<String, dynamic>? buildFlightPayload(FlightOffer flight) {
      return {
        'airline_logo': flight.airlineLogo,
        'booking_token': flight.bookingToken,
        'currency': flight.currency,
        'legs': flight.legs.map((leg) => {
          'airline': leg.airline,
          'arrival_airport': leg.arrivalAirport,
          'arrival_airport_name': leg.arrivalAirportName,
          'arrival_time': leg.arrivalTime,
          'departure_airport': leg.departureAirport,
          'departure_airport_name': leg.departureAirportName,
          'departure_time': leg.departureTime,
          'duration_minutes': leg.duration,
          'flight_number': leg.flightNumber,
        }).toList(),
        'price': flight.price,
        'stops': flight.stops,
        'total_duration_minutes': flight.totalDuration,
      };
    }

    Map<String, dynamic>? buildBusPayload(BusOffer bus) {
      return {
        'additional_info': bus.additionalInfo,
        'arr_name': bus.arrName,
        'arr_time': bus.arrTime,
        'changeovers': bus.changeovers,
        'currency': bus.currency,
        'deeplink': bus.deeplink,
        'dep_name': bus.depName,
        'dep_time': bus.depTime,
        'duration': bus.duration,
        'duration_minutes': bus.durationMinutes,
        'price': bus.price,
        'segments': bus.segments.map((seg) => {
          'dep_name': seg.depName,
          'arr_name': seg.arrName,
          'dep_time': seg.depTime,
          'arr_time': seg.arrTime,
          'product_type': seg.productType,
          'product': seg.product,
        }).toList(),
      };
    }

    final body = {
      'name': name,
      'outbound_flight': buildFlightPayload(outboundFlight),
      'return_flight': returnFlight != null ? buildFlightPayload(returnFlight) : null,
      'bus_journey': busOffer != null ? buildBusPayload(busOffer) : null,
    };

    _logRequest('POST', uri, body: body);
    final response = await http.post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    _logResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to save trip: ${response.statusCode} ${response.body}');
  }

  Future<List<User>> searchUsers({
    required String token,
    required String query,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/search').replace(
      queryParameters: {'q': query, 'limit': limit.toString()},
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<TripMember>> getTripMembers({
    required String token,
    required String tripId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/members');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TripMember.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> addTripMember({
    required String token,
    required String tripId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/members');
    final body = {'user_id': userId};
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode != 201) {
      throw Exception('Failed to add member: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> removeTripMember({
    required String token,
    required String tripId,
    required String memberUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/members/$memberUserId');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 204) {
      throw Exception('Failed to remove member: ${response.statusCode} ${response.body}');
    }
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── Finances ───────────────────────────────────────────────────────

  Future<FinanceSummary> getFinanceSummary({
    required String token,
    required String tripId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/finances');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      return FinanceSummary.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get finance summary: ${response.statusCode}');
  }

  Future<Expense> addExpense({
    required String token,
    required String tripId,
    required String name,
    required double amount,
    required String currency,
    required String paidBy,
    required List<String> eligibleMemberIds,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/finances/expenses');
    final body = {
      'name': name,
      'amount': amount,
      'currency': currency,
      'paid_by': paidBy,
      'eligible_member_ids': eligibleMemberIds,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 201) {
      return Expense.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add expense: ${response.statusCode} ${response.body}');
  }

  Future<void> deleteExpense({
    required String token,
    required String tripId,
    required String expenseId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/finances/expenses/$expenseId');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete expense: ${response.statusCode}');
    }
  }

  // ─── Hotels ─────────────────────────────────────────────────────────

  Future<List<HotelDestination>> searchHotelDestinations({
    required String query,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/hotels/destinations').replace(
      queryParameters: {'query': query},
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => HotelDestination.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<HotelOffer>> searchHotels({
    required String destId,
    required String arrivalDate,
    required String departureDate,
    String searchType = 'CITY',
    int adults = 1,
    int roomQty = 1,
    int pageNumber = 1,
    String currencyCode = 'EUR',
    String sortBy = 'price',
    int? priceMin,
    int? priceMax,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/hotels/search');
    final body = <String, dynamic>{
      'dest_id': destId,
      'search_type': searchType,
      'arrival_date': arrivalDate,
      'departure_date': departureDate,
      'adults': adults,
      'room_qty': roomQty,
      'page_number': pageNumber,
      'currency_code': currencyCode,
      'sort_by': sortBy,
    };
    if (priceMin != null) body['price_min'] = priceMin;
    if (priceMax != null) body['price_max'] = priceMax;

    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => HotelOffer.fromJson(json)).toList();
    }
    return [];
  }

  Future<HotelDetails?> getHotelDetails({
    required int hotelId,
    required String arrivalDate,
    required String departureDate,
    int adults = 1,
    int roomQty = 1,
    String currencyCode = 'EUR',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/hotels/details/$hotelId').replace(
      queryParameters: {
        'arrival_date': arrivalDate,
        'departure_date': departureDate,
        'adults': adults.toString(),
        'room_qty': roomQty.toString(),
        'currency_code': currencyCode,
      },
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _headers);
    _logResponse(response);
    if (response.statusCode == 200) {
      return HotelDetails.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> saveHotelToTrip({
    required String token,
    required String tripId,
    required Map<String, dynamic> hotelData,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/hotels');
    _logRequest('POST', uri, body: hotelData);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(hotelData));
    _logResponse(response);
    return response.statusCode == 200;
  }

  Future<void> removeHotelFromTrip({
    required String token,
    required String tripId,
    required int hotelId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/hotels/$hotelId');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to remove hotel: ${response.statusCode}');
    }
  }

  Future<String> getHotelBookingLink({
    required String token,
    required String tripId,
    required int hotelId,
    int adults = 1,
    int rooms = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/hotels/$hotelId/booking-link').replace(
      queryParameters: {
        'adults': adults.toString(),
        'rooms': rooms.toString(),
      },
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['booking_url'] as String;
    }
    throw Exception('Failed to get hotel booking link: ${response.statusCode}');
  }

  // ─── Flight Payment ─────────────────────────────────────────────────

  Future<void> markFlightPaid({
    required String token,
    required String tripId,
    required String flightType,
    required double actualPaidAmount,
    required String paidBy,
    required List<String> eligibleMemberIds,
    String currency = 'EUR',
  }) async {
    final path = flightType == 'bus'
        ? '$baseUrl/api/v1/trips/$tripId/bus/payment'
        : '$baseUrl/api/v1/trips/$tripId/flights/$flightType/payment';
    final uri = Uri.parse(path);
    final body = {
      'actual_paid_amount': actualPaidAmount,
      'paid_by': paidBy,
      'eligible_member_ids': eligibleMemberIds,
      'currency': currency,
    };
    _logRequest('PATCH', uri, body: body);
    final response = await http.patch(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark flight paid: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> unmarkFlightPaid({
    required String token,
    required String tripId,
    required String flightType,
  }) async {
    final path = flightType == 'bus'
        ? '$baseUrl/api/v1/trips/$tripId/bus/payment'
        : '$baseUrl/api/v1/trips/$tripId/flights/$flightType/payment';
    final uri = Uri.parse(path);
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to unmark flight paid: ${response.statusCode}');
    }
  }

  // ─── Hotel Payment ──────────────────────────────────────────────────

  Future<void> markHotelPaid({
    required String token,
    required String tripId,
    required int hotelId,
    required double actualPaidAmount,
    required String paidBy,
    required List<String> eligibleMemberIds,
    String currency = 'EUR',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/hotels/$hotelId/payment');
    final body = {
      'actual_paid_amount': actualPaidAmount,
      'paid_by': paidBy,
      'eligible_member_ids': eligibleMemberIds,
      'currency': currency,
    };
    _logRequest('PATCH', uri, body: body);
    final response = await http.patch(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark hotel paid: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> unmarkHotelPaid({
    required String token,
    required String tripId,
    required int hotelId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/hotels/$hotelId/payment');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to unmark hotel paid: ${response.statusCode}');
    }
  }

  // ─── Edit Expense ───────────────────────────────────────────────────

  Future<Expense> editExpense({
    required String token,
    required String tripId,
    required String expenseId,
    required String name,
    required double amount,
    required String currency,
    required String paidBy,
    required List<String> eligibleMemberIds,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/finances/expenses/$expenseId');
    final body = {
      'name': name,
      'amount': amount,
      'currency': currency,
      'paid_by': paidBy,
      'eligible_member_ids': eligibleMemberIds,
    };
    _logRequest('PATCH', uri, body: body);
    final response = await http.patch(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to edit expense: ${response.statusCode} ${response.body}');
  }

  // ─── DOCUMENTS ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> requestDocumentUploadUrl({
    required String token,
    required String tripId,
    required String fileName,
    required String contentType,
    required int sizeBytes,
    required String category,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/documents/upload-url');
    final body = {
      'file_name': fileName,
      'content_type': contentType,
      'size_bytes': sizeBytes,
      'category': category,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get upload URL: ${response.statusCode} ${response.body}');
  }

  Future<void> uploadFileToPresignedUrl({
    required String uploadUrl,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    final uri = Uri.parse(uploadUrl);
    _logRequest('PUT', uri);
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': contentType,
      },
      body: fileBytes,
    );
    debugPrint('[API] ← ${response.statusCode} PUT presigned URL');
    debugPrint('[API]   Response body: ${response.body}');
    debugPrint('[API]   Response headers: ${response.headers}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload file: ${response.statusCode} ${response.body}');
    }
  }

  Future<TripDocument> confirmDocumentUpload({
    required String token,
    required String tripId,
    required String fileKey,
    required String fileName,
    required String contentType,
    required int sizeBytes,
    required String category,
    String visibility = 'group',
    String? name,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/documents');
    final body = {
      'file_key': fileKey,
      'file_name': fileName,
      'content_type': contentType,
      'size_bytes': sizeBytes,
      'category': category,
      'visibility': visibility,
      if (name != null) 'name': name,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TripDocument.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to confirm document upload: ${response.statusCode} ${response.body}');
  }

  Future<List<TripDocument>> listDocuments({
    required String token,
    required String tripId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/documents');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => TripDocument.fromJson(e)).toList();
    }
    throw Exception('Failed to list documents: ${response.statusCode} ${response.body}');
  }

  Future<String> getDocumentDownloadUrl({
    required String token,
    required String tripId,
    required String documentId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/documents/$documentId/download-url');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['download_url'] as String;
    }
    throw Exception('Failed to get download URL: ${response.statusCode} ${response.body}');
  }

  Future<void> deleteDocument({
    required String token,
    required String tripId,
    required String documentId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/documents/$documentId');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete document: ${response.statusCode} ${response.body}');
    }
  }

  // ─── PHOTOS ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> requestPhotoUploadUrl({
    required String token,
    required String tripId,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/photos/upload-url');
    final body = {
      'file_name': fileName,
      'content_type': contentType,
      'size_bytes': sizeBytes,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get photo upload URL: ${response.statusCode} ${response.body}');
  }

  Future<TripPhoto> confirmPhotoUpload({
    required String token,
    required String tripId,
    required String fileKey,
    required String fileName,
    required String contentType,
    required int sizeBytes,
    String? caption,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/photos');
    final body = {
      'file_key': fileKey,
      'file_name': fileName,
      'content_type': contentType,
      'size_bytes': sizeBytes,
      if (caption != null) 'caption': caption,
    };
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TripPhoto.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to confirm photo upload: ${response.statusCode} ${response.body}');
  }

  Future<PaginatedPhotos> listPhotos({
    required String token,
    required String tripId,
    int skip = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/photos').replace(
      queryParameters: {'skip': skip.toString(), 'limit': limit.toString()},
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      return PaginatedPhotos.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to list photos: ${response.statusCode} ${response.body}');
  }

  Future<String> getPhotoDownloadUrl({
    required String token,
    required String tripId,
    required String photoId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/photos/$photoId/download-url');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['download_url'] as String;
    }
    throw Exception('Failed to get photo download URL: ${response.statusCode} ${response.body}');
  }

  Future<void> deletePhoto({
    required String token,
    required String tripId,
    required String photoId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips/$tripId/photos/$photoId');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete photo: ${response.statusCode} ${response.body}');
    }
  }
}
