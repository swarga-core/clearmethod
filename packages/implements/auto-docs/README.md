# Auto-Docs Package

**Automatic documentation generation integrated with ClearMethod workflows.**

> Status: **Planned** (Concept only, no implementation yet)

---

## Problem

Documentation is often:
- ❌ Out of sync with code
- ❌ Written after the fact (or not at all)
- ❌ Incomplete or inconsistent
- ❌ Manual work that gets skipped
- ❌ Becomes stale quickly

---

## Solution

**Auto-Docs** generates documentation automatically as part of the workflow:
- ✅ Generated during implementation (not after)
- ✅ Always up-to-date with code
- ✅ Comprehensive coverage
- ✅ Multiple formats (API, guides, diagrams)
- ✅ Integrated with quality gates

---

## Key Features

### 1. Stage-Triggered Generation

```yaml
# After implementing stage
on: task.stage_completed
  if: stage == "implementing"
  then:
    - DOCS.generate("api")         # Generate API docs
    - DOCS.generate("examples")    # Create usage examples
    - DOCS.update("readme")        # Update README
```

### 2. API Documentation

```typescript
// From code
export function authenticateUser(
  username: string,
  password: string
): Promise<AuthResult>

// Auto-generated markdown
## authenticateUser

Authenticates a user with username and password.

**Parameters:**
- `username` (string) - User's username
- `password` (string) - User's password

**Returns:** `Promise<AuthResult>`

**Example:**
\`\`\`typescript
const result = await authenticateUser("john", "secret123");
if (result.success) {
  console.log("Authenticated!");
}
\`\`\`
```

### 3. Architecture Diagrams

```yaml
- DOCS.generate("architecture")

# Creates Mermaid diagram:
graph TD
  A[User] --> B[API Gateway]
  B --> C[Auth Service]
  B --> D[Data Service]
  C --> E[(Database)]
  D --> E
```

### 4. Documentation Coverage

```yaml
- DOCS.get_coverage()
  into: coverage

# Returns:
#   api_coverage: 85%
#   functions_documented: 42/50
#   examples_present: 38/50
#   status: "passing"  # > 80%
```

### 5. Changelog Management

```yaml
on: workflow.completed
  - DOCS.update("changelog", {
      version: "1.2.0",
      type: "feature",
      description: task.title,
      changes: task.changes
    })

# Appends to CHANGELOG.md:
## [1.2.0] - 2025-11-25
### Added
- User authentication with JWT tokens
### Changed
- Updated password hashing algorithm
```

---

## Use Cases

### UC-1: API Documentation During Implementation

```yaml
# Agent implements new API endpoint
- implement: POST /api/users
- add: authentication
- add: validation

# Auto-Docs:
- DOCS.generate("api", {
    path: "src/api/users.ts",
    format: "openapi"
  })

# Generates OpenAPI spec:
paths:
  /api/users:
    post:
      summary: Create new user
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                username: {type: string}
                email: {type: string}
      responses:
        201:
          description: User created successfully
```

### UC-2: README Auto-Update

```yaml
# Project structure changes
- add: new feature module
- update: dependencies

# Auto-Docs:
- DOCS.update("readme", {
    sections: ["installation", "features"]
  })

# README.md updated:
## Features
- ✅ User Authentication
- ✅ Data Persistence
- ✅ Real-time Updates (NEW!)
```

### UC-3: Documentation Quality Gate

```yaml
# Before completing workflow
- QA_GATE.check("documentation")

# Checks:
#   ✅ All public APIs documented
#   ✅ README up-to-date
#   ✅ Examples provided
#   ❌ Architecture diagram missing
#
# Result: FAILED
# Action: Generate missing diagram
```

---

## API (Planned)

### DOCS.generate(type, options?)

Generate documentation of specified type.

**Types:**
- `api` - API documentation
- `architecture` - Architecture diagrams
- `examples` - Usage examples
- `readme` - README file
- `changelog` - Changelog entry

**Returns:**
```yaml
{
  generated_files: [string],
  coverage: number,
  warnings: [string]
}
```

### DOCS.update(document, content?)

Update existing documentation.

### DOCS.validate(requirements?)

Validate documentation completeness.

**Returns:**
```yaml
{
  valid: boolean,
  coverage: number,
  missing: [string],
  issues: [string]
}
```

### DOCS.get_coverage()

Get documentation coverage metrics.

**Returns:**
```yaml
{
  overall: number,
  by_type: {
    api: number,
    functions: number,
    classes: number
  },
  missing: [string],
  status: "passing" | "failing"
}
```

---

## Documentation Types

### 1. API Documentation

**Input:** Source code + JSDoc/docstrings  
**Output:** Markdown, HTML, or OpenAPI spec

**Features:**
- Function signatures
- Parameter descriptions
- Return types
- Usage examples
- Error handling

