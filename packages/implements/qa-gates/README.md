# QA Gates Package

Quality Assurance Gate system for automated code validation in ClearMethod workflows.

## Overview

`qa-gates` provides a comprehensive quality gate system that ensures code meets quality standards before progressing through workflow stages. It integrates linters, test runners, and coverage tools into an event-driven quality enforcement framework.

**Key Features:**
- ✅ **Stage-based gates** - Different quality requirements per workflow stage
- ✅ **Event-driven** - Automatic checks on stage completion
- ✅ **Configurable thresholds** - Project-specific quality standards
- ✅ **Workflow integration** - Blocks progression on failures
- ✅ **Multiple check types** - Linting, testing, coverage, documentation
- ✅ **Tool-agnostic** - Works with any linter/test runner

**Philosophy:** Quality gates enforce standards automatically, catching issues early.

---

## Installation

The `qa-gates` package is included in ClearMethod core setup.

**Manual installation:**
```bash
# Copy package to project
cp -r packages/qa-gates .cm/packages/

# Update project.yml
```

```yaml
# .cm/project.yml
concept_implementations:
  QA_GATE: qa-gates.BASIC_QA_GATE

packages:
  qa_gates:
    enabled: true
    gates:
      verifying:
        enabled: true
        checks:
          - linter
          - all_tests
          - coverage
```

**Dependencies:**
- `file-task` - Task storage
- `basic-events` - Event system
- Linter tool (eslint, pylint, etc.)
- Test runner (jest, pytest, etc.)

---

## Quick Start

### Enable Quality Gates

```yaml
# .cm/project.yml
packages:
  qa_gates:
    enabled: true
    
    # Default thresholds
    defaults:
      min_coverage: 80
      max_linter_errors: 0
    
    # Gates by stage
    gates:
      implementing:
        enabled: true
        checks:
          - linter
          - basic_tests
      
      verifying:
        enabled: true
        checks:
          - linter
          - all_tests
          - coverage
        tests:
          min_coverage: 85
```

Now when you complete `implementing` or `verifying` stages, quality gates run automatically.

### Manual Check

```yaml
# In workflow state or command
instructions:
  - QA_GATE.check("verifying", task_id)
    into: result
  
  - if: !result.passed
    then:
      - error: "Quality gate failed"
```

---

## API Reference

### QA_GATE.check(gate_name, task_id, config?)

Execute all checks for specified gate.

**Parameters:**
- `gate_name` (string, required) - Gate to check (usually stage name)
- `task_id` (string, required) - Task ID for context and logging
- `config` (object, optional) - Override gate configuration

**Returns:**
```yaml
{
  gate_name: "verifying",
  passed: false,
  checks: [
    {
      name: "linter",
      type: "code_quality",
      passed: true,
      score: 0,
      threshold: 0,
      message: "0 error(s), 2 warning(s)",
      details: {...}
    },
    {
      name: "all_tests",
      type: "testing",
      passed: false,
      score: 48,
      threshold: 50,
      message: "48/50 passed",
      details: {...}
    },
    {
      name: "coverage",
      type: "coverage",
      passed: true,
      score: 85,
      threshold: 80,
      message: "85% (threshold: 80%)",
      details: {...}
    }
  ],
  summary: {
    total: 3,
    passed: 2,
    failed: 1,
    warnings: 2
  },
  timestamp: "2025-11-25T10:30:00Z"
}
```

**Events emitted:**
- `quality.gate_checked`
- `quality.gate_passed` (if passed)
- `quality.gate_failed` (if failed)

**Example:**
```yaml
# Check verifying stage gate
- QA_GATE.check("verifying", task_id)
  into: gate_result

- if: gate_result.passed
  then:
    - info: "✅ All quality checks passed!"
  else:
    - let: failed = gate_result.checks.filter(c => !c.passed)
    - warn: "{failed.length} check(s) failed"
```

---

### QA_GATE.validate(task_id, stage)

Validate that all gates for stage are passed. **Throws error if not.**

**Parameters:**
- `task_id` (string, required) - Task ID
- `stage` (string, required) - Current workflow stage

**Returns:** `true` (or throws error)

