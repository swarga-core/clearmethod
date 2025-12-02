# File-Kanban Package

File-based implementation of **KANBAN** concept for ClearMethod.

Visualizes workflow progress through markdown kanban board with configurable column-to-state mapping.

---

## Features

✅ **Markdown Board Generation** - Human-readable, git-friendly output  
✅ **Auto-update on Events** - Board syncs automatically with task changes  
✅ **Configurable Columns** - Each project defines its own structure  
✅ **State-based Mapping** - Columns map to workflow states  
✅ **Manual Task Movement** - Move tasks between columns explicitly  
✅ **Column Management** - Add/remove columns dynamically  

---

## Quick Start

### 1. Enable in Configuration

Add to `.cm/project.yml`:

```yaml
concept_implementations:
  KANBAN: file-kanban.FILE_KANBAN

packages:
  file_kanban:
    enabled: true
    output_file: ".cm/kanban/board.md"
    auto_update: true
    
    columns:
      - name: "📋 Backlog"
        states: [creating]
        color: "grey"
      
      - name: "🔄 In Progress"
        states: [analyzing, designing, implementing]
        color: "blue"
      
      - name: "🔍 Review"
        states: [verifying]
        color: "yellow"
      
      - name: "✅ Done"
        states: [completing]
        color: "green"
    
    show_properties:
      - priority
      - assignee
```

### 2. Update Board

```yaml
instructions:
  - KANBAN.update_board(true)
    into: board_state
  
  - info: "Board has {board_state.total_tasks} task(s)"
```

### 3. Check the Result

View generated board at `.cm/kanban/board.md`:

```markdown
# Kanban Board

> Last updated: 2025-11-25T...

**Total tasks:** 5

---

## 📋 Backlog (2)

- **[TASK-001]** Add user authentication
  - State: `creating`

- **[TASK-002]** Implement caching
  - State: `creating`

---

## 🔄 In Progress (1)

- **[TASK-003]** Fix login bug
  - State: `implementing`
  - priority: high

---
```

---

## API

### update_board(force?)

Regenerate board from current task states.

```yaml
- KANBAN.update_board(true)
  into: result
# → {columns: [...], total_tasks: 5, last_updated: "..."}
```

**Parameters:**
- `force` (boolean, optional) - Force regeneration even if no changes

---

### move_task(task_id, to_column, update_state?)

Move task to different column.

```yaml
- KANBAN.move_task("TASK-001", "🔄 In Progress", true)
  into: result
# → {task_id, from_column, to_column, state_updated: true}
```

**Parameters:**
- `task_id` (string) - Task ID to move
- `to_column` (string) - Target column name
- `update_state` (boolean, optional) - Also update workflow state to match column

---

### get_board_state()

Get current board state (from cache).

```yaml
- KANBAN.get_board_state()
  into: board
# → {columns: [...], config: {...}, last_updated: "..."}
```

---

### get_column_tasks(column_name)

Get all tasks in specific column.

```yaml
- KANBAN.get_column_tasks("🔄 In Progress")
  into: tasks
# → [{id: "TASK-001", title: "...", state: "implementing", properties: {...}}]
```

---

### add_column(column_name, states[], position?)

Add new column to board.

```yaml
- KANBAN.add_column("⚠️ Blocked", ["blocked"], 2)
  into: col
# → {column_name: "⚠️ Blocked", states: ["blocked"], position: 2}
```

**Updates `.cm/project.yml` and regenerates board.**

---

### remove_column(column_name, move_tasks_to?)

Remove column from board.

```yaml
- KANBAN.remove_column("⚠️ Blocked", "📋 Backlog")
  into: success
# → true
```

**Parameters:**
- `column_name` (string) - Column to remove
- `move_tasks_to` (string, optional) - Move tasks to this column before removal

---

### generate_markdown(include_properties?)

Generate markdown representation.

```yaml
- KANBAN.generate_markdown(["priority", "assignee"])
  into: markdown
# → "# Kanban Board\n\n..."
```

---

## Event Integration

### Events Emitted

**kanban.board_updated**
```yaml
payload:
  total_tasks: 5
  columns: [{name: "...", count: 2}, ...]
  timestamp: "2025-11-25T..."
```

**kanban.task_moved**
```yaml
payload:
  task_id: "TASK-001"
  from_column: "📋 Backlog"
  to_column: "🔄 In Progress"
  from_state: "creating"
  to_state: "implementing"
  timestamp: "..."
```

**kanban.column_added** / **kanban.column_removed**

### Events Subscribed To

File-kanban automatically updates on:

- **task.created** → Add task to board (in appropriate column)
- **task.state_changed** → Move task to new column based on state
- **task.workflow_completed** → Move task to Done column

**All handlers have priority 30 and only trigger when `auto_update: true`.**

---

## How It Works

### 1. Column-to-State Mapping

Each column maps to one or more workflow states:

```yaml
columns:
  - name: "🔄 In Progress"
    states: [analyzing, designing, implementing]
```

