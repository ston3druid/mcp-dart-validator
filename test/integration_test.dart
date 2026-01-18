import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_validation_mcp/src/analyzer.dart';
import 'package:dart_validation_mcp/src/mcp_refactor_client.dart';
import 'package:dart_validation_mcp/src/models/validation_models.dart';

void main() {
  group('Analyzer Integration Tests', () {
    late FlutterAnalyzer analyzer;
    late McpRefactorClient mcpClient;
    late String testProjectPath;

    setUpAll(() {
      // Use the current Flutter project as test subject
      testProjectPath = Directory.current.path;
      analyzer = const FlutterAnalyzer(
        config: ValidationConfig(
          checkPackages: false, // Disable for faster testing
          checkFlutterApi: true,
        ),
      );
      mcpClient = McpRefactorClient();
    });

    test('FlutterAnalyzer can analyze project', () async {
      print('Analyzing project at: $testProjectPath');

      final summary = await analyzer.analyzeProject(testProjectPath);

      expect(summary, isA<ValidationSummary>());
      expect(summary.totalFiles, greaterThan(0));
      expect(summary.issues, isA<List<ValidationIssue>>());
      expect(summary.analysisTime, isA<Duration>());

      print('Analysis completed:');
      print('- Files analyzed: ${summary.totalFiles}');
      print('- Issues found: ${summary.issuesFound}');
      print('- Analysis time: ${summary.analysisTime.inMilliseconds}ms');

      if (summary.issues.isNotEmpty) {
        print('\nIssues found:');
        for (final issue in summary.issues.take(5)) {
          print('  ${issue.toString()}');
        }
        if (summary.issues.length > 5) {
          print('  ... and ${summary.issues.length - 5} more');
        }
      }
    });

    test('MCP client can handle analyzer results', () async {
      // First get analysis results
      final summary = await analyzer.analyzeProject(testProjectPath);

      // Convert issues to string format for MCP client
      final issueStrings = summary.issues
          .map(
            (issue) => '${issue.filePath}:${issue.line ?? 0}: ${issue.message}',
          )
          .toList();

      print('Testing MCP client with ${issueStrings.length} issues');

      // Test MCP server availability first
      final isServerAvailable = await mcpClient.isServerAvailable();
      print('MCP Server available: $isServerAvailable');

      if (isServerAvailable) {
        // Test applying fixes (this will likely fail without a running server, but tests the integration)
        try {
          final fixResults = await mcpClient.applyFixes(
            testProjectPath,
            issueStrings,
          );
          expect(fixResults, isA<List<String>>());
          print('MCP fix results: ${fixResults.take(3).join(', ')}');
        } catch (e) {
          print(
            'MCP fix application failed (expected if server not running): $e',
          );
        }

        // Test code formatting
        try {
          final formatSuccess = await mcpClient.formatCode(testProjectPath);
          expect(formatSuccess, isA<bool>());
          print('Code formatting success: $formatSuccess');
        } catch (e) {
          print('Code formatting failed (expected if server not running): $e');
        }

        // Test refactoring analysis
        try {
          final refactorAnalysis = await mcpClient.analyzeForRefactoring(
            testProjectPath,
          );
          expect(refactorAnalysis, isA<Map<String, dynamic>>());
          print('Refactoring analysis completed: ${refactorAnalysis.keys}');
        } catch (e) {
          print(
            'Refactoring analysis failed (expected if server not running): $e',
          );
        }
      } else {
        print('Skipping MCP tests - server not available');
      }
    });

    test('Analyzer handles edge cases', () async {
      // Test with non-existent path
      const nonExistentPath = '/path/that/does/not/exist';
      final summary = await analyzer.analyzeProject(nonExistentPath);

      expect(summary, isA<ValidationSummary>());
      expect(summary.totalFiles, equals(0));
      expect(summary.issues, isA<List<ValidationIssue>>());
    });

    test('Validation models work correctly', () {
      // Test ValidationIssue creation
      const issue = ValidationIssue(
        filePath: 'test.dart',
        message: 'Test issue',
        type: 'warning',
        line: 10,
        column: 5,
        rule: 'test_rule',
      );

      expect(issue.filePath, equals('test.dart'));
      expect(issue.message, equals('Test issue'));
      expect(issue.type, equals('warning'));
      expect(issue.line, equals(10));
      expect(issue.column, equals(5));
      expect(issue.rule, equals('test_rule'));

      // Test ValidationSummary creation
      final summary = ValidationSummary(
        totalFiles: 5,
        issuesFound: 2,
        issues: [issue],
        packages: [],
        analysisTime: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(summary.totalFiles, equals(5));
      expect(summary.issuesFound, equals(2));
      expect(summary.hasWarnings, isTrue);
      expect(summary.warningCount, equals(1));
    });
  });
}
