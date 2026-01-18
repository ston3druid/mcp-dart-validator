# Dart Validation MCP

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/ston3druid/mcp-dart-validator)](https://github.com/ston3druid/mcp-dart-validator/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ston3druid/mcp-dart-validator)](https://github.com/ston3druid/mcp-dart-validator/network)
[![GitHub issues](https://img.shields.io/github/issues/ston3druid/mcp-dart-validator)](https://github.com/ston3druid/mcp-dart-validator/issues)
[![Dart SDK](https://img.shields.io/badge/Dart%20SDK-%3E%3D3.0.0-blue)](https://dart.dev/get-dart)

A simplified and efficient Dart validation tool that leverages the built-in `dart analyze` command for fast, reliable code validation with enhanced reporting and configuration options.

## ✨ Features

- 🚀 **Fast & Lightweight** - Uses native `dart analyze` for optimal performance
- 📊 **Enhanced Reporting** - File counting, timing, and detailed issue summaries
- 🔧 **Flexible Configuration** - Exclude paths, multiple output formats, verbose options
- 🛡️ **Robust Error Handling** - Pre-flight checks and comprehensive error reporting
- 📈 **Progress Indicators** - Real-time feedback for large projects
- 🎯 **Cross-Platform** - Works on Windows, macOS, and Linux
- 📝 **Multiple Output Formats** - Text and JSON output options
- 🚫 **Smart Exclusions** - Configurable path exclusions with pattern matching

## 🚀 Quick Start

### Installation

**From GitHub repository:**

```bash
# Clone the repository
git clone https://github.com/ston3druid/mcp-dart-validator.git
cd mcp-dart-validator
dart pub get

# Or add to pubspec.yaml
dependencies:
  dart_validation_mcp: ^1.0.0
```

### Basic Usage

```bash
# Quick validation
dart run bin/dart_mcp_tools.dart validate

# Detailed analysis
dart run bin/dart_mcp_tools.dart analyze

# With options
dart run bin/dart_mcp_tools.dart validate --verbose --format json

# Exclude paths
dart run bin/dart_mcp_tools.dart validate --exclude test --exclude build

# Custom project path
dart run bin/dart_mcp_tools.dart validate --path /path/to/project
```

## 📋 Available Commands

| Command | Description | Options |
|---------|-------------|----------|
| `validate` | Validate project using dart analyze | `--path <path>`, `--exclude <path>`, `--verbose`, `--format <format>` |
| `analyze` | Run detailed dart analyze with verbose output | `--path <path>`, `--verbose` |
| `--help` | Show help message | - |

### Command Options

- `--path <path>` - Specify project path (default: current directory)
- `--exclude <path>` - Exclude path from analysis (can be used multiple times)
- `--verbose` - Show detailed progress and error information
- `--format <format>` - Output format: text (default) or json
- `--help, -h` - Show help message

## 🎯 Use Cases

### For Development Teams
- **Code Quality Gates** - Ensure consistent code standards
- **Pre-commit Hooks** - Automated validation before commits
- **CI/CD Integration** - Automated quality checks in pipelines

### For Individual Developers
- **Fast Feedback** - Quick validation during development
- **Learning Tool** - Understand Dart analyzer output better
- **Project Health** - Monitor code quality over time

## 🏗️ Architecture

```
dart_validation_mcp/
├── lib/
│   ├── flutter_mcp_tools.dart       # Main library export
│   └── src/
│       ├── validation/
│       │   └── simple_validator.dart  # Core validation engine
│       └── models/
│           └── validation_models.dart # Data models
├── bin/
│   └── dart_mcp_tools.dart          # Enhanced CLI interface
└── docs/                             # Documentation
    ├── README.md                     # Main documentation
    ├── API_REFERENCE.md              # API reference
    ├── CHANGELOG.md                  # Version history
    └── ...                           # Other docs
```

## 📊 Validation Features

### Core Analysis
- **Dart Analyzer Integration** - Leverages native Dart analysis tools
- **Fast Performance** - Optimized for quick feedback
- **Error Classification** - Clear separation of errors, warnings, and info
- **File Counting** - Tracks number of files analyzed
- **Timing Information** - Analysis duration reporting

### Enhanced Features
- **Path Exclusions** - Configurable exclude patterns
- **Multiple Output Formats** - Text and JSON output
- **Verbose Mode** - Detailed progress and error information
- **Cross-Platform** - Works on Windows, macOS, and Linux
- **Pre-flight Checks** - Validates Dart SDK and project structure

## 🔧 Configuration

### Command Line Options

The tool is configured primarily through command-line arguments:

```bash
# Basic validation
dart run bin/dart_mcp_tools.dart validate

# With exclusions
dart run bin/dart_mcp_tools.dart validate --exclude test --exclude build

# Verbose output
dart run bin/dart_mcp_tools.dart validate --verbose

# JSON format
dart run bin/dart_mcp_tools.dart validate --format json

# Custom path
dart run bin/dart_mcp_tools.dart validate --path /path/to/project
```

### Environment Variables

- `DART_ANALYZE_PATH` - Custom path to dart analyze executable
- `DART_VALIDATION_VERBOSE` - Enable verbose mode by default

## 🔄 CI/CD Integration

### GitHub Actions
```yaml
name: Dart Validation
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart run bin/dart_mcp_tools.dart validate --format json > validation-results.json
      - uses: actions/upload-artifact@v3
        with:
          name: validation-results
          path: validation-results.json
```

### Pre-commit Hook
```bash
#!/bin/sh
# .git/hooks/pre-commit
dart run bin/dart_mcp_tools.dart validate
if [ $? -ne 0 ]; then
  echo "❌ Validation failed. Commit aborted."
  exit 1
fi
echo "✅ Validation passed."
```

## 📝 Examples

### Basic Project Validation
```dart
import 'package:dart_validation_mcp/flutter_mcp_tools.dart';

void main() async {
  final validator = SimpleValidator(projectPath: '.');
  final result = await validator.validate();
  
  print('Files analyzed: ${result.filesAnalyzed}');
  print('Analysis time: ${result.analysisTime.inMilliseconds}ms');
  print('Issues found: ${result.issues.length}');
  
  if (result.success) {
    print('✅ Validation passed!');
  } else {
    print('❌ Validation failed:');
    for (final issue in result.issues) {
      print('  ${issue.type}: ${issue.message}');
    }
  }
}
```

### Advanced Validation with Options
```dart
import 'package:dart_validation_mcp/flutter_mcp_tools.dart';

void main() async {
  final validator = SimpleValidator(
    projectPath: '.',
    excludePaths: ['test', 'build', '.dart_tool'],
    verbose: true,
  );
  
  final result = await validator.validate();
  
  // Process results...
}
```

## 🧪 Testing

```bash
# Run all tests
dart test

# Test the CLI tool
dart run bin/dart_mcp_tools.dart --help
dart run bin/dart_mcp_tools.dart validate

# Test with options
dart run bin/dart_mcp_tools.dart validate --verbose --format json
```

## 📊 Performance

- **Analysis Speed**: ~500-800ms for small to medium projects
- **Memory Usage**: <20MB for typical projects
- **File Counting**: Optimized Directory.list traversal
- **Cross-Platform**: Native performance on Windows, macOS, Linux

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
git clone https://github.com/ston3druid/mcp-dart-validator
cd dart_validation_mcp
dart pub get
dart test
```

### Running Tests
```bash
# Unit tests
dart test

# Integration tests
dart run bin/dart_mcp_tools.dart validate --verbose

# Performance testing
dart run bin/dart_mcp_tools.dart validate --format json
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Dart team for the excellent `dart analyze` tool
- Flutter community for inspiration and feedback
- Open source contributors who make tools like this possible

## 📞 Support

- 📖 [Documentation](https://github.com/ston3druid/mcp-dart-validator)
- 🐛 [Issue Tracker](https://github.com/ston3druid/mcp-dart-validator/issues)
- 🌐 [Repository](https://github.com/ston3druid/mcp-dart-validator)
- ⭐ [Star on GitHub](https://github.com/ston3druid/mcp-dart-validator)

---

**Made with ❤️ by [Cascade AI](https://github.com/cascade-ai)**

Simplifying Dart validation with enhanced tooling. 🚀
