# Security Policy

This document outlines the security practices and policies for Dart Validation MCP.

## 🔒 Security Overview

Dart Validation MCP is a static analysis tool that reads and analyzes Dart source code. While the tool is designed with security in mind, users should be aware of potential security considerations.

## 🛡️ Security Features

### Input Validation

The tool implements comprehensive input validation:

- **Path Sanitization**: All file paths are validated and sanitized
- **Command Injection Prevention**: Uses secure process execution methods
- **Resource Limits**: Implements reasonable timeouts and memory limits
- **File Access Control**: Restricts access to intended directories only

### Safe Execution

- **No Network Access**: The tool does not make external network requests
- **No Code Execution**: Only analyzes source code, never executes it
- **Read-Only Operations**: Does not modify user files during analysis
- **Sandboxed Analysis**: Isolates analysis processes

### Data Protection

- **Local Processing**: All analysis happens locally on the user's machine
- **No Data Collection**: The tool does not collect or transmit user data
- **Temporary Files**: Securely handles temporary files and cleans up properly
- **Memory Safety**: Uses memory-safe Dart language features

## 🚨 Potential Security Considerations

### File System Access

The tool needs read access to:

- Project source files (*.dart)
- Configuration files (pubspec.yaml, analysis_options.yaml)
- Build artifacts (for comprehensive analysis)

**Mitigation**: The tool validates all paths and prevents directory traversal attacks.

### Process Execution

The tool executes `dart analyze` as a subprocess:

- Uses absolute paths when possible
- Validates command arguments
- Implements process timeouts
- Restricts execution to intended commands only

**Mitigation**: All subprocess calls use secure APIs with proper argument validation.

### Resource Usage

Large projects may consume significant resources:

- Memory usage scales with project size
- CPU usage during analysis
- Temporary disk space for processing

**Mitigation**: The tool implements resource monitoring and reasonable limits.

## 📋 Security Best Practices

### For Users

#### 1. Validate Input Paths
```bash
# Use absolute paths to prevent directory traversal
dart run bin/dart_mcp_tools.dart validate --path "/absolute/path/to/project"

# Avoid relative paths with parent directory references
# ❌ Don't do this:
dart run bin/dart_mcp_tools.dart validate --path "../../../sensitive/project"
```

#### 2. Review Exclusions
```bash
# Be explicit about exclusions to avoid unintended access
dart run bin/dart_mcp_tools.dart validate \
  --exclude "build" \
  --exclude "test" \
  --exclude ".dart_tool"
```

#### 3. Monitor Resource Usage
```bash
# Use verbose mode to monitor resource usage
dart run bin/dart_mcp_tools.dart validate --verbose
```

#### 4. Secure CI/CD Integration
```yaml
# GitHub Actions example with security considerations
- name: Run validation
  run: |
    # Use specific project path
    dart run bin/dart_mcp_tools.dart validate \
      --path "${{ github.workspace }}" \
      --format json \
      --exclude "build" \
      --exclude "test"
  env:
    # Limit environment exposure
    DART_VALIDATION_VERBOSE: "false"
```

### For Developers

#### 1. Input Validation
```dart
// Example of secure path validation
bool _isValidPath(String path) {
  try {
    final resolved = Directory(path).resolveSymbolicLinksSync();
    final current = Directory.current.resolveSymbolicLinksSync();
    
    // Ensure path is within current directory or allowed paths
    return resolved.path.startsWith(current.path);
  } catch (e) {
    return false;
  }
}
```

#### 2. Process Security
```dart
// Example of secure process execution
Future<ProcessResult> _runSecureProcess(
  String executable,
  List<String> arguments,
) async {
  // Validate executable
  if (!_isValidExecutable(executable)) {
    throw ArgumentError('Invalid executable: $executable');
  }
  
  // Validate arguments
  final sanitizedArgs = arguments.where(_isValidArgument).toList();
  
  // Run with timeout
  return await Process.run(executable, sanitizedArgs)
      .timeout(Duration(minutes: 5));
}
```

#### 3. Resource Limits
```dart
// Example of resource monitoring
class ResourceMonitor {
  static const maxMemoryMB = 512;
  static const maxTimeout = Duration(minutes: 10);
  
  static bool checkMemoryUsage() {
    final info = ProcessInfo.currentRss;
    return (info / (1024 * 1024)) < maxMemoryMB;
  }
}
```

## 🔍 Vulnerability Disclosure

### Reporting Security Issues

If you discover a security vulnerability, please report it responsibly:

1. **Do not** open a public issue
2. **Do not** disclose the vulnerability publicly
3. **Do** send a detailed report to: security@ston3druid.dev
4. **Do** include steps to reproduce the vulnerability
5. **Do** include potential impact assessment

### Response Timeline

