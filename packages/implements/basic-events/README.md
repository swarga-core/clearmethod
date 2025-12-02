# Basic Events Extension

File-based event system implementation for ClearMethod.

## Overview

`basic-events` provides a simple, reliable event system for inter-component communication. Events enable loose coupling between extensions, allowing them to react to state changes without direct dependencies.

## Features

- ✅ **Synchronous event emission** - Predictable execution flow
- ✅ **Priority-based handlers** - Control execution order
- ✅ **Event filtering** - Narrow down when handlers trigger
- ✅ **Event history** - Full audit trail of all events
- ✅ **Cascade support** - Handlers can emit new events
- ✅ **Error isolation** - Failed handlers don't stop others
- ✅ **File-based storage** - Simple YAML files, no database required

## Installation

The `basic-events` extension is included in ClearMethod core setup.

**Manual installation:**
```bash
# Copy extension to project
cp -r core/extensions/basic-events .cm/extensions/

# Update project.yml
```

```yaml
# .cm/project.yml
concept_implementations:
  EVENT: basic-events.BASIC_EVENT
```

## Quick Start

### 1. Emit an Event

In any CML file (workflow state, method, command):

```yaml
# Notify that a task was created
- EVENT.emit("task.created", {
    task_id: "FEAT-001",
    workflow: "sbd.feature",
    title: "Add user authentication",
    created_by: "John Doe"
  })
```

### 2. Subscribe to Events

Create a handler file in your extension:

```yaml
# extensions/my-extension/handlers/on_task_created.yml
name: on_task_created
description: React when task is created

params:
  - name: event
  - name: payload

instructions:
  - info: "New task: {payload.task_id}"
  - info: "Title: {payload.title}"
  
  # Your custom logic here
  - NOTIFIER.send_slack("#dev", "New task created: {payload.title}")
```

### 3. Register Subscription

Add to `.cm/events/subscriptions.yml`:

```yaml
subscriptions:
  - id: sub-my-001
    event_type: task.created
    extension: my-extension
    handler: handlers/on_task_created
    priority: 50
    enabled: true
```

Or register programmatically:

```yaml
- EVENT.subscribe(
    "task.created",
    "my-extension",
    "handlers/on_task_created",
    {priority: 50}
  )
```

## Event Types

### Task Lifecycle

| Event | When | Payload |
|-------|------|---------|
| `task.created` | Task created | task_id, workflow, title, created_by |
| `task.updated` | Task properties updated | task_id, changes |
| `task.deleted` | Task deleted | task_id |
| `task.state_changed` | Workflow state changed | task_id, from, to |
| `task.stage_started` | Stage execution begins | task_id, stage |
| `task.stage_completed` | Stage execution ends | task_id, stage, duration_ms |
| `task.workflow_completed` | Workflow finished | task_id, workflow, final_state |

### Quality & Validation

| Event | When | Payload |
|-------|------|---------|
| `quality.gate_checked` | Quality gate evaluated | task_id, gate_name, stage |
| `quality.gate_passed` | Gate passed | task_id, gate_name, result |
| `quality.gate_failed` | Gate failed | task_id, gate_name, errors |

### VCS Operations

| Event | When | Payload |
|-------|------|---------|
| `vcs.branch_created` | Git branch created | task_id, branch, from |
| `vcs.commit_created` | Commit made | task_id, sha, message |
| `vcs.push_completed` | Pushed to remote | task_id, branch, commits |
| `vcs.pr_created` | PR opened | task_id, pr_url, number |

### Context Management

| Event | When | Payload |
|-------|------|---------|
| `context.loaded` | Context loaded | files_count, tokens |
| `context.file_added` | File added to context | file_path, size |
| `context.updated` | Context refreshed | changes |

## Handler Development

### Handler Structure

```yaml
name: handler_name
description: What this handler does

params:
  - name: event      # Full event object
  - name: payload    # Event payload data

instructions:
  - info: "Handling {event.type}"
  
  # Your logic here
  - let: task_id = payload.task_id
  - TASK.log(task_id, "Handler executed")
  
  # Can emit new events (cascade)
  - EVENT.emit("custom.event", {
      related_to: event.id,
      task_id: task_id
    })
```

