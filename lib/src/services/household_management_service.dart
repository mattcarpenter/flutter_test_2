import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/database.dart';
import '../../app_config.dart';
import 'logging/app_logger.dart';

// Data models for API communication
class CreateInviteResponse {
  final HouseholdInviteEntry invite;
  final String? inviteUrl;

  CreateInviteResponse({required this.invite, this.inviteUrl});

  factory CreateInviteResponse.fromJson(Map<String, dynamic> json) {
    return CreateInviteResponse(
      invite: HouseholdInviteEntry.fromJson(json['invite']),
      inviteUrl: json['inviteUrl'],
    );
  }
}

class AcceptInviteResponse {
  final bool success;
  final HouseholdEntry household;
  final HouseholdMemberEntry membership;

  AcceptInviteResponse({
    required this.success,
    required this.household,
    required this.membership,
  });

  factory AcceptInviteResponse.fromJson(Map<String, dynamic> json) {
    return AcceptInviteResponse(
      success: json['success'],
      household: HouseholdEntry.fromJson(json['household']),
      membership: HouseholdMemberEntry.fromJson(json['membership']),
    );
  }
}

class LeaveHouseholdResponse {
  final bool success;
  final String leftAt;
  final bool? ownershipTransferred;

  LeaveHouseholdResponse({
    required this.success,
    required this.leftAt,
    this.ownershipTransferred,
  });

  factory LeaveHouseholdResponse.fromJson(Map<String, dynamic> json) {
    return LeaveHouseholdResponse(
      success: json['success'],
      leftAt: json['leftAt'],
      ownershipTransferred: json['ownershipTransferred'],
    );
  }
}

class HouseholdApiException implements Exception {
  final int statusCode;
  final String message;
  final String? details;

  HouseholdApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  factory HouseholdApiException.fromResponse(http.Response response) {
    final body = json.decode(response.body);
    return HouseholdApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Unknown error',
      details: body['details']?.toString(),
    );
  }

  @override
  String toString() => 'HouseholdApiException: $message (HTTP $statusCode)';
}

class HouseholdManagementService {
  final String apiBaseUrl;
  final String Function() getAuthToken;

  HouseholdManagementService({
    required this.apiBaseUrl,
    required this.getAuthToken,
  });

  Future<CreateInviteResponse> createEmailInvite(
    String householdId,
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'householdId': householdId,
        'email': email,
        'inviteType': 'email',
      }),
    );

    if (response.statusCode == 201) {
      return CreateInviteResponse.fromJson(json.decode(response.body));
    } else {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<CreateInviteResponse> createCodeInvite(
    String householdId,
    String displayName,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'householdId': householdId,
        'displayName': displayName,
        'inviteType': 'code',
      }),
    );

    if (response.statusCode == 201) {
      return CreateInviteResponse.fromJson(json.decode(response.body));
    } else {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<void> resendInvite(String inviteId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteId/resend'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<void> revokeInvite(String inviteId) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteId'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<AcceptInviteResponse> acceptInvite(String inviteCode) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/v1/household/invites/$inviteCode/accept'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        return AcceptInviteResponse.fromJson(json.decode(response.body));
      } else {
        throw HouseholdApiException.fromResponse(response);
      }
    } catch (e) {
      AppLogger.warning('Accept invite failed', e);
      rethrow;
    }
  }

  Future<void> declineInvite(String inviteCode) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteCode/decline'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<void> removeMember(String memberId) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/v1/household/members/$memberId'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<LeaveHouseholdResponse> leaveHousehold(
    String householdId, {
    String? newOwnerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/v1/household/leave'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'householdId': householdId,
          if (newOwnerId != null) 'newOwnerId': newOwnerId,
        }),
      );

      if (response.statusCode == 200) {
        return LeaveHouseholdResponse.fromJson(json.decode(response.body));
      } else {
        throw HouseholdApiException.fromResponse(response);
      }
    } catch (e) {
      AppLogger.warning('Leave household failed', e);
      rethrow;
    }
  }
  
  /// Delete a household (owner only, when no other members)
  Future<void> deleteHousehold(String householdId) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/v1/households/$householdId'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  /// Fetch email addresses for all members of a household.
  /// Returns a map of userId -> email.
  /// Only accessible by active members of the household.
  Future<Map<String, String>> getMemberEmails(String householdId) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/v1/household/$householdId/member-emails'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final members = data['members'] as Map<String, dynamic>?;
      if (members == null) {
        return {};
      }
      // Convert { "userId": { "email": "..." } } to { "userId": "email" }
      return members.map((userId, value) => MapEntry(
        userId,
        (value as Map<String, dynamic>)['email'] as String,
      ));
    } else if (response.statusCode == 403) {
      // Not a member - return empty map instead of throwing
      return {};
    } else {
      throw HouseholdApiException.fromResponse(response);
    }
  }
}

// Provider for the household management service
final householdManagementServiceProvider = Provider<HouseholdManagementService>((ref) {
  return HouseholdManagementService(
    apiBaseUrl: AppConfig.ingredientApiUrl, // Use the configured API URL
    getAuthToken: () {
      final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
      if (accessToken == null) {
        throw StateError('User must be authenticated to access household API');
      }
      return accessToken;
    },
  );
});
