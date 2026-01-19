#!/usr/bin/env dart

/// 🤖 AI Agent Activation Script for Dart Validation MCP
/// 
/// This script provides a single entry point for AI agents to 
/// discover and activate the Dart Validation MCP tool.
/// 
/// Usage: dart run activate.dart
/// 
/// AI agents can run this script to:
/// 1. Verify the tool is properly set up
/// 2. Get activation commands
/// 3. Start the MCP server
/// 4. Test functionality

import 'dart:io';

void main(List<String> args) async {
  print('🤖 Dart Validation MCP - AI Agent Activation');
  print('=' * 50);
  
  // Check prerequisites
  if (!await _checkPrerequisites()) {
    print('❌ Prerequisites check failed');
    exit(1);
  }
  
  print('✅ Prerequisites check passed');
  
  // Show activation options
  _showActivationOptions(args);
  
  // If auto-activate requested
  if (args.contains('--auto') || args.contains('-a')) {
    await _autoActivate();
  }
}

/// Check if all prerequisites are met
Future<bool> _checkPrerequisites() async {
  print('\n🔍 Checking prerequisites...');
  
  // Check if we're in the right directory
  if (!await File('pubspec.yaml').exists()) {
    print('❌ pubspec.yaml not found - run this script from the project root');
    return false;
  }
  
  if (!await File('bin/mcp_validation_server.dart').exists()) {
    print('❌ MCP server not found - bin/mcp_validation_server.dart');
    return false;
  }
  
  if (!await File('AI_AGENT_README.md').exists()) {
    print('⚠️  AI_AGENT_README.md not found - may be older version');
  }
  
  // Check if dart pub get has been run
  try {
    final result = await Process.run('dart', ['pub', 'get'], 
        workingDirectory: Directory.current.path);
    if (result.exitCode != 0) {
      print('⚠️  Running dart pub get...');
      await Process.run('dart', ['pub', 'get'], 
          workingDirectory: Directory.current.path);
    }
  } catch (e) {
    print('❌ Failed to run dart pub get: $e');
    return false;
  }
  
  return true;
}

/// Show activation options for AI agents
void _showActivationOptions(List<String> args) {
  print('\n📋 Activation Options:');
  print('');
  print('1️⃣  Start MCP Server (Recommended):');
  print('   dart run bin/mcp_validation_server.dart');
  print('');
  print('2️⃣  Quick CLI Test:');
  print('   dart run bin/dart_mcp_tools.dart q');
  print('');
  print('3️⃣  Auto-Activate (with --auto flag):');
  print('   dart run activate.dart --auto');
  print('');
  print('4️⃣  Get Help:');
  print('   dart run activate.dart --help');
  print('');
  
  if (args.contains('--help') || args.contains('-h')) {
    _showDetailedHelp();
  }
}

/// Show detailed help information
void _showDetailedHelp() {
  print('\n📖 Detailed Help:');
  print('');
  print('🔧 Available Tools:');
  print('   • validate_dart_project - Validate Dart code');
  print('   • analyze_project_context - Understand project structure');
  print('   • get_error_context - Get help for errors');
  print('   • get_suggestions - Get smart suggestions');
  print('   • help - Get usage information');
  print('   • self_improve - Analyze and improve MCP server');
  print('');
  print('📁 Project Structure:');
  print('   • AI_AGENT_README.md - AI discovery guide');
  print('   • bin/mcp_validation_server.dart - Main MCP server');
  print('   • bin/dart_mcp_tools.dart - CLI tools');
  print('   • lib/dart_validation_mcp.dart - Main library');
  print('');
  print('🚀 Quick Start:');
  print('   1. Run: dart run activate.dart --auto');
  print('   2. Connect your MCP client to stdin/stdout');
  print('   3. Start using the tools!');
  print('');
}

/// Auto-activate the MCP server
Future<void> _autoActivate() async {
  print('\n🚀 Auto-activating MCP Server...');
  print('');
  
  try {
    // Start the MCP server
    final process = await Process.start('dart', ['run', 'bin/mcp_validation_server.dart'],
        workingDirectory: Directory.current.path,
        mode: ProcessStartMode.inheritStdio);
    
    print('✅ MCP Server started successfully!');
    print('📡 Listening for JSON-RPC requests on stdin/stdout');
    print('');
    print('🔧 Test with this JSON-RPC request:');
    print('   {"jsonrpc": "2.0", "id": 1, "method": "tools/list"}');
    print('');
    print('🛑 Press Ctrl+C to stop the server');
    
    // Wait for the process to complete
    await process.exitCode;
    
  } catch (e) {
    print('❌ Failed to start MCP server: $e');
    print('');
    print('🔧 Manual activation:');
    print('   dart run bin/mcp_validation_server.dart');
    exit(1);
  }
}
