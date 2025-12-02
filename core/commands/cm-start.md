# /cm-start

Create task and start workflow.

**Usage**: `/cm-start [workflow-id] [task-id] [title]`

---

## Execute

### 1. Collect parameters (request if missing)
```
// All parameters are requestable
workflow_id = arg1 OR ask_user("Which workflow? (e.g. sbd.feature)")
task_id = arg2 OR ask_user("Task ID? (e.g. TASK-123)")
title = arg3+ OR ask_user("Task title?")
```

### 2. Validate
```
CHECK: workflow exists in .cm/packages/*/workflows/
IF NOT: ERROR "Workflow {workflow_id} not found"

CHECK: task_id matches pattern "^[A-Z]+-[0-9]+$"
IF NOT: ERROR "Invalid task-id format. Use: TASK-123"

CHECK: NOT exists(.cm/tasks/{task_id}/)
IF EXISTS: ERROR "Task {task_id} already exists"
```

### 3. Get user name
```
user_name = READ .cm.conf → user.name
// If .cm.conf not exists or user.name not set: use "user" as default
```

### 4. Create task
```
FILE_TASK.create(
  task_id,
  title,
  "",           // content empty initially
  user_name,
  workflow_id
)

LOG: "Task {task_id} created"
```

### 5. Start workflow
```
WORKFLOW.start(task_id)
// This will:
// - Set task status to start_state
// - Execute start_state file
```

### 6. Execute first state
```
READ: workflow.yml → find start_state
READ: states/{start_state}.yml
EXECUTE: state instructions

// Example: for sbd.feature start_state = "creating"
// Agent will begin dialog about requirements
```

---

## Critical

- **Request missing params** - ask user for any missing parameter
- **Validate before creating** - check everything first
- **Once all params collected** - proceed immediately
- **Create then start** - task must exist before workflow starts
- **Execute state immediately** - don't stop after creation
- **Log everything** - use FILE_TASK.log()

---

## After execution

Task folder structure:
```
.cm/tasks/{task_id}/
  status.yml    (created, status = start_state)
  specs.md      (empty, filled during workflow)
  log.md        (initial entry)
```

Agent is now **inside first state**, executing its instructions.