When task enters `implementing` state → automatically moves to "🔄 In Progress" column.

### 2. Task Property: kanban_column

Each task has a property:

```yaml
# .cm/tasks/TASK-001/task.yml
properties:
  kanban_column: "🔄 In Progress"
```

This tracks the task's current column. If not set, column is inferred from task state.

### 3. Board State Cache

Fast access without regeneration:

```yaml
# .cm/kanban/board-state.yml
columns:
  - name: "📋 Backlog"
    states: [creating]
    tasks: [TASK-001, TASK-002]
    count: 2
total_tasks: 5
last_updated: "2025-11-25T..."
```

### 4. Markdown Output

Human-readable board at `.cm/kanban/board.md` (git-friendly, easy to view).

---

## Configuration Options

```yaml
packages:
  file_kanban:
    enabled: true                    # Enable/disable package
    output_file: ".cm/kanban/board.md"  # Board location
    auto_update: true                # Update on task events
    
    columns:                         # Column definitions
      - name: string                 # Display name (with emoji)
        states: [string]             # Workflow states
        color: string                # Color hint (unused currently)
    
    show_properties: [string]        # Task properties to show
    show_task_links: boolean         # Show task file links
    group_by_workflow: boolean       # Group by workflow type
    
    update_on_events:                # Which events trigger update
      - task.created
      - task.state_changed
      - task.workflow_completed
```

---

## Use Cases

### 1. Visualize Team Progress

```bash
$ cat .cm/kanban/board.md
# Shows all tasks organized by workflow stage
```

### 2. Manually Reorganize Tasks

```yaml
- KANBAN.move_task("TASK-005", "🔍 Review", false)
# Move to Review column without changing state
```

### 3. Custom Workflow Columns

```yaml
columns:
  - name: "🚀 Ready to Deploy"
    states: [verified, approved]
  
  - name: "🔥 Hotfix"
    states: [hotfix_implementing]
```

### 4. Monitor Blocked Tasks

```yaml
- KANBAN.add_column("⚠️ Blocked", ["blocked"], 2)
- TASK.set_state("TASK-003", "blocked")
# Task appears in Blocked column
```

### 5. Integration with CI/CD

```yaml
# On deploy success
on: deployment.completed
  - KANBAN.move_task(event.payload.task_id, "✅ Done", true)
```

---

## Best Practices

### 1. Column Design

- **Keep it simple:** 3-5 columns is optimal
- **Use emojis:** Visual distinction helps readability
- **Map multiple states:** Group related states into columns

### 2. State Mapping

```yaml
# ✅ Good - logical grouping
- name: "🔄 Development"
  states: [analyzing, designing, implementing]

# ❌ Bad - too granular
- name: "Analyzing"
  states: [analyzing]
- name: "Designing"  
  states: [designing]
```

### 3. Auto-update

Enable for active projects:

```yaml
auto_update: true  # Board always up-to-date
```

Disable for manual control:

```yaml
auto_update: false  # Update only via KANBAN.update_board()
```

### 4. Property Display

Show relevant context:

```yaml
show_properties:
  - priority      # high/medium/low
  - assignee      # who's working on it
  - blocked_by    # dependencies
```

---

## Troubleshooting

### Board not updating?

1. Check `enabled: true` in config
2. Check `auto_update: true` if using events
3. Manually update: `KANBAN.update_board(true)`

### Task in wrong column?

```yaml
# Check task state
- TASK.get_state("TASK-001")
  into: state

# Check column property
- TASK.get_property("TASK-001", "kanban_column")
  into: column

# Fix manually
- KANBAN.move_task("TASK-001", "correct_column", true)
```

### Column doesn't exist?

```yaml
# List all columns
- KANBAN.get_board_state()
  into: board

- info: "Available columns: {board.columns.map(c => c.name)}"
```

---

## Dependencies

- **kanban-concept** - KANBAN abstract interface
- **file-task** - For task access (TASK.get_state, TASK.set_property, etc.)
- **basic-events** - For event handling (EVENT.emit, subscriptions)

---

## Files Structure

```
packages/implements/file-kanban/
├── package.yml                      # Package metadata
├── concept.yml                      # FILE_KANBAN concept
├── README.md                        # This file
├── primer.md                        # Agent documentation
├── methods/                         # 7 CML methods
│   ├── update_board.yml
│   ├── move_task.yml
│   ├── get_board_state.yml
│   ├── get_column_tasks.yml
│   ├── generate_markdown.yml
│   ├── add_column.yml
│   └── remove_column.yml
└── handlers/                        # 3 event handlers
    ├── on_task_created.yml
    ├── on_task_state_changed.yml
    └── on_workflow_completed.yml
```

---

## See Also

- [kanban-concept](../../concepts/kanban-concept/) - KANBAN abstract interface
- [file-task](../file-task/) - Task storage implementation
- [basic-events](../basic-events/) - Event system implementation
- [Events Documentation](../../../docs/core/concepts/events.md)

---

## License

MIT

