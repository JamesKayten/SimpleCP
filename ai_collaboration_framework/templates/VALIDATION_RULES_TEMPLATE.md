# Validation Rules for {{PROJECT_NAME}}

## Overview
These rules define the quality standards that AIs must enforce during collaboration.
Customize these rules for your project's specific requirements.

## File Size Limits
**Purpose:** Prevent overly complex files that are hard to maintain

```yaml
# Customize these limits for your project
file_size_limits:
  python_files: 300 lines max
  javascript_files: 200 lines max
  component_files: 150 lines max
  test_files: 500 lines max
  config_files: 100 lines max
```

**Validation Commands:**
```bash
# Check file sizes
find . -name "*.py" -exec wc -l {} \; | awk '$1 > 300 {print "VIOLATION: " $2 " has " $1 " lines (limit: 300)"}'
find . -name "*.js" -exec wc -l {} \; | awk '$1 > 200 {print "VIOLATION: " $2 " has " $1 " lines (limit: 200)"}'
```

## Code Quality Standards
**Purpose:** Maintain readable, maintainable code

### Complexity Limits
```yaml
complexity_rules:
  max_function_lines: 50
  max_class_lines: 200
  max_nesting_depth: 4
  max_parameters: 6
```

### Style Requirements
```yaml
style_requirements:
  consistent_formatting: required
  meaningful_names: required
  comments_for_complex_logic: required
  type_annotations: required (if applicable)
```

**Validation Commands:**
```bash
# Example validation commands (customize for your tools)
# Python example:
flake8 --max-line-length=88 --max-complexity=10 .
black --check .
mypy .

# JavaScript example:
npx eslint .
npx prettier --check .

# Add your project-specific commands here
```

## Testing Requirements
**Purpose:** Ensure code reliability and prevent regressions

```yaml
testing_requirements:
  unit_test_coverage: 85% minimum
  integration_tests: required for API endpoints
  test_naming: descriptive test names required
  test_isolation: no dependencies between tests
```

**Validation Commands:**
```bash
# Example testing validation (customize for your framework)
# Python example:
pytest --cov=. --cov-report=term-missing --cov-fail-under=85

# JavaScript example:
npm test -- --coverage --coverageThreshold='{"global":{"branches":85,"functions":85,"lines":85,"statements":85}}'

# Add your project-specific test commands here
```

## Security Standards
**Purpose:** Prevent security vulnerabilities

```yaml
security_requirements:
  no_hardcoded_secrets: required
  secure_dependencies: all dependencies must be current
  input_validation: required for all user inputs
  error_handling: no sensitive data in error messages
```

**Validation Commands:**
```bash
# Example security checks (customize for your tools)
# Python example:
bandit -r . -f json
safety check

# JavaScript example:
npm audit --audit-level=moderate
npx eslint-plugin-security

# Add your project-specific security commands here
```

## Performance Requirements
**Purpose:** Maintain application performance

```yaml
performance_requirements:
  response_time: API endpoints under 200ms
  memory_usage: reasonable memory consumption
  database_queries: optimized queries only
  bundle_size: frontend bundles under 1MB (if applicable)
```

**Validation Commands:**
```bash
# Example performance checks
# API response time testing
# Bundle size analysis
# Memory usage profiling

# Add your project-specific performance commands here
```

## Documentation Standards
**Purpose:** Maintain clear, up-to-date documentation

```yaml
documentation_requirements:
  api_documentation: OpenAPI/Swagger specs required
  code_comments: complex logic must be commented
  readme_updates: keep README current
  changelog: document all changes
```

## Project-Specific Rules

### {{PROJECT_NAME}} Custom Rules
```yaml
# Add rules specific to your project here
# Examples:

# For web applications:
# accessibility: WCAG 2.1 AA compliance
# browser_support: IE11+ support required

# For APIs:
# versioning: all endpoints must be versioned
# rate_limiting: all endpoints must have rate limits

# For data projects:
# data_validation: all data inputs must be validated
# model_accuracy: ML models must meet accuracy thresholds

# For mobile:
# offline_capability: core features work offline
# performance: 60fps UI rendering
```

## Validation Command Examples by Project Type

### Web Application (React + Node.js)
```bash
# Frontend validation
npm run lint
npm run test:coverage
npm run build # Check bundle size
npx lighthouse-ci autorun # Performance check

# Backend validation
npm run lint:server
npm run test:server
npm run security:check
```

### Python Data Science Project
```bash
# Code quality
black --check .
flake8 .
mypy .

# Testing
pytest --cov=. --cov-fail-under=85

# Data validation
python scripts/validate_data_schemas.py

# Model validation
python scripts/validate_model_performance.py
```

### Mobile Backend API
```bash
# Code quality
./gradlew ktlintCheck  # Kotlin
./gradlew spotbugsMain # Security

# Testing
./gradlew test
./gradlew integrationTest

# Performance
./gradlew performanceTest

# API validation
newman run api-tests.postman_collection.json
```

## Enforcement Strategy

### Violation Severity Levels
- **🔴 CRITICAL**: Must be fixed before merge (security, major functionality)
- **🟡 WARNING**: Should be addressed (code quality, minor performance)
- **🔵 INFO**: Nice to have (documentation, minor style)

### Auto-Merge Criteria
Only merge branches when:
- ✅ All CRITICAL violations resolved
- ✅ All validation commands pass
- ✅ All tests pass
- ✅ Code coverage meets minimum threshold

## Customization Instructions

1. **Review each section** and adapt rules to your project needs
2. **Update validation commands** to use your specific tools and frameworks
3. **Set appropriate thresholds** for your project's complexity and requirements
4. **Add project-specific rules** in the custom rules section
5. **Test validation commands** to ensure they work in your environment

---
**Project**: {{PROJECT_NAME}}
**Last Updated**: Installation date
**Framework**: AI Collaboration Framework

**Next Steps**: Customize these rules for your project, then test the validation workflow with "work ready" command.