**Example:**
```yaml
# In workflow state (e.g., verifying.yml)
instructions:
  # This will block if gate fails
  - QA_GATE.validate(task_id, "verifying")
  
  # Only reached if validation passes
  - info: "Quality gate passed, proceeding..."
```

**Use cases:**
- Enforce quality before stage transition
- Block workflow progression on failures
- Ensure standards are met

---

### QA_GATE.run_linter(files?, fix?)

Run code linter.

**Parameters:**
- `files` (array<string>, optional) - Specific files (empty = all)
- `fix` (boolean, optional) - Auto-fix issues (default: false)

**Returns:**
```yaml
{
  total_issues: 12,
  errors: 3,
  warnings: 9,
  fixed: 0,
  files_checked: 25,
  issues: [],
  raw_output: "..."
}
```

**Events emitted:**
- `quality.linter_completed`

**Example:**
```yaml
# Run linter on all files
- QA_GATE.run_linter()
  into: linter_result

- if: linter_result.errors > 0
  then:
    - error: "Fix {linter_result.errors} linter error(s)"

# Auto-fix and re-check
- QA_GATE.run_linter(null, true)
  into: fixed_result
```

**Configuration:**
```yaml
# .cm/project.yml
packages:
  qa_gates:
    linter:
      command: "npm run lint"
      fix_command: "npm run lint:fix"
      config_file: ".eslintrc.json"
```

---

### QA_GATE.run_tests(test_pattern?, coverage?)

Run test suite.

**Parameters:**
- `test_pattern` (string, optional) - Test file pattern
- `coverage` (boolean, optional) - Generate coverage (default: true)

**Returns:**
```yaml
{
  total: 50,
  passed: 48,
  failed: 2,
  skipped: 0,
  duration_ms: 5230,
  coverage: {
    lines: 85,
    statements: 83,
    functions: 78,
    branches: 72
  },
  failed_tests: [
    {
      name: "should validate user input",
      file: "tests/validation.test.js",
      error: "Expected true but got false"
    }
  ],
  raw_output: "..."
}
```

**Events emitted:**
- `quality.tests_completed`
- `quality.coverage_low` (if below threshold)

**Example:**
```yaml
# Run all tests with coverage
- QA_GATE.run_tests(null, true)
  into: test_result

- if: test_result.failed > 0
  then:
    - warn: "{test_result.failed} test(s) failed"
    
    - for: failed_test in test_result.failed_tests
      do:
        - warn: "  ❌ {failed_test.name}"

# Run specific tests
- QA_GATE.run_tests("**/*.unit.test.js", false)
  into: unit_tests
```

**Configuration:**
```yaml
# .cm/project.yml
packages:
  qa_gates:
    tests:
      command: "npm test"
      coverage_command: "npm run test:coverage"
```

---

### QA_GATE.check_coverage(threshold?)

Check if coverage meets threshold.

**Parameters:**
- `threshold` (number, optional) - Coverage % required (defaults to config)

**Returns:**
```yaml
{
  passed: false,
  coverage: 78,
  threshold: 80,
  uncovered_files: []
}
```

**Example:**
```yaml
# Check default threshold
- QA_GATE.check_coverage()
  into: coverage

- if: !coverage.passed
  then:
    - warn: "Coverage {coverage.coverage}% < {coverage.threshold}%"

# Check custom threshold
- QA_GATE.check_coverage(90)
  into: strict_coverage
```

---

### QA_GATE.get_config(gate_name?)

Get quality gate configuration.

**Parameters:**
- `gate_name` (string, optional) - Specific gate (empty = all)

**Returns:** Configuration object

**Example:**
```yaml
# Get all gate configs
- QA_GATE.get_config()
  into: all_configs

# Get specific gate config
- QA_GATE.get_config("verifying")
  into: verifying_config

- info: "Verifying gate requires: {verifying_config.checks}"
```

---

### QA_GATE.get_results(task_id, gate_name?, limit?)

Get historical quality gate results.

**Parameters:**
- `task_id` (string, required) - Task ID
- `gate_name` (string, optional) - Filter by gate name
- `limit` (number, optional) - Max results (default: 10)

**Returns:** Array of results

