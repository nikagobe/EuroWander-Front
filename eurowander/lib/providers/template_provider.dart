import 'package:flutter/foundation.dart';
import '../models/template.dart';
import '../services/template_service.dart';

class TemplateProvider extends ChangeNotifier {
  final TemplateService _service = TemplateService();

  // ─── Discovery State ──────────────────────────────────────────────
  List<TemplateListItem> _templates = [];
  bool _isLoading = false;
  String? _error;
  int _skip = 0;
  bool _hasMore = true;
  String _sortBy = 'newest';
  String? _tagsFilter;
  String? _destinationFilter;

  List<TemplateListItem> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get sortBy => _sortBy;

  // ─── My Templates State ───────────────────────────────────────────
  List<TemplateListItem> _myTemplates = [];
  bool _isLoadingMine = false;

  List<TemplateListItem> get myTemplates => _myTemplates;
  bool get isLoadingMine => _isLoadingMine;

  List<TemplateListItem> get myDrafts =>
      _myTemplates.where((t) => t.status == 'draft').toList();
  List<TemplateListItem> get myPublished =>
      _myTemplates.where((t) => t.status == 'published').toList();
  List<TemplateListItem> get myArchived =>
      _myTemplates.where((t) => t.status == 'archived').toList();

  // ─── Detail State ─────────────────────────────────────────────────
  TemplateResponse? _currentTemplate;
  bool _isLoadingDetail = false;

  TemplateResponse? get currentTemplate => _currentTemplate;
  bool get isLoadingDetail => _isLoadingDetail;

  // ─── Like State ───────────────────────────────────────────────────
  final Set<String> _likedTemplateIds = {};
  bool isLiked(String templateId) => _likedTemplateIds.contains(templateId);

  // ─── Discovery Actions ────────────────────────────────────────────

  Future<void> loadTemplates({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _skip = 0;
      _hasMore = true;
      _templates = [];
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _service.getTemplates(
        skip: _skip,
        limit: 20,
        tags: _tagsFilter,
        destination: _destinationFilter,
        sortBy: _sortBy,
      );
      _templates.addAll(results);
      _skip += results.length;
      _hasMore = results.length == 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    loadTemplates(refresh: true);
  }

  void setTagsFilter(String? tags) {
    _tagsFilter = tags;
    loadTemplates(refresh: true);
  }

  void setDestinationFilter(String? destination) {
    _destinationFilter = destination;
    loadTemplates(refresh: true);
  }

  // ─── My Templates Actions ─────────────────────────────────────────

  Future<void> loadMyTemplates(String authorId) async {
    if (_isLoadingMine) return;
    _isLoadingMine = true;
    notifyListeners();

    try {
      _myTemplates = await _service.getMyTemplates(authorId: authorId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  // ─── Detail Actions ───────────────────────────────────────────────

  Future<void> loadTemplateDetail(String templateId) async {
    _isLoadingDetail = true;
    _currentTemplate = null;
    notifyListeners();

    try {
      _currentTemplate = await _service.getTemplate(templateId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ─── CRUD Actions ─────────────────────────────────────────────────

  Future<TemplateResponse?> createTemplate(CreateTemplateRequest request) async {
    try {
      final result = await _service.createTemplate(request);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<TemplateResponse?> updateTemplate({
    required String templateId,
    required String userId,
    required UpdateTemplateRequest request,
  }) async {
    try {
      final result = await _service.updateTemplate(
        templateId: templateId,
        userId: userId,
        request: request,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> publishTemplate({
    required String templateId,
    required String userId,
  }) async {
    try {
      await _service.publishTemplate(
        templateId: templateId,
        userId: userId,
      );
      // Update local state
      final idx = _myTemplates.indexWhere((t) => t.id == templateId);
      if (idx != -1) {
        await loadMyTemplates(userId);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveTemplate({
    required String templateId,
    required String userId,
  }) async {
    try {
      await _service.archiveTemplate(
        templateId: templateId,
        userId: userId,
      );
      await loadMyTemplates(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTemplate({
    required String templateId,
    required String userId,
  }) async {
    try {
      await _service.deleteTemplate(
        templateId: templateId,
        userId: userId,
      );
      _myTemplates.removeWhere((t) => t.id == templateId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Like Action ──────────────────────────────────────────────────

  Future<void> toggleLike({
    required String templateId,
    required String userId,
  }) async {
    // Optimistic update
    final wasLiked = _likedTemplateIds.contains(templateId);
    if (wasLiked) {
      _likedTemplateIds.remove(templateId);
    } else {
      _likedTemplateIds.add(templateId);
    }
    notifyListeners();

    try {
      final result = await _service.likeTemplate(
        templateId: templateId,
        userId: userId,
      );
      // Sync with server response
      if (result['liked'] == true) {
        _likedTemplateIds.add(templateId);
      } else {
        _likedTemplateIds.remove(templateId);
      }
      // Update like count in current template if viewing
      if (_currentTemplate?.id == templateId) {
        await loadTemplateDetail(templateId);
      }
    } catch (e) {
      // Revert on failure
      if (wasLiked) {
        _likedTemplateIds.add(templateId);
      } else {
        _likedTemplateIds.remove(templateId);
      }
    }
    notifyListeners();
  }
}
