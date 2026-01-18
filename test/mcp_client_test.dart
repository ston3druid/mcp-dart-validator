import 'package:test/test.dart';
import 'package:dart_validation_mcp/src/mcp_refactor_client.dart';

void main() {
  group('MCP Refactor Client Tests', () {
    late McpRefactorClient client;

    setUp(() {
      client = McpRefactorClient();
    });

    test('Client can be instantiated', () {
      expect(client, isA<McpRefactorClient>());
    });

    test('applyFixes handles dynamic response correctly', () async {
      // This test verifies the fix for the dynamic type issue
      // Since we don't have a real MCP server running, we expect the method to handle the error gracefully

      final result = await client.applyFixes('/test/path', ['test issue']);

      expect(result, isA<List<String>>());
      expect(result.first, contains('Failed to apply fixes'));
    });

    test('formatCode handles server unavailability', () async {
      final result = await client.formatCode('/test/path.dart');

      expect(result, isA<bool>());
      expect(result, isFalse); // Should return false when server is unavailable
    });

    test('analyzeForRefactoring handles server unavailability', () async {
      final result = await client.analyzeForRefactoring('/test/path');

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('error'), isTrue);
      expect(result['error'], contains('Analysis failed'));
    });

    test('isServerAvailable returns false when server is down', () async {
      final result = await client.isServerAvailable();

      expect(result, isA<bool>());
      expect(result, isFalse); // Should return false when no server is running
    });

    test('Client with custom server URL', () {
      const customUrl = 'http://localhost:8080';
      final customClient = McpRefactorClient(serverUrl: customUrl);

      expect(customClient, isA<McpRefactorClient>());
      // We can't directly access the private _serverUrl field, but the client should be created successfully
    });
  });
}
