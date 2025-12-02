# Test Runner Package

**Intelligent test execution integrated with ClearMethod workflows.**

> Status: **Planned** (Concept only, no implementation yet)

---

## Problem

Traditional testing workflows have issues:
- ❌ Running all tests is slow
- ❌ Don't know which tests to run after changes
- ❌ Flaky tests cause false failures
- ❌ No performance tracking
- ❌ Manual test execution

---

## Solution

**Test Runner** provides intelligent test execution:
- ✅ Smart test selection (run only affected tests)
- ✅ Parallel execution for speed
- ✅ Coverage tracking and enforcement
- ✅ Flaky test detection
- ✅ Performance benchmarking
- ✅ Workflow integration

---

## Key Features

### 1. Smart Test Selection

```yaml
# Only run tests affected by changes
- TEST.run_affected()

# Analysis:
#   Changed: src/auth/login.ts
#   
#   Affected tests:
#   ✓ auth/login.test.ts (direct)
#   ✓ api/auth.test.ts (imports login.ts)
#   ✓ integration/auth-flow.test.ts (integration)
#   
#   Running 3/150 tests (98% time saved)
```

### 2. Coverage Enforcement

```yaml
- TEST.run({coverage: true})
  into: results

# Results:
coverage:
  lines: 85%      ✅ (threshold: 80%)
  functions: 78%  ✅ (threshold: 75%)
  branches: 68%   ❌ (threshold: 70%)
  
status: FAILED - Branch coverage below threshold
```

### 3. Flaky Test Detection

```yaml
# Test fails intermittently
- TEST.run()

# Flaky detector:
⚠️ Flaky Test Detected
───────────────────────
Test: auth/session.test.ts > should refresh expired tokens
Runs: 10
Passes: 7 (70%)
Fails: 3 (30%)

Likely cause: Race condition or timing issue

Recommendation: Add explicit waits or mock timers
```

### 4. Performance Tracking

```yaml
- TEST.run()

# Performance report:
Test Performance
────────────────
Total: 45.2s (baseline: 38.1s) ⚠️ +18% slower

Slowest tests:
1. integration/payment-flow.test.ts   12.3s (+3.2s)
2. api/large-dataset.test.ts          8.7s (+2.1s)
3. e2e/checkout.test.ts               6.5s (+0.8s)

Recommendation: Optimize or split slow tests
```

### 5. Watch Mode

```yaml
# Start watch mode
- TEST.watch()

# Monitors file changes and runs affected tests
[14:32:15] Changed: src/auth/login.ts
[14:32:16] Running 3 affected tests...
[14:32:18] ✅ All tests passed (2.1s)
```

---

## Use Cases

### UC-1: Fast Feedback During Implementation

```yaml
# Agent modifies code
- edit: src/api/users.ts

# Test Runner auto-triggers
- TEST.run_affected()

# Runs only:
#   - api/users.test.ts
#   - integration/user-api.test.ts
#
# Result: 2 tests, 0.8s (vs 150 tests, 45s)
```

### UC-2: Coverage Gate Before Merging

```yaml
# Verifying stage
- WORKFLOW.go("verifying")

# Auto-run tests with coverage
- TEST.run({coverage: true, all: true})

# Check coverage
- if: results.coverage.global < 80%
  then:
    - fail: "Coverage below threshold"
    - log: "Add tests for: {results.uncovered_files}"
```

### UC-3: Performance Regression Detection

```yaml
- TEST.run({benchmark: true})

# Detects regression:
❌ Performance Regression
─────────────────────────
Test: api/search.test.ts > complex query
Current: 850ms
Baseline: 420ms
Regression: +102% ⚠️

Possible causes:
- New N+1 query introduced
- Missing database index
- Inefficient algorithm

Action: Review recent changes in search module
```

---

## API (Planned)

### TEST.run(options?)

Run tests with options.

**Options:**
```yaml
{
  pattern: string,      # Test file pattern
  coverage: boolean,    # Collect coverage
  watch: boolean,       # Watch mode
  bail: boolean,        # Stop on first failure
  parallel: boolean,    # Run in parallel
  verbose: boolean,     # Verbose output
  updateSnapshot: boolean  # Update snapshots
}
```

**Returns:**
```yaml
{
  passed: number,
  failed: number,
  skipped: number,
  duration_ms: number,
  coverage: {
    lines: number,
    functions: number,
    branches: number,
    statements: number
  },
  failures: [
    {
      test: string,
      file: string,
      error: string,
      stack: string
    }
  ]
}
```