- **Initial Response**: Within 48 hours
- **Assessment**: Within 7 days
- **Fix Timeline**: Based on severity (see below)
- **Public Disclosure**: After fix is released

### Severity Levels

| Severity | Response Time | Description |
|----------|---------------|-------------|
| Critical | 48 hours | Remote code execution, data theft |
| High | 7 days | Local privilege escalation, data corruption |
| Medium | 14 days | Information disclosure, DoS |
| Low | 30 days | Minor issues, best practices |

### Security Updates

Security updates will be released as:

1. **Patch Releases**: For critical and high severity issues
2. **Minor Releases**: For medium severity issues
3. **Major Releases**: For architectural security improvements

## 🔐 Dependencies

### Third-Party Dependencies

The tool uses minimal dependencies:

- **Dart SDK**: Core analysis capabilities
- **Standard Library**: File system, process management
- **No External Libraries**: Minimizes attack surface

### Dependency Security

- **Regular Updates**: Dependencies are updated regularly
- **Security Scanning**: Automated vulnerability scanning
- **Minimal Dependencies**: Only essential dependencies included
- **Source Verification**: All dependencies are from trusted sources

## 🚀 Secure Deployment

### Container Security

```dockerfile
# Use non-root user
FROM dart:stable
RUN useradd -m -u 1000 validator
USER validator

# Minimal permissions
COPY --chown=validator:validator . /app
WORKDIR /app

# Secure execution
RUN chmod +x bin/dart_mcp_tools.dart
```

### Network Security

```bash
# Run without network access (recommended)
docker run --network none dart-validator

# Or with restricted network
docker run --network none --read-only dart-validator
```

### File System Security

```bash
# Use specific volume mounting
docker run \
  --volume $(pwd)/source:/app/source:ro \
  --volume $(pwd)/output:/app/output:rw \
  dart-validator validate --path /app/source
```

## 📊 Security Monitoring

### Logging

The tool provides security-relevant logging:

```bash
# Enable verbose logging for security monitoring
dart run bin/dart_mcp_tools.dart validate --verbose

# Log to file for audit trail
dart run bin/dart_mcp_tools.dart validate --verbose 2>&1 | tee security.log
```

### Audit Trail

Key security events are logged:

- File access attempts
- Process execution
- Resource usage
- Error conditions
- Validation results

### Monitoring Integration

```bash
# Example monitoring script
#!/bin/bash

LOG_FILE="security-monitor.log"
ALERT_THRESHOLD=10

# Monitor validation results
dart run bin/dart_mcp_tools.dart validate --format json > results.json

# Check for suspicious activity
ERRORS=$(jq -r '.summary.errors // 0' results.json)
if [ "$ERRORS" -gt "$ALERT_THRESHOLD" ]; then
  echo "$(date): High error count detected: $ERRORS" >> $LOG_FILE
  # Send alert (integrate with your monitoring system)
fi
```

## 🔄 Incident Response

### Security Incident Process

1. **Detection**: Automated monitoring or user report
2. **Assessment**: Evaluate impact and scope
3. **Containment**: Limit potential damage
4. **Remediation**: Fix the vulnerability
5. **Communication**: Notify affected users
6. **Post-Mortem**: Learn and improve

### Emergency Contacts

- **Security Team**: security@ston3druid.dev
- **GitHub Security**: https://github.com/ston3druid/mcp-dart-validator/security
- **Discussions**: https://github.com/ston3druid/mcp-dart-validator/discussions

## 📚 Security Resources

### Recommended Reading

- [Dart Security Best Practices](https://dart.dev/guides/language/security)
- [OWASP Static Analysis Security](https://owasp.org/www-project-static-analysis-sast/)
- [Container Security Guidelines](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

### Tools

- **Dart Analyzer**: Built-in static analysis
- **Dependency Scanning**: `dart pub deps`
- **Container Scanning**: Docker Scout, Trivy
- **Code Scanning**: GitHub CodeQL, SonarQube

## 🤝 Contributing to Security

### Security Contributions

We welcome security-related contributions:

1. **Security Testing**: Help test security features
2. **Code Review**: Review code for security issues
3. **Documentation**: Improve security documentation
4. **Tools**: Develop security monitoring tools

### Security Guidelines for Contributors

- Follow secure coding practices
- Validate all inputs and outputs
- Use secure APIs and libraries
- Test for common vulnerabilities
- Document security considerations

---

## 📞 Contact

For security-related questions or concerns:

- 📧 **Security Team**: security@ston3druid.dev
- 🐛 **Report Issues**: Use private vulnerability reporting
- 🌐 **Repository**: https://github.com/ston3druid/mcp-dart-validator
- 📖 **Documentation**: [Security Best Practices](https://dart.dev/guides/language/security)

---

**Note**: This security policy is part of our commitment to maintaining a secure and reliable tool. We regularly review and update our security practices based on emerging threats and industry best practices.
