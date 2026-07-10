import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/playlist.dart';

class PlaylistService {
  final String baseUrl = AppConstants.baseUrl;

  void _logRequest(String method, Uri uri, {Object? body}) {
    debugPrint('[PLAYLIST] → $method $uri');
    if (body != null) debugPrint('[PLAYLIST]   Body: $body');
  }

  void _logResponse(http.Response response) {
    debugPrint('[PLAYLIST] ← ${response.statusCode} ${response.request?.url}');
    debugPrint('[PLAYLIST]   Response: ${response.body}');
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ─── Search & Discovery ─────────────────────────────────────────────

  Future<List<PlaylistSummary>> searchPlaylists({
    required String token,
    String? city,
    String? vibe,
    String? budgetTier,
    String? keyword,
    String sortBy = 'popular',
    int skip = 0,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'sort_by': sortBy,
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (vibe != null && vibe.isNotEmpty) params['vibe'] = vibe;
    if (budgetTier != null && budgetTier.isNotEmpty) params['budget_tier'] = budgetTier;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final uri = Uri.parse('$baseUrl/api/v1/playlists/search').replace(queryParameters: params);
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PlaylistSummary.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<String>> getCities({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/cities');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  // ─── My Playlists ──────────────────────────────────────────────────

  Future<List<PlaylistSummary>> getMyPlaylists({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/mine');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PlaylistSummary.fromJson(json)).toList();
    }
    return [];
  }

  // ─── CRUD ──────────────────────────────────────────────────────────

  Future<Playlist> getPlaylist({required String token, required String id}) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$id');
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      return Playlist.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get playlist: ${response.statusCode}');
  }

  Future<Playlist> createPlaylist({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists');
    _logRequest('POST', uri, body: data);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(data));
    _logResponse(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Playlist.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create playlist: ${response.statusCode} ${response.body}');
  }

  Future<Playlist> updatePlaylist({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$id');
    _logRequest('PUT', uri, body: data);
    final response = await http.put(uri, headers: _authHeaders(token), body: jsonEncode(data));
    _logResponse(response);
    if (response.statusCode == 200) {
      return Playlist.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update playlist: ${response.statusCode} ${response.body}');
  }

  Future<void> deletePlaylist({required String token, required String id}) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$id');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete playlist: ${response.statusCode}');
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<bool> toggleLike({required String token, required String id}) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$id/like');
    _logRequest('POST', uri);
    final response = await http.post(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['liked'] == true;
    }
    throw Exception('Failed to toggle like: ${response.statusCode}');
  }

  Future<Playlist> forkPlaylist({required String token, required String id}) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$id/fork');
    _logRequest('POST', uri);
    final response = await http.post(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Playlist.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fork playlist: ${response.statusCode}');
  }

  Future<int> importToTrip({
    required String token,
    required String playlistId,
    required String tripId,
    required String startDate,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$playlistId/import/$tripId');
    final body = {'start_date': startDate};
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imported_items'] ?? 0;
    }
    throw Exception('Failed to import playlist: ${response.statusCode} ${response.body}');
  }

  // ─── Reviews ───────────────────────────────────────────────────────

  Future<List<PlaylistReview>> getReviews({
    required String token,
    required String playlistId,
    int skip = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$playlistId/reviews').replace(
      queryParameters: {'skip': skip.toString(), 'limit': limit.toString()},
    );
    _logRequest('GET', uri);
    final response = await http.get(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PlaylistReview.fromJson(json)).toList();
    }
    return [];
  }

  Future<PlaylistReview> addReview({
    required String token,
    required String playlistId,
    required int rating,
    required String comment,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$playlistId/reviews');
    final body = {'rating': rating, 'comment': comment};
    _logRequest('POST', uri, body: body);
    final response = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
    _logResponse(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return PlaylistReview.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add review: ${response.statusCode} ${response.body}');
  }

  Future<void> deleteReview({
    required String token,
    required String playlistId,
    required String reviewId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/playlists/$playlistId/reviews/$reviewId');
    _logRequest('DELETE', uri);
    final response = await http.delete(uri, headers: _authHeaders(token));
    _logResponse(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete review: ${response.statusCode}');
    }
  }
}
