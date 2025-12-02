# Code Review Package

**AI-powered automated code review integrated with ClearMethod workflows.**

> Status: **Planned** (Concept only, no implementation yet)

---

## Problem

Manual code review has limitations:
- ❌ Time-consuming and costly
- ❌ Inconsistent quality
- ❌ Human reviewers miss subtle issues
- ❌ Delays in feedback loop
- ❌ Not scalable for solo developers

---

## Solution

**Code Review** provides automated AI-powered analysis:
- ✅ Instant feedback during implementation
- ✅ Comprehensive checks (quality, security, performance)
- ✅ Consistent standards enforcement
- ✅ Integrated with quality gates
- ✅ Learning from patterns

---

## Key Features

### 1. Multi-Category Analysis

**Quality:**
- Code complexity (cyclomatic complexity)
- Code duplication
- Naming conventions
- Function/method length
- Class design patterns

**Security:**
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication issues
- Secrets in code
- Unsafe dependencies

**Performance:**
- N+1 query problems
- Memory leaks
- Inefficient algorithms
- Unnecessary loops/iterations

**Maintainability:**
- Test coverage
- Documentation completeness
- Error handling
- Logging practices
- Dead code detection

### 2. Stage-Integrated Review

```yaml
# After implementing stage
on: task.stage_completed
  if: stage == "implementing"
  then:
    - REVIEW.analyze({
        focus: ["security", "quality"],
        severity: "major+"
      })
      into: review
    
    - if: review.has_blockers
      then:
        - fail: "Code review found blocking issues"
        - TASK.log(review.issues)
```

### 3. Severity-Based Actions

```yaml
# Review results
issues:
  - severity: "blocker"
    category: "security"
    message: "SQL injection vulnerability in user query"
    file: "src/db/users.ts"
    line: 42
    action: "FAIL"  # ← Blocks workflow progression
  
  - severity: "major"
    category: "performance"
    message: "N+1 query detected in getUsers()"
    file: "src/api/users.ts"
    line: 15
    action: "WARN"  # ← Warning but doesn't block
```

### 4. AI-Powered Insights

```typescript
// Code
function getUserData(userId: string) {
  return db.query(`SELECT * FROM users WHERE id = '${userId}'`);
}

// AI Review
🚨 BLOCKER - Security Issue
─────────────────────────────
SQL Injection Vulnerability

File: src/db/users.ts:42
Severity: BLOCKER

Issue:
User input (userId) is directly interpolated into SQL query,
allowing SQL injection attacks.

Example Attack:
userId = "1' OR '1'='1"
→ Returns all users

Recommendation:
Use parameterized queries:
```typescript
return db.query('SELECT * FROM users WHERE id = ?', [userId]);
```

References:
- OWASP SQL Injection: https://...
- Best Practices: https://...
```

### 5. Quality Gate Integration

```yaml
qa_gates:
  gates:
    verifying:
      checks:
        - code_review
      
      code_review:
        enabled: true
        min_score: 7.0
        max_blockers: 0
        max_critical: 2
        auto_fix_suggestions: true
```

---

## Use Cases

### UC-1: Security Review During Implementation

```yaml
# Agent implements login function
- implement: user authentication

# Auto-review triggers
- REVIEW.analyze("security")

# Finds issues:
❌ Password stored in plain text
❌ No rate limiting on login attempts
❌ Session tokens not signed
⚠️ Missing password complexity requirements

# Blocks progression until fixed
```

### UC-2: Performance Optimization

```yaml
# Review detects performance issue
- REVIEW.analyze("performance")

# Findings:
⚠️ N+1 Query Pattern Detected
───────────────────────────────
File: src/api/posts.ts:89

Current code executes 101 queries:
1. SELECT * FROM posts       # 1 query
2. For each post:
   SELECT * FROM users       # 100 queries

Recommendation: Use JOIN
```typescript
// Instead of:
const posts = await db.query('SELECT * FROM posts');
for (let post of posts) {
  post.author = await db.query('SELECT * FROM users WHERE id = ?', [post.user_id]);
}

// Use:
const posts = await db.query(`
  SELECT posts.*, users.name as author_name
  FROM posts
  JOIN users ON posts.user_id = users.id
`);
```

Expected improvement: 101 queries → 1 query
```

### UC-3: Code Quality Feedback

```yaml
- REVIEW.analyze("quality")

# Findings:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Code Quality Issues (3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. HIGH COMPLEXITY
   Function: processUserData()
   Cyclomatic Complexity: 15 (limit: 10)
   → Consider splitting into smaller functions

2. CODE DUPLICATION
   Blocks: src/api/users.ts:45-67 ≈ src/api/posts.ts:82-104
   Similarity: 92%
   → Extract common logic to shared function

3. NAMING CONVENTION
   Variable: usr_dt (line 23)
   → Use descriptive name: userData
```

---

## API (Planned)

### REVIEW.analyze(options?)

Perform code review analysis.

