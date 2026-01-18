# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-18

### Added
- **Enhanced CLI Interface** - Complete rewrite with modern command-line parsing
- **Multiple Output Formats** - Support for text and JSON output formats
- **Path Exclusions** - Configurable exclude patterns for analysis
- **Verbose Mode** - Detailed progress and error reporting
- **File Counting** - Tracks number of Dart files analyzed
- **Timing Information** - Analysis duration reporting
- **Cross-Platform Support** - Works on Windows, macOS, and Linux
- **Robust Error Handling** - Pre-flight checks and comprehensive error reporting
- **Progress Indicators** - Real-time feedback for large projects
- **JSON Output** - Machine-readable output for CI/CD integration

### Enhanced
- **Simplified Architecture** - Reduced from ~4000 lines to ~200 lines
- **Performance Optimization** - Uses native `dart analyze` for optimal speed
- **Better User Experience** - Clear error messages and helpful suggestions
- **Documentation** - Complete API reference and usage examples

### Removed
- **Complex Validation Logic** - Removed custom validation in favor of dart analyze
- **Unused Models** - Eliminated PackageInfo, FlutterApiInfo, ValidationSummary, ValidationConfig
- **MCP Integration** - Simplified to focus on core validation functionality
- **Health Scoring** - Removed complex scoring algorithms
- **Dependency Checking** - Simplified to focus on code analysis

### Fixed
- **Cross-Platform Compatibility** - Replaced `find` command with `Directory.list`
- **JSON Parsing** - Better handling of malformed analyzer output
- **Memory Usage** - Stream-based processing for large projects
- **Error Reporting** - More informative error messages

### Security
- **Input Validation** - Proper validation of file paths and arguments
- **Error Handling** - Safe handling of malformed data

### Documentation
- **Complete README Rewrite** - Updated to reflect current simplified state
- **API Reference** - Comprehensive documentation of all public APIs
- **Usage Examples** - Real-world examples and integration patterns
- **CI/CD Integration** - GitHub Actions and pre-commit hook examples

---

## [0.x.x] - Previous Versions

### Legacy Features (Removed in 1.0.0)
- Complex validation with 90+ custom rules
- Flutter-specific API checking
- MCP (Model Context Protocol) integration
- Health scoring and grading system
- Dependency analysis and security scanning
- Automated refactoring suggestions
- AI-powered code improvements

### Migration from 0.x to 1.0.0

The 1.0.0 release represents a complete simplification of the project. If you were using the 0.x versions:

1. **CLI Changes**: Commands have been simplified to `validate` and `analyze`
2. **Configuration**: Now uses command-line arguments instead of YAML files
3. **Output**: Enhanced text and JSON output formats
4. **Performance**: Significantly faster due to dart analyze integration
5. **Dependencies**: Reduced dependency footprint

**Old CLI:**
```bash
dart run dart_validation_mcp validate --quick
dart run dart_validation_mcp health
dart run dart_validation_mcp docs_check lib/
```

**New CLI:**
```bash
dart run bin/dart_mcp_tools.dart validate
dart run bin/dart_mcp_tools.dart analyze
dart run bin/dart_mcp_tools.dart validate --exclude test
```

---

## Version History

### 1.0.0 (2026-01-18)
- **Major Release**: Complete rewrite and simplification
- **Focus**: Fast, reliable Dart validation using native tools
- **Performance**: 5-10x faster than previous versions
- **Maintainability**: 95% reduction in code complexity

### 0.x.x (Historical)
- **Complex Feature Set**: Comprehensive validation and analysis
- **MCP Integration**: AI-powered development workflows
- **Health Scoring**: Project quality metrics
- **Dependency Analysis**: Security and version checking

---

## Upgrade Guide

### From 0.x to 1.0.0

1. **Update Dependencies**:
   ```yaml
   dependencies:
     dart_validation_mcp: ^1.0.0
   ```

2. **Update CLI Usage**:
   ```bash
   # Old
   dart run dart_validation_mcp validate --quick
   
   # New
   dart run bin/dart_mcp_tools.dart validate
   ```

3. **Update Code**:
   ```dart
   // Old
   final validator = ProjectValidator();
   final result = await validator.validateProject('.');
   
   // New
   final validator = SimpleValidator(projectPath: '.');
   final result = await validator.validate();
   ```

4. **Update CI/CD**:
   ```yaml
   # Old GitHub Actions
   - run: dart run dart_validation_mcp validate --report
   
   # New GitHub Actions
   - run: dart run bin/dart_mcp_tools.dart validate --format json
   ```

### Breaking Changes

- **CLI Interface**: Completely redesigned
- **API Surface**: Simplified to core validation functionality
- **Configuration**: Moved from YAML to command-line arguments
- **Output Format**: Enhanced text and JSON formats
- **Dependencies**: Reduced to minimal required packages

---

## Support

For help with migration or upgrading:

- 📖 [Documentation](README.md)
- 🐛 [Issue Tracker](https://github.com/ston3druid/mcp-dart-validator/issues)
- 🌐 [Repository](https://github.com/ston3druid/mcp-dart-validator)

---

**Note**: This changelog covers the major simplification in version 1.0.0. For detailed historical changes, see the git commit history.
