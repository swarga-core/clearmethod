# CML Primer

> **ClearMethod Language** - YAML-based DSL for agent instructions

---

## Core constructs

### Variables
```yaml
- let: variable_name = "value"
- let: count = 5
- let: result = CONCEPT.method()
```

### Actions
```yaml
# Natural language instruction
- "Create folder structure"

# Method call
- TASK.create(task_id, title, "", user_name, workflow_id)

# Multiple actions
- "First action"
- "Second action"
- TASK.log(task_id, "Done")
```

**Note**: Simple instructions don't need `do:`. Use `do:` only in loops.

### Conditionals
```yaml
- if: condition
  then:
    - "action if true"
    - "another action"
  else:
    - "action if false"

# Without else
- if: exists(.cm/)
  then:
    - "proceed"
    - TASK.log(task_id, "Setup verified")
```

**Operators**:
```yaml
# Comparison
- if: x == 5
- if: name != "admin"
- if: count > 10
- if: count >= 5
- if: count < 100
- if: count <= 50

# Logical
- if: x > 5 and y < 10
- if: status == "active" or status == "pending"
- if: not finished

# Empty checks
- if: name is empty
- if: list is not empty
- if: value is null

# Existence
- if: exists(path/to/file)
- if: not exists(.cm/)
```

### Loops

**For - iterate over collection**:
```yaml
- for: item in collection
  do:
    - "Process {item}"
```

**While - iterate by condition**:
```yaml
# Basic while
- while: condition
  do:
    - "action"

# With max iterations (safety)
- while: not finished
  max_iterations: 50
  do:
    - "process"

# Example: step-by-step execution
- let: current_step = 1
- let: total_steps = 5

- while: current_step <= total_steps
  do:
    - "Execute step {current_step}"
    - ask: "Continue to next step?"
      into: continue
    - if: continue == "no"
      then:
        - return
    - let: current_step = current_step + 1
```

**Safety**: If `max_iterations` not specified, default is 100. On exceed: warning + stop.

### Return
```yaml
- return: value
```

---

## String interpolation

Variables can be interpolated using `{variable}` syntax.

**Where it works**:
```yaml
# In strings
- info: "Hello, {name}!"
- "Task {task_id} created by {user}"

# In file paths
- read: .cm/tasks/{task_id}/status.yml
  into: status
- read: .cm/extensions/{extension_name}/primer.md

# In method calls
- TASK.create("{task_id}", "{title}", "", "{user}", "{workflow}")

# Multiple variables
- info: "Task {task_id}: {status} ({progress}%)"

# Nested properties
- info: "Project: {config.project.name}"
```

**Rules**:
- Variables replaced with their string values
- Undefined variables → empty string (no error)
- Works in all string contexts

---

## Collections & arrays

**Accessing array elements**:
```yaml
# Parse YAML with arrays
- read: config.yml
  as: yaml
  into: config

# Access by index (0-based)
- let: first = config.items[0]
- let: second = config.items[1]

# Access nested properties
- let: name = config.primers[0].path
```

**Iterating arrays**:
```yaml
# From parsed YAML
- read: priming.yml
  as: yaml
  into: priming_config

- for: primer in priming_config.primers.core
  do:
    - info: "Loading: {primer.path}"
    - read: "{primer.path}"

# Nested iteration
- for: category in config.categories
  do:
    - for: item in category.items
      do:
        - "Process {item}"
```

**Array operations**:
```yaml
# Count elements
- let: count = length(config.items)

# Check if empty
- if: config.items is empty
  then:
    - error: "No items found"
```

---

## File operations

### Read file
```yaml
# Read as text
- read: path/to/file.md
  into: content

# Read and parse YAML
- read: .cm/project.yml
  as: yaml
  into: config

# Read and parse JSON
- read: data.json
  as: json
  into: data
```

**Note**: `as: yaml|json` automatically parses, no separate parse step needed.

---

## User interaction

### Ask question
```yaml
# Simple question
- ask: "What is your name?"
  into: user_name

# With default value
- ask: "Task title?"
  into: title
  default: "Untitled"
```

**Used for**: collecting missing parameters, clarifications, confirmations.

---

## Validation