**Example:**
```yaml
# Get last 5 gate results
- QA_GATE.get_results(task_id, null, 5)
  into: history

- for: result in history
  do:
    - info: "{result.gate_name}: {result.passed ? 'PASSED' : 'FAILED'}"
```

---

## Gate Configuration

### Structure

Quality gates are configured per workflow stage:

```yaml
packages:
  qa_gates:
    enabled: true  # Global enable/disable
    
    # Default thresholds (used if stage doesn't override)
    defaults:
      min_coverage: 80
      max_linter_errors: 0
      max_linter_warnings: 10
      require_tests: true
    
    # Gates by stage name
    gates:
      <stage_name>:
        enabled: true
        checks: [...]  # List of check types
        linter: {...}   # Linter-specific config
        tests: {...}    # Test-specific config
        require_all_passed: true  # Block if any check fails
```

### Check Types

Available check types:

| Check Type | Description | When to Use |
|------------|-------------|-------------|
| `linter` | Code quality check | All stages |
| `basic_tests` | Quick unit tests | Early stages (implementing) |
| `all_tests` | Full test suite | Later stages (verifying, completing) |
| `coverage` | Code coverage % | Critical stages (verifying) |
| `design_document_exists` | Design doc check | Design stage |

---

## Stage-Based Gates

### Example Configuration

```yaml
packages:
  qa_gates:
    enabled: true
    
    gates:
      # DESIGNING STAGE
      designing:
        enabled: false
        checks:
          - design_document_exists
      
      # IMPLEMENTING STAGE
      implementing:
        enabled: true
        checks:
          - linter
          - basic_tests
        linter:
          enabled: true
          fail_on_error: true
          fail_on_warning: false
        tests:
          enabled: true
          require_coverage: false
      
      # VERIFYING STAGE (STRICT)
      verifying:
        enabled: true
        checks:
          - linter
          - all_tests
          - coverage
        linter:
          enabled: true
          fail_on_error: true
          fail_on_warning: false
        tests:
          enabled: true
          require_coverage: true
          min_coverage: 85
        coverage:
          enabled: true
          min_lines: 85
          min_functions: 80
          min_branches: 75
        require_all_passed: true  # CRITICAL: blocks progression
      
      # COMPLETING STAGE (FINAL CHECK)
      completing:
        enabled: true
        checks:
          - linter
          - all_tests
        require_all_passed: true
```

### Progressive Strictness

**Philosophy:** Gates get stricter as task progresses.

```
designing     → (optional) design doc check
              ↓
implementing  → linter + basic tests
              ↓
verifying     → linter + ALL tests + coverage (STRICT)
              ↓
completing    → final checks, must pass to complete
```

---

## Event-Driven Automation

QA-Gates automatically runs checks based on workflow events.

### Auto-Check on Stage Completion

**Event:** `task.stage_completed`

**Behavior:**
1. Check if `qa_gates.enabled` is true
2. Check if gate is configured for this stage
3. Run all configured checks
4. Log results to task
5. Block progression if failed and `block_progression: true`
6. Emit `quality.gate_passed` or `quality.gate_failed`

**Configuration:**
```yaml
packages:
  qa_gates:
    on_failure:
      block_progression: true   # Block workflow progression
      create_task_note: true    # Add failure note to task
      emit_event: true          # Emit failure event
```

---

### Quick Check After Commit

**Event:** `vcs.commit_created`

**Behavior:**
1. Run quick linter check on committed code
2. Run basic tests (if configured)
3. Log warnings (doesn't block, commit already happened)

**Use case:** Catch issues immediately after commit for quick fixes.

**Configuration:**
```yaml
packages:
  qa_gates:
    gates:
      pre-commit:  # Special gate for post-commit checks
        enabled: true
        checks:
          - linter
          - basic_tests
```

---

## Events Emitted

QA-Gates emits events for integration with other packages.

### quality.gate_checked

Emitted after any gate check.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  gate_name: "verifying",
  stage: "verifying",
  passed: false,
  checks_total: 3,
  checks_passed: 2,
  timestamp: "2025-11-25T10:30:00Z"
}
```

---

### quality.gate_passed

Emitted when gate validation succeeds.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  gate_name: "verifying",
  stage: "verifying",
  score: 100,
  timestamp: "2025-11-25T10:30:00Z"
}
```

