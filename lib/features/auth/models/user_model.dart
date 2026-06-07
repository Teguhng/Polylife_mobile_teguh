class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String roleLabel;
  final int adminLevel;
  final String accountStatus;
  final String? emailVerifiedAt;
  final UserAffiliation? affiliation;
  final UserProfile? profile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleLabel,
    this.adminLevel = 0,
    this.accountStatus = 'active',
    this.emailVerifiedAt,
    this.affiliation,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawAffiliation = json['affiliation'];
    final rawProfile = json['profile'];

    return User(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      roleLabel: json['role_label']?.toString() ?? 'Pengguna',
      adminLevel: json['admin_level'] is int
          ? json['admin_level'] as int
          : int.tryParse((json['admin_level'] ?? '').toString()) ?? 0,
      accountStatus: json['account_status']?.toString() ?? 'active',
      emailVerifiedAt: _nullableString(json['email_verified_at']),
      affiliation: rawAffiliation is Map<String, dynamic>
          ? UserAffiliation.fromJson(rawAffiliation)
          : rawAffiliation is Map
          ? UserAffiliation.fromJson(Map<String, dynamic>.from(rawAffiliation))
          : null,
      profile: rawProfile is Map<String, dynamic>
          ? UserProfile.fromJson(rawProfile)
          : rawProfile is Map
          ? UserProfile.fromJson(Map<String, dynamic>.from(rawProfile))
          : null,
    );
  }

  String get displayName {
    final fromProfile = (profile?.displayName ?? '').trim();
    return fromProfile.isNotEmpty ? fromProfile : name;
  }

  bool get hasVerifiedEmail {
    final value = emailVerifiedAt?.trim() ?? '';
    return value.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'role_label': roleLabel,
      'admin_level': adminLevel,
      'account_status': accountStatus,
      'email_verified_at': emailVerifiedAt,
      'affiliation': affiliation?.toJson(),
      'profile': profile?.toJson(),
    };
  }
}

class UserAffiliation {
  final String? type;
  final String? name;
  final String? studentIdType;
  final String? studentIdNumber;
  final String status;
  final String? verifiedAt;
  final UserAffiliationRequest? pendingRequest;
  final UserAffiliationRequest? latestRejectedRequest;

  const UserAffiliation({
    this.type,
    this.name,
    this.studentIdType,
    this.studentIdNumber,
    this.status = 'pending',
    this.verifiedAt,
    this.pendingRequest,
    this.latestRejectedRequest,
  });

  factory UserAffiliation.fromJson(Map<String, dynamic> json) {
    final rawPendingRequest = json['pending_request'];
    final rawLatestRejectedRequest = json['latest_rejected_request'];

    return UserAffiliation(
      type: _nullableString(json['type']),
      name: _nullableString(json['name']),
      studentIdType: _nullableString(json['student_id_type']),
      studentIdNumber: _nullableString(json['student_id_number']),
      status: json['status']?.toString() ?? 'pending',
      verifiedAt: _nullableString(json['verified_at']),
      pendingRequest: rawPendingRequest is Map<String, dynamic>
          ? UserAffiliationRequest.fromJson(rawPendingRequest)
          : rawPendingRequest is Map
          ? UserAffiliationRequest.fromJson(
              Map<String, dynamic>.from(rawPendingRequest),
            )
          : null,
      latestRejectedRequest: rawLatestRejectedRequest is Map<String, dynamic>
          ? UserAffiliationRequest.fromJson(rawLatestRejectedRequest)
          : rawLatestRejectedRequest is Map
          ? UserAffiliationRequest.fromJson(
              Map<String, dynamic>.from(rawLatestRejectedRequest),
            )
          : null,
    );
  }

  bool get hasAnyDetail {
    return [
      type,
      name,
      studentIdType,
      studentIdNumber,
    ].any((value) => (value ?? '').trim().isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'student_id_type': studentIdType,
      'student_id_number': studentIdNumber,
      'status': status,
      'verified_at': verifiedAt,
      'pending_request': pendingRequest?.toJson(),
      'latest_rejected_request': latestRejectedRequest?.toJson(),
    };
  }
}

class UserAffiliationRequest {
  final int id;
  final String? type;
  final String? name;
  final String? studentIdType;
  final String? studentIdNumber;
  final String status;
  final String? rejectionReason;
  final String? createdAt;
  final String? reviewedAt;

  const UserAffiliationRequest({
    required this.id,
    this.type,
    this.name,
    this.studentIdType,
    this.studentIdNumber,
    this.status = 'pending',
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  factory UserAffiliationRequest.fromJson(Map<String, dynamic> json) {
    return UserAffiliationRequest(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse((json['id'] ?? '').toString()) ?? 0,
      type: _nullableString(json['type']),
      name: _nullableString(json['name']),
      studentIdType: _nullableString(json['student_id_type']),
      studentIdNumber: _nullableString(json['student_id_number']),
      status: json['status']?.toString() ?? 'pending',
      rejectionReason: _nullableString(json['rejection_reason']),
      createdAt: _nullableString(json['created_at']),
      reviewedAt: _nullableString(json['reviewed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'student_id_type': studentIdType,
      'student_id_number': studentIdNumber,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
      'reviewed_at': reviewedAt,
    };
  }
}

class UserProfile {
  final String? displayName;
  final String? bio;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? location;
  final String themePreference;
  final String? timezone;
  final String? locale;
  final bool hasAvatar;
  final String? avatarUrl;
  final String? avatarUpdatedAt;

  const UserProfile({
    this.displayName,
    this.bio,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.themePreference = 'system',
    this.timezone,
    this.locale,
    this.hasAvatar = false,
    this.avatarUrl,
    this.avatarUpdatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: _nullableString(json['display_name']),
      bio: _nullableString(json['bio']),
      phone: _nullableString(json['phone']),
      dateOfBirth: _nullableString(json['date_of_birth']),
      gender: _nullableString(json['gender']),
      location: _nullableString(json['location']),
      themePreference: json['theme_preference']?.toString() ?? 'system',
      timezone: _nullableString(json['timezone']),
      locale: _nullableString(json['locale']),
      hasAvatar: json['has_avatar'] == true,
      avatarUrl: _nullableString(json['avatar_url']),
      avatarUpdatedAt: _nullableString(json['avatar_updated_at']),
    );
  }

  bool get hasAnyDetail {
    return [
      displayName,
      bio,
      phone,
      dateOfBirth,
      gender,
      location,
      timezone,
      locale,
    ].any((value) => (value ?? '').trim().isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'bio': bio,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'location': location,
      'theme_preference': themePreference,
      'timezone': timezone,
      'locale': locale,
      'has_avatar': hasAvatar,
      'avatar_url': avatarUrl,
      'avatar_updated_at': avatarUpdatedAt,
    };
  }
}

String? _nullableString(dynamic value) {
  final stringValue = value?.toString().trim() ?? '';
  return stringValue.isEmpty ? null : stringValue;
}
