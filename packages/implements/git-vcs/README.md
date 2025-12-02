# Git VCS Package

Git-based Version Control System integration for ClearMethod workflows.

## Overview

`git-vcs` provides seamless git integration for AI-driven development workflows. It automates version control operations based on workflow events, ensuring consistent commit practices and streamlined collaboration.

**Key Features:**
- ✅ **Event-driven automation** - Auto-commit on stage completion
- ✅ **Safety first** - Protected branches, validation, no force push to main
- ✅ **Workflow integration** - Tight coupling with SBD workflows
- ✅ **PR automation** - Auto-create pull requests on workflow completion
- ✅ **Comprehensive API** - Full git operations available
- ✅ **Conventional commits** - Structured commit messages

**Philosophy:** Version control should be automatic where safe, manual where critical.

---

## Installation

The `git-vcs` package is included in ClearMethod core setup.

**Manual installation:**
```bash
# Copy package to project
cp -r packages/git-vcs .cm/packages/

# Update project.yml
```

```yaml
# .cm/project.yml
concept_implementations:
  VCS: git-vcs.GIT_VCS

packages:
  git_vcs:
    auto_commit:
      enabled: true
      stages: [implementing, completing]
```

**Dependencies:**
- `file-task` - Task storage
- `basic-events` - Event system
- `git` CLI tool (system requirement)
- `gh` CLI tool (optional, for PR creation)

---

## Quick Start

### Enable Auto-Commit

```yaml
# .cm/project.yml
packages:
  git_vcs:
    auto_commit:
      enabled: true
      stages:
        - implementing
        - completing
      message_template: "feat({{task_id}}): {{stage}} completed"
```

Now when you complete `implementing` or `completing` stages, changes are automatically committed.

### Manual Commit

```yaml
# In workflow state or command
instructions:
  - VCS.commit("feat: add user authentication", [], false)
```

### Create Feature Branch

```yaml
instructions:
  - VCS.create_branch("feature/TASK-123", "main", true)
  # Work on feature...
  - VCS.commit("feat: implement feature", [], true)  # commit + push
```

---

## API Reference

### VCS.commit(message, files?, push?)

Stage and commit changes.

**Parameters:**
- `message` (string, required) - Commit message (min 3 chars)
- `files` (array<string>, optional) - Specific files to commit (empty = all)
- `push` (boolean, optional) - Push after commit (default: false)

**Returns:**
```yaml
{
  commit_hash: "a1b2c3d4...",
  files_changed: 5,
  pushed: false,
  message: "feat: add feature"
}
```

**Events emitted:**
- `vcs.commit_created`

**Example:**
```yaml
# Commit all changes
- VCS.commit("feat: add user profile page")

# Commit specific files
- VCS.commit("fix: correct validation", ["src/validator.js", "tests/validator.test.js"])

# Commit and push
- VCS.commit("feat: complete feature", [], true)
```

**Validation:**
- ✅ Message length: 3-100 characters
- ✅ Files exist
- ✅ Changes present
- ⚠️ Warns if message > 100 chars

---

### VCS.push(branch?, force?)

Push commits to remote repository.

**Parameters:**
- `branch` (string, optional) - Branch to push (default: current)
- `force` (boolean, optional) - Force push (default: false, NOT RECOMMENDED)

**Returns:**
```yaml
{
  success: true,
  commits_pushed: 3,
  branch: "feature/TASK-123"
}
```

**Events emitted:**
- `vcs.push_completed`

**Example:**
```yaml
# Push current branch
- VCS.push()

# Push specific branch
- VCS.push("feature/new-feature")

# Force push (USE WITH CAUTION)
- VCS.push("my-branch", true)
```

**Safety:**
- ❌ Cannot force push to protected branches (main, master, production)
- ✅ Checks for unpushed commits before pushing
- ✅ Returns early if nothing to push

---

### VCS.get_status()

Get current repository status.

**Parameters:** None

**Returns:**
```yaml
{
  branch: "feature/TASK-123",
  modified: ["src/file.js", "README.md"],
  staged: ["src/new.js"],
  untracked: ["temp.txt"],
  ahead: 2,
  behind: 0,
  clean: false
}
```

