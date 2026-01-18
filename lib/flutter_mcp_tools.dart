/// Dart Validation MCP Tools - Simplified Version
/// 
/// This package provides simplified validation tools that leverage dart analyze
/// instead of custom validation logic, reducing code redundancy and maintenance.
///
/// Features:
/// - Simple wrapper around dart analyze
/// - JSON parsing of analysis results
/// - Clean CLI interface
/// - Minimal code footprint
/// - Enhanced context analysis for AI assistance
/// - Smart error suggestions
/// - Project structure understanding
///
/// Usage: Add as dependency and use SimpleValidator directly
library flutter_mcp_tools;

// Simple validation
export 'src/validation/simple_validator.dart';

// Models and utilities
export 'src/models/validation_models.dart';

// Context analysis for AI assistance
export 'src/context/project_analyzer.dart';
export 'src/context/error_context_provider.dart';
export 'src/context/smart_suggester.dart';
export 'src/models/context_models.dart';