### Handler Best Practices

#### ✅ DO

- **Keep handlers focused** - One responsibility per handler
- **Check preconditions** - Validate payload data
- **Log actions** - Use `info:` for debugging
- **Handle errors gracefully** - Use try/catch if needed
- **Document handlers** - Clear description and params

#### ❌ DON'T

- **Don't do heavy computation** - Handlers block execution
- **Don't modify global state directly** - Use proper methods
- **Don't create infinite loops** - Be careful with cascades
- **Don't rely on execution order** - Use priorities explicitly
- **Don't ignore errors silently** - Log failures

### Filters

Narrow down when handlers execute:

```yaml
# Only for specific workflow
filter:
  workflow: sbd.feature

# Only for certain stages
filter:
  stage: [designing, implementing, verifying]

# Multiple conditions (all must match)
filter:
  workflow: sbd.feature
  task_type: feature
  priority: high
```

### Priorities

Control execution order (lower = earlier):

- **1-10**: Critical validation & security checks
- **11-50**: Pre-action handlers (quality gates, preconditions)
- **51-100**: Normal handlers (integrations, automations)
- **101-200**: Post-action handlers (notifications, logging)
- **201+**: Low-priority handlers (analytics, cleanup)

## Real-World Examples

### Example 1: Auto-create Git Branch

```yaml
# Subscription
event_type: task.created
extension: git-vcs
handler: handlers/auto_branch
filter:
  workflow: sbd.feature
priority: 20

# Handler: extensions/git-vcs/handlers/auto_branch.yml
name: auto_branch
params:
  - name: event
  - name: payload

instructions:
  - let: branch_name = "feature/{payload.task_id}-{slugify(payload.title)}"
  
  - VCS.create_branch(payload.task_id, branch_name)
  
  - TASK.log(payload.task_id, "Branch created: {branch_name}")
  
  - EVENT.emit("vcs.branch_created", {
      task_id: payload.task_id,
      branch: branch_name
    })
```

### Example 2: Quality Gate Validation

```yaml
# Subscription
event_type: task.stage_completed
extension: qa-gates
handler: handlers/validate_stage
filter:
  stage: [designing, implementing, verifying]
priority: 5  # High priority - validate before proceeding

# Handler: extensions/qa-gates/handlers/validate_stage.yml
name: validate_stage
params:
  - name: event
  - name: payload

instructions:
  - let: stage = payload.stage
  - let: task_id = payload.task_id
  
  - info: "Validating quality gate for stage: {stage}"
  
  - let: result = QA_GATE.check(task_id, stage)
  
  - if: result.passed
    then:
      - TASK.log(task_id, "✅ Quality gate passed for {stage}")
      - EVENT.emit("quality.gate_passed", {
          task_id: task_id,
          stage: stage,
          checks: result.checks
        })
    else:
      - TASK.log(task_id, "❌ Quality gate failed for {stage}")
      - EVENT.emit("quality.gate_failed", {
          task_id: task_id,
          stage: stage,
          errors: result.errors
        })
      - error: "Quality gate failed: {result.errors}"
```

### Example 3: Team Notifications

```yaml
# Subscription
event_type: task.workflow_completed
extension: notifications
handler: handlers/notify_team
filter:
  workflow: sbd.feature
priority: 100

# Handler: extensions/notifications/handlers/notify_team.yml
name: notify_team
params:
  - name: event
  - name: payload

instructions:
  - let: task = TASK.get(payload.task_id)
  
  - let: message = "✅ Task {payload.task_id} completed!\n" +
                   "Title: {task.title}\n" +
                   "Duration: {format_duration(task.duration)}"
  
  - NOTIFIER.send_slack("#dev", message)
  
  - TASK.log(payload.task_id, "Team notified via Slack")
```

## Debugging

### View Recent Events

```bash
# Check event log
cat .cm/events/events.yml

# Last 10 events
tail -n 50 .cm/events/events.yml
```

### List Active Subscriptions

```bash
cat .cm/events/subscriptions.yml
```