**Example:**
```yaml
- let: status = VCS.get_status()

- if: !status.clean
  then:
    - warn: "You have {status.modified.length} modified file(s)"

- if: status.ahead > 0
  then:
    - info: "{status.ahead} commit(s) not pushed"
```

---

### VCS.get_diff(file?, staged?)

Get diff of changes.

**Parameters:**
- `file` (string, optional) - Specific file (empty = all changes)
- `staged` (boolean, optional) - Show staged changes only (default: false)

**Returns:** string (diff output)

**Example:**
```yaml
# All unstaged changes
- VCS.get_diff()
  into: diff

# Staged changes only
- VCS.get_diff(null, true)
  into: staged_diff

# Specific file
- VCS.get_diff("src/feature.js")
  into: file_diff

- info: "Changes:\n{diff}"
```

---

### VCS.create_branch(branch_name, from_branch?, checkout?)

Create a new branch.

**Parameters:**
- `branch_name` (string, required) - Name for new branch
- `from_branch` (string, optional) - Base branch (default: current)
- `checkout` (boolean, optional) - Switch to new branch (default: true)

**Returns:**
```yaml
{
  branch: "feature/TASK-123",
  from_branch: "main",
  checked_out: true
}
```

**Events emitted:**
- `vcs.branch_created`

**Example:**
```yaml
# Create and checkout
- VCS.create_branch("feature/new-feature")

# Create from specific branch
- VCS.create_branch("hotfix/bug-123", "production")

# Create but don't checkout
- VCS.create_branch("backup", "main", false)
```

**Validation:**
- ✅ Branch name: only `a-z`, `A-Z`, `0-9`, `-`, `_`, `/`
- ✅ Branch must not already exist
- ✅ Base branch must exist

---

### VCS.switch_branch(branch_name)

Switch to a different branch.

**Parameters:**
- `branch_name` (string, required) - Branch to switch to

**Returns:**
```yaml
{
  previous_branch: "main",
  current_branch: "feature/TASK-123"
}
```

**Example:**
```yaml
- VCS.switch_branch("main")

- info: "Switched to {result.current_branch}"
```

**Safety:**
- ⚠️ Warns if uncommitted changes present
- ✅ Changes carry over to new branch

---

### VCS.create_pr(title, description?, base_branch?, source_branch?)

Create pull request (requires GitHub CLI).

**Parameters:**
- `title` (string, required) - PR title
- `description` (string, optional) - PR description
- `base_branch` (string, optional) - Target branch (default: "main")
- `source_branch` (string, optional) - Source branch (default: current)

**Returns:**
```yaml
{
  pr_number: 42,
  pr_url: "https://github.com/owner/repo/pull/42",
  title: "Add user authentication",
  base_branch: "main",
  source_branch: "feature/auth"
}
```

**Events emitted:**
- `vcs.pr_created`

**Example:**
```yaml
# Simple PR
- VCS.create_pr("Add user authentication")

# Detailed PR
- VCS.create_pr(
    "Add user authentication",
    "This PR implements JWT-based authentication with refresh tokens.",
    "develop",
    "feature/auth-jwt"
  )
```

**Requirements:**
- ✅ GitHub CLI (`gh`) installed and authenticated
- ✅ Source branch has commits ahead of base
- ✅ Source and base branches are different

---

### VCS.get_log(limit?, branch?)

Get commit history.

**Parameters:**
- `limit` (number, optional) - Number of commits (default: 10)
- `branch` (string, optional) - Branch to show log for (default: current)

**Returns:**
```yaml
[
  {
    hash: "a1b2c3d4e5f6...",
    author: "John Doe",
    author_email: "john@example.com",
    date: "2025-11-25 10:30:00 +0000",
    message: "feat: add feature"
  },
  ...
]
```

**Example:**
```yaml
# Last 5 commits
- VCS.get_log(5)
  into: recent_commits

- for: commit in recent_commits
  do:
    - info: "{commit.hash.substring(0, 7)} - {commit.message}"

# Specific branch
- VCS.get_log(20, "main")
  into: main_history
```

