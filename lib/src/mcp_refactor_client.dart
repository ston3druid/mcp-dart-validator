import 'dart:convert';
import 'package:http/http.dart' as http;

/// MCP client for Dart refactoring operations
class McpRefactorClient {
  final String _serverUrl;

  McpRefactorClient({String serverUrl = 'http://localhost:3000'})
    : _serverUrl = serverUrl;

  /// Apply automated fixes using Dart MCP server
  Future<List<String>> applyFixes(
    String projectPath,
    List<String> issues,
  ) async {
    try {
      final response = await _callMcpTool('apply_fixes', {
        'projectPath': projectPath,
        'issues': issues,
      });

      return List<String>.from((response['results'] as List?) ?? []);
    } catch (e) {
      return ['Failed to apply fixes: $e'];
    }
  }

  /// Format code using Dart MCP server
  Future<bool> formatCode(String filePath) async {
    try {
      final response = await _callMcpTool('format', {'path': filePath});

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Analyze code for refactoring opportunities
  Future<Map<String, dynamic>> analyzeForRefactoring(String projectPath) async {
    try {
      return await _callMcpTool('analyze', {
        'path': projectPath,
        'includeSuggestions': true,
      });
    } catch (e) {
      return {'error': 'Analysis failed: $e'};
    }
  }

  /// Call MCP tool endpoint
  Future<Map<String, dynamic>> _callMcpTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    final response = await http.post(
      Uri.parse('$_serverUrl/tools/$toolName'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'jsonrpc': '2.0',
        'id': DateTime.now().millisecondsSinceEpoch,
        'method': 'tools/call',
        'params': {'name': toolName, 'arguments': params},
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['result'] as Map<String, dynamic>;
    } else {
      throw Exception('MCP server error: ${response.statusCode}');
    }
  }

  /// Check if MCP server is available
  Future<bool> isServerAvailable() async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