**Use cases:**
- Trigger deployment
- Send success notification
- Auto-progress workflow

---

### quality.gate_failed

Emitted when gate validation fails.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  gate_name: "verifying",
  stage: "verifying",
  errors: [
    "2 test(s) failed",
    "Coverage 78% < 80%"
  ],
  checks_failed: 2,
  timestamp: "2025-11-25T10:30:00Z"
}
```

**Use cases:**
- Block deployment
- Send alert notification
- Create bug task

---

### quality.linter_completed

Emitted after linter run.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  total_issues: 12,
  errors: 3,
  warnings: 9,
  files_checked: 25,
  timestamp: "2025-11-25T10:30:00Z"
}
```

---

### quality.tests_completed

Emitted after test run.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  total: 50,
  passed: 48,
  failed: 2,
  coverage: 85,
  timestamp: "2025-11-25T10:30:00Z"
}
```

---

### quality.coverage_low

Emitted when coverage below threshold.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  coverage: 78,
  threshold: 80,
  timestamp: "2025-11-25T10:30:00Z"
}
```

---

## Integration Examples

### With SBD Workflows

```yaml
# In verifying.yml state
instructions:
  group: "Run verification checks"
  do:
    - info: "Running comprehensive quality checks..."
    
    # This will throw error if gate fails
    - QA_GATE.validate(task_id, "verifying")
    
    - info: "✅ All quality gates passed!"
    
    - TASK.set_property(task_id, "quality_verified", true)
  
  group: "Prepare for completion"
  do:
    - WORKFLOW.next(task_id)
```

---

### With Git-VCS

```yaml
# git-vcs handler listens to quality.gate_passed
on event: quality.gate_passed
  if gate_name == "completing":
    → VCS.commit("chore: quality gates passed")
    → VCS.push()
```

If quality gate fails, push is blocked.

---

### With Notifications

```yaml
# notifications handler listens to quality.gate_failed
on event: quality.gate_failed
  → NOTIFIER.send_slack("⚠️ Quality gate failed: {event.payload.errors}")
```

---

## Best Practices

### ✅ DO

**Use progressive strictness**
```yaml
# Good - stricter checks as workflow progresses
gates:
  implementing:
    checks: [linter, basic_tests]
  
  verifying:
    checks: [linter, all_tests, coverage]  # More strict
    require_all_passed: true
```

**Configure thresholds per stage**
```yaml
# Good - different requirements per stage
gates:
  implementing:
    tests:
      min_coverage: 60  # Lenient early on
  
  verifying:
    tests:
      min_coverage: 85  # Strict before completion
```

**Block progression on critical failures**
```yaml
# Good - prevent bad code from progressing
gates:
  verifying:
    require_all_passed: true  # Must pass to proceed
```

**Use events for integration**
```yaml
# Good - reactive quality enforcement
on event: quality.gate_failed
  → create_bug_task()
  → notify_team()
  → block_deployment()
```

---

### ❌ DON'T

**Don't use same strictness everywhere**
```yaml
# Bad - too strict too early
gates:
  implementing:
    checks: [linter, all_tests, coverage]
    tests:
      min_coverage: 95  # Too strict for early stage
```

**Don't ignore linter errors**
```yaml
# Bad - allowing errors to accumulate
linter:
  fail_on_error: false  # Should be true
```

**Don't skip critical stages**
```yaml
# Bad - no gate for verifying stage
gates:
  implementing:
    enabled: true
  
  verifying:
    enabled: false  # DANGEROUS!
  
  completing:
    enabled: true
```

**Don't block on warnings**
```yaml
# Bad - too restrictive
linter:
  fail_on_warning: true  # Blocks on every warning
```

---

## Troubleshooting

### Gate always passes (no checks run)

**Symptom:** `QA_GATE.check()` returns `passed: true` with 0 checks

**Diagnosis:**
```yaml
- QA_GATE.get_config("verifying")
  into: config
- info: "Gate enabled: {config.enabled}"
- info: "Checks: {config.checks}"
```