---

## Event-Driven Automation

Git-VCS automatically reacts to workflow events for seamless integration.

### Auto-Commit on Stage Completion

**Event:** `task.stage_completed`

**Behavior:**
1. Check if `auto_commit.enabled` is true
2. Check if stage is in `auto_commit.stages` list
3. Check for changes (`VCS.get_status()`)
4. Build commit message from template
5. Commit all changes
6. Optionally push (if `auto_push` configured)

**Configuration:**
```yaml
packages:
  git_vcs:
    auto_commit:
      enabled: true
      stages:
        - implementing
        - completing
      message_template: "feat({{task_id}}): {{stage}} completed"
    
    auto_push:
      enabled: true
      on_stages:
        - completing
      require_tests: true
```

**Template variables:**
- `{{task_id}}` - Task ID
- `{{stage}}` - Current stage name
- `{{task_title}}` - Task title
- `{{duration}}` - Stage duration in seconds

---

### Auto-PR on Workflow Completion

**Event:** `task.workflow_completed`

**Behavior:**
1. Check if `auto_pr.enabled` and `auto_pr.on_workflow_complete` are true
2. Check if workflow completed successfully
3. Check if on feature branch (not on base branch)
4. Check for commits ahead of base
5. Build PR title and description
6. Create PR using GitHub CLI

**Configuration:**
```yaml
packages:
  git_vcs:
    auto_pr:
      enabled: true
      on_workflow_complete: true
      title_template: "[{{task_id}}] {{task_title}}"
      include_summary: true
    
    branch_strategy:
      base_branch: "develop"
```

**PR Description includes:**
- Task ID and title
- Workflow name
- List of commits with hashes
- Task log summary (if `include_summary: true`)

---

## Events Emitted

Git-VCS emits events for other packages to react to:

### vcs.commit_created

Emitted after successful commit.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  commit_hash: "a1b2c3d4...",
  message: "feat: add feature",
  files_changed: 5,
  timestamp: "2025-11-25T10:30:00Z"
}
```

**Use cases:**
- QA gates package runs linter on committed files
- Notification package sends Slack message
- Documentation package updates changelog

---

### vcs.push_completed

Emitted after successful push.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  branch: "feature/TASK-123",
  commits_pushed: 3,
  timestamp: "2025-11-25T10:31:00Z"
}
```

**Use cases:**
- CI/CD package triggers build
- Notification package alerts team

---

### vcs.branch_created

Emitted after branch creation.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  branch_name: "feature/TASK-123",
  from_branch: "main",
  timestamp: "2025-11-25T10:00:00Z"
}
```

---

### vcs.pr_created

Emitted after PR creation.

**Payload:**
```yaml
{
  task_id: "TASK-123",
  pr_number: 42,
  pr_url: "https://github.com/owner/repo/pull/42",
  title: "Add feature",
  timestamp: "2025-11-25T11:00:00Z"
}
```

**Use cases:**
- Notification package sends PR link to team
- Task package updates task with PR link
- QA gates package triggers PR checks

---

## Configuration

### Default Configuration

```yaml
# packages/git-vcs/package.yml (defaults)
config_template:
  git_vcs:
    auto_commit:
      enabled: false
      stages: [implementing, completing]
      message_template: "feat({{task_id}}): {{stage}} completed"
    
    auto_push:
      enabled: false
      on_stages: [completing]
      require_tests: true
    
    branch_strategy:
      enabled: false
      pattern: "task/{{task_id}}"
      create_on_start: false
      base_branch: "main"
    
    auto_pr:
      enabled: false
      on_workflow_complete: false
      title_template: "{{task_title}}"
      include_summary: true
    
    commit_format:
      convention: "conventional"
      validate: true
      scopes_allowed: []
    
    protected_branches:
      - main
      - master
      - production
      - develop
    
    force_push_allowed: false
    
    remote_provider: "github"
    remote_url: ""
