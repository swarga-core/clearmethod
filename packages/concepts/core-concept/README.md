# Core Concepts

**The foundation of ClearMethod framework.**

This package provides the four fundamental abstract concepts that define the core contracts of ClearMethod:

- **TASK** - Unit of work management
- **WORKFLOW** - State machine for task progression
- **CONTEXT** - AI agent context management
- **EVENT** - Inter-component communication

---

## Philosophy

**Pure abstractions, zero implementation.**

`core-concept` is the ONLY package with special status in ClearMethod. It defines the minimal set of interfaces that all other packages depend on. Everything else is an optional extension.

### Design Principles

1. **Minimal** - Only absolutely essential concepts
2. **Abstract** - No implementation details
3. **Stable** - Changes require major version bump
4. **Framework-agnostic** - Can be implemented in any way

---

## Concepts

### TASK

Interface for task management.

**Key methods:**
- `create(id, title, content, creator, workflow)`
- `get_state()` / `set_state(state)`
- `get_property(name)` / `set_property(name, value)`
- `log(entry)` / `get_log()`

**Properties:**
- `id`, `title`, `content`
- `creator`, `created_at`, `last_updated_at`
- `workflow`, `status`

**Implementations:**
- [file-task](../../implements/file-task/) - File-based storage

---

### WORKFLOW

Interface for state machine workflows.

**Key methods:**
- `start(task_id)` - Initialize workflow for task
- `go(task_id, target_state)` - Transition to state
- `next(task_id)` - Auto-advance to next state
- `goback(task_id)` - Return to previous state
- `rework(task_id)` - Restart current state
- `finalize(task_id)` - Complete workflow

**Properties:**
- `id`, `title`, `description`, `version`
- `states`, `start_state`, `end_states`

**Implementations:**
- [sbd](../../implements/sbd/) - Stage-Based Development workflows

---

### CONTEXT

Interface for AI agent context management.

**Key methods:**
- `prime()` - Load initial context from `.cm/priming.yml`
- `load(context_info)` - JIT load specific context segments

**Philosophy:**
> Tokens are currency. Load minimum needed, at the right moment.

**Implementations:**
- TBD (currently handled by IDE/framework)

---

### EVENT

Interface for inter-component communication.

**Key methods:**
- `emit(event_type, payload, sync?)` - Trigger event
- `subscribe(event_type, package, handler, filter?, priority?)` - Register handler
- `unsubscribe(subscription_id)` - Remove handler
- `get_history(task_id?, event_type?, limit?, since?)` - Audit log
- `list_subscriptions(event_type?, package?)` - List handlers

**Standard event types:**
- `task.*` - Task lifecycle events
- `workflow.*` - Workflow state changes
- `quality.*` - QA gate results
- `vcs.*` - Git operations
- `context.*` - Context updates
- `system.*` - Framework events

**Implementations:**
- [basic-events](../../implements/basic-events/) - File-based synchronous events

---

## Usage

### In project configuration

```yaml
# .cm/project.yml
concept_implementations:
  TASK: file-task.FILE_TASK
  WORKFLOW: sbd.SBD_WORKFLOW
  EVENT: basic-events.BASIC_EVENT
  # CONTEXT: not yet implemented
```

### In package dependencies

```yaml
# packages/implements/my-package/package.yml
depends_on:
  - core-concept  # ← Get access to TASK, WORKFLOW, CONTEXT, EVENT
```

### In CML code

```yaml
# Use concepts directly (resolved via project.yml)
instructions:
  - TASK.create("TASK-001", "Fix bug", "...", "user", "sbd.bugfix")
  - WORKFLOW.start("TASK-001")
  - EVENT.emit("task.created", {task_id: "TASK-001"})
```

---

## Why These Four?

### TASK
Every system needs a way to track work units. TASK is the minimal interface for that.

### WORKFLOW
Tasks follow trajectories. WORKFLOW defines those trajectories as state machines.

### CONTEXT
AI agents need information to work effectively. CONTEXT manages what information is loaded and when.

### EVENT
Components need to communicate without tight coupling. EVENT enables pub-sub architecture.

**Everything else is optional!**

---

## Evolution

### Current Status: MVP

All four concepts have at least one implementation:
- ✅ TASK → file-task
- ✅ WORKFLOW → sbd
- ✅ EVENT → basic-events
- ⏳ CONTEXT → manual (not yet packaged)

### Future Additions (Maybe Never)

Core concepts are intentionally minimal. Resist adding more unless absolutely unavoidable.

Possible candidates (but probably should stay as optional concepts):
- ~~VCS~~ → Already moved to `vcs-concept` package ✅
- ~~QA_GATE~~ → Already moved to `qa-gate-concept` package ✅
- ~~KANBAN~~ → Already an optional concept ✅

---

## Implementation Requirements

When implementing these concepts:

1. **Declare dependency** on `core-concept` in `package.yml`
2. **Implement ALL methods** from the interface
3. **Match signatures exactly** (params, returns)
4. **Can add extra methods** specific to your implementation
5. **Must validate inputs** and handle errors gracefully
6. **Must log operations** for auditability

---

## Files

```
packages/concepts/core-concept/
├── package.yml         # Package metadata
├── README.md           # This file
├── task.yml            # TASK concept
├── workflow.yml        # WORKFLOW concept
├── context.yml         # CONTEXT concept
└── event.yml           # EVENT concept
```

---

## See Also

- [Concepts Documentation](../../../docs/core/concepts/core.md)
- [Package Architecture](../../../docs/core/concepts/packages.md)
- [Implementation Packages](../../implements/)

---

**Status:** Stable  
**Version:** 1.0.0  
**License:** MIT

