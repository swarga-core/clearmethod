# Git VCS Package - Agent Primer

## Концепт

**GIT_VCS** - конкретная реализация абстрактного концепта **VCS**.

Предоставляет git-операции для управления версионным контролем.

## Методы

### Основные операции

```yaml
# Закоммитить изменения
VCS.commit(message, files?, push?)
# → {commit_hash, files_changed, pushed}

# Запушить коммиты
VCS.push(branch?, force?)
# → {success, commits_pushed}

# Получить статус репозитория
VCS.get_status()
# → {branch, modified, staged, untracked, ahead, behind, clean}

# Получить diff
VCS.get_diff(file?, staged?)
# → string (diff output)
```

### Работа с ветками

```yaml
# Создать ветку
VCS.create_branch(branch_name, from_branch?, checkout?)
# → {branch, from_branch, checked_out}

# Переключиться на ветку
VCS.switch_branch(branch_name)
# → {previous_branch, current_branch}

# Получить историю коммитов
VCS.get_log(limit?, branch?)
# → [{hash, author, date, message}, ...]
```

### Pull Requests

```yaml
# Создать PR (требует GitHub CLI)
VCS.create_pr(title, description?, base_branch?, source_branch?)
# → {pr_number, pr_url}
```

## Автоматизация через события

Git-VCS слушает события и автоматически выполняет операции:

### Auto-commit на завершении стадий

```yaml
# Подписка на событие
on: task.stage_completed

# Если stage в списке auto_commit.stages → VCS.commit()
```

### Auto-PR на завершении workflow

```yaml
# Подписка на событие
on: task.workflow_completed

# Если workflow успешен → VCS.create_pr()
```

## События

Git-VCS эмитит события:

```yaml
vcs.commit_created       # После коммита
vcs.push_completed       # После пуша
vcs.branch_created       # После создания ветки
vcs.pr_created           # После создания PR
vcs.operation_failed     # При ошибке
```

## Безопасность

**Защищенные ветки** (по умолчанию: main, master, production):
- ❌ Force push запрещен
- ⚠️ Все операции логируются

**Валидация**:
- Commit message: минимум 3 символа
- Branch name: только a-z, A-Z, 0-9, -, _, /
- Предупреждение о uncommitted changes

## Примеры использования

### Коммит после реализации

```yaml
instructions:
  # Implement feature
  - write: "src/feature.js"
    contents: code
  
  # Commit automatically via event
  # OR manually:
  - VCS.commit("feat: add new feature", ["src/feature.js"], false)
```

### Создание feature branch

```yaml
instructions:
  # Create branch for task
  - let: branch_name = "feature/{task_id}"
  - VCS.create_branch(branch_name, "main", true)
  
  # Work on feature...
  
  # Commit and push
  - VCS.commit("feat: implement feature", [], true)
```

### Проверка статуса перед действием

```yaml
instructions:
  - let: status = VCS.get_status()
  
  - if: !status.clean
    then:
      - warn: "Uncommitted changes: {status.modified.length} modified files"
  
  - if: status.ahead > 0
    then:
      - VCS.push()
```

## Конфигурация

Читается из `.cm/project.yml`:

```yaml
packages:
  git_vcs:
    auto_commit:
      enabled: true
      stages: [implementing, completing]
      message_template: "feat({{task_id}}): {{stage}} completed"
    
    auto_push:
      enabled: true
      on_stages: [completing]
      require_tests: true
    
    protected_branches:
      - main
      - production
```

## Важно

1. **Всегда проверяй статус** перед git-операциями
2. **Не force push** на protected branches
3. **Логируй операции** в task log
4. **Проверяй наличие gh CLI** перед созданием PR
5. **Используй conventional commits** для consistency

## Интеграция с workflow

Git-VCS автоматически интегрируется с SBD workflows:

- **implementing stage** → auto-commit
- **completing stage** → auto-commit + auto-push
- **workflow complete** → auto-create PR

Всё настраивается в конфиге!

