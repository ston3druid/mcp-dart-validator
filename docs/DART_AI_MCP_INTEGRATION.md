# Dart AI Code Generator with Official MCP Server Integration

This package provides enhanced AI-powered code generation capabilities that integrate seamlessly with the **official Dart and Flutter MCP server**.

## 🎯 Key Features

### Integration with Official MCP Server
- **Uses `dart mcp-server`** for project analysis and context gathering
- **Enhances** official MCP capabilities with advanced code generation
- **Falls back gracefully** when official MCP server is unavailable
- **Follows official MCP protocol** standards

### Advanced Code Generation
- **Context-aware generation** using official Dart/Flutter analysis
- **Project-specific patterns** learned from existing codebase
- **Intelligent validation** with automatic error correction
- **Multi-format support** (classes, widgets, refactoring)

## 🚀 Quick Start

### Prerequisites
1. **Dart SDK 3.9+** (required for official MCP server)
2. **Flutter SDK 3.35+** (for Flutter projects)
3. **Official MCP server** enabled in your AI assistant

### Setup with Official MCP Server

The official Dart and Flutter MCP server is accessed via:
```bash
dart mcp-server
```

Configure your AI assistant to use the official MCP server:

#### VS Code
```json
{
  "dart.mcpServer": true
}
```

#### Cursor
```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": ["mcp-server"]
    }
  }
}
```

#### Gemini CLI
```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": ["mcp-server"]
    }
  }
}
```

### Using This Package

```dart
import 'package:dart_validation_mcp/dart_ai_code_generator.dart';

// Create generator with official MCP integration
final generator = DartAiCodeGenerator(
  useOfficialMcpServer: true, // Default: true
);

// Generate a class with official MCP context
final result = await generator.generateClass(
  projectPath: '/path/to/your/project',
  className: 'MyCustomWidget',
  baseClass: 'StatelessWidget',
  description: 'A custom widget with animation support',
);

if (result.success) {
  print('Generated code: ${result.generatedCode}');
  print('Required imports: ${result.imports}');
} else {
  print('Errors: ${result.errors}');
}
```

## 📋 Available Methods

### Code Generation
- `generateCode()` - General purpose code generation
- `generateClass()` - Generate Dart classes with inheritance
- `generateWidget()` - Generate Flutter widgets
- `refactorCode()` - Refactor existing code

### Official MCP Integration
- `_gatherProjectContextViaMcp()` - Context via official MCP
- `_analyzeClassViaMcp()` - Class analysis via official MCP
- `_analyzeFlutterProjectViaMcp()` - Flutter project analysis
- `_analyzeCodeViaMcp()` - Code analysis via official MCP

## 🔄 How It Works

### 1. Context Gathering
```dart
// Uses official MCP server tools
final context = await _gatherProjectContextViaMcp(projectPath, targetFilePath);
```

The official MCP server provides:
- **Project structure analysis**
- **Dependency information**
- **Existing classes and widgets**
- **Dart/Flutter version detection**
- **Import analysis**

### 2. Enhanced Generation
```dart
// Enhanced with official MCP context
final enhancedPrompt = '''
Generate a Dart class with official MCP context:
- Dart Version: ${context.dartVersion}
- Flutter Version: ${context.flutterVersion}
- Dependencies: ${context.dependencies.keys.join(', ')}
- Existing Classes: ${context.existingClasses.join(', ')}
''';
```

### 3. Validation & Fixes
```dart
// Validates using official Dart analysis
final validatedCode = await _validateAndFixCode(
  generatedCode,
  context,
  targetFilePath,
);
```

## 🛠️ Configuration Options

### DartAiCodeGenerator Options
```dart
final generator = DartAiCodeGenerator(
  serverUrl: 'http://localhost:3000', // Fallback server URL
  versionConfig: DartVersionConfig(),   // Version configuration
  useOfficialMcpServer: true,          // Use official MCP server
);
```

### Fallback Mode
When the official MCP server is unavailable, the generator automatically falls back to:
- **Local project analysis**
- **Basic code generation**
- **Simplified validation**

## 📊 Examples

### Generate a Flutter Widget
```dart
final result = await generator.generateWidget(
  projectPath: '/my/flutter_app',
  widgetName: 'AnimatedCard',
  widgetType: 'StatefulWidget',
  description: 'A card with flip animation and gesture support',
  properties: {
    'title': 'String',
    'onTap': 'VoidCallback',
    'duration': 'Duration',
  },
);
```

### Refactor Existing Code
```dart
final result = await generator.refactorCode(
  projectPath: '/my/dart_project',
  filePath: 'lib/old_service.dart',
  refactorDescription: 'Convert to use async/await and add error handling',
);
```

## 🧪 Testing

The package includes comprehensive tests for:
- **Official MCP integration**
- **Fallback behavior**
- **Code generation quality**
- **Error handling**

Run tests:
```bash
dart test test/dart_ai_code_generator_test.dart
```

## 🔧 Troubleshooting

### Official MCP Server Not Available
```
Warning: Official MCP server unavailable, using fallback
```

**Solution:**
1. Ensure Dart SDK 3.9+ is installed
2. Run `dart mcp-server` to test availability
3. Check your AI assistant MCP configuration

### Generation Fails
```
Code generation failed: Connection refused
```

**Solution:**
1. The generator falls back to local mode automatically
2. Set `useOfficialMcpServer: false` to use fallback only
3. Check network connectivity for AI service calls

### Context Issues
```
Class MyWidget already exists in the project
```

**Solution:**
1. The generator prevents duplicate class creation
2. Use a different class name
3. Check existing project structure

## 📚 Official MCP Server Documentation

For more information about the official Dart and Flutter MCP server:

- **Official Documentation**: https://docs.flutter.dev/ai/mcp-server
- **GitHub Repository**: https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp_server
- **Configuration Guide**: https://docs.flutter.dev/ai/create-with-ai

## 🤝 Contributing

This package is designed to **complement** the official Dart MCP server, not replace it. When contributing:

1. **Prioritize official MCP integration**
2. **Maintain fallback compatibility**
3. **Follow official MCP protocols**
4. **Test with and without official MCP server**

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- **Dart Team** for the official MCP server
- **Flutter Community** for feedback and testing
- **AI Assistant Community** for MCP protocol standards