**Solutions:**
1. Verify `qa_gates.enabled: true` globally
2. Verify stage gate `enabled: true`
3. Verify `checks` array has items

---

### Linter not running

**Symptom:** Linter check skipped or fails immediately

**Diagnosis:**
```bash
# Test linter command directly
npm run lint  # or whatever command is configured
```

**Solutions:**
1. Verify linter command in config
2. Install linter dependencies
3. Check linter config file exists

---

### Tests fail but coverage shows 0%

**Symptom:** Tests run but coverage not collected

**Solutions:**
1. Use `coverage_command` instead of `command`
2. Install coverage tool (jest --coverage, pytest-cov)
3. Configure coverage in test runner config

---

### Gate blocks but errors unclear

**Symptom:** Validation fails but error message not helpful

**Diagnosis:**
```yaml
- QA_GATE.check("verifying", task_id)
  into: result

- for: check in result.checks
  do:
    - if: !check.passed
      then:
        - info: "Failed check: {check.name}"
        - info: "  Message: {check.message}"
        - info: "  Details: {yaml(check.details)}"
```

---

## Performance

### Check Duration Estimates

| Check Type | Typical Time | Notes |
|------------|--------------|-------|
| Linter | 1-5s | Fast, local only |
| Basic tests (unit) | 5-30s | Depends on test count |
| All tests | 30s-5min | Includes integration tests |
| Coverage | +10-50% | Adds overhead to test run |

### Optimization Tips

1. **Incremental linting** - Check only changed files
   ```yaml
   - VCS.get_diff()
     into: changed_files
   - QA_GATE.run_linter(changed_files)
   ```

2. **Parallel test execution** - Enable in test runner config

3. **Cache test results** - Skip if code hasn't changed

4. **Use `basic_tests` early** - Run quick tests first, comprehensive later

---

## Security

### Code Quality Standards

QA-Gates enforces security best practices:

```yaml
# Security-focused checks
gates:
  verifying:
    checks:
      - linter  # Catches common vulnerabilities
      - all_tests  # Security test coverage
      - coverage  # Ensure security code is tested
```

**Linter rules for security:**
- No eval()
- No insecure randomness
- SQL injection prevention
- XSS prevention

---

## Tool Integration

### Supported Linters

| Tool | Language | Command Example |
|------|----------|-----------------|
| ESLint | JavaScript/TS | `eslint .` |
| Pylint | Python | `pylint src/` |
| RuboCop | Ruby | `rubocop` |
| golint | Go | `golint ./...` |
| rustfmt | Rust | `cargo fmt --check` |

### Supported Test Runners

| Tool | Language | Command Example |
|------|----------|-----------------|
| Jest | JavaScript/TS | `jest --coverage` |
| pytest | Python | `pytest --cov=src` |
| RSpec | Ruby | `rspec` |
| Go test | Go | `go test -cover ./...` |
| cargo test | Rust | `cargo test` |

---

## Comparison

| Feature | QA-Gates | Manual Testing | CI/CD Only |
|---------|----------|----------------|------------|
| **Auto-check** | ✅ Yes | ❌ No | ⚠️ On push only |
| **Stage-based** | ✅ Yes | ❌ No | ❌ No |
| **Block progression** | ✅ Yes | ❌ No | ⚠️ Partial |
| **Event-driven** | ✅ Yes | ❌ No | ⚠️ Webhooks |
| **AI-friendly** | ✅ CML API | ❌ Manual | ❌ YAML config |

**QA-Gates Advantages:**
- Enforces quality at every workflow stage
- Prevents bad code from progressing
- Integrates tightly with AI workflows
- Configurable per project/stage

---

## Contributing

To improve qa-gates:

1. **Add check types** - Security scans, performance tests
2. **Better parsing** - Tool-specific output parsing
3. **More integrations** - Additional linters/test runners
4. **Custom checks** - User-defined quality checks

See main `CONTRIBUTING.md`.

---

## License

MIT License - Part of ClearMethod framework.

---

## See Also

- [QA_GATE Concept](../../docs/core/concepts/qa_gate.md)
- [Events System](../../docs/core/concepts/events.md)
- [SBD Package](../sbd/) - Workflow integration
- [Git-VCS Package](../git-vcs/) - Version control

