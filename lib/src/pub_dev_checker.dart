import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/validation_models.dart';

/// Enhanced pub.dev API checker with comprehensive package validation
class PubDevChecker {
  static const String _baseUrl = 'https://pub.dev/api';

  /// Get detailed package information
  static Future<PackageInfo> getPackageInfo(
    String packageName, {
    String? version,
  }) async {
    try {
      final url = version != null
          ? '$_baseUrl/packages/$packageName/versions/$version'
          : '$_baseUrl/packages/$packageName';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (version != null) {
          // Specific version info
          return PackageInfo(
            name: packageName,
            latestVersion: version,
            description: data['description'] as String?,
            isValid: true,
          );
        } else {
          // Latest version info
          final latest = data['latest'] as Map<String, dynamic>?;
          return PackageInfo(
            name: packageName,
            latestVersion: latest?['version'] as String?,
            description: latest?['description'] as String?,
            isValid: true,
          );
        }
      } else if (response.statusCode == 404) {
        return PackageInfo(
          name: packageName,
          isValid: false,
          error: 'Package not found on pub.dev',
        );
      } else {
        return PackageInfo(
          name: packageName,
          isValid: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return PackageInfo(
        name: packageName,
        isValid: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Check package version compatibility
  static Future<bool> isVersionCompatible(
    String packageName,
    String constraint,
  ) async {
    final info = await getPackageInfo(packageName);
    if (!info.isValid || info.latestVersion == null) {
      return false;
    }

    return _satisfiesConstraint(info.latestVersion!, constraint);
  }

  /// Get package dependencies
  static Future<List<String>> getPackageDependencies(String packageName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/packages/$packageName'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latest = data['latest'] as Map<String, dynamic>?;
        final pubspec = latest?['pubspec'] as Map<String, dynamic>?;
        final dependencies = pubspec?['dependencies'] as Map<String, dynamic>?;

        if (dependencies != null) {
          return dependencies.keys.cast<String>().toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Check if package is actively maintained
  static Future<bool> isActivelyMaintained(String packageName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/packages/$packageName'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latest = data['latest'] as Map<String, dynamic>?;
        final publishedAt = latest?['published_at'] as String?;

        if (publishedAt != null) {
          final publishDate = DateTime.parse(publishedAt);
          final sixMonthsAgo = DateTime.now().subtract(
            const Duration(days: 180),
          );
          return publishDate.isAfter(sixMonthsAgo);
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get package popularity metrics
  static Future<Map<String, dynamic>?> getPackageMetrics(
    String packageName,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/packages/$packageName'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latest = data['latest'] as Map<String, dynamic>?;

        return {
          'likes': latest?['likes'] as int? ?? 0,
          'pubPoints': latest?['pub_points'] as int? ?? 0,
          'popularity': latest?['popularity'] as double? ?? 0.0,
          'grantedPoints': latest?['granted_points'] as int? ?? 0,
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate multiple packages
  static Future<List<PackageInfo>> validatePackages(
    Map<String, String> dependencies,
  ) async {
    final results = <PackageInfo>[];

    // Check packages in parallel for better performance
    final futures = dependencies.entries.map((entry) async {
      final info = await getPackageInfo(entry.key);
      return info;
    }).toList();

    final packageInfos = await Future.wait(futures);
    results.addAll(packageInfos);

    return results;
  }

  /// Check for security advisories
  static Future<List<Map<String, dynamic>>> getSecurityAdvisories(
    String packageName,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/packages/$packageName/advisories'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final advisories = data['advisories'] as List<dynamic>? ?? [];
        return advisories.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Simple semantic version constraint checking
  static bool _satisfiesConstraint(String version, String constraint) {
    // Remove common constraint operators
    final cleanConstraint = constraint.replaceAll(RegExp(r'[\^~>=<]'), '');
    final cleanVersion = version.split('-')[0]; // Remove build metadata

    // Simple version comparison (can be enhanced with proper semver library)
    final constraintParts = cleanConstraint.split('.').map(int.parse).toList();
    final versionParts = cleanVersion.split('.').map(int.parse).toList();

    for (
      int i = 0;
      i < constraintParts.length && i < versionParts.length;
      i++
    ) {
      if (versionParts[i] > constraintParts[i]) {
        return true;
      } else if (versionParts[i] < constraintParts[i]) {
        return false;
      }
    }

    return versionParts.length >= constraintParts.length;
  }

  /// Generate dependency report
  static String generateDependencyReport(List<PackageInfo> packages) {
    final buffer = StringBuffer();
    buffer.writeln('# Dependency Validation Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');

    int validCount = 0;
    int invalidCount = 0;

    for (final package in packages) {
      if (package.isValid) {
        validCount++;
        buffer.writeln('✅ **${package.name}**');
        buffer.writeln('   Latest: ${package.latestVersion ?? "Unknown"}');
        if (package.description != null) {
          buffer.writeln('   Description: ${package.description}');
        }
      } else {
        invalidCount++;
        buffer.writeln('❌ **${package.name}**');
        buffer.writeln('   Error: ${package.error}');
      }
      buffer.writeln('');
    }

    buffer.writeln('## Summary');
    buffer.writeln('- Valid packages: $validCount');
    buffer.writeln('- Invalid packages: $invalidCount');
    buffer.writeln('- Total: ${packages.length}');

    return buffer.toString();
  }
}
