# Production Deployment Guide

This guide covers deploying and using Dart Validation MCP in production environments.

## 🚀 Production Setup

### System Requirements

- **Dart SDK**: >=3.0.0
- **Operating System**: Windows 10+, macOS 10.14+, Ubuntu 18.04+
- **Memory**: Minimum 512MB RAM (recommended 1GB+)
- **Disk Space**: 50MB for tool installation
- **Network**: Optional (for dependency resolution)

### Installation

#### Option 1: From Source
```bash
# Clone the repository
git clone https://github.com/ston3druid/mcp-dart-validator.git
cd mcp-dart-validator

# Install dependencies
dart pub get

# Test installation
dart run bin/dart_mcp_tools.dart --help
```

#### Option 2: As Dependency
```yaml
# pubspec.yaml
dependencies:
  dart_validation_mcp: ^1.0.0
```

```bash
dart pub get
```

## 🔧 Configuration

### Environment Variables

```bash
# Optional: Custom Dart SDK path
export DART_ANALYZE_PATH="/path/to/dart-sdk/bin/dart"

# Optional: Default verbose mode
export DART_VALIDATION_VERBOSE="true"

# Optional: Default output format
export DART_VALIDATION_FORMAT="json"
```

### Production Best Practices

#### 1. CI/CD Integration

**GitHub Actions:**
```yaml
name: Dart Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      
      - name: Install dependencies
        run: dart pub get
      
      - name: Run validation
        run: |
          dart run bin/dart_mcp_tools.dart validate \
            --format json \
            --exclude build \
            --exclude test > validation-results.json
      
      - name: Upload results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: validation-results
          path: validation-results.json
      
      - name: Check results
        run: |
          if [ -f validation-results.json ]; then
            errors=$(jq -r '.summary.errors // 0' validation-results.json)
            if [ "$errors" -gt 0 ]; then
              echo "❌ Validation failed with $errors errors"
              exit 1
            fi
          fi
```

**GitLab CI:**
```yaml
dart_validation:
  stage: test
  image: dart:stable
  script:
    - dart pub get
    - dart run bin/dart_mcp_tools.dart validate --format json > results.json
    - |
      errors=$(jq -r '.summary.errors // 0' results.json)
      if [ "$errors" -gt 0 ]; then
        echo "❌ Validation failed with $errors errors"
        exit 1
      fi
  artifacts:
    reports:
      junit: results.json
    paths:
      - results.json
    expire_in: 1 week
```

#### 2. Pre-commit Hooks

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 Running Dart validation..."

# Run validation
dart run bin/dart_mcp_tools.dart validate --exclude build --exclude test

# Check result
if [ $? -ne 0 ]; then
  echo "❌ Validation failed. Please fix issues before committing."
  echo "Run 'dart run bin/dart_mcp_tools.dart validate --verbose' for details."
  exit 1
fi

echo "✅ Validation passed. Commit allowed."
```

#### 3. Docker Integration

```dockerfile
FROM dart:stable AS builder

WORKDIR /app
COPY . .
RUN dart pub get

# Validation stage
FROM dart:stable AS validation
WORKDIR /app
COPY --from=builder /app .

# Add validation script
RUN echo '#!/bin/sh\n\
dart run bin/dart_mcp_tools.dart validate --format json "$@"' \
    > /usr/local/bin/validate-dart && \
    chmod +x /usr/local/bin/validate-dart

ENTRYPOINT ["validate-dart"]
```

```bash
# Build and run
docker build -t dart-validator .
docker run --rm -v $(pwd):/app dart-validator /app
```

## 📊 Monitoring and Logging

### Structured Logging

For production monitoring, use JSON output:

```bash
# Log validation results
dart run bin/dart_mcp_tools.dart validate --format json \
  --exclude build --exclude test \
  2>&1 | tee validation-$(date +%Y%m%d-%H%M%S).json
```

### Metrics Collection

Create a monitoring script:

```bash
#!/bin/bash
# monitor-validation.sh

PROJECT_PATH=${1:-"."}
LOG_FILE="validation-metrics.log"

echo "$(date): Starting validation" >> $LOG_FILE

# Run validation and capture metrics
START_TIME=$(date +%s%N)
RESULT=$(dart run bin/dart_mcp_tools.dart validate --format json --path "$PROJECT_PATH")
END_TIME=$(date +%s%N)

# Extract metrics
FILES=$(echo $RESULT | jq -r '.filesAnalyzed // 0')
ISSUES=$(echo $RESULT | jq -r '.summary.totalIssues // 0')
ERRORS=$(echo $RESULT | jq -r '.summary.errors // 0')
WARNINGS=$(echo $RESULT | jq -r '.summary.warnings // 0')
DURATION=$(( ($END_TIME - $START_TIME) / 1000000 ))

# Log metrics
echo "$(date): files=$FILES issues=$ISSUES errors=$ERRORS warnings=$WARNINGS duration_ms=$DURATION" >> $LOG_FILE

# Exit with error code if validation failed
if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
```

### Alerting

Set up alerts for validation failures:

```bash
#!/bin/bash
# alert-on-failure.sh

