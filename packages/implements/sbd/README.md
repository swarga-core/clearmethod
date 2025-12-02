# Stage-Based Development (SBD) Package

Structured workflows for software development with AI assistance.

## Overview

`sbd` (Stage-Based Development) provides a set of workflows designed for systematic software development. Each workflow breaks down the development process into isolated stages with clear inputs, outputs, and transitions.

**Key Principles:**
- ✅ **Stage isolation** - Each stage is self-contained
- ✅ **Clear boundaries** - Explicit preconditions and postconditions
- ✅ **Controlled transitions** - No stage skipping
- ✅ **Artifact accumulation** - Progressive knowledge building
- ✅ **Event-driven** - Full integration with ClearMethod event system

**Philosophy:** Structured progression beats chaos. Small, verified steps beat big leaps.

---

## Workflows

The SBD package provides three workflows for different development scenarios:

| Workflow | States | Use Case | Duration |
|----------|--------|----------|----------|
| **sbd.feature** | 7 | New feature development | Long (days) |
| **sbd.bugfix** | 5 | Bug investigation and fix | Short (hours) |
| **sbd.refactoring** | 5 | Code improvement | Medium (hours/day) |

---

## Installation

The `sbd` package is included in ClearMethod core setup.

**Manual installation:**
```bash
# Copy package to project
cp -r packages/sbd .cm/packages/

# Update project.yml
```

```yaml
# .cm/project.yml
concept_implementations:
  WORKFLOW: sbd.SBD_WORKFLOW

workflows:
  default: sbd.feature
```

**Dependencies:**
- `file-task` - For task storage

---

## Workflow 1: sbd.feature

**Purpose:** Complete feature development from idea to deployment.

**Stages:** 7 (creating → analyzing → designing → planning → implementing → verifying → completing)

**Duration:** Typically 1-5 days depending on complexity

### Flow Diagram

```
┌──────────┐
│ creating │  Initial task setup and requirements gathering
└────┬─────┘
     │
┌────▼─────┐
│analyzing │  Detailed requirements analysis and decomposition
└────┬─────┘
     │
┌────▼────┐
│designing│  Solution design and architecture decisions
└────┬────┘
     │
┌────▼────┐
│planning │  Create detailed implementation plan
└────┬────┘
     │
┌────▼────────┐
│implementing │  Code implementation
└────┬────────┘
     │
┌────▼─────┐
│verifying │  Testing and quality assurance
└────┬─────┘
     │
┌────▼──────┐
│completing │  Finalization and documentation
└───────────┘
```

### Stages

#### 1. Creating
**Goal:** Establish task foundation and gather initial requirements.

**Activities:**
- Collect task specifications from user
- Document initial requirements
- Set up task structure
- Determine workflow parameters

**Outputs:**
- `specs.md` - Task specification
- Initial properties (priority, complexity, etc.)
- Task log started

**Events:**
- `task.stage_started` (stage: "creating")
- `task.created`
- `task.stage_completed` (stage: "creating")

---

#### 2. Analyzing
**Goal:** Deep dive into requirements, identify edge cases, decompose complexity.

**Activities:**
- Analyze requirements in detail
- Identify technical challenges
- List edge cases and constraints
- Break down complex requirements
- Estimate effort

**Outputs:**
- `analysis.md` - Detailed analysis
- Properties: `edge_cases`, `technical_challenges`, `estimated_effort`
- Risk assessment

**Preconditions:**
- Task created
- Initial specs available

**Postconditions:**
- Analysis complete
- Edge cases identified
- Complexity assessed

**Events:**
- `task.stage_started` (stage: "analyzing")
- `task.stage_completed` (stage: "analyzing")

**Quality Gates:**
- All requirements understood
- Edge cases documented
- Risks identified

---

#### 3. Designing
**Goal:** Create solution architecture and design decisions.

**Activities:**
- Design system architecture
- Make technology choices
- Plan implementation approach
- Design data structures and APIs
- Consider alternatives

**Outputs:**
- `design.md` - Architecture and design document
- Properties: `design_approved`, `tech_stack`, `api_design`
- Design diagrams (if applicable)

**Preconditions:**
- Analysis completed
- Requirements understood

**Postconditions:**
- Design documented
- Architecture approved
- Ready for planning

**Events:**
- `task.stage_started` (stage: "designing")
- `task.stage_completed` (stage: "designing")

**Quality Gates:**
- Design addresses all requirements
- Edge cases covered in design
- Scalability considered

---

#### 4. Planning
**Goal:** Create detailed, step-by-step implementation plan.

