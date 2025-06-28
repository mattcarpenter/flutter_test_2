import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/database.dart';
import '../../app_config.dart';

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
    print('HOUSEHOLD API: Creating code invite for household: $householdId, displayName: $displayName');
    print('HOUSEHOLD API: Calling $apiBaseUrl/v1/household/invites');

    final authToken = getAuthToken();
    print('HOUSEHOLD API: Auth token: ${authToken.substring(0, 20)}...');

    final requestBody = {
      'householdId': householdId,
      'displayName': displayName,
      'inviteType': 'code',
    };
    print('HOUSEHOLD API: Request body: ${json.encode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/v1/household/invites'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('HOUSEHOLD API: Response status: ${response.statusCode}');
      print('HOUSEHOLD API: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('HOUSEHOLD API: Successfully created invite: ${responseData['invite']['id']}');
        return CreateInviteResponse.fromJson(responseData);
      } else {
        print('HOUSEHOLD API: Error response: ${response.statusCode} - ${response.body}');
        throw HouseholdApiException.fromResponse(response);
      }
    } catch (e) {
      print('HOUSEHOLD API: Exception occurred: $e');
      rethrow;
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
    print('HOUSEHOLD SERVICE: Accepting invite with code: $inviteCode');
    print('HOUSEHOLD SERVICE: Calling $apiBaseUrl/v1/household/invites/$inviteCode/accept');
    
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteCode/accept'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    print('HOUSEHOLD SERVICE: Accept response status: ${response.statusCode}');
    print('HOUSEHOLD SERVICE: Accept response body: ${response.body}');

    if (response.statusCode == 200) {
      return AcceptInviteResponse.fromJson(json.decode(response.body));
    } else {
      throw HouseholdApiException.fromResponse(response);
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
