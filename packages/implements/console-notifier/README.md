# Console Notifier Package

**Console and log-based notifications for development and CI/CD.**

> Status: **Planned** (Concept only, no implementation yet)

---

## Overview

Simple notification implementation that outputs to console and log files.
Perfect for development, testing, and CI/CD pipelines.

---

## Features

- ✅ Console output with colors
- ✅ File logging
- ✅ Configurable formatting
- ✅ Level-based filtering
- ✅ Zero external dependencies

---

## Configuration

```yaml
packages:
  console_notifier:
    enabled: true
    
    outputs:
      console: true
      file: true
      file_path: ".cm/logs/notifications.log"
    
    format:
      colors: true
      timestamps: true
      emoji: true
```

---

## Example Output

```
[2025-11-25 14:32:15] 🚀 INFO: Workflow started
  Task: TASK-123 - Add user authentication
  Workflow: sbd.feature

[2025-11-25 14:45:03] ⚠️  WARN: Quality gate check
  Gate: implementing
  Issues: 2 warnings found

[2025-11-25 15:10:42] ✅ SUCCESS: Workflow completed
  Task: TASK-123
  Duration: 38m 27s
```

---

**Dependencies:**
- `core-concept` - TASK, WORKFLOW, EVENT
- `notification-concept` - NOTIFICATION abstract
- `basic-events` - For event handling

