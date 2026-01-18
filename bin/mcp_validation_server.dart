import 'package:dart_validation_mcp/dart_validation_mcp.dart';

/// Main entry point for the Dart Validation MCP Server
/// 
/// This executable starts the MCP server that provides AI-friendly
/// Dart validation and context analysis tools.
void main() async {
  await DartValidationMcpServer.start();
}