```

### Project Configuration

Override in `.cm/project.yml`:

```yaml
packages:
  git_vcs:
    # Enable auto-commit for implementing and completing stages
    auto_commit:
      enabled: true
      stages:
        - implementing
        - completing
      message_template: "feat({task_id}): {stage} - {{task_title}}"
    
    # Push automatically after completing stage
    auto_push:
      enabled: true
      on_stages:
        - completing
      require_tests: true  # Only push if tests passed
    
    # Create feature branch on task start
    branch_strategy:
      enabled: true
      pattern: "feature/{{task_id}}-{{task_title_slug}}"
      create_on_start: true
      base_branch: "develop"
    
    # Create PR when workflow completes
    auto_pr:
      enabled: true
      on_workflow_complete: true
      title_template: "[{{task_id}}] {{task_title}}"
      include_summary: true
    
    # Use conventional commits
    commit_format:
      convention: "conventional"  # feat:, fix:, chore:, etc.
      validate: true
      scopes_allowed: [api, ui, db, auth]
    
    # Protected branches (no force push allowed)
    protected_branches:
      - main
      - develop
      - production
      - staging
    
    # GitHub as remote provider
    remote_provider: "github"
    remote_url: "https://github.com/org/repo"
```

---

## Best Practices

### ✅ DO

**Use auto-commit for non-critical stages**
```yaml
# Good - auto-commit for implementation
auto_commit:
  stages: [implementing]
```

**Check status before operations**
```yaml
# Good - check before committing
- let: status = VCS.get_status()
- if: !status.clean
  then:
    - VCS.commit("feat: ...")
```

**Use conventional commits**
```yaml
# Good - structured commit messages
- VCS.commit("feat(auth): add JWT authentication")
- VCS.commit("fix(api): handle null response")
- VCS.commit("docs: update README")
```

**Log VCS operations to task**
```yaml
# Good - audit trail
- VCS.commit("feat: add feature")
  into: result
- TASK.log(task_id, "Committed: {result.commit_hash}")
```

**Use feature branches**
```yaml
# Good - isolate features
- VCS.create_branch("feature/{task_id}")
# Work on feature
- VCS.commit("feat: implement")
- VCS.create_pr("Add feature")
```

---

### ❌ DON'T

**Don't force push to protected branches**
```yaml
# Bad - dangerous!
- VCS.push("main", true)

# Good - never force push main
- VCS.push("my-feature-branch")
```

**Don't commit without checking**
```yaml
# Bad - blind commit
- VCS.commit("changes")

# Good - check first
- let: status = VCS.get_status()
- if: status.modified.length > 0
  then:
    - VCS.commit("...")
```

**Don't use vague commit messages**
```yaml
# Bad - no context
- VCS.commit("update")
- VCS.commit("fix")
- VCS.commit("changes")

# Good - clear and descriptive
- VCS.commit("feat(api): add user endpoints")
- VCS.commit("fix(ui): correct button alignment")
```

**Don't auto-push without tests**
```yaml
# Bad - push broken code
auto_push:
  require_tests: false

# Good - verify tests first
auto_push:
  require_tests: true
```

---

## Troubleshooting

### Cannot commit: "No changes to commit"

**Symptom:** `VCS.commit()` returns `files_changed: 0`

**Diagnosis:**
```yaml
- let: status = VCS.get_status()
- info: "Modified: {status.modified}"
- info: "Staged: {status.staged}"
- info: "Untracked: {status.untracked}"
```

**Solution:** Check if files are in `.gitignore` or outside repository

---

### Force push blocked

**Symptom:** Error: "Force push to protected branch 'main' is not allowed"

**Solution:** Never force push to main/master/production. Use feature branches.

---

### PR creation fails

**Symptom:** Error: "GitHub CLI (gh) not installed"

**Solution:**
```bash
# Install GitHub CLI
# macOS
brew install gh

# Linux
sudo apt install gh

# Authenticate
gh auth login
```

---

### Auto-commit not working

**Symptom:** Completing stage doesn't trigger commit

**Diagnosis:**
```yaml
# Check configuration
- read: ".cm/project.yml"
  into: config
