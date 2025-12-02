# File-Task Package

Simple file-based task storage for ClearMethod.

## Overview

`file-task` provides a straightforward implementation of the `TASK` concept using the filesystem. Each task is stored as a directory containing YAML configuration and Markdown artifacts.

**Key Features:**
- ✅ Simple directory-based storage
- ✅ Human-readable YAML and Markdown files
- ✅ Easy to debug and inspect
- ✅ Git-friendly (text files)
- ✅ No database required
- ✅ Implements full TASK interface

**Philosophy:** Simplicity over complexity. Files you can open, read, and edit manually if needed.

---

## Installation

The `file-task` package is included in ClearMethod core setup.

**Manual installation:**
```bash
# Copy package to project
cp -r packages/file-task .cm/packages/

# Update project.yml
```

```yaml
# .cm/project.yml
concept_implementations:
  TASK: file-task.FILE_TASK
```

---

## Task Structure

Each task is stored as a directory with multiple files:

```
.cm/tasks/
  TASK-123/
    status.yml    # Task properties and metadata
    specs.md      # Task specification
    log.md        # Action log
    design.md     # Created during workflow
    code.md       # Created during workflow
    ...           # Other artifacts
```

### status.yml Format

```yaml
id: TASK-123
title: "Add user notifications"
workflow: sbd.feature
status: designing
created_at: "2025-11-25T10:00:00Z"
created_by: "john.doe"
last_updated_at: "2025-11-25T12:30:00Z"
last_updater: "ai-agent"

# Custom properties (set by workflow)
properties:
  specs_ready: true
  design_approved: false
  priority: high
  estimated_hours: 8
```

**Key fields:**
- `id` - Unique task identifier (TASK-XXX format)
- `title` - Short task description
- `workflow` - Workflow ID (e.g., "sbd.feature")
- `status` - Current workflow state
- `created_at` / `created_by` - Creation metadata
- `last_updated_at` / `last_updater` - Last modification
- `properties` - Custom key-value pairs

### log.md Format

```markdown
[2025-11-25T10:00:00Z] Task created by john.doe
[2025-11-25T10:15:00Z] Moved to analyzing state
[2025-11-25T11:00:00Z] Specs approved
[2025-11-25T12:30:00Z] Design phase started
```

---

## API Methods

`FILE_TASK` implements all methods from the `TASK` interface:

### create()

Creates a new task with initial files.

```yaml
TASK.create(task_id, title, content, creator, workflow)
```

**Parameters:**
- `task_id` (string) - Task ID (e.g., "TASK-123")
- `title` (string) - Task title
- `content` (string) - Task specification content
- `creator` (string) - Who created the task
- `workflow` (string) - Workflow ID (e.g., "sbd.feature")

**Creates:**
- `.cm/tasks/{task_id}/` directory
- `status.yml` with initial properties
- `specs.md` with content
- `log.md` with creation entry

**Example:**
```yaml
- TASK.create(
    "FEAT-001",
    "Add user authentication",
    "As a user, I want to log in...",
    "john.doe",
    "sbd.feature"
  )
```

---

### get_state()

Returns current workflow state.

```yaml
TASK.get_state(task_id) → string
```

**Example:**
```yaml
- let: current_state = TASK.get_state("FEAT-001")
- info: "Task is in {current_state} state"
```

---

### set_state()

Updates workflow state.

```yaml
TASK.set_state(task_id, new_state)
```

**Example:**
```yaml
- TASK.set_state("FEAT-001", "designing")
- TASK.log("FEAT-001", "Moved to designing state")
```

---

### get_property()

Reads a custom property value.

```yaml
TASK.get_property(task_id, property_name) → value
```

**Example:**
```yaml
- let: priority = TASK.get_property("FEAT-001", "priority")
- if: priority == "high"
  then:
    - info: "High priority task!"
```

---

### set_property()

Sets or updates a custom property.

```yaml
TASK.set_property(task_id, property_name, value)
```

**Example:**
```yaml
- TASK.set_property("FEAT-001", "specs_ready", true)
- TASK.set_property("FEAT-001", "estimated_hours", 8)
```

**Note:** Automatically updates `last_updated_at` timestamp.

---

### log()

Appends an entry to the task log.

```yaml
TASK.log(task_id, message)
```

**Example:**
```yaml
- TASK.log("FEAT-001", "Design review completed")
- TASK.log("FEAT-001", "Found 3 edge cases to handle")
```

**Format:** `[timestamp] message`

---

### get_log()

Retrieves entire task log.

```yaml
TASK.get_log(task_id) → string
```

**Example:**
```yaml
- let: log_content = TASK.get_log("FEAT-001")
- info: "Task history:\n{log_content}"
```

---

## Usage Examples

### Example 1: Create and Start Task

