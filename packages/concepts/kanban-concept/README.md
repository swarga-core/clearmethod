# Kanban Concept

Abstract concept defining interface for kanban board visualization and task organization.

## Overview

**KANBAN** is an abstract concept that defines how task visualization boards should work in ClearMethod. It provides a standard interface for organizing tasks into columns based on workflow states.

**Key features:**
- Column-based task organization
- Customizable column-to-state mapping
- Board state management
- Visualization generation
- Event-driven updates

## Interface

### Methods

#### update_board(force?)
Regenerate board visualization from current task states.

**Parameters:**
- `force` (boolean, optional) - Force regeneration even if no changes

**Returns:** `{columns[], total_tasks, last_updated}`

---

#### move_task(task_id, to_column, update_state?)
Move task to different column.

**Parameters:**
- `task_id` (string) - Task to move
- `to_column` (string) - Target column
- `update_state` (boolean, optional) - Also update workflow state

**Returns:** `{task_id, from_column, to_column, state_updated}`

---

#### get_board_state()
Get current board state without regeneration.

**Returns:** `{columns[], config, last_updated}`

---

#### get_column_tasks(column_name)
Get all tasks in specific column.

**Returns:** Array of task objects

---

#### add_column(column_name, states[], position?)
Add new column to configuration.

**Returns:** Column configuration

---

#### remove_column(column_name, move_tasks_to?)
Remove column from configuration.

**Returns:** boolean

---

#### generate_markdown(include_properties?)
Generate markdown representation of board.

**Returns:** string (markdown)

---

## Standard Events

Implementations must emit these events:

- **kanban.board_updated** - After board regeneration
- **kanban.task_moved** - When task moves between columns  
- **kanban.column_added** - When new column added
- **kanban.column_removed** - When column removed

Implementations should subscribe to:

- **task.created** - Add new tasks to board
- **task.state_changed** - Move tasks between columns
- **task.workflow_completed** - Move completed tasks to Done

---

## Implementation Examples

### File-based Implementation
[file-kanban](../../implements/file-kanban/) - Markdown board with property-based tracking

### Potential Implementations
- **database-kanban** - Database-backed board
- **github-kanban** - Sync with GitHub Projects
- **jira-kanban** - Sync with Jira boards

---

## Configuration Structure

Implementations should support this configuration:

```yaml
packages:
  <implementation>:
    enabled: true
    output_file: string
    auto_update: boolean
    
    columns:
      - name: string
        states: [string]
        color: string
    
    show_properties: [string]
```

---

## Design Philosophy

1. **Column = Group of States** - Columns aggregate multiple workflow states
2. **Configurable Mapping** - Each project defines its own column structure
3. **Event-driven** - Board updates automatically on task changes
4. **Human-readable** - Output is git-friendly and easy to read
5. **Tool-agnostic** - Can integrate with external tools

---

## See Also

- [file-kanban Implementation](../../implements/file-kanban/)
- [TASK Concept](../../../core/concepts/task.yml)
- [WORKFLOW Concept](../../../core/concepts/workflow.yml)
- [Events System](../../../docs/core/concepts/events.md)