**Activities:**
- Break design into implementation phases
- List all files to create/modify
- Define sequence of implementation steps
- Create actionable checklist
- Identify dependencies between steps
- Plan testing strategy
- Estimate complexity

**Outputs:**
- `plan.md` - Detailed implementation plan
- `checklist.md` - Step-by-step checklist (optional)
- Properties: `plan_approved`, `estimated_complexity`, `files_to_modify`
- Implementation roadmap

**Preconditions:**
- Design approved
- Architecture documented

**Postconditions:**
- Plan documented and approved
- Implementation steps clear
- Dependencies identified
- Ready for implementation

**Events:**
- `task.stage_started` (stage: "planning")
- `task.stage_completed` (stage: "planning")

**Quality Gates:**
- Plan covers all design aspects
- Steps are concrete and actionable
- Dependencies clearly identified
- Files list is complete

**Why Planning is separate:**
- **Different thinking mode:** Design = architectural, Planning = procedural
- **Better context management:** Planning loads only design.md, not all requirements
- **Clearer handoff:** Implementing stage gets concrete checklist, not high-level design
- **Easier review:** Can validate plan before writing code
- **Flexibility:** Can iterate on plan without redesigning

---

#### 5. Implementing
**Goal:** Write code according to plan.

**Activities:**
- Implement functionality
- Write tests
- Follow coding standards
- Document code
- Commit changes incrementally

**Outputs:**
- Source code files
- Unit tests
- Properties: `files_created`, `tests_written`, `lines_of_code`
- Git commits

**Preconditions:**
- Plan approved
- Implementation steps clear

**Postconditions:**
- Code implemented
- Tests written
- Code compiles/runs

**Events:**
- `task.stage_started` (stage: "implementing")
- `vcs.commit_created` (triggered by git-vcs package)
- `task.stage_completed` (stage: "implementing")

**Quality Gates:**
- Code follows standards
- Tests cover main scenarios
- No obvious bugs

---

#### 6. Verifying
**Goal:** Ensure quality through comprehensive testing.

**Activities:**
- Run all tests
- Manual testing
- Check code coverage
- Review code quality
- Verify edge cases
- Performance testing (if needed)

**Outputs:**
- Test results
- Coverage report
- Properties: `tests_passed`, `coverage_percent`, `bugs_found`
- Bug reports (if issues found)

**Preconditions:**
- Implementation complete
- Tests exist

**Postconditions:**
- All tests pass
- Coverage acceptable
- No critical bugs
- Edge cases verified

**Events:**
- `task.stage_started` (stage: "verifying")
- `quality.gate_checked`
- `quality.gate_passed` or `quality.gate_failed`
- `task.stage_completed` (stage: "verifying")

**Quality Gates:**
- Test pass rate: 100%
- Coverage: ≥80% (configurable)
- Linter errors: 0
- Critical bugs: 0

---

#### 7. Completing
**Goal:** Finalize task and prepare for deployment.

**Activities:**
- Final documentation
- Create/update README
- Prepare deployment notes
- Create changelog
- Clean up temporary files
- Final git commit

**Outputs:**
- `completion-report.md` - Summary of work done
- Updated documentation
- Deployment instructions
- Properties: `workflow_complete`, `final_status`

**Preconditions:**
- Verification passed
- All quality gates met

**Postconditions:**
- Task fully documented
- Ready for deployment
- Workflow completed

**Events:**
- `task.stage_started` (stage: "completing")
- `task.stage_completed` (stage: "completing")
- `task.workflow_completed` (workflow: "sbd.feature")
- `vcs.pr_created` (if configured)

---

## Workflow 2: sbd.bugfix

**Purpose:** Systematic bug investigation and fix.

**Stages:** 5 (investigating → reproducing → fixing → verifying → completing)

**Duration:** Typically 1-8 hours depending on complexity

### Flow Diagram

```
┌──────────────┐
│investigating │  Understand the bug
└──────┬───────┘
       │
┌──────▼──────┐
│reproducing  │  Create failing test
└──────┬──────┘
       │
┌──────▼──┐
│ fixing  │  Fix the code
└──────┬──┘
       │
┌──────▼────┐
│verifying  │  Comprehensive testing
└──────┬────┘
    ┌──┴──┐
    │  ↓  │  ← Can loop back if tests fail
┌───▼─────▼───┐
│ completing  │  Document and finalize
└─────────────┘
```

### Key Features

✅ **Reproduction first** - Always create a failing test before fixing
✅ **Test-driven** - The failing test becomes your success criteria
✅ **Quick cycle** - Shorter than feature workflow
✅ **Loop capability** - Can return from verifying to fixing if needed
✅ **Regression prevention** - All existing tests must still pass

