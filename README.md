# Dart Validation MCP

A simplified and efficient Dart validation tool that leverages the built-in `dart analyze` command for fast, reliable code validation with enhanced reporting and configuration options.

## Documentation

- **[Main README](docs/README.md)** - Complete project documentation and usage guide
- **[API Reference](docs/API_REFERENCE.md)** - Detailed API documentation and examples
- **[MCP Integration](docs/MCP_INTEGRATION.md)** - Model Context Protocol server setup
- **[Changelog](docs/CHANGELOG.md)** - Version history and migration guide
- **[Production Guide](docs/PRODUCTION.md)** - Production deployment and CI/CD integration
- **[Security Policy](docs/SECURITY.md)** - Security considerations and best practices
- **[License](docs/LICENSE)** - MIT License

## Quick Start

```bash
# Clone the repository
git clone https://github.com/ston3druid/mcp-dart-validator.git
cd mcp-dart-validator
dart pub get

# Easiest way - quick validation with smart defaults
dart run bin/dart_mcp_tools.dart q

# Short aliases for common tasks
dart run bin/dart_mcp_tools.dart v      # validate
dart run bin/dart_mcp_tools.dart a      # analyze
dart run bin/dart_mcp_tools.dart check  # quick validation

# Traditional commands
dart run bin/dart_mcp_tools.dart validate
dart run bin/dart_mcp_tools.dart analyze
```

## Features

- 🚀 **Fast & Lightweight** - Uses native `dart analyze` for optimal performance
- 📊 **Enhanced Reporting** - File counting, timing, and detailed issue summaries
- 🔧 **Flexible Configuration** - Exclude paths, multiple output formats, verbose options
- 🛡️ **Robust Error Handling** - Pre-flight checks and comprehensive error reporting
- 📈 **Progress Indicators** - Real-time feedback for large projects
- 🎯 **Cross-Platform** - Works on Windows, macOS, and Linux
- 📝 **Multiple Output Formats** - Text and JSON output options
- 🚫 **Smart Exclusions** - Configurable path exclusions with pattern matching
- 🤖 **MCP Integration** - Simple Model Context Protocol server for AI assistants
- ⚡ **Maximum Ease of Use** - Short aliases, smart defaults, auto-detection

## Description

This project provides simplified Dart validation tools by leveraging the built-in `dart analyze` command. The codebase has been streamlined from ~4000 lines to ~200 lines for better maintainability and performance, while adding enhanced features like file counting, timing information, and multiple output formats.

## Commands

| Command | Short | Description | Smart Defaults |
|---------|-------|-------------|---------------|
| `validate` | `v` | Full validation with all options | Auto-detects project path |
| `analyze` | `a` | Detailed dart analyze with verbose output | Auto-detects project path |
| `quick` | `q` | Quick validation with smart defaults | Excludes build, .dart_tool, generated |
| `check` | - | Alias for quick validation | Same as quick |

### Ease of Use Examples

```bash
# Super simple - just type 'q' for quick validation
dart run bin/dart_mcp_tools.dart q

# Short aliases
dart run bin/dart_mcp_tools.dart v      # validate
dart run bin/dart_mcp_tools.dart a      # analyze

# Smart features - auto-detects project, excludes common dirs
dart run bin/dart_mcp_tools.dart quick

# Quiet mode for scripts
dart run bin/dart_mcp_tools.dart q --quiet

# Short options
dart run bin/dart_mcp_tools.dart v -e test -e build --json
```

## MCP Server

Start the MCP server to integrate with AI assistants:

```bash
dart run bin/mcp_validation_server.dart
```

See [MCP Integration Guide](docs/MCP_INTEGRATION.md) for configuration details.

## Examples

```bash
# Basic validation
dart run bin/dart_mcp_tools.dart validate

# With exclusions
dart run bin/dart_mcp_tools.dart validate --exclude test --exclude build

# Verbose output
dart run bin/dart_mcp_tools.dart validate --verbose

# JSON format for CI/CD
dart run bin/dart_mcp_tools.dart validate --format json

# Custom project path
dart run bin/dart_mcp_tools.dart validate --path /path/to/project
```

## Output Examples

### Text Format
```
🔍 Validating project at: /path/to/project
⏳ Running dart analyze...

📊 Validation Results:
   Status: ✅ Success
   Files analyzed: 4
   Analysis time: 754ms
   Message: No issues found
```

### JSON Format
```json
{
  "success": true,
  "filesAnalyzed": 4,
  "analysisTimeMs": 689,
  "message": "No issues found",
  "summary": {
    "totalIssues": 0,
    "errors": 0,
    "warnings": 0,
    "info": 0
  },
  "issues": []
}
```

For comprehensive documentation, see the [docs/README.md](docs/README.md) file.