### Query Events Programmatically

```yaml
# In CML
- let: recent = EVENT.get_history(limit: 20)
- for: event in recent
  do:
    - info: "{event.timestamp} - {event.type} ({event.handlers_executed.length} handlers)"
```

### Check Handler Execution

Events include execution results:

```yaml
handlers_executed:
  - subscription_id: sub-001
    extension: git-vcs
    handler: handlers/auto_branch
    status: success
    duration_ms: 156
  
  - subscription_id: sub-002
    extension: qa-gates
    handler: handlers/validate_stage
    status: error
    error: "Quality gate failed: missing tests"
    duration_ms: 89
```

## Performance Considerations

### Event Log Growth

The event log grows over time. Clean up old events periodically:

```bash
# Keep only last 1000 events
tail -n 5000 .cm/events/events.yml > .cm/events/events.tmp
mv .cm/events/events.tmp .cm/events/events.yml
```

Or use retention policy (future feature):

```yaml
# concept.yml
configuration:
  log_retention_days: 90  # Auto-cleanup after 90 days
```

### Handler Performance

- Keep handlers fast (<100ms recommended)
- Avoid I/O operations when possible
- Use async operations for slow tasks (future feature)
- Monitor `duration_ms` in event records

### Cascade Depth

Limit cascades to avoid performance issues:

- Maximum depth: 10 levels (enforced)
- Typical depth: 1-3 levels
- Monitor `cascade_depth` in payloads
- Design events to minimize cascades

## Architecture

### Storage Files

```
.cm/events/
├── events.yml          # Chronological event log
└── subscriptions.yml   # Active subscriptions
```

### Event Record Format

```yaml
id: evt-123
type: task.created
timestamp: 2025-11-25T10:30:00Z
payload:
  task_id: FEAT-001
  workflow: sbd.feature
  title: "New feature"
cascade_depth: 0
handlers_executed:
  - subscription_id: sub-001
    extension: git-vcs
    handler: handlers/auto_branch
    status: success
    duration_ms: 156
duration_ms: 1234
status: completed
```

### Subscription Format

```yaml
id: sub-001
event_type: task.created
extension: git-vcs
handler: handlers/auto_branch
filter:
  workflow: sbd.feature
priority: 20
enabled: true
created_at: 2025-11-25T10:00:00Z
```

## Roadmap

Future enhancements:

- [ ] Asynchronous event emission
- [ ] Event log rotation and retention
- [ ] Event replay for debugging
- [ ] Subscription import/export
- [ ] Event type validation
- [ ] Performance metrics dashboard
- [ ] Wildcard event types in subscriptions
- [ ] Regex filters in subscriptions

## Troubleshooting

### Handler Not Triggered

1. **Check subscription exists:**
   ```bash
   grep "event_type: task.created" .cm/events/subscriptions.yml
   ```

2. **Verify handler file exists:**
   ```bash
   ls .cm/extensions/your-extension/handlers/
   ```

3. **Check filters match:**
   ```yaml
   # Subscription filter
   filter:
     workflow: sbd.feature
   
   # Event payload must include
   payload:
     workflow: sbd.feature  # ← Must match!
   ```

4. **Check enabled status:**
   ```yaml
   enabled: true  # Must be true
   ```

### Handler Fails Silently

Check event log for errors:

```bash
# Find events with errors
grep -A 5 "status: error" .cm/events/events.yml
```

### Performance Issues

1. Check handler execution times:
   ```bash
   grep "duration_ms" .cm/events/events.yml | tail -20
   ```

2. Count subscriptions:
   ```bash
   grep "^  - id:" .cm/events/subscriptions.yml | wc -l
   ```

3. Check cascade depth:
   ```bash
   grep "cascade_depth" .cm/events/events.yml | sort -rn | head -10
   ```

## Contributing

To add new event types or improve the event system, see:

- `core/concepts/event.yml` - Abstract EVENT concept
- `extensions/basic-events/methods/` - Implementation methods
- `docs/architecture/events.md` - Event system architecture

## License

Part of ClearMethod framework. See main LICENSE file.