### Stages

#### 1. Investigating
**Goal:** Understand what's broken and why.

**Activities:**
- Analyze bug report
- Gather reproduction steps
- Identify affected files/modules
- Assess severity and impact

**Outputs:**
- `bug-report.md`
- Properties: `severity`, `affected_files`, `estimated_hours`

---

#### 2. Reproducing
**Goal:** Create a test that demonstrates the bug.

**Activities:**
- Follow reproduction steps
- Create failing test
- Verify test fails consistently
- Document expected vs actual behavior

**Outputs:**
- Failing test file
- Properties: `test_file`, `bug_reproduced`, `test_verified`

**Critical:** Test MUST fail before fix. This proves it catches the bug.

---

#### 3. Fixing
**Goal:** Implement the fix.

**Activities:**
- Fix the code
- Run the previously failing test
- Verify test now passes
- Document fix approach

**Outputs:**
- Fixed code
- Properties: `fix_approach`, `files_modified`, `test_passes`

---

#### 4. Verifying
**Goal:** Ensure fix works and no regressions.

**Activities:**
- Run ALL tests (not just the new one)
- Manual testing of original bug scenario
- Check for side effects
- Verify edge cases

**Outputs:**
- Test results
- Properties: `all_tests_pass`, `manually_verified`

**Loop Condition:** If tests fail or bug persists → return to Fixing

---

#### 5. Completing
**Goal:** Document and close.

**Activities:**
- Write fix summary
- Document root cause
- Prepare commit message
- Clean up debug code

**Outputs:**
- `fix-summary.md`
- Properties: `workflow_complete`, `commit_message`

---

## Workflow 3: sbd.refactoring

**Purpose:** Improve code quality without changing behavior.

**Stages:** 5 (analyzing → planning → refactoring → testing → completing)

**Duration:** Typically 2-16 hours depending on scope

### Flow Diagram

```
┌──────────┐
│analyzing │  Identify code smells
└────┬─────┘
     │
┌────▼────┐
│planning │  Plan refactoring strategy
└────┬────┘
     │
┌────▼────────┐
│refactoring  │  Improve code
└────┬────────┘
     │
┌────▼────┐
│testing  │  CRITICAL: Verify no behavioral changes
└────┬────┘
  ┌──┴──┐
  │  ↓  │  ← Loop back if tests fail or behavior changed
┌─▼──────▼──┐
│completing │  Document improvements
└───────────┘
```

### Key Principles

⚠️ **CRITICAL RULES:**
1. **No behavioral changes** - Functionality must remain identical
2. **All tests must pass** - 100% pass rate required
3. **Incremental steps** - Small, verifiable changes
4. **Test-driven** - Run tests after each change

### Stages

#### 1. Analyzing
**Goal:** Identify what needs refactoring.

**Activities:**
- Analyze code quality
- Identify code smells (duplication, complexity, etc.)
- Check test coverage
- List improvement opportunities

**Outputs:**
- Properties: `target_code`, `code_issues`, `current_coverage`

**Common code smells:**
- Duplicated code
- Long methods
- Large classes
- Too many parameters
- Magic numbers
- Nested conditionals

---

#### 2. Planning
**Goal:** Plan the refactoring approach.

**Activities:**
- Choose refactoring techniques
- Plan order of changes
- Identify risks
- Define success criteria

**Outputs:**
- `refactoring-plan.md`
- Properties: `strategy`, `expected_improvements`, `risks`

**Common refactoring techniques:**
- Extract Method
- Extract Class
- Rename Variable/Method
- Replace Magic Number with Constant
- Simplify Conditional Expression
- Remove Duplication

---

#### 3. Refactoring
**Goal:** Execute planned code improvements.

**Activities:**
- Apply refactoring techniques
- Make incremental changes
- Run tests after each change
- Document techniques used

**Outputs:**
- Improved code
- Properties: `files_modified`, `techniques_used`

**Best Practice:** Make smallest possible changes, test, commit, repeat.

---

#### 4. Testing
**Goal:** Verify no functionality was broken.

**Activities:**
- Run full test suite
- Check for behavioral changes
- Compare with original behavior
- Verify no regressions

**Outputs:**
- Test results
- Properties: `testing_complete`, `all_tests_pass`, `has_behavioral_changes`

**Quality Gates (STRICT):**
- ✅ All tests pass: REQUIRED
- ✅ No behavioral changes: REQUIRED
- ✅ Code coverage not decreased: REQUIRED

**Loop Condition:** If ANY test fails or behavior changed → return to Refactoring

