import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/profile.dart';

class ProfileApiService {
  final String baseUrl = AppConstants.baseUrl;

  Map<String, String> _headers({required String token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<FullProfile> getMyProfile({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/me');
    debugPrint('[PROFILE] → GET $uri');
    final response = await http.get(uri, headers: _headers(token: token));
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return FullProfile.fromJson(data);
    }
    throw ProfileException('Failed to load profile');
  }

  Future<UserProfile> updateProfile({
    required String token,
    required Map<String, dynamic> fields,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/me');
    debugPrint('[PROFILE] → PATCH $uri');
    final response = await http.patch(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(fields),
    );
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    }
    throw ProfileException('Failed to update profile');
  }

  Future<ActivityFeed> getActivity({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/me/activity');
    debugPrint('[PROFILE] → GET $uri');
    final response = await http.get(uri, headers: _headers(token: token));
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ActivityFeed.fromJson(data);
    }
    throw ProfileException('Failed to load activity');
  }

  Future<FullProfile> getUserProfile({
    required String token,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/$userId');
    debugPrint('[PROFILE] → GET $uri');
    final response = await http.get(uri, headers: _headers(token: token));
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return FullProfile.fromJson(data);
    }
    throw ProfileException('Failed to load user profile');
  }

  /// Request a presigned upload URL for profile or cover photo.
  Future<({String uploadUrl, String fileKey})> requestUploadUrl({
    required String token,
    required String photoType,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/me/$photoType/upload-url');
    debugPrint('[PROFILE] → POST $uri');
    final response = await http.post(
      uri,
      headers: _headers(token: token),
      body: jsonEncode({
        'file_name': fileName,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      }),
    );
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        uploadUrl: data['upload_url'] as String,
        fileKey: data['file_key'] as String,
      );
    }
    final detail = _parseError(response);
    throw ProfileException(detail);
  }

  /// Upload raw bytes directly to S3 using the presigned URL.
  Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    debugPrint('[PROFILE] → PUT S3 (${bytes.length} bytes)');
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    debugPrint('[PROFILE] ← S3 ${response.statusCode}');

    if (response.statusCode != 200) {
      throw ProfileException('Upload to storage failed (${response.statusCode})');
    }
  }

  /// Confirm the upload and save the photo to the profile.
  Future<UserProfile> confirmUpload({
    required String token,
    required String photoType,
    required String fileKey,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/me/$photoType/confirm');
    debugPrint('[PROFILE] → POST $uri');
    final response = await http.post(
      uri,
      headers: _headers(token: token),
      body: jsonEncode({'file_key': fileKey}),
    );
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    }
    throw ProfileException('Failed to confirm upload');
  }

  /// Get a presigned download URL for viewing a photo.
  Future<String> getPhotoDownloadUrl({
    required String token,
    required String photoType,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/me/$photoType/download-url');
    debugPrint('[PROFILE] → GET $uri');
    final response = await http.get(uri, headers: _headers(token: token));
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['download_url'] as String;
    }
    throw ProfileException('Failed to get photo URL');
  }

  /// Delete a photo from S3 and clear the profile field.
  Future<void> deletePhoto({
    required String token,
    required String photoType,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/profiles/me/$photoType/photo');
    debugPrint('[PROFILE] → DELETE $uri');
    final response = await http.delete(uri, headers: _headers(token: token));
    debugPrint('[PROFILE] ← ${response.statusCode}');

    if (response.statusCode != 204) {
      throw ProfileException('Failed to delete photo');
    }
  }

  /// Full upload flow: request URL → PUT to S3 → confirm.
  Future<UserProfile> uploadPhoto({
    required String token,
    required String photoType,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final presigned = await requestUploadUrl(
      token: token,
      photoType: photoType,
      fileName: fileName,
      contentType: contentType,
      sizeBytes: bytes.length,
    );

    await uploadToS3(
      uploadUrl: presigned.uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );

    return confirmUpload(
      token: token,
      photoType: photoType,
      fileKey: presigned.fileKey,
    );
  }

  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['detail'] is String) return data['detail'];
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}

class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);

  @override
  String toString() => message;
}
