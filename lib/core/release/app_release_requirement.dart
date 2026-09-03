import 'package:equatable/equatable.dart';

class AppReleaseRequirement extends Equatable {
  const AppReleaseRequirement({
    required this.platform,
    required this.minimumVersion,
    required this.minimumBuild,
    required this.forceUpdate,
    this.latestVersion,
    this.latestBuild,
    this.message,
    this.storeUrl,
  });

  factory AppReleaseRequirement.fromJson(Map<String, dynamic> json) {
    return AppReleaseRequirement(
      platform: json['platform'] as String,
      minimumVersion: json['minimum_version'] as String,
      minimumBuild: json['minimum_build'] as int,
      forceUpdate: json['force_update'] as bool,
      latestVersion: json['latest_version'] as String?,
      latestBuild: json['latest_build'] as int?,
      message: json['message'] as String?,
      storeUrl: json['store_url'] as String?,
    );
  }

  final String platform;
  final String minimumVersion;
  final int minimumBuild;
  final bool forceUpdate;
  final String? latestVersion;
  final int? latestBuild;
  final String? message;
  final String? storeUrl;

  @override
  List<Object?> get props => [
    platform,
    minimumVersion,
    minimumBuild,
    forceUpdate,
    latestVersion,
    latestBuild,
    message,
    storeUrl,
  ];
}