**Options:**
```yaml
{
  focus: ["quality" | "security" | "performance" | "maintainability"],
  severity: "all" | "blocker+" | "critical+" | "major+",
  files: [string],  # Specific files to review
  since_commit: string  # Review changes since commit
}
```

**Returns:**
```yaml
{
  score: number,  # 0-10
  issues: [
    {
      severity: "blocker" | "critical" | "major" | "minor",
      category: string,
      message: string,
      file: string,
      line: number,
      column: number,
      suggestion: string,
      references: [string]
    }
  ],
  has_blockers: boolean,
  summary: {
    total_issues: number,
    by_severity: object,
    by_category: object
  }
}
```

### REVIEW.get_issues(filter?)

Get review issues with optional filtering.

### REVIEW.approve(comments?)

Mark code review as approved.

### REVIEW.request_changes(issues)

Request changes based on review findings.

---

## Review Categories Detail

### 1. Quality Checks

**Complexity Analysis:**
```
Cyclomatic Complexity > 10  → Warning
Cognitive Complexity > 15   → Warning
Nesting Depth > 4          → Warning
```

**Code Smells:**
- Long functions (> 50 lines)
- Large classes (> 500 lines)
- Long parameter lists (> 5 params)
- Duplicate code blocks
- Dead code
- Magic numbers

### 2. Security Checks

**Common Vulnerabilities:**
- SQL Injection
- XSS (Cross-Site Scripting)
- CSRF (Cross-Site Request Forgery)
- Path Traversal
- Insecure Deserialization
- Weak Cryptography
- Hardcoded Secrets

**Dependency Security:**
- Known CVEs in dependencies
- Outdated packages
- Deprecated packages

### 3. Performance Checks

**Database:**
- N+1 queries
- Missing indexes
- Inefficient queries
- Missing pagination

**Algorithms:**
- O(n²) or worse complexity
- Unnecessary iterations
- Redundant computations
- Memory leaks

### 4. Maintainability Checks

**Testing:**
- Test coverage < threshold
- Missing edge case tests
- No integration tests

**Documentation:**
- Missing function docs
- Outdated comments
- No usage examples

**Error Handling:**
- Uncaught exceptions
- Empty catch blocks
- Missing error logging

---

## Configuration

```yaml
packages:
  code_review:
    enabled: true
    
    # Auto-review triggers
    auto_review:
      enabled: true
      on_stages: [implementing, verifying]
      on_commit: true
      on_pr_create: true
    
    # Categories
    categories:
      quality:
        enabled: true
        max_complexity: 10
        max_function_length: 50
        max_class_length: 500
        check_naming: true
        check_duplication: true
      
      security:
        enabled: true
        severity_level: "strict"
        check_dependencies: true
        fail_on_secrets: true
      
      performance:
        enabled: true
        check_algorithms: true
        check_database: true
        check_memory: true
      
      maintainability:
        enabled: true
        min_test_coverage: 80
        require_docs: true
        check_error_handling: true
    
    # Severity actions
    severity:
      blocker:
        action: "fail"
        notify: true
        require_fix: true
      critical:
        action: "warn"
        notify: true
      major:
        action: "warn"
      minor:
        action: "pass"
    
    # Scoring
    scoring:
      weights:
        quality: 0.3
        security: 0.4
        performance: 0.2
        maintainability: 0.1
      min_passing_score: 7.0
    
    # AI configuration
    ai:
      enabled: true
      model: "gpt-4"
      temperature: 0.2
      max_context: 8000
      include_fix_suggestions: true
```

---

## Integration

### With Quality Gates

```yaml
qa_gates:
  gates:
    implementing:
      checks: [code_review]
      code_review:
        focus: ["security", "quality"]
        max_blockers: 0
    
    verifying:
      checks: [code_review]
      code_review:
        focus: ["all"]
        min_score: 8.0
```

### With VCS

```yaml
# Review on commit
on: vcs.commit_created
  - REVIEW.analyze({
      since_commit: event.payload.parent_commit
    })
  
  - if: review.has_blockers
    then:
      - VCS.rollback()
      - error: "Commit blocked by code review"
```

### With Events

```yaml
# Emit review events
on: review.completed
  - EVENT.emit("code_review.completed", {
      task_id: task.id,
      score: review.score,
      issues: review.summary
    })

on: review.issues_found
  if: review.has_blockers
  - EVENT.emit("code_review.blockers_found", {
      task_id: task.id,
      issues: review.blockers
    })
```

---

## Benefits

1. **Early Detection** - Catch issues during implementation
2. **Comprehensive** - Multiple categories of analysis
3. **Consistent** - Same standards every time
4. **Educational** - Learn from feedback
5. **Automated** - No manual review needed

---

## Future Enhancements

- **Learning from Fixes** - Adapt to project patterns
- **Custom Rules** - Project-specific checks
- **Team Standards** - Enforce team conventions
- **Historical Analysis** - Track quality over time
- **Comparative Review** - Compare with similar code

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
- [Smart Context](../smart-context/)

---

**Status:** Planned  
**Priority:** High (code quality is critical)  
**Complexity:** High (AI analysis, pattern detection, security checks)

