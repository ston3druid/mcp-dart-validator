import 'dart:io';
import 'models/validation_models.dart';
import 'analyzer.dart';
import 'flutter_docs_checker.dart';

/// Master project validator that orchestrates all validation tools
class ProjectValidator {
  final ValidationConfig config;
  late final FlutterAnalyzer _analyzer;

  ProjectValidator({this.config = const ValidationConfig()}) {
    _analyzer = FlutterAnalyzer(config: config);
  }

  /// Run comprehensive project validation
  Future<ValidationSummary> validateProject(String projectPath) async {
    print('🚀 Starting comprehensive project validation...\n');

    return await _analyzer.analyzeProject(projectPath);
  }

  /// Quick validation (analyze + dependencies only)
  Future<ValidationSummary> quickValidate(String projectPath) async {
    print('⚡ Running quick validation...\n');

    final quickConfig = config.copyWith(
      checkFlutterApi: false,
      generateReport: false,
    );

    final analyzer = FlutterAnalyzer(config: quickConfig);
    return await analyzer.analyzeProject(projectPath);
  }

  /// Generate detailed report
  Future<void> generateReport(
    ValidationSummary summary,
    String outputPath,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('# Flutter Project Validation Report');
    buffer.writeln('Generated: ${summary.timestamp}');
    buffer.writeln('Project path: ${Directory.current.path}');
    buffer.writeln('');

    // Executive summary
    buffer.writeln('## Executive Summary');
    buffer.writeln('- **Files analyzed**: ${summary.totalFiles}');
    buffer.writeln('- **Issues found**: ${summary.issuesFound}');
    buffer.writeln('- **Errors**: ${summary.errorCount}');
    buffer.writeln('- **Warnings**: ${summary.warningCount}');
    buffer.writeln('- **Info**: ${summary.infoCount}');
    buffer.writeln(
      '- **Analysis time**: ${summary.analysisTime.inMilliseconds}ms',
    );
    buffer.writeln(
      '- **Status**: ${summary.hasErrors ? "❌ Failed" : "✅ Passed"}',
    );
    buffer.writeln('');

    // Issues by type
    buffer.writeln('## Issues by Type');
    buffer.writeln('### Errors (${summary.errorCount})');
    for (final issue in summary.issues.where((i) => i.type == 'error')) {
      buffer.writeln(
        '- **${issue.filePath}**:${issue.line ?? 0} - ${issue.message}',
      );
    }

    buffer.writeln('### Warnings (${summary.warningCount})');
    for (final issue in summary.issues.where((i) => i.type == 'warning')) {
      buffer.writeln(
        '- **${issue.filePath}**:${issue.line ?? 0} - ${issue.message}',
      );
    }

    buffer.writeln('### Info (${summary.infoCount})');
    for (final issue in summary.issues.where((i) => i.type == 'info')) {
      buffer.writeln(
        '- **${issue.filePath}**:${issue.line ?? 0} - ${issue.message}',
      );
    }
    buffer.writeln('');

    // Package validation
    if (summary.packages.isNotEmpty) {
      buffer.writeln('## Package Validation');
      int validPackages = 0;
      int invalidPackages = 0;

      for (final package in summary.packages) {
        if (package.isValid) {
          validPackages++;
          buffer.writeln('✅ **${package.name}**');
          buffer.writeln(
            '   - Latest version: ${package.latestVersion ?? "Unknown"}',
          );
          if (package.description != null) {
            buffer.writeln('   - Description: ${package.description}');
          }
        } else {
          invalidPackages++;
          buffer.writeln('❌ **${package.name}**');
          buffer.writeln('   - Error: ${package.error}');
        }
        buffer.writeln('');
      }

      buffer.writeln('### Package Summary');
      buffer.writeln('- **Valid packages**: $validPackages');
      buffer.writeln('- **Invalid packages**: $invalidPackages');
      buffer.writeln('- **Total**: ${summary.packages.length}');
      buffer.writeln('');
    }

    // Recommendations
    buffer.writeln('## Recommendations');

    if (summary.hasErrors) {
      buffer.writeln('🚨 **Critical Issues Found**');
      buffer.writeln('- Fix all errors before committing or releasing');
      buffer.writeln(
        '- Run `flutter analyze` to get detailed error information',
      );
      buffer.writeln('');
    }

    if (summary.hasWarnings) {
      buffer.writeln('⚠️ **Improvements Recommended**');
      buffer.writeln('- Address warnings for better code quality');
      buffer.writeln('- Consider using const constructors for performance');
      buffer.writeln('- Add semantic widgets for better accessibility');
      buffer.writeln('');
    }

    if (!summary.hasErrors && !summary.hasWarnings) {
      buffer.writeln('🎉 **Excellent Code Quality**');
      buffer.writeln('- No issues found');
      buffer.writeln('- Project is ready for production');
      buffer.writeln('');
    }

    // Flutter version info
    final flutterVersion = await FlutterDocsChecker.getFlutterVersionInfo();
    if (flutterVersion != null) {
      buffer.writeln('## Flutter Environment');
      buffer.writeln('- **Latest Flutter**: ${flutterVersion['tag_name']}');
      buffer.writeln('- **Released**: ${flutterVersion['published_at']}');
      buffer.writeln('');
    }

    // Save report
    final reportFile = File(outputPath);
    await reportFile.writeAsString(buffer.toString());

    print('📄 Report saved to: $outputPath');
  }

