# BASIC_EVENT Extension Primer

## Overview

`BASIC_EVENT` is a file-based implementation of the `EVENT` abstract concept. It provides synchronous event emission and subscription management for inter-component communication in ClearMethod.

## Key Concepts

### Events
Events are notifications about state changes or significant actions. They enable loose coupling between components.

**Standard format:**
```yaml
id: evt-001
type: task.created
timestamp: 2025-11-25T10:30:00Z
payload:
  task_id: FEAT-001
  workflow: sbd.feature
  created_by: "User Name"
handlers_executed: [...]
duration_ms: 1234
```

### Subscriptions
Subscriptions register handlers to be triggered when specific events occur.

**Subscription format:**
```yaml
id: sub-001
event_type: task.created
extension: git-vcs
handler: handlers/on_task_created
filter:
  workflow: sbd.feature
priority: 10
enabled: true
```

## Storage

- **Event Log**: `.cm/events/events.yml` - All emitted events
- **Subscriptions**: `.cm/events/subscriptions.yml` - Active subscriptions

## Usage in CML

### Emitting Events

```yaml
# Basic emission
- EVENT.emit("task.created", {
    task_id: task_id,
    workflow: "sbd.feature",
    title: "New feature"
  })

# With result capture
- let: result = EVENT.emit("task.stage_completed", {
    task_id: task_id,
    stage: "designing"
  })
- info: "Event {result.event_id} triggered {result.handlers_executed} handlers"
```

### Common Event Types

**Task lifecycle:**
- `task.created` - New task created
- `task.state_changed` - Task state updated
- `task.stage_started` - Stage execution started
- `task.stage_completed` - Stage execution completed
- `task.workflow_completed` - Workflow finished

**Quality & Validation:**
- `quality.gate_checked` - Quality gate evaluated
- `quality.gate_passed` - Quality gate passed
- `quality.gate_failed` - Quality gate failed

**VCS operations:**
- `vcs.branch_created` - Git branch created
- `vcs.commit_created` - Commit made
- `vcs.pr_created` - Pull request created

**Context operations:**
- `context.loaded` - Context loaded
- `context.file_added` - File added to context

## Event Handlers

Handlers are CML files that respond to events. They are stored in extension directories.

**Handler location:**
`.cm/packages/{extension}/handlers/{handler_name}.yml`

**Example handler:**
```yaml
# .cm/packages/git-vcs/handlers/on_task_created.yml
name: on_task_created
description: Create git branch when task is created

params:
  - name: event
  - name: payload

instructions:
  - info: "Handling task.created for {payload.task_id}"
  
  - let: branch_name = "feature/{payload.task_id}"
  
  - VCS.create_branch(payload.task_id, branch_name)
  
  - TASK.log(payload.task_id, "Git branch created: {branch_name}")
  
  # Handlers can emit new events (cascade)
  - EVENT.emit("vcs.branch_created", {
      task_id: payload.task_id,
      branch: branch_name
    })
```

## Handler Execution

### Priority
- Lower number = higher priority (executes first)
- Default priority: 100
- Use priorities 1-50 for critical handlers (e.g., validation, security)
- Use priorities 51-100 for normal handlers (e.g., integrations)
- Use priorities 101+ for low-priority handlers (e.g., notifications)

### Filters
Narrow down when handlers are triggered:

```yaml
# Only for specific workflow
filter:
  workflow: sbd.feature

# Only for specific stages
filter:
  stage: [designing, implementing]

# Multiple conditions (AND logic)
filter:
  workflow: sbd.feature
  task_type: feature
```

### Error Handling
- Each handler executes in isolation (try/catch)
- Failed handler doesn't stop other handlers
- Errors are logged in event record
- Handler result includes status: `success` or `error`

### Cascade Protection
- Handlers can emit new events (cascade)
- Maximum cascade depth: 10 levels
- Prevents infinite loops
- Each emitted event increments `cascade_depth` in payload

## Best Practices

### When to Emit Events

✅ **DO emit events for:**
- State changes (task created, stage completed)
- Significant actions (commit created, PR merged)
- Quality gates (validation passed/failed)
- Integration points (notification sent)

