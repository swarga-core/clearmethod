# /cm-prime

Load ClearMethod context into agent's context window.

---

## Execute

### 1. Check setup
```
IF NOT exists(.cm/) THEN
  ERROR: "ClearMethod not set up. .cm/ folder not found."
  STOP
```

### 2. Read priming config
```
READ: .cm/priming.yml
PARSE: primers list with paths
```

### 3. Load primers sequentially
```
FOR EACH primer IN config.primers:
  IF exists(primer.path):
    READ file completely
    Process and internalize
  ELSE:
    WARN: "Primer {path} not found, skipping"
```

**Load order** (from priming.yml):
1. Core primer (required)
2. Extension primers (active extensions)
3. Project primers (optional)

### 4. Confirm
```
REPORT to user:
"✅ Context loaded
- Core: [loaded/error]
- Extensions: [list]
- Project: [yes/no]

Ready to work."
```

---

## Critical notes

- **Blocking operation** - complete all reads before responding
- **No summaries** - read primer files completely
- **Fail on missing core** - can't proceed without core primer
- **Warn on missing extensions** - but continue
- **Token budget**: ~5-8K total (acceptable)

---

## After priming

You now know:
- ClearMethod concepts (TASK, WORKFLOW, AGENT, CONTEXT, EVENT)
- All available commands
- Active extensions and their methods
- Project context

**You are ready to execute workflows.**
