import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileApiService _service = ProfileApiService();

  FullProfile? _myProfile;
  ActivityFeed? _activityFeed;
  FullProfile? _viewedProfile;
  bool _isLoading = false;
  bool _isActivityLoading = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _error;

  // Cached presigned download URLs
  String? _profilePhotoUrl;
  String? _coverPhotoUrl;

  FullProfile? get myProfile => _myProfile;
  ActivityFeed? get activityFeed => _activityFeed;
  FullProfile? get viewedProfile => _viewedProfile;
  bool get isLoading => _isLoading;
  bool get isActivityLoading => _isActivityLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get error => _error;
  String? get profilePhotoUrl => _profilePhotoUrl;
  String? get coverPhotoUrl => _coverPhotoUrl;

  Future<void> fetchMyProfile({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myProfile = await _service.getMyProfile(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String token,
    required Map<String, dynamic> fields,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProfile = await _service.updateProfile(
        token: token,
        fields: fields,
      );
      if (_myProfile != null) {
        _myProfile = FullProfile(
          profile: updatedProfile,
          stats: _myProfile!.stats,
          badges: _myProfile!.badges,
          collaborators: _myProfile!.collaborators,
        );
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchActivity({required String token}) async {
    _isActivityLoading = true;
    notifyListeners();

    try {
      _activityFeed = await _service.getActivity(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isActivityLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile({
    required String token,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    _viewedProfile = null;
    notifyListeners();

    try {
      _viewedProfile = await _service.getUserProfile(
        token: token,
        userId: userId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearViewedProfile() {
    _viewedProfile = null;
    notifyListeners();
  }

  /// Upload a profile or cover photo (full 3-step flow).
  Future<bool> uploadPhoto({
    required String token,
    required String photoType,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _isUploadingPhoto = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProfile = await _service.uploadPhoto(
        token: token,
        photoType: photoType,
        fileName: fileName,
        bytes: bytes,
        contentType: contentType,
      );
      if (_myProfile != null) {
        _myProfile = FullProfile(
          profile: updatedProfile,
          stats: _myProfile!.stats,
          badges: _myProfile!.badges,
          collaborators: _myProfile!.collaborators,
        );
      }
      // Clear cached URL so it gets re-fetched
      if (photoType == 'profile') {
        _profilePhotoUrl = null;
      } else {
        _coverPhotoUrl = null;
      }
      _isUploadingPhoto = false;
      notifyListeners();
      // Fetch the new download URL
      await fetchPhotoUrl(token: token, photoType: photoType);
      return true;
    } catch (e) {
      _error = e.toString();
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a profile or cover photo.
  Future<bool> deletePhoto({
    required String token,
    required String photoType,
  }) async {
    _isUploadingPhoto = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deletePhoto(token: token, photoType: photoType);
      if (_myProfile != null) {
        final p = _myProfile!.profile;
        final updated = UserProfile(
          userId: p.userId,
          bio: p.bio,
          homeCity: p.homeCity,
          baseAirport: p.baseAirport,
          profilePhotoUrl: photoType == 'profile' ? '' : p.profilePhotoUrl,
          coverPhotoUrl: photoType == 'cover' ? '' : p.coverPhotoUrl,
          preferredLanguages: p.preferredLanguages,
          travelStyleTags: p.travelStyleTags,
          updatedAt: DateTime.now(),
          firstName: p.firstName,
          lastName: p.lastName,
        );
        _myProfile = FullProfile(
          profile: updated,
          stats: _myProfile!.stats,
          badges: _myProfile!.badges,
          collaborators: _myProfile!.collaborators,
        );
      }
      if (photoType == 'profile') {
        _profilePhotoUrl = null;
      } else {
        _coverPhotoUrl = null;
      }
      _isUploadingPhoto = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch a presigned download URL for a photo.
  Future<void> fetchPhotoUrl({
    required String token,
    required String photoType,
  }) async {
    try {
      final url = await _service.getPhotoDownloadUrl(
        token: token,
        photoType: photoType,
      );
      if (photoType == 'profile') {
        _profilePhotoUrl = url;
      } else {
        _coverPhotoUrl = url;
      }
      notifyListeners();
    } catch (_) {
      // Photo may not exist — that's fine
    }
  }

  /// Fetch both photo download URLs.
  Future<void> fetchPhotoUrls({required String token}) async {
    final profile = _myProfile?.profile;
    if (profile == null) return;
    if (profile.profilePhotoUrl.isNotEmpty) {
      await fetchPhotoUrl(token: token, photoType: 'profile');
    }
    if (profile.coverPhotoUrl.isNotEmpty) {
      await fetchPhotoUrl(token: token, photoType: 'cover');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