❌ **DON'T emit events for:**
- Internal logic steps
- Trivial property updates
- High-frequency operations
- Private implementation details

### Event Naming

Use hierarchical naming: `{domain}.{action}_{past_tense}`

**Examples:**
- `task.created`, `task.updated`, `task.deleted`
- `workflow.stage_started`, `workflow.stage_completed`
- `vcs.branch_created`, `vcs.commit_pushed`
- `quality.gate_passed`, `quality.gate_failed`

### Payload Design

Include essential context:
```yaml
# Good payload
{
  task_id: "FEAT-001",        # Required for task events
  stage: "designing",          # Current state
  previous_stage: "analyzing", # Previous state (for transitions)
  metadata: {...}              # Additional context
}
```

Avoid large payloads (they're logged to disk).

### Handler Design

Keep handlers focused and independent:

```yaml
# ✅ Good: Single responsibility
name: on_task_created_create_branch
instructions:
  - VCS.create_branch(payload.task_id, branch_name)

# ❌ Bad: Multiple responsibilities
name: on_task_created_do_everything
instructions:
  - VCS.create_branch(...)
  - NOTIFIER.send_slack(...)
  - DOC_GEN.generate_readme(...)
  # Too much in one handler!
```

Create separate subscriptions for separate concerns.

## Querying Events

### Get History
```yaml
# All events for a task
- let: events = EVENT.get_history(task_id: "FEAT-001")

# Recent events of specific type
- let: events = EVENT.get_history(
    event_type: "task.stage_completed",
    limit: 10
  )

# Events since timestamp
- let: events = EVENT.get_history(
    since: "2025-11-25T00:00:00Z"
  )
```

### List Subscriptions
```yaml
# All subscriptions
- let: subs = EVENT.list_subscriptions()

# For specific event type
- let: subs = EVENT.list_subscriptions(event_type: "task.created")

# For specific extension
- let: subs = EVENT.list_subscriptions(extension: "git-vcs")
```

## Debugging Events

### Check Event Log
```yaml
# View recent events
- let: recent = EVENT.get_history(limit: 20)
- for: event in recent
  do:
    - info: "[{event.timestamp}] {event.type} → {event.handlers_executed.length} handlers"
```

### Verify Subscriptions
```yaml
# Check if handler is registered
- let: subs = EVENT.list_subscriptions(event_type: "task.created")
- info: "Found {subs.length} handlers for task.created"
- for: sub in subs
  do:
    - info: "  - {sub.extension}.{sub.handler} (priority: {sub.priority})"
```

### Track Cascades
Check `cascade_depth` in event payload to track event chains.

## Performance Considerations

- **Synchronous execution**: Handlers block workflow execution
- **Keep handlers fast**: Avoid long-running operations
- **Filter early**: Use specific event types and filters
- **Limit cascades**: Avoid deep event chains
- **Monitor event log**: Can grow large over time (use retention policy)

## Common Patterns

### Pre-action Validation
Use high-priority handlers (1-10) to validate before action:

```yaml
# Subscription
event_type: task.transition_requested
handler: handlers/validate_quality_gate
priority: 5  # Execute before other handlers
```

### Post-action Integration
Use normal priority handlers (50-100) for integrations:

```yaml
# After task created
event_type: task.created
handler: handlers/notify_team
priority: 50
```

### Conditional Logic
Use filters to narrow down execution:

```yaml
# Only for production-ready tasks
event_type: task.workflow_completed
filter:
  workflow: sbd.feature
  stage: completing
```

## Troubleshooting

**Handler not triggered?**
1. Check subscription exists: `EVENT.list_subscriptions()`
2. Check `enabled: true`
3. Verify filters match event payload
4. Check handler file exists at specified path

**Too many handlers?**
1. Review priorities
2. Check for duplicate subscriptions
3. Consider consolidating similar handlers

**Performance issues?**
1. Check cascade depth
2. Profile handler execution times (check `duration_ms`)
3. Reduce number of subscriptions
4. Add more specific filters

