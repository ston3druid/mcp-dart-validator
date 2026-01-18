// Copyright (c) 2026 Flutter MCP Tools Team
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT
// 
// Contributions by:
// - Cascade AI Assistant (Architecture & Implementation)
// - Flutter Community (Feedback & Testing)

import 'dart:io';
import 'package:pub_semver/pub_semver.dart';
import 'dart_version_config.dart';

/// Analyzes a project to determine optimal Dart linting configuration
class ProjectAnalyzer {
  /// Analyze a Flutter/Dart project and get recommended configuration
  static Future<ProjectAnalysisResult> analyzeProject(String projectPath) async {
    final projectDartVersion = await _detectProjectDartVersion(projectPath);
    final flutterVersion = await _detectFlutterVersion(projectPath);
    final projectStructure = await _analyzeProjectStructure(projectPath);
    final dependencies = await _analyzeDependencies(projectPath);
    final recommendedConfig = _generateOptimalConfig(ProjectAnalysisResult(
      projectDartVersion: projectDartVersion,
      flutterVersion: flutterVersion,
      projectStructure: projectStructure,
      dependencies: dependencies,
      recommendedConfig: {},
      issues: 0,
    ));
    
    return ProjectAnalysisResult(
      projectDartVersion: projectDartVersion,
      flutterVersion: flutterVersion,
      projectStructure: projectStructure,
      dependencies: dependencies,
      recommendedConfig: recommendedConfig,
      issues: 0,
    );
  }
  
  /// Detect Dart version constraint from pubspec.yaml
  static Future<Version?> _detectProjectDartVersion(String projectPath) async {
    try {
      final pubspecFile = File('$projectPath/pubspec.yaml');
      if (!await pubspecFile.exists()) return null;
      
      final content = await pubspecFile.readAsString();
      
      // Look for SDK constraint
      final sdkPattern = RegExp('sdk:\\\\s*[\\\'\\"]?\\^?(\\d+)\\.(\\d+)\\.(\\d+)[\\\'\\"]?');
      final sdkMatch = sdkPattern.firstMatch(content);
      if (sdkMatch != null) {
        final major = int.parse(sdkMatch.group(1)!);
        final minor = int.parse(sdkMatch.group(2)!);
        final patch = int.parse(sdkMatch.group(3)!);
        return Version(major, minor, patch);
      }
      
      return null;
    } on FileSystemException catch (e) {
      // Log file system errors but don't crash
      stderr.writeln('Warning: Could not read pubspec.yaml: ${e.message}');
      return null;
    } on FormatException catch (e) {
      // Log version parsing errors
      stderr.writeln('Warning: Invalid version format in pubspec.yaml: ${e.message}');
      return null;
    } catch (e) {
      // Catch any other unexpected errors
      stderr.writeln('Warning: Unexpected error detecting Dart version: $e');
      return null;
    }
  }
  
