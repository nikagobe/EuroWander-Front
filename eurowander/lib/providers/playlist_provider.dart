import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _service = PlaylistService();

  // ─── Search State ──────────────────────────────────────────────────
  List<PlaylistSummary> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String _sortBy = 'popular';
  String? _filterCity;
  String? _filterVibe;
  String? _filterBudgetTier;
  String? _keyword;
  int _searchSkip = 0;
  bool _hasMore = true;
  List<String> _cities = [];

  List<PlaylistSummary> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  String get sortBy => _sortBy;
  String? get filterCity => _filterCity;
  String? get filterVibe => _filterVibe;
  String? get filterBudgetTier => _filterBudgetTier;
  String? get keyword => _keyword;
  bool get hasMore => _hasMore;
  List<String> get cities => _cities;

  // ─── Detail State ──────────────────────────────────────────────────
  Playlist? _currentPlaylist;
  bool _isLoadingDetail = false;
  String? _detailError;

  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;

  // ─── My Playlists State ────────────────────────────────────────────
  List<PlaylistSummary> _myPlaylists = [];
  bool _isLoadingMine = false;

  List<PlaylistSummary> get myPlaylists => _myPlaylists;
  bool get isLoadingMine => _isLoadingMine;

  // ─── Reviews State ─────────────────────────────────────────────────
  List<PlaylistReview> _reviews = [];
  bool _isLoadingReviews = false;
  int _reviewSkip = 0;
  bool _hasMoreReviews = true;

  List<PlaylistReview> get reviews => _reviews;
  bool get isLoadingReviews => _isLoadingReviews;
  bool get hasMoreReviews => _hasMoreReviews;

  // ─── Search Methods ────────────────────────────────────────────────

  void setFilters({
    String? city,
    String? vibe,
    String? budgetTier,
    String? keyword,
    String? sortBy,
  }) {
    _filterCity = city;
    _filterVibe = vibe;
    _filterBudgetTier = budgetTier;
    _keyword = keyword;
    if (sortBy != null) _sortBy = sortBy;
    notifyListeners();
  }

  void clearFilters() {
    _filterCity = null;
    _filterVibe = null;
    _filterBudgetTier = null;
    _keyword = null;
    _sortBy = 'popular';
    notifyListeners();
  }

  Future<void> searchPlaylists({required String token, bool refresh = false}) async {
    if (refresh) {
      _searchSkip = 0;
      _searchResults = [];
      _hasMore = true;
    }
    if (!_hasMore || _isSearching) return;

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final results = await _service.searchPlaylists(
        token: token,
        city: _filterCity,
        vibe: _filterVibe,
        budgetTier: _filterBudgetTier,
        keyword: _keyword,
        sortBy: _sortBy,
        skip: _searchSkip,
        limit: 20,
      );
      _searchResults.addAll(results);
      _searchSkip += results.length;
      _hasMore = results.length == 20;
    } catch (e) {
      _searchError = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadCities({required String token}) async {
    try {
      _cities = await _service.getCities(token: token);
      notifyListeners();
    } catch (_) {}
  }

  // ─── Detail Methods ────────────────────────────────────────────────

  Future<void> loadPlaylist({required String token, required String id}) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      _currentPlaylist = await _service.getPlaylist(token: token, id: id);
    } catch (e) {
      _detailError = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> toggleLike({required String token, required String id}) async {
    try {
      final liked = await _service.toggleLike(token: token, id: id);
      if (_currentPlaylist != null && _currentPlaylist!.id == id) {
        _currentPlaylist = Playlist.fromJson({
          ..._playlistToMap(_currentPlaylist!),
          'is_liked_by_me': liked,
          'like_count': _currentPlaylist!.likeCount + (liked ? 1 : -1),
        });
        notifyListeners();
      }
      return liked;
    } catch (e) {
      return false;
    }
  }

  Future<Playlist?> forkPlaylist({required String token, required String id}) async {
    try {
      final forked = await _service.forkPlaylist(token: token, id: id);
      return forked;
    } catch (e) {
      return null;
    }
  }

  Future<int> importToTrip({
    required String token,
    required String playlistId,
    required String tripId,
    required String startDate,
  }) async {
    return await _service.importToTrip(
      token: token,
      playlistId: playlistId,
      tripId: tripId,
      startDate: startDate,
    );
  }

  // ─── My Playlists Methods ─────────────────────────────────────────

  Future<void> loadMyPlaylists({required String token}) async {
    _isLoadingMine = true;
    notifyListeners();

    try {
      _myPlaylists = await _service.getMyPlaylists(token: token);
    } catch (_) {}
    finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  Future<Playlist> createPlaylist({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final playlist = await _service.createPlaylist(token: token, data: data);
    await loadMyPlaylists(token: token);
    return playlist;
  }

  Future<Playlist> updatePlaylist({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final playlist = await _service.updatePlaylist(token: token, id: id, data: data);
    await loadMyPlaylists(token: token);
    return playlist;
  }

  Future<void> deletePlaylist({required String token, required String id}) async {
    await _service.deletePlaylist(token: token, id: id);
    _myPlaylists.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ─── Review Methods ────────────────────────────────────────────────

  Future<void> loadReviews({required String token, required String playlistId, bool refresh = false}) async {
    if (refresh) {
      _reviewSkip = 0;
      _reviews = [];
      _hasMoreReviews = true;
    }
    if (!_hasMoreReviews || _isLoadingReviews) return;

    _isLoadingReviews = true;
    notifyListeners();

    try {
      final results = await _service.getReviews(
        token: token,
        playlistId: playlistId,
        skip: _reviewSkip,
        limit: 20,
      );
      _reviews.addAll(results);
      _reviewSkip += results.length;
      _hasMoreReviews = results.length == 20;
    } catch (_) {}
    finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  Future<void> addReview({
    required String token,
    required String playlistId,
    required int rating,
    required String comment,
  }) async {
    final review = await _service.addReview(
      token: token,
      playlistId: playlistId,
      rating: rating,
      comment: comment,
    );
    _reviews.insert(0, review);
    notifyListeners();
  }

  Future<void> deleteReview({
    required String token,
    required String playlistId,
    required String reviewId,
  }) async {
    await _service.deleteReview(token: token, playlistId: playlistId, reviewId: reviewId);
    _reviews.removeWhere((r) => r.id == reviewId);
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  Map<String, dynamic> _playlistToMap(Playlist p) {
    return {
      'id': p.id,
      'creator_id': p.creatorId,
      'creator_first_name': p.creatorFirstName,
      'creator_last_name': p.creatorLastName,
      'city': p.city,
      'country': p.country,
      'title': p.title,
      'description': p.description,
      'cover_photo_url': p.coverPhotoUrl,
      'vibe': p.vibe,
      'budget_tier': p.budgetTier,
      'items': p.items.map((i) => i.toJson()).toList(),
      'tags': p.tags,
      'total_days': p.totalDays,
      'is_public': p.isPublic,
      'like_count': p.likeCount,
      'import_count': p.importCount,
      'review_count': p.reviewCount,
      'average_rating': p.averageRating,
      'created_at': p.createdAt,
      'updated_at': p.updatedAt,
      'is_liked_by_me': p.isLikedByMe,
    };
  }
}