```yaml
# Command: /cm-start
instructions:
  - let: task_id = "FEAT-001"
  - let: title = "Add user authentication"
  - let: workflow = "sbd.feature"
  
  # Create task
  - TASK.create(task_id, title, specs_content, user_name, workflow)
  
  # Emit event (other packages can react)
  - EVENT.emit("task.created", {
      task_id: task_id,
      workflow: workflow,
      title: title
    })
  
  # Set initial state
  - TASK.set_state(task_id, "creating")
  
  - info: "Task {task_id} created and ready!"
```

---

### Example 2: Workflow State Tracking

```yaml
# states/designing.yml
instructions:
  # Check prerequisites
  - let: specs_ready = TASK.get_property(task_id, "specs_ready")
  - if: !specs_ready
    then:
      - error: "Cannot start design without specs"
  
  # Update state
  - TASK.set_state(task_id, "designing")
  - TASK.log(task_id, "Started design phase")
  
  # ... design work ...
  
  # Mark complete
  - TASK.set_property(task_id, "design_complete", true)
  - TASK.log(task_id, "Design phase completed")
```

---

### Example 3: Progress Tracking

```yaml
# Track implementation progress
instructions:
  - TASK.set_property(task_id, "files_changed", 12)
  - TASK.set_property(task_id, "tests_written", 8)
  - TASK.set_property(task_id, "coverage_percent", 85)
  
  - let: tests = TASK.get_property(task_id, "tests_written")
  - TASK.log(task_id, "Wrote {tests} unit tests")
```

---

### Example 4: Conditional Logic Based on Properties

```yaml
instructions:
  - let: complexity = TASK.get_property(task_id, "complexity")
  
  - if: complexity == "high"
    then:
      - info: "High complexity task - requiring design review"
      - TASK.set_property(task_id, "design_review_required", true)
    else:
      - info: "Standard complexity - can proceed directly"
      - TASK.set_property(task_id, "design_review_required", false)
```

---

## Best Practices

### ✅ DO

**Use descriptive property names**
```yaml
# Good
- TASK.set_property(task_id, "api_design_approved", true)
- TASK.set_property(task_id, "database_schema_ready", true)

# Bad
- TASK.set_property(task_id, "flag1", true)
- TASK.set_property(task_id, "x", true)
```

**Log significant actions**
```yaml
# Good - context and details
- TASK.log(task_id, "Design review completed by Sarah. Approved with minor comments.")

# Bad - too vague
- TASK.log(task_id, "Done")
```

**Check property existence**
```yaml
# Good
- let: priority = TASK.get_property(task_id, "priority")
- if: priority
  then:
    - info: "Priority: {priority}"
  else:
    - warn: "Priority not set, defaulting to medium"
    - TASK.set_property(task_id, "priority", "medium")
```

**Update properties atomically**
```yaml
# Good - one update per logical change
- TASK.set_property(task_id, "stage_complete", true)
- TASK.log(task_id, "Stage completed")

# Bad - fragmented updates
- TASK.set_property(task_id, "stage", "done")
- TASK.set_property(task_id, "complete", true)
```

---

### ❌ DON'T

**Don't store large data in properties**
```yaml
# Bad - properties are for metadata
- TASK.set_property(task_id, "entire_design_document", huge_text)

# Good - store in file
- write: ".cm/tasks/{task_id}/design.md"
  content: design_document
- TASK.set_property(task_id, "design_document_ready", true)
```

**Don't use properties for temporary state**
```yaml
# Bad - temporary loop counter
- TASK.set_property(task_id, "loop_counter", 0)
- for: item in items
  do:
    - let: counter = TASK.get_property(task_id, "loop_counter")
    - TASK.set_property(task_id, "loop_counter", counter + 1)

# Good - use local variables
- let: counter = 0
- for: item in items
  do:
    - let: counter = counter + 1
```

**Don't skip logging important events**
```yaml
# Bad - no audit trail
- TASK.set_state(task_id, "implementing")

# Good - log state transitions
- TASK.set_state(task_id, "implementing")
- TASK.log(task_id, "Transitioned to implementing state")
```

---

## Configuration

### Default Settings

```yaml
# packages/file-task/concept.yml
config:
  tasks_root: ".cm/tasks"      # Where tasks are stored
  status_file: "status.yml"    # Status filename
  log_file: "log.md"           # Log filename
```

### Project Override

```yaml
# .cm/project.yml
packages:
  file-task:
    tasks_root: ".clearmethod/tasks"  # Custom location
    status_file: "task.yml"           # Custom filename
```

---

## File System Layout

### Typical Project Structure

```
project/
├── .cm/
│   ├── tasks/
│   │   ├── FEAT-001/
│   │   │   ├── status.yml
│   │   │   ├── specs.md
│   │   │   ├── design.md
│   │   │   └── log.md
│   │   ├── FEAT-002/
│   │   │   └── ...
│   │   └── BUG-001/
│   │       └── ...
│   ├── project.yml
│   └── priming.yml
├── src/
└── ...
```

