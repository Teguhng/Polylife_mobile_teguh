import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:mobile_ver/core/config/api_config.dart';
import 'package:mobile_ver/core/media/local_image_cache.dart';
import 'package:mobile_ver/core/storage/local_storage.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/auth/models/user_model.dart';

class ProfileAvatar extends StatefulWidget {
  final User? user;
  final String fallbackName;
  final double size;
  final double borderWidth;
  final TextStyle initialsStyle;
  final List<Color> gradientColors;
  final List<BoxShadow> boxShadow;

  const ProfileAvatar({
    super.key,
    required this.user,
    required this.fallbackName,
    required this.size,
    required this.initialsStyle,
    required this.gradientColors,
    this.borderWidth = 2,
    this.boxShadow = const [],
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _lastAvatarUrl;
  Future<Uint8List?>? _avatarBytesFuture;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _resolveAvatarUrl(widget.user);
    if (avatarUrl != _lastAvatarUrl) {
      _lastAvatarUrl = avatarUrl;
      _avatarBytesFuture = avatarUrl == null
          ? null
          : _loadAvatarBytes(avatarUrl);
    }

    return Container(
      height: widget.size,
      width: widget.size,
      padding: EdgeInsets.all(widget.borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appSurface,
        boxShadow: widget.boxShadow,
      ),
      child: ClipOval(
        child: avatarUrl == null
            ? _InitialsAvatar(
                name: widget.fallbackName,
                style: widget.initialsStyle,
                gradientColors: widget.gradientColors,
              )
            : FutureBuilder<Uint8List?>(
                future: _avatarBytesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
                    return _InitialsAvatar(
                      name: widget.fallbackName,
                      style: widget.initialsStyle,
                      gradientColors: widget.gradientColors,
                    );
                  }

                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: widget.size,
                    height: widget.size,
                    errorBuilder: (context, error, stackTrace) {
                      return _InitialsAvatar(
                        name: widget.fallbackName,
                        style: widget.initialsStyle,
                        gradientColors: widget.gradientColors,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<Uint8List?> _loadAvatarBytes(String avatarUrl) async {
    final cachedFile = await LocalImageCache.getIfExists(
      avatarUrl,
      cacheNamespace: 'profile_avatars',
    );
    if (cachedFile != null) {
      final bytes = await cachedFile.readAsBytes();
      if (bytes.isNotEmpty) {
        return bytes;
      }
    }

    final token = (await LocalStorage.getToken())?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }

    return LocalImageCache.getOrFetchBytes(
      avatarUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'image/webp,image/*',
      },
      cacheNamespace: 'profile_avatars',
    );
  }

  String? _resolveAvatarUrl(User? user) {
    final profile = user?.profile;
    if (profile?.hasAvatar != true) {
      return null;
    }

    final resolved =
        ApiConfig.resolveMediaUrl(profile?.avatarUrl) ??
        ApiConfig.endpointUri('/profile/avatar').toString();
    final version = profile?.avatarUpdatedAt?.trim();

    if (version == null || version.isEmpty) {
      return resolved;
    }

    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      return resolved;
    }

    return uri
        .replace(queryParameters: {...uri.queryParameters, 'v': version})
        .toString();
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final TextStyle style;
  final List<Color> gradientColors;

  const _InitialsAvatar({
    required this.name,
    required this.style,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(_initialsFromName(name), style: style)),
    );
  }
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'PL';
  }

  if (parts.length == 1) {
    final chunk = parts.first;
    return chunk.substring(0, chunk.length >= 2 ? 2 : 1).toUpperCase();
  }

  return (parts.first[0] + parts.last[0]).toUpperCase();
}