VALIDATION_RESULT=$(dart run bin/dart_mcp_tools.dart validate --format json)
ERRORS=$(echo $VALIDATION_RESULT | jq -r '.summary.errors // 0')

if [ "$ERRORS" -gt 0 ]; then
  # Send alert (example with curl)
  curl -X POST "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
    -H 'Content-type: application/json' \
    --data "{\"text\":\"❌ Dart validation failed with $ERRORS errors in $(basename $PWD)\"}"
  
  exit 1
fi
```

## 🔒 Security Considerations

### Input Validation

The tool validates inputs to prevent security issues:

- **Path Traversal**: Validates and sanitizes file paths
- **Command Injection**: Uses proper process execution
- **Resource Limits**: Implements reasonable timeouts and limits

### Secure Deployment

#### 1. Container Security
```dockerfile
# Use non-root user
FROM dart:stable
RUN useradd -m -u 1000 validator
USER validator

# Minimal permissions
COPY --chown=validator:validator . /app
WORKDIR /app
```

#### 2. Network Isolation
```bash
# Run without network access (if not needed)
docker run --network none dart-validator
```

#### 3. Resource Limits
```bash
# Limit memory and CPU
docker run --memory=512m --cpus=1.0 dart-validator
```

## 🚀 Performance Optimization

### Large Project Handling

For projects with many files:

```bash
# Use exclusions to speed up analysis
dart run bin/dart_mcp_tools.dart validate \
  --exclude build \
  --exclude test \
  --exclude .dart_tool \
  --exclude generated \
  --verbose
```

### Caching

The tool leverages dart analyze's built-in caching:

```bash
# Clear cache if needed (rarely necessary)
dart analyze --clear-cache
```

### Parallel Processing

For multiple projects:

```bash
#!/bin/bash
# parallel-validation.sh

PROJECTS=("project1" "project2" "project3")

for project in "${PROJECTS[@]}"; do
  (
    echo "Validating $project..."
    dart run bin/dart_mcp_tools.dart validate --path "$project" \
      --format json > "$project-validation.json"
  ) &
done

wait

echo "All validations completed."
```

## 🔄 Maintenance

### Regular Updates

```bash
# Update dependencies
dart pub upgrade

# Check for tool updates
git pull origin main
dart pub get
```

### Health Checks

```bash
#!/bin/bash
# health-check.sh

# Check Dart SDK
if ! dart --version > /dev/null 2>&1; then
  echo "❌ Dart SDK not found"
  exit 1
fi

# Check tool installation
if ! dart run bin/dart_mcp_tools.dart --help > /dev/null 2>&1; then
  echo "❌ Validation tool not working"
  exit 1
fi

# Test on sample project
echo "🔍 Running health check validation..."
dart run bin/dart_mcp_tools.dart validate --path . > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "✅ Health check passed"
else
  echo "❌ Health check failed"
  exit 1
fi
```

## 📈 Scaling

### Horizontal Scaling

For large organizations:

1. **Distributed Validation**: Run validation on multiple agents
2. **Result Aggregation**: Collect and aggregate results
3. **Load Balancing**: Distribute validation tasks

### Vertical Scaling

For single large projects:

1. **Resource Allocation**: More CPU and memory
2. **Optimized Exclusions**: Exclude non-critical paths
3. **Incremental Analysis**: Validate only changed files

## 🎯 Troubleshooting

### Common Issues

#### 1. "Dart SDK not found"
```bash
# Solution: Install Dart SDK
# macOS
brew tap dart-lang/dart
brew install dart

# Ubuntu
sudo apt-get update
sudo apt-get install dart

# Windows
# Download from https://dart.dev/get-dart
```

#### 2. "Not a Dart project"
```bash
# Solution: Ensure pubspec.yaml exists
ls pubspec.yaml

# Create if missing
dart create --template=console .
```

#### 3. Performance issues
```bash
# Solution: Use exclusions and verbose mode
dart run bin/dart_mcp_tools.dart validate \
  --exclude build --exclude test --exclude .dart_tool \
  --verbose
```

### Debug Mode

Enable verbose output for debugging:

```bash
dart run bin/dart_mcp_tools.dart validate --verbose
```

### Log Analysis

Parse JSON logs for analysis:

```bash
# Extract error summary
jq '.summary' validation-results.json

# Find most common error types
jq -r '.issues[] | .type' validation-results.json | sort | uniq -c

# Find files with most issues
jq -r '.issues[] | .filePath' validation-results.json | sort | uniq -c | sort -nr
```

## 📞 Support

For production support:

- 📖 [Documentation](README.md)
- 🐛 [Issue Tracker](https://github.com/ston3druid/mcp-dart-validator/issues)
- 🌐 [Repository](https://github.com/ston3druid/mcp-dart-validator)
- 📧 [Discussions](https://github.com/ston3druid/mcp-dart-validator/discussions)

---

**Note**: This guide focuses on production deployment. For development usage, see the main [README.md](README.md).