- info: "Auto-commit enabled: {config.packages.git_vcs.auto_commit.enabled}"
- info: "Stages: {config.packages.git_vcs.auto_commit.stages}"
```

**Solutions:**
1. Verify `auto_commit.enabled: true`
2. Check stage name is in `stages` list
3. Verify event handler is subscribed (`EVENT.list_subscriptions()`)

---

## Integration Examples

### With SBD Workflows

```yaml
# .cm/project.yml
workflows:
  default: sbd.feature

packages:
  git_vcs:
    auto_commit:
      enabled: true
      stages: [implementing, completing]
    auto_pr:
      enabled: true
      on_workflow_complete: true
```

**Flow:**
1. Start feature: `/cm-start sbd.feature FEAT-001`
2. Create branch: `VCS.create_branch("feature/FEAT-001")`
3. Implement → auto-commit after stage
4. Complete → auto-commit + auto-push
5. Workflow completes → auto-create PR

---

### With QA Gates

```yaml
# qa-gates handler listens to vcs.commit_created
on event: vcs.commit_created
  → QA_GATE.run_linter()
  → QA_GATE.run_tests()
  → emit quality.gate_passed or quality.gate_failed
```

If quality gate fails, auto-push is blocked.

---

### With Notifications

```yaml
# notifications handler listens to vcs.pr_created
on event: vcs.pr_created
  → NOTIFIER.send_slack("PR created: {event.payload.pr_url}")
```

---

## Performance

### Operation Times

| Operation | Typical Time | Notes |
|-----------|--------------|-------|
| get_status() | 50-100ms | Fast, no network |
| commit() | 100-500ms | Local only |
| push() | 1-5s | Network dependent |
| create_branch() | 50-100ms | Local only |
| create_pr() | 2-10s | GitHub API call |

### Optimization Tips

1. **Batch commits** - Don't commit after every file change
2. **Lazy push** - Push only when necessary (completing stage)
3. **Cache status** - Don't call `get_status()` repeatedly
4. **Use filters** - Event handlers filter by config to avoid unnecessary checks

---

## Security

### Protected Branches

Git-VCS enforces protection for specified branches:

```yaml
protected_branches:
  - main
  - master
  - production
  - develop
```

**Restrictions:**
- ❌ No force push
- ⚠️ All operations logged
- ✅ Normal push allowed (with permissions)

---

### Commit Message Validation

Optional validation for conventional commits:

```yaml
commit_format:
  convention: "conventional"
  validate: true
  scopes_allowed: [api, ui, db]
```

**Format:** `<type>(<scope>): <description>`

**Types:** feat, fix, docs, style, refactor, test, chore

---

## Comparison

| Feature | Git-VCS | Manual Git | GitHub Actions |
|---------|---------|------------|----------------|
| **Auto-commit** | ✅ Yes | ❌ No | ⚠️ Partial |
| **Workflow integration** | ✅ Tight | ❌ No | ⚠️ Loose |
| **Safety checks** | ✅ Built-in | ⚠️ Manual | ✅ Configurable |
| **Event-driven** | ✅ Yes | ❌ No | ✅ Yes |
| **AI-friendly** | ✅ CML API | ❌ CLI only | ❌ YAML config |

**Git-VCS Advantages:**
- Automatic version control integrated with workflow stages
- Safety checks prevent dangerous operations
- Event system enables reactive programming
- CML API is AI-friendly

---

## Contributing

To improve git-vcs:

1. **Add remote providers** - GitLab, Bitbucket support
2. **Enhance PR creation** - Add labels, reviewers, assignees
3. **Improve validation** - Better commit message checking
4. **Add git hooks** - Pre-commit, pre-push hooks

See main `CONTRIBUTING.md`.

---

## License

MIT License - Part of ClearMethod framework.

---

## See Also

- [VCS Concept](../../docs/core/concepts/vcs.md)
- [Events System](../../docs/core/concepts/events.md)
- [SBD Package](../sbd/) - Workflow integration
- [QA-Gates Package](../qa-gates/) - Quality checks
- [GitHub CLI](https://cli.github.com/) - For PR creation

