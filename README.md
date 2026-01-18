# Dart Validation MCP

A simplified and efficient Dart validation tool that leverages the built-in `dart analyze` command for fast, reliable code validation with enhanced reporting and configuration options.

## Documentation

- **[Main README](docs/README.md)** - Complete project documentation and usage guide
- **[API Reference](docs/API_REFERENCE.md)** - Detailed API documentation and examples
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

# Quick validation
dart run bin/dart_mcp_tools.dart validate

# Detailed analysis
dart run bin/dart_mcp_tools.dart analyze

# With options
dart run bin/dart_mcp_tools.dart validate --verbose --format json
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

## Description

This project provides simplified Dart validation tools by leveraging the built-in `dart analyze` command. The codebase has been streamlined from ~4000 lines to ~200 lines for better maintainability and performance, while adding enhanced features like file counting, timing information, and multiple output formats.

## Commands

| Command | Description | Options |
|---------|-------------|----------|
| `validate` | Validate project using dart analyze | `--path <path>`, `--exclude <path>`, `--verbose`, `--format <format>` |
| `analyze` | Run detailed dart analyze with verbose output | `--path <path>`, `--verbose` |
| `--help` | Show help message | - |

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