### 2. Architecture Documentation

**Input:** Code structure + dependencies  
**Output:** Mermaid diagrams + descriptions

**Diagrams:**
- Component architecture
- Data flow
- Sequence diagrams
- Dependency graphs

### 3. README Files

**Input:** Project metadata + code analysis  
**Output:** Comprehensive README.md

**Sections:**
- Project overview
- Installation
- Quick start
- Features
- API reference
- Contributing
- License

### 4. Usage Examples

**Input:** Code + test cases  
**Output:** Runnable examples

**Types:**
- Quick start examples
- Common use cases
- Advanced scenarios
- Integration examples

### 5. Changelog

**Input:** Git history + task data  
**Output:** CHANGELOG.md (Keep a Changelog format)

**Tracks:**
- Added features
- Changed functionality
- Deprecated APIs
- Bug fixes
- Breaking changes

---

## Configuration

```yaml
packages:
  auto_docs:
    enabled: true
    
    # Output locations
    output:
      api_docs: "docs/api"
      guides: "docs/guides"
      readme: "README.md"
      changelog: "CHANGELOG.md"
    
    # Auto-generation
    auto_generate:
      enabled: true
      on_stages:
        - implementing
        - completing
      on_workflow_complete: true
    
    # Documentation types
    types:
      api:
        enabled: true
        format: "markdown"
        include_examples: true
        include_types: true
        parse_jsdoc: true
      
      architecture:
        enabled: true
        diagrams: true
        diagram_format: "mermaid"
        auto_detect_components: true
      
      readme:
        enabled: true
        auto_update: true
        template: "docs/templates/README.tpl"
        sections:
          - overview
          - installation
          - quick_start
          - features
          - api_reference
          - examples
          - contributing
          - license
      
      examples:
        enabled: true
        extract_from_tests: true
        validate_runnable: true
      
      changelog:
        enabled: true
        format: "keep-a-changelog"
        auto_update_on_complete: true
        group_by: "type"  # type, scope, file
    
    # Coverage requirements
    coverage:
      min_api_coverage: 80
      min_example_coverage: 50
      warn_on_low_coverage: true
      fail_qa_gate: false
    
    # Integration
    commit_docs:
      enabled: true
      auto_commit: true
      message_template: "docs: update documentation for {task_id}"
```

---

## Integration Points

### With Workflows (SBD)

```yaml
# SBD Feature Workflow integration

implementing:
  postconditions:
    - DOCS.validate({min_coverage: 60})

completing:
  execute:
    - DOCS.generate("api")
    - DOCS.generate("examples")
    - DOCS.update("readme")
    - DOCS.update("changelog")
  postconditions:
    - DOCS.get_coverage() >= 80
```

### With Quality Gates

```yaml
qa_gates:
  gates:
    completing:
      checks:
        - documentation
      
      documentation:
        enabled: true
        min_api_coverage: 80
        require_examples: true
        require_readme: true
        require_changelog: true
```

### With VCS

```yaml
# Auto-commit documentation
on: docs.generated
  if: config.auto_commit
  then:
    - VCS.commit({
        files: event.payload.files,
        message: "docs: {event.payload.type}"
      })
```

---

## Technical Approach

### API Documentation

1. **Parse**: Analyze source code (AST)
2. **Extract**: Get JSDoc/docstrings
3. **Generate**: Create markdown/HTML
4. **Validate**: Check completeness

### Architecture Diagrams

1. **Analyze**: Scan imports and dependencies
2. **Build Graph**: Create dependency graph
3. **Simplify**: Group related components
4. **Render**: Generate Mermaid/PlantUML

### Example Generation

1. **Extract**: Find test cases
2. **Simplify**: Remove test boilerplate
3. **Annotate**: Add comments
4. **Validate**: Ensure runnable

---

## Benefits

1. **Always Up-to-Date** - Generated with code
2. **Comprehensive** - Coverage metrics ensure completeness
3. **Automatic** - No manual documentation work
4. **Consistent** - Standard format across project
5. **Quality Gate** - Enforces documentation standards

---

## Future Enhancements

- **AI-Generated Descriptions** - Use LLM for better descriptions
- **Interactive Docs** - Live code playground
- **Multilingual** - Generate docs in multiple languages
- **Video Tutorials** - Auto-generate from code walkthroughs
- **Versioned Docs** - Per-version documentation

---

## Dependencies

- `core-concept` - TASK, WORKFLOW, EVENT abstractions
- `file-task` - For task access
- `basic-events` - For event handling

---

## See Also

- [Quality Gates](../qa-gates/)
- [SBD Workflows](../sbd/)
- [Git VCS](../git-vcs/)

---

**Status:** Planned  
**Priority:** Medium (quality of life improvement)  
**Complexity:** Medium (parsing, generation, templates)