---

#### 5. Completing
**Goal:** Document the improvements.

**Activities:**
- Document what was improved
- List techniques used
- Measure code quality improvements
- Final cleanup

**Outputs:**
- `refactoring-results.md`
- Properties: `workflow_complete`, `improvements`

---

## Event Integration

All SBD workflows emit events at key points, enabling integration with other packages.

### Standard Events

**Stage lifecycle:**
```yaml
- task.stage_started {task_id, stage}
- task.stage_completed {task_id, stage, duration_ms}
```

**Workflow lifecycle:**
```yaml
- task.workflow_started {task_id, workflow}
- task.workflow_completed {task_id, workflow, result}
```

**Quality gates:**
```yaml
- quality.gate_checked {task_id, gate_name, stage}
- quality.gate_passed {task_id, gate_name}
- quality.gate_failed {task_id, gate_name, errors}
```

### Example Integrations

**With git-vcs package:**
```yaml
# git-vcs listens to task.stage_completed
on event: task.stage_completed
  if stage == "implementing":
    → VCS.commit()
    → VCS.push()
```

**With qa-gates package:**
```yaml
# qa-gates listens to task.stage_completed
on event: task.stage_completed
  if stage in ["designing", "implementing", "verifying"]:
    → QA_GATE.validate()
    → emit quality.gate_passed or quality.gate_failed
```

**With notifications package:**
```yaml
# notifications listens to task.workflow_completed
on event: task.workflow_completed:
  → NOTIFIER.send_slack("Task {task_id} completed!")
```

---

## Usage Examples

### Example 1: Start Feature Development

```yaml
# User: /cm-start sbd.feature FEAT-001

instructions:
  - TASK.create("FEAT-001", "Add user notifications", specs, user, "sbd.feature")
  - EVENT.emit("task.created", {task_id: "FEAT-001"})
  - WORKFLOW.start("FEAT-001", "sbd.feature")
  # → Enters creating stage automatically
```

### Example 2: Move Through Workflow

```yaml
# User: /cm-next

instructions:
  # Check postconditions of current stage
  - if: !all_postconditions_met():
    then:
      - error: "Cannot proceed. Complete current stage first."
  
  # Transition to next stage
  - let: next_stage = WORKFLOW.next("FEAT-001")
  - TASK.set_state("FEAT-001", next_stage)
  - execute_stage_logic(next_stage)
```

### Example 3: Bug Fix Workflow

```yaml
# User: /cm-start sbd.bugfix BUG-042

instructions:
  - TASK.create("BUG-042", "Login fails on Safari", bug_report, user, "sbd.bugfix")
  - WORKFLOW.start("BUG-042", "sbd.bugfix")
  
  # Workflow progresses:
  # 1. investigating → understand the issue
  # 2. reproducing → create failing test
  # 3. fixing → fix code, test passes
  # 4. verifying → all tests pass
  # 5. completing → document fix
```

---

## Configuration

### Default Settings

```yaml
# packages/sbd/package.yml
config_template:
  sbd:
    default_workflow: "sbd.feature"
    artifacts_in_task_folder: true
    auto_git_integration: false
```

### Project Override

```yaml
# .cm/project.yml
packages:
  sbd:
    default_workflow: "sbd.bugfix"  # Default to bugfix for maintenance projects
    auto_git_integration: true      # Enable automatic commits
    quality_gates:
      verifying:
        min_coverage: 85            # Require 85% coverage
        max_linter_errors: 0        # No linter errors allowed
```

---

## Best Practices

### ✅ DO

**Follow stage isolation**
```yaml
# Good - stage knows only about itself
- TASK.set_property(task_id, "design_complete", true)

# Bad - stage knows about next stage
- TASK.set_property(task_id, "next_stage", "implementing")
```

**Use properties for coordination**
```yaml
# Stage 1 sets property
- TASK.set_property(task_id, "specs_ready", true)

# Stage 2 checks property (in preconditions)
preconditions:
  - TASK.get_property(task_id, "specs_ready") == true
```

**Log significant events**
```yaml
- TASK.log(task_id, "Design review completed. 3 alternatives considered.")
- TASK.log(task_id, "Implementation: 12 files created, 8 modified")
```

**Emit events for integration points**
```yaml
- EVENT.emit("task.stage_completed", {
    task_id: task_id,
    stage: "designing",
    duration_ms: elapsed_time
  })
```

---

### ❌ DON'T

**Don't skip stages**
```yaml
# Bad
- TASK.set_state(task_id, "implementing")  # Skipped analyzing and designing!

# Good
- WORKFLOW.next(task_id)  # Proper progression
```