### Validate condition
```yaml
# Check file exists
- validate: exists(.cm/)
  error: "ClearMethod not set up"

# Check format
- validate: task_id matches "^[A-Z]+-[0-9]+$"
  error: "Invalid task-id format. Use: TASK-123"

# Check value
- validate: workflow_id is not empty
  error: "Workflow ID required"
```

**On failure**: stops execution, shows error to user.

---

## Messages

```yaml
# Error - stop execution
- error: "Critical error occurred"

# Warning - continue execution
- warn: "Something might be wrong"

# Info - message to user
- info: "Operation completed successfully"

# Log - to task log (via TASK.log)
- TASK.log(task_id, "Action performed")
```

---

## Built-in functions

**File system**:
- `exists(path)` - check if file/folder exists
- `read(path)` - read file content (use with `read:` instruction)

**String operations**:
- `{variable}` - string interpolation (automatic)
- `matches(string, pattern)` - regex match for validation

**Collections**:
- `length(array)` - count elements in array
- `array[index]` - access element by index (0-based)

**Type checks**:
- `is empty` - check if string/array is empty
- `is not empty` - check if has content
- `is null` - check if variable is null/undefined

**Comparison**:
- `==`, `!=` - equality
- `>`, `>=`, `<`, `<=` - numeric comparison

**Logical**:
- `and`, `or`, `not` - boolean logic

---

## Execution model

1. **Sequential** - instructions execute top to bottom
2. **Blocking** - each completes before next starts
3. **Interpolation** - `{variable}` replaced with actual value everywhere
4. **Simple instructions** - no `do:` prefix needed (just write instruction)
5. **Loops use `do:`** - `for` and `while` require `do:` block
6. **Method calls** - `CONCEPT.method()` invokes concept method
7. **Error stops** - `error:` stops execution immediately
8. **Validate stops** - failed validation stops execution
9. **Loop safety** - `while` has max_iterations limit (default 100) to prevent infinite loops
10. **Undefined variables** - treated as empty string (no error)

---

## Example: Simple command

```yaml
command: cm-hello
description: "Greet user"

execute:
  - ask: "What is your name?"
    into: name
  
  - if: name is empty
    then:
      - let: name = "friend"
  
  - info: "Hello, {name}!"
```

---

## Example: Command with validation

```yaml
command: cm-start
description: "Start task"

execute:
  # Validate setup
  - validate: exists(.cm/)
    error: "ClearMethod not set up"
  
  # Read config
  - read: .cm/project.yml
    as: yaml
    into: config
  
  # Collect params
  - ask: "Workflow ID?"
    into: workflow_id
    default: "{config.defaults.workflow}"
  
  - ask: "Task ID?"
    into: task_id
  
  # Validate format
  - validate: task_id matches "^[A-Z]+-[0-9]+$"
    error: "Invalid task-id format"
  
  # Create task
  - TASK.create(task_id, title, "", user, workflow_id)
  - info: "Task {task_id} created"
```

---

## Example: Step-by-step implementation with while

```yaml
state: implementing
description: "Execute implementation plan step by step"

execute:
  # Read design
  - read: .cm/tasks/{task_id}/design.md
    into: design
  
  # Extract steps count
  - "Count implementation steps in design"
  - let: total_steps = steps_count
  - let: current_step = 1
  
  # Execute steps one by one
  - while: current_step <= total_steps
    max_iterations: 20
    do:
      - info: "Step {current_step} of {total_steps}"
      - "Read and implement step {current_step} from design"
      - TASK.log(task_id, "Completed step {current_step}")
      
      # Ask confirmation
      - ask: "Step {current_step} done. Continue to next?"
        into: continue
        default: "yes"
      
      - if: continue == "no"
        then:
          - info: "Implementation paused at step {current_step}"
          - return
      
      - let: current_step = current_step + 1
  
  - info: "All {total_steps} steps completed!"
  - TASK.set_property(task_id, "implementation_complete", true)
```

---

## Summary

**CML syntax rules**:
- Simple instructions: just write them (no `do:`)
- Loops (`for`, `while`): use `do:` block
- Conditionals (`if/then/else`): list instructions under `then:`/`else:`
- String interpolation: `{variable}` works everywhere
- Method calls: `CONCEPT.method()`
- Arrays: access with `array[index]`, iterate with `for`
- Operators: `==`, `!=`, `>`, `<`, `and`, `or`, `not`

**As agent, you interpret CML instructions sequentially. Handle errors gracefully.**