### Task Directory Permissions

- **Read**: Anyone can read task files
- **Write**: Only ClearMethod agent should modify
- **Manual edits**: Possible but discouraged (breaks automation)

---

## Troubleshooting

### Task Not Found Error

**Symptom:**
```
ERROR: Task FEAT-001 not found
```

**Solution:**
```bash
# Check if task directory exists
ls -la .cm/tasks/FEAT-001

# Check status.yml exists
cat .cm/tasks/FEAT-001/status.yml
```

**Common causes:**
- Task ID typo
- Task not created yet
- Wrong tasks_root configured

---

### Property Not Set

**Symptom:**
```yaml
- let: value = TASK.get_property(task_id, "missing_prop")
# Returns null or empty
```

**Solution:**
```yaml
# Always check if property exists
- let: value = TASK.get_property(task_id, "prop")
- if: !value
  then:
    - warn: "Property 'prop' not set, using default"
    - let: value = "default_value"
```

---

### Status.yml Corrupted

**Symptom:**
```
ERROR: Failed to parse status.yml: Invalid YAML
```

**Solution:**
```bash
# Validate YAML syntax
cat .cm/tasks/FEAT-001/status.yml | yaml-validator

# Fix manually or restore from git
git checkout .cm/tasks/FEAT-001/status.yml
```

**Prevention:**
- Always use TASK methods (don't edit manually)
- Keep git history of .cm/tasks/

---

### Last Updated Not Updating

**Symptom:** `last_updated_at` timestamp doesn't change

**Cause:** Using file operations instead of TASK methods

**Solution:**
```yaml
# Bad - bypasses TASK logic
- write: ".cm/tasks/{task_id}/status.yml"
  content: ...

# Good - uses TASK methods
- TASK.set_property(task_id, "key", "value")
```

---

## Performance Considerations

### File System Operations

- **Read operations**: Fast (YAML parsing ~1-5ms)
- **Write operations**: Fast (file write ~5-10ms)
- **Concurrent access**: No locking (single agent assumption)

### Scalability

| Tasks | Performance | Notes |
|-------|-------------|-------|
| 1-100 | Excellent | No issues |
| 100-1000 | Good | Slight directory traversal delay |
| 1000+ | Acceptable | Consider cleanup of old tasks |

**Optimization tips:**
- Archive completed tasks periodically
- Use task ID prefixes for organization (FEAT-, BUG-, etc.)
- Keep task directories clean (remove temp files)

---

## Comparison with Alternatives

| Feature | FILE_TASK | HELLO_TASK | Database-based |
|---------|-----------|------------|----------------|
| **Storage** | Directory per task | Single YAML file | Database table |
| **Artifacts** | ✅ Separate files | ❌ All in one file | ❌ BLOBs |
| **Human-readable** | ✅ Yes | ✅ Yes | ❌ Binary |
| **Git-friendly** | ✅ Yes | ✅ Yes | ❌ No |
| **Query performance** | ⚠️ O(n) scan | ⚠️ O(n) scan | ✅ O(1) index |
| **Complexity** | Low | Very low | High |
| **Best for** | Production | Testing | Large scale |

---

## Migration

### From HELLO_TASK to FILE_TASK

```bash
# Convert single-file tasks to directory structure
for task in .cm/tasks/*.yml; do
  task_id=$(basename "$task" .yml)
  mkdir -p ".cm/tasks/$task_id"
  mv "$task" ".cm/tasks/$task_id/status.yml"
  touch ".cm/tasks/$task_id/specs.md"
  touch ".cm/tasks/$task_id/log.md"
done
```

### From FILE_TASK to Database

```python
# Example migration script (pseudocode)
for task_dir in glob(".cm/tasks/*"):
    task_id = os.path.basename(task_dir)
    status = yaml.load(open(f"{task_dir}/status.yml"))
    specs = open(f"{task_dir}/specs.md").read()
    log = open(f"{task_dir}/log.md").read()
    
    db.insert_task(
        id=task_id,
        status=status,
        specs=specs,
        log=log
    )
```

---

## Contributing

To improve `file-task`:

1. **Add new methods** - Update `concept.yml` and create method implementation
2. **Improve error handling** - Add validation and helpful error messages
3. **Optimize performance** - Cache status.yml reads
4. **Add features** - Task archiving, search, bulk operations

See `CONTRIBUTING.md` in main repo.

---

## License

MIT License - Part of ClearMethod framework.

---

## See Also

- [TASK Concept Documentation](../../docs/core/concepts/core.md#2-task)
- [CML Language Spec](../../docs/core/cml/spec.md)
- [Hello-World Package](../hello-world/) - Simpler alternative
- [SBD Package](../sbd/) - Workflows using FILE_TASK