  /// Detect Flutter version from pubspec.lock
  static Future<Version?> _detectFlutterVersion(String projectPath) async {
    try {
      final lockFile = File('$projectPath/pubspec.lock');
      if (!await lockFile.exists()) return null;
      
      final content = await lockFile.readAsString();
      
      // Look for Flutter version in lock file
      final flutterMatch = RegExp(r'flutter:\s*\n\s*version:\s*(\d+)\.(\d+)\.(\d+)').firstMatch(content);
      if (flutterMatch != null) {
        final major = int.parse(flutterMatch.group(1)!);
        final minor = int.parse(flutterMatch.group(2)!);
        final patch = int.parse(flutterMatch.group(3)!);
        return Version(major, minor, patch);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Analyze project structure
  static Future<ProjectStructure> _analyzeProjectStructure(String projectPath) async {
    bool isFlutterProject = false;
    int dartFileCount = 0;
    int testFileCount = 0;
    bool hasTests = false;
    bool hasGeneratedFiles = false;
    
    // Check for Flutter project
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      isFlutterProject = content.contains('flutter:') || content.contains('sdk: flutter');
    }
    
    // Count Dart files
    final libDir = Directory('$projectPath/lib');
    if (await libDir.exists()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          dartFileCount++;
        }
      }
    }
    
    // Check for test files
    final testDir = Directory('$projectPath/test');
    if (await testDir.exists()) {
      hasTests = true;
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          testFileCount++;
        }
      }
    }
    
    // Check for generated files
    hasGeneratedFiles = await _hasGeneratedFiles(projectPath);
    
    return ProjectStructure(
      isFlutterProject: isFlutterProject,
      dartFileCount: dartFileCount,
      testFileCount: testFileCount,
      hasTests: hasTests,
      hasGeneratedFiles: hasGeneratedFiles,
    );
  }
  
  /// Analyze dependencies from pubspec.yaml
  static Future<Map<String, DependencyInfo>> _analyzeDependencies(String projectPath) async {
    final dependencies = <String, DependencyInfo>{};
    
    try {
      final pubspecFile = File('$projectPath/pubspec.yaml');
      if (!await pubspecFile.exists()) return dependencies;
      
      final content = await pubspecFile.readAsString();
      
      // Parse dependencies (simple regex approach)
      final depPattern = RegExp(r'^\s+([\w_-]+):\s*\^?([\d.]+)', multiLine: true);
      final matches = depPattern.allMatches(content);
      
      for (final match in matches) {
        final name = match.group(1)!;
        final version = match.group(2)!;
        dependencies[name] = DependencyInfo(name: name, version: version);
      }
    } catch (e) {
      // Return empty map on error
    }
    
    return dependencies;
  }
  
  /// Check if project has generated files
  static Future<bool> _hasGeneratedFiles(String projectPath) async {
    final patterns = ['*.g.dart', '*.freezed.dart', '*.mocks.dart'];
    
    for (final pattern in patterns) {
      final files = await Directory(projectPath)
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.contains(pattern))
          .cast<File>()
          .toList();
      
      if (files.isNotEmpty) return true;
    }
    
    return false;
  }
  
  /// Generate optimal configuration based on project analysis
  static Map<String, dynamic> _generateOptimalConfig(ProjectAnalysisResult analysis) {
    final config = <String, dynamic>{};
    
    // Base rules from current Dart version
    final baseConfig = DartVersionConfig.getAnalysisOptions();
    config.addAll(baseConfig);
    
    final rules = Map<String, bool>.from(config['rules'] as Map);
    
    // Adjust based on project type
    if (analysis.projectStructure?.isFlutterProject == true) {
      // Flutter-specific rules
      rules['use_key_in_widget_constructors'] = true;
      rules['use_full_hex_values_for_flutter_colors'] = true;
      rules['avoid_web_libraries_in_flutter'] = true;
    }
    
    // Adjust based on project size
    if (analysis.projectStructure?.dartFileCount != null && 
        analysis.projectStructure!.dartFileCount! > 50) {
      // Stricter rules for larger projects
      rules['prefer_final_locals'] = true;
      rules['prefer_final_fields'] = true;
      rules['omit_local_variable_types'] = true;
    }
    
    // Adjust based on dependencies
    if (analysis.dependencies.containsKey('json_serializable')) {
      rules['unnecessary_lambdas'] = false; // Required for serialization
    }
    
    if (analysis.dependencies.containsKey('freezed')) {
      rules['unnecessary_this'] = false; // Required for freezed classes
    }
    
    // Adjust based on Dart version compatibility
    if (analysis.projectDartVersion != null) {
      final projectVersion = analysis.projectDartVersion!;
      final currentVersion = DartVersionConfig.currentVersion;
      
      if (projectVersion < currentVersion) {
        print('⚠️  Project Dart version ($projectVersion) is older than current ($currentVersion)');
        print('   Consider updating project dependencies for latest features');
      }
    }
    
    config['rules'] = rules;
    config['project_analysis'] = {
      'dart_version': analysis.projectDartVersion?.toString(),
      'flutter_version': analysis.flutterVersion?.toString(),
      'is_flutter': analysis.projectStructure?.isFlutterProject,
      'dart_files': analysis.projectStructure?.dartFileCount,
      'test_files': analysis.projectStructure?.testFileCount,
      'dependencies': analysis.dependencies.length,
    };
    
    return config;
  }
  
  /// Generate project-specific analysis_options.yaml
  static Future<String> generateProjectSpecificAnalysisOptions(String projectPath) async {
    final analysis = await analyzeProject(projectPath);
    final config = analysis.recommendedConfig;
    
    final buffer = StringBuffer();
    
    buffer.writeln('# Project-Specific Analysis Options');
    buffer.writeln('# Generated for: ${analysis.projectDartVersion ?? 'Unknown Dart version'}');
    buffer.writeln('# Current Dart SDK: ${DartVersionConfig.currentVersion}');
    buffer.writeln('# Flutter version: ${analysis.flutterVersion ?? 'Not detected'}');
    buffer.writeln();
    
    buffer.writeln('include: package:flutter_lints/flutter.yaml');
    buffer.writeln();
    buffer.writeln('analyzer:');
    buffer.writeln('  exclude:');
    
    if (analysis.projectStructure?.hasGeneratedFiles == true) {
      buffer.writeln('    - "**/*.g.dart"');
      buffer.writeln('    - "**/*.freezed.dart"');
    }
    
    buffer.writeln('    - "bin/**"');
    
    if (analysis.projectStructure?.hasTests == true) {
      buffer.writeln('    - "test/**"');
    }
    
    buffer.writeln();
    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    
    // Sort rules for consistent output
    final rules = Map<String, bool>.from(config['rules'] as Map);
    final sortedRules = Map.fromEntries(
      rules.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    for (final entry in sortedRules.entries) {
      buffer.writeln('    ${entry.key}: ${entry.value}');
    }
    
    buffer.writeln();
    buffer.writeln('# Project Analysis Summary:');
    final projectInfo = config['project_analysis'] as Map<String, dynamic>;
    for (final entry in projectInfo.entries) {
      buffer.writeln('# ${entry.key}: ${entry.value}');
    }
    
    return buffer.toString();
  }
}

/// Result of project analysis
class ProjectAnalysisResult {
  final Version? projectDartVersion;
  final Version? flutterVersion;
  final ProjectStructure? projectStructure;
  final Map<String, DependencyInfo> dependencies;
  final Map<String, dynamic> recommendedConfig;
  final int? issues;
  
  const ProjectAnalysisResult({
    this.projectDartVersion,
    this.flutterVersion,
    this.projectStructure,
    this.dependencies = const {},
    this.recommendedConfig = const {},
    this.issues = 0,
  });
}

/// Information about project structure
class ProjectStructure {
  final bool isFlutterProject;
  final int dartFileCount;
  final int testFileCount;
  final bool hasTests;
  final bool hasGeneratedFiles;
  
  const ProjectStructure({
    this.isFlutterProject = false,
    this.dartFileCount = 0,
    this.testFileCount = 0,
    this.hasTests = false,
    this.hasGeneratedFiles = false,
  });
}

/// Information about a dependency
class DependencyInfo {
  final String name;
  final String version;
  
  const DependencyInfo({required this.name, required this.version});
}