### TEST.run_affected(options?)

Run only tests affected by recent changes.

**Analysis:**
1. Get changed files (from Git or file watcher)
2. Build dependency graph
3. Find affected test files
4. Run only those tests

### TEST.get_coverage(format?)

Get test coverage report.

**Formats:**
- `json` - Structured data
- `text` - Console output
- `html` - HTML report
- `lcov` - LCOV format (for CI)

### TEST.watch(pattern?)

Start watch mode.

**Behavior:**
- Monitor file changes
- Run affected tests automatically
- Provide instant feedback
- Clear terminal between runs

---

## Smart Test Selection

### Strategy: Affected

Only run tests affected by changes.

**Analysis:**
1. **Direct imports**: Test file imports changed file
2. **Transitive imports**: Test imports module that imports changed file
3. **Integration tests**: Always run for changes in critical paths

**Example:**
```
Changed: src/auth/jwt.ts

Dependency graph:
  jwt.ts
  ├─> auth/jwt.test.ts         (direct)
  ├─> auth/middleware.ts
  │   └─> api/protected.test.ts (transitive)
  └─> integration/auth.test.ts  (integration)

Run: 3 tests (instead of 150)
Time saved: 95%
```

### Strategy: Changed

Run tests in changed files only.

### Strategy: All

Run all tests (for CI/CD or pre-merge).

---

## Configuration

```yaml
packages:
  test_runner:
    enabled: true
    
    # Framework
    framework: "jest"
    config_file: "jest.config.js"
    
    # Execution
    execution:
      parallel: true
      max_workers: 4
      timeout: 30000
      bail: false
    
    # Smart selection
    smart_selection:
      enabled: true
      strategy: "affected"
      use_git_diff: true
      use_imports_analysis: true
    
    # Coverage
    coverage:
      enabled: true
      threshold:
        global:
          lines: 80
          functions: 75
          branches: 70
      report_formats: ["text", "html"]
    
    # Auto-run
    auto_run:
      enabled: true
      on_stages: [implementing, verifying]
      on_file_change: true
      debounce_ms: 1000
    
    # Flaky detection
    flaky_detection:
      enabled: true
      retry_count: 3
      mark_flaky_threshold: 0.5
    
    # Performance
    performance:
      enabled: true
      baseline_file: ".cm/test-performance.json"
      warn_on_slowdown: true
      slowdown_threshold: 1.5
```

---

## Integration

### With Workflows (SBD)

```yaml
implementing:
  postconditions:
    - TEST.run_affected().passed == TEST.run_affected().total

verifying:
  execute:
    - TEST.run({coverage: true, all: true})
  postconditions:
    - TEST.get_coverage().lines >= 80
```

### With Quality Gates

```yaml
qa_gates:
  gates:
    implementing:
      checks: [tests]
      tests:
        strategy: "affected"
        max_failed: 0
    
    verifying:
      checks: [tests, coverage]
      tests:
        strategy: "all"
        max_failed: 0
      coverage:
        min_lines: 80
        min_branches: 70
```

### With Events

```yaml
on: file.changed
  if: config.auto_run
  - TEST.run_affected()

on: test.failed
  - EVENT.emit("test.failure", {
      test: result.test,
      error: result.error
    })
  - NOTIFICATION.send("Test failed: {test}")
```

---

## Benefits

1. **Fast Feedback** - Run only affected tests
2. **High Confidence** - Comprehensive coverage
3. **Early Detection** - Find flaky tests immediately
4. **Performance Tracking** - Prevent regressions
5. **Automatic** - Integrated into workflow

---

## Future Enhancements

- **ML-based test selection** - Learn which tests to run
- **Visual regression testing** - Screenshot comparisons
- **Mutation testing** - Test the tests
- **Distributed execution** - Run across multiple machines
- **Test impact analysis** - Understand test importance

---

## Dependencies

- `core-concept` - TASK, WORKFLOW, EVENT abstractions
- `file-task` - For task access
- `basic-events` - For event handling
- `qa-gates` - For quality gate integration

---

## See Also

- [Quality Gates](../qa-gates/)
- [SBD Workflows](../sbd/)
- [Code Review](../code-review/)

---

**Status:** Planned  
**Priority:** High (testing is critical)  
**Complexity:** High (smart selection, coverage analysis, flaky detection)