  /// Validate specific file
  Future<List<ValidationIssue>> validateFile(String filePath) async {
    print('🔍 Analyzing file: $filePath\n');

    final issues = <ValidationIssue>[];

    // Flutter-specific analysis
    if (filePath.endsWith('.dart')) {
      final flutterIssues = await FlutterDocsChecker.analyzeFlutterFile(
        filePath,
        strictMode: config.strictMode,
      );
      issues.addAll(flutterIssues);
    }

    return issues;
  }

  /// Check project health score
  double calculateHealthScore(ValidationSummary summary) {
    if (summary.totalFiles == 0) return 0.0;

    double score = 100.0;

    // Deduct points for errors
    score -= (summary.errorCount * 10.0);

    // Deduct points for warnings
    score -= (summary.warningCount * 2.0);

    // Deduct points for info issues
    score -= (summary.infoCount * 0.5);

    // Ensure score doesn't go below 0
    return score.clamp(0.0, 100.0);
  }

  /// Get health grade
  String getHealthGrade(double score) {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'C+';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Generate health report
  String generateHealthReport(ValidationSummary summary) {
    final score = calculateHealthScore(summary);
    final grade = getHealthGrade(score);

    final buffer = StringBuffer()
      ..writeln('# Project Health Report')
      ..writeln('Generated: ${DateTime.now()}')
      ..writeln('')
      ..writeln('## Health Score: ${score.toStringAsFixed(1)}/100')
      ..writeln('## Grade: $grade')
      ..writeln('')
      ..writeln('## Health Breakdown')
      ..writeln('- **Base Score**: 100.0')
      ..writeln('- **Error Penalty**: -${summary.errorCount * 10.0}')
      ..writeln('- **Warning Penalty**: -${summary.warningCount * 2.0}')
      ..writeln('- **Info Penalty**: -${summary.infoCount * 0.5}')
      ..writeln('- **Final Score**: $score')
      ..writeln('')
      ..writeln('## Recommendations');
    switch (grade) {
      case 'A+':
      case 'A':
        buffer.writeln('🎉 **Excellent!** Your project is in top shape.');
        buffer.writeln('- Keep up the great work!');
        buffer.writeln('- Consider sharing your practices with the team.');
        break;
      case 'B+':
      case 'B':
        buffer.writeln('👍 **Good!** Your project is well-maintained.');
        buffer.writeln('- Address warnings to achieve A grade.');
        buffer.writeln('- Consider adding more tests.');
        break;
      case 'C+':
      case 'C':
        buffer.writeln('⚠️ **Fair.** Your project needs some attention.');
        buffer.writeln('- Fix errors and warnings ASAP.');
        buffer.writeln('- Review code quality standards.');
        break;
      case 'D':
      case 'F':
        buffer.writeln('🚨 **Poor.** Your project needs immediate attention.');
        buffer.writeln('- Critical issues must be fixed.');
        buffer.writeln('- Consider code refactoring.');
        buffer.writeln('- Schedule code review.');
        break;
    }

    return buffer.toString();
  }

  /// Setup validation for CI/CD
  static Future<void> setupCIValidation() async {
    print('🔧 Setting up CI/CD validation...\n');

    // Create GitHub Actions workflow
    final workflow = File('.github/workflows/flutter-validation.yml');
    if (!await workflow.parent.exists()) {
      await workflow.parent.create(recursive: true);
    }

    const workflowContent = '''
name: Flutter Project Validation

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.0'
        channel: 'stable'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run Flutter MCP validation
      run: |
        dart pub add flutter_mcp_tools
        dart run flutter_mcp_tools validate --report
      
    - name: Upload validation report
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: validation-report
        path: validation-report.md
''';

    await workflow.writeAsString(workflowContent);
    print('✅ GitHub Actions workflow created');

    // Create pre-commit hook
    final preCommit = File('.git/hooks/pre-commit');
    if (!await preCommit.parent.exists()) {
      await preCommit.parent.create(recursive: true);
    }

    const preCommitContent = '''#!/bin/sh
# Flutter MCP Tools pre-commit hook
echo "🔍 Running pre-commit validation..."

# Run quick validation
dart run flutter_mcp_tools validate --quick

if [ \$? -ne 0 ]; then
  echo "❌ Validation failed! Commit aborted."
  echo "Run 'dart run flutter_mcp_tools validate' for details."
  exit 1
fi

echo "✅ Validation passed!"
exit 0
''';

    await preCommit.writeAsString(preCommitContent);

    // Make hook executable
    await Process.run('chmod', ['+x', preCommit.path]);
    print('✅ Pre-commit hook created');

    print('\n🎉 CI/CD validation setup complete!');
    print('📁 Files created:');
    print('  - .github/workflows/flutter-validation.yml');
    print('  - .git/hooks/pre-commit');
  }
}
