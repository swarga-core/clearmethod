# /cm-prime

Load ClearMethod context into agent's context window.

**Note**: This is the ONLY command not written in CML, because it loads CML itself.

---

## Execute

### Step 1: Validate setup

Check if `.cm/` folder exists in project root.

**If NOT exists**:
- Report error: "ClearMethod not set up. .cm/ folder not found."
- STOP execution

**If exists**:
- Continue to step 2

### Step 2: Read priming configuration

Try to read `.cm/priming.yml` file.

**If file exists**:
- Read and parse the YAML file
- Extract the `primers` configuration (core, extensions, project sections)
- Continue with this configuration

**If file NOT exists**:
- Show warning: "priming.yml not found, using default primer locations"
- Use default configuration:
  - Core: `.cm/core/primer.md`, `.cm/core/cml/primer.md`
  - Extensions: `.cm/packages/file-task/primer.md`, `.cm/packages/sbd/primer.md`
  - Project: (skip)

### Step 3: Load primers sequentially

Load primers in this order: Core → Extensions → Project

#### 3a. Load core primers

For each primer in core section:
1. Check if file exists at specified path
2. **If exists**:
   - Read the file COMPLETELY (don't skip or summarize)
   - Process and internalize the content
   - Report: "✓ Loaded: {path}"
3. **If NOT exists**:
   - If marked as `required: true`: ERROR and STOP
   - If marked as `required: false`: WARN and continue

**Default core primers** (if no config):
- `.cm/core/primer.md` (REQUIRED)
- `.cm/core/cml/primer.md` (REQUIRED)

#### 3b. Load extension primers

For each primer in extensions section:
1. Check if file exists
2. **If exists**: read completely and report loaded
3. **If NOT exists**: show warning but continue (extensions are optional)

**Default extension primers** (if no config):
- `.cm/packages/file-task/primer.md` (if exists)
- `.cm/packages/sbd/primer.md` (if exists)

#### 3c. Load project primers

For each primer in project section:
1. Check if file exists
2. **If exists**: read and report loaded
3. **If NOT exists**: skip silently (project primers are fully optional)

### Step 4: Confirm to user

Report to user:

```
✅ ClearMethod context loaded

Loaded primers:
- Core: ClearMethod framework
- Core: CML language
- Extension: file-task
- Extension: sbd
[- Project: ...]

Available workflows:
- sbd.feature (Feature Development - 6 stages)

Available commands:
/cm-start <workflow> <task-id> [title] - Start new task
/cm-next - Proceed to next stage
/cm-status - Show current task status

Ready to work! 🚀
```

---

## Critical rules

1. **Read files COMPLETELY** - don't skip, don't summarize
2. **Process content** - internalize information, understand it
3. **Blocking operation** - complete all loads before responding
4. **Fail on missing core** - can't proceed without core primers
5. **Warn on missing extensions** - but continue execution
6. **Skip missing project** - silently, they're fully optional

---

## After execution

You now have full knowledge of:
- ClearMethod concepts (TASK, WORKFLOW, AGENT, CONTEXT, EVENT)
- CML language (how to interpret .yml instructions)
- All available commands
- Active extensions and their methods
- Project context (if provided)

**You are ready to execute other commands (which are written in CML).**

---

## Token budget

Estimated: 5-8K tokens total
- Core primer: ~2K
- CML primer: ~2K
- Extension primers: ~1K each
- Project primers: ~1-2K total

This is acceptable for modern LLMs with large context windows.
