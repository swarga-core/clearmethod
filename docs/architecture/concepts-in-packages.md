# Concepts in Packages - Final Architecture

> **CRITICAL UPDATE**: As of v1.0, ALL concepts are now in packages. Core is minimal.

---

## The Big Change

### Before (v0.x)

```
core/
  concepts/       # ← "Special" concepts
    task.yml
    workflow.yml
    context.yml
    event.yml
    vcs.yml
    qa_gate.yml
```

❌ **Problem**: Core concepts had privileged status. Not symmetric.

### After (v1.0+)

```
core/
  # No concepts here! Only infrastructure (CML spec, primer)

packages/
  concepts/
    core-concept/         # TASK, WORKFLOW, AGENT, CONTEXT, EVENT
    vcs-concept/          # VCS
    qa-gate-concept/      # QA_GATE
    kanban-concept/       # KANBAN
  implements/
    file-task/
    sbd/
    basic-events/
    git-vcs/
    qa-gates/
    file-kanban/
```

✅ **Solution**: ALL concepts are packages. Perfect symmetry!

---

## Core Concept Package

**packages/concepts/core-concept/**

Contains the five fundamental abstractions:

1. **TASK** - Unit of work management
2. **WORKFLOW** - State machine for task progression  
3. **AGENT** - AI agent runtime (model, tokens, capabilities)
4. **CONTEXT** - AI agent context management
5. **EVENT** - Inter-component communication

**Status**: `type: concept`, `status: stable`

**Why separate package?**

These five concepts are the ONLY ones with special meaning:
- AGENT defines the runtime (who executes)
- TASK and WORKFLOW define the core workflow engine
- CONTEXT defines how agents load information
- EVENT enables loose coupling

Everything else is optional extensions.

---

## Architecture Benefits

### 1. Perfect Symmetry

**No privileged concepts.** All concepts are equal:

```yaml
# All concepts are packages
packages/concepts/
  core-concept/      # TASK, WORKFLOW, AGENT, CONTEXT, EVENT
  vcs-concept/       # VCS
  qa-gate-concept/   # QA_GATE  
  kanban-concept/    # KANBAN
  your-concept/      # Your custom concept
```

### 2. Dependency Chain

```yaml
# Implementation package
depends_on:
  - core-concept     # Get TASK, WORKFLOW, AGENT, CONTEXT, EVENT
  - vcs-concept      # Get VCS
```

Auto-import: depend on implementation → get its concept dependencies.

### 3. Ecosystem-ready

Just like:
- **Java** - interfaces + implementations
- **Go** - interfaces + structs
- **Rust** - traits + impls

ClearMethod:
- **Concept packages** - abstract interfaces
- **Implementation packages** - concrete realizations

---

## Migration Path

### Old Code (v0.x)

```yaml
# Referred to core/concepts/
- TASK.create(...)
- EVENT.emit(...)
```

### New Code (v1.0+)

```yaml
# Same code! Resolution happens via project.yml
- TASK.create(...)      # → file-task.FILE_TASK.create
- EVENT.emit(...)       # → basic-events.BASIC_EVENT.emit

# In .cm/project.yml:
concept_implementations:
  TASK: file-task.FILE_TASK
  EVENT: basic-events.BASIC_EVENT
```

**No breaking changes in CML code!** Only package structure changed.

---

## What's in Core Now?

```
core/
├── primer.md              # Framework overview for agents
├── concepts/              # EMPTY (all moved to packages)
└── cml/
    └── spec.md            # CML language specification
```

**Core is now minimal infrastructure only.**

---

## Implementation Examples

### Creating New Concept

```yaml
# packages/concepts/notification-concept/package.yml
id: notification-concept
type: concept
provides:
  concepts:
    - NOTIFICATION (abstract)
```

### Creating Implementation

```yaml
# packages/implements/slack-notifier/package.yml
id: slack-notifier
type: implementation
depends_on:
  - core-concept          # TASK, EVENT
  - notification-concept  # NOTIFICATION
provides:
  concepts:
    - SLACK_NOTIFIER (implements: NOTIFICATION)
```

---

## Key Files

### Core Concept Package

- `packages/concepts/core-concept/package.yml`
- `packages/concepts/core-concept/task.yml`
- `packages/concepts/core-concept/workflow.yml`
- `packages/concepts/core-concept/context.yml`
- `packages/concepts/core-concept/event.yml`
- `packages/concepts/core-concept/README.md`

### Updated Implementations

All implementation packages now depend on `core-concept`:

- `file-task` → `depends_on: [core-concept]`
- `basic-events` → `depends_on: [core-concept]`
- `sbd` → `depends_on: [core-concept, file-task]`
- `git-vcs` → `depends_on: [core-concept, vcs-concept, file-task, basic-events]`
- `qa-gates` → `depends_on: [core-concept, qa-gate-concept, file-task, basic-events]`
- `file-kanban` → `depends_on: [core-concept, kanban-concept, file-task, basic-events]`

---

## Philosophy

> **No special concepts. Everything is a package.**

This architecture enables:
- ✅ Consistent treatment of all concepts
- ✅ Clear dependency graph
- ✅ Ecosystem growth (anyone can add concepts)
- ✅ Version independence
- ✅ Multiple implementations per concept
- ✅ Clean separation of abstractions and implementations

---

## See Also

- [Core Concept README](../../packages/concepts/core-concept/README.md)
- [Package Architecture](../core/concepts/packages.md)
- [Concept List](../core/concepts/core.md)

---

**Date**: 2025-11-25  
**Version**: 1.0.0  
**Status**: Final Architecture