**Don't bypass preconditions**
```yaml
# Bad - ignoring precondition failures
preconditions:
  - TASK.get_property(task_id, "analysis_complete") == true

instructions:
  # Just proceed anyway... NO!

# Good - handle precondition failures
instructions:
  - if: !TASK.get_property(task_id, "analysis_complete"):
    then:
      - error: "Cannot start design without completed analysis"
```

**Don't put stage logic in workflow.yml**
```yaml
# Bad - workflow.yml should only define graph
transitions:
  - from: analyzing
    to: designing
    execute:  # NO! Logic belongs in states/
      - do_analysis()
      - prepare_design()

# Good - clean transition definition
transitions:
  - from: analyzing
    to: designing
    description: "Analysis complete, ready to design"
```

---

## Troubleshooting

### Stuck in a Stage

**Symptom:** Cannot progress to next stage

**Diagnosis:**
```yaml
# Check postconditions
- let: state = TASK.get_state(task_id)
- info: "Current state: {state}"
- let: props = TASK.get_all_properties(task_id)
- info: "Properties: {yaml(props)}"
```

**Solution:** Complete missing postconditions or use `/cm-rework` to return to previous stage

---

### Wrong Workflow Chosen

**Symptom:** Task is in wrong workflow (e.g., feature when should be bugfix)

**Solution:** 
```bash
# Currently no built-in workflow migration
# Workaround: Create new task with correct workflow
/cm-start sbd.bugfix BUG-042
# Copy relevant info from old task manually
```

---

### Quality Gate Failures

**Symptom:** `quality.gate_failed` event, cannot proceed

**Diagnosis:**
```yaml
- let: log = TASK.get_log(task_id)
- info: "Check log for quality gate details:\n{log}"
```

**Solution:** Address quality issues and retry verification

---

## Performance

### Workflow Duration Estimates

| Workflow | Minimum | Typical | Maximum |
|----------|---------|---------|---------|
| feature | 4 hours | 1-3 days | 2 weeks |
| bugfix | 30 min | 2-4 hours | 1 day |
| refactoring | 1 hour | 4-8 hours | 2 days |

### Optimization Tips

1. **Parallelize when possible** - Multiple developers on different stages (not same task)
2. **Prepare artifacts early** - Gather requirements before starting
3. **Use templates** - Reusable design/test templates
4. **Automate quality gates** - Let qa-gates package handle checks

---

## Extending SBD

### Add Custom Workflow

```yaml
# packages/sbd/workflows/spike/workflow.yml
name: sbd.spike
description: "Spike for research and prototyping"

states:
  - researching
  - prototyping
  - evaluating
  - documenting

transitions:
  - from: null
    to: researching
  - from: researching
    to: prototyping
  # ...
```

### Add Custom Stage

```yaml
# packages/sbd/workflows/feature/states/code-review.yml
name: code-review
description: "Peer code review stage"

instructions:
  - ask: "Reviewer name?"
    into: reviewer
  - ask: "Review comments?"
    into: comments
  - TASK.set_property(task_id, "review_approved", true)
```

---

## Comparison with Other Methodologies

| Aspect | SBD | Scrum | Kanban | Waterfall |
|--------|-----|-------|--------|-----------|
| **Structure** | Fixed stages | Sprints | Continuous flow | Sequential phases |
| **Flexibility** | Medium | High | Very high | Low |
| **AI-friendly** | ✅ Yes | ⚠️ Partial | ⚠️ Partial | ✅ Yes |
| **Stage isolation** | ✅ Strong | ❌ Weak | ❌ None | ✅ Strong |
| **Best for** | AI collaboration | Teams | Operations | Large projects |

**SBD Advantages for AI:**
- Clear stage boundaries help AI understand context
- Explicit preconditions/postconditions enable validation
- Event system allows AI to coordinate actions
- Structured progression prevents confusion

---

## Contributing

To improve SBD workflows:

1. **Test on real projects** - Report what works/doesn't
2. **Suggest stage improvements** - Better instructions, checks
3. **Create new workflows** - Different development patterns
4. **Improve event integration** - Better coordination

See main `CONTRIBUTING.md`.

---

## License

MIT License - Part of ClearMethod framework.

---

## See Also

- [WORKFLOW Concept](../../docs/core/concepts/core.md#3-workflow)
- [Events System](../../docs/core/concepts/events.md)
- [File-Task Package](../file-task/) - Task storage
- [Git-VCS Package](../git-vcs/) - Git automation
- [QA-Gates Package](../qa-gates/) - Quality checks

