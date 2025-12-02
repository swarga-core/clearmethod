# Концепты пакетов ClearMethod

> **Доменно-специфичные концепты, расширяющие возможности ядра**

---

## Философия пакетов

Расширения добавляют функциональность, специфичную для определенных доменов или практик:
- **Опциональны** - подключаются по выбору проекта
- **Независимы** - не изменяют ядро
- **Композируемы** - можно комбинировать разные пакета
- **Реализуют концепты** - предоставляют новые концепты с методами

---

## FILE_TASK (для MVP)

**Тип**: Конкретная реализация (implements TASK)

**Назначение**: Простое файловое хранилище задач без сложной логики.

**Философия**: Минимализм. Задачи хранятся как папки с файлами. Легко понять, легко отладить.

**Реализует**: Абстрактный концепт TASK из ядра (см. [core.md](core.md#2-task))

**Структура хранения**:
```
.cm/
  tasks/
    TASK-123/
      status.yml      # Состояние задачи (свойства)
      specs.md        # Спецификация
      design.md       # Дизайн (создается в процессе)
      log.md          # Журнал действий
    TASK-124/
      ...
```

### Конфигурация

```yaml
# extension.yml
extension:
  id: file-task
  name: "File-based Task Storage"
  implements: [TASK]  # Реализует интерфейс TASK

config:
  tasks_root: ".cm/tasks"
  status_file: "status.yml"
  log_file: "log.md"
```

### Свойства

- `tasks_root: string` - корневая папка задач (по умолчанию `.cm/tasks`)
- `status_file: string` - имя файла состояния (по умолчанию `status.yml`)
- `log_file: string` - имя файла журнала (по умолчанию `log.md`)

### Методы

#### create(task_id, workflow_id, title, specs)
Создает новую задачу в файловой системе.

```yaml
execute:
  - let: TASK_FOLDER = "{tasks_root}/{task_id}"
  - do: "Create folder {TASK_FOLDER}"
  - do: "Create status.yml from template"
  - do: "Set status.yml: id={task_id}, workflow={workflow_id}, title={title}"
  - do: "Create specs.md with {specs}"
  - do: "Create log.md with creation entry"
```

#### get_state(task_id) → string
Читает текущее состояние из `status.yml`.

```yaml
execute:
  - let: STATUS_FILE = "{tasks_root}/{task_id}/status.yml"
  - do: "Read 'status' field from {STATUS_FILE}"
  - return: status_value
```

#### set_state(task_id, state)
Обновляет состояние в `status.yml`.

```yaml
execute:
  - let: STATUS_FILE = "{tasks_root}/{task_id}/status.yml"
  - do: "Update 'status' field in {STATUS_FILE} to {state}"
  - do: "Update 'last_updated_at' field to current datetime"
```

#### get_property(task_id, name) → value
Читает свойство из `status.yml`.

```yaml
execute:
  - let: STATUS_FILE = "{tasks_root}/{task_id}/status.yml"
  - do: "Read '{name}' field from {STATUS_FILE}"
  - return: property_value
```

#### set_property(task_id, name, value)
Устанавливает свойство в `status.yml`.

```yaml
execute:
  - let: STATUS_FILE = "{tasks_root}/{task_id}/status.yml"
  - do: "Update '{name}' field in {STATUS_FILE} to {value}"
  - do: "Update 'last_updated_at' to current datetime"
```

#### log(task_id, entry)
Добавляет запись в журнал задачи.

```yaml
execute:
  - let: LOG_FILE = "{tasks_root}/{task_id}/log.md"
  - do: "Append to {LOG_FILE}: [{datetime}] {entry}"
```

#### get_log(task_id) → array
Читает весь журнал задачи.

```yaml
execute:
  - let: LOG_FILE = "{tasks_root}/{task_id}/log.md"
  - do: "Read all lines from {LOG_FILE}"
  - return: log_lines
```

### Структура status.yml

```yaml
id: TASK-123
title: "Add notification system"
workflow: feature
status: designing
created_at: 2025-11-23T10:30:00Z
created_by: andrey
last_updated_at: 2025-11-23T12:45:00Z
last_updater: ai-agent

# Кастомные свойства (устанавливаются workflow)
specs_ready: true
design_completed: false
priority: high
```

### Пример использования

```yaml
# Создание задачи
- do: FILE_TASK.create("TASK-123", "feature", "Add notifications", "User story: ...")

# Работа с состоянием
- do: FILE_TASK.set_state("TASK-123", "designing")
- let: current_state = FILE_TASK.get_state("TASK-123")

# Работа со свойствами
- do: FILE_TASK.set_property("TASK-123", "priority", "high")
- let: priority = FILE_TASK.get_property("TASK-123", "priority")

# Логирование
- do: FILE_TASK.log("TASK-123", "Started design phase")
```

---

## VCS (planned, не для MVP)

**Назначение**: Абстракция над системой контроля версий.

**Философия**: Один интерфейс для разных VCS (git, hg, svn). Расширения реализуют специфику.

**Свойства**:
- `id: string` - идентификатор реализации (например, "git")

**Методы**:
- `checkout(branch)` - переключиться на ветку
- `commit(message, files)` - создать коммит
- `push(remote, branch)` - отправить изменения
- `pull(remote, branch)` - получить изменения
- `create_branch(name)` - создать ветку
- `merge(branch)` - слить ветку

**Пример**:
```yaml
execute:
  - do: VCS.create_branch("feature/notifications")
  - do: VCS.checkout("feature/notifications")
  - do: "... implement feature ..."
  - do: VCS.commit("Add notification system", ["src/notifications/*"])
  - do: VCS.push("origin", "feature/notifications")
```

---

## KANBAN (planned, не для MVP)

**Назначение**: Управление доской задач с колонками.

**Философия**: Абстракция над хранилищем задач. Может быть файловая система, MCP к Jira, и т.д.

**Свойства**:
- `id: string` - идентификатор реализации
- `columns: array<string>` - список колонок (например, ["backlog", "in_progress", "done"])
- `start_column: string` - начальная колонка
- `finish_column: string` - финальная колонка

**Методы**:
- `move(task_id, to_column)` - переместить задачу между колонками
- `list(column) → array<task_id>` - список задач в колонке

**File-based реализация**:
```
.cm/
  tasks/
    backlog/
      TASK-123/
    in_progress/
      TASK-124/
    done/
      TASK-125/
```

**Пример**:
```yaml
execute:
  - do: KANBAN.move("TASK-123", "in_progress")
  # Физически перемещает папку tasks/backlog/TASK-123 
  # в tasks/in_progress/TASK-123
```

---

## Как создать свое пакет

### 1. Определить концепт

```yaml
# packages/my-extension/concept.yml
concept: MY_CONCEPT
description: "What this concept does"
version: 1.0.0

properties:
  - name: some_property
    type: string
    description: "Purpose of this property"

dependencies:
  required: [TASK]  # Обязательные зависимости
  optional: [VCS]   # Опциональные зависимости
```

### 2. Описать методы

```yaml
# packages/my-extension/methods/do_something.yml
method: do_something
description: "What this method does"

parameters:
  - name: param1
    type: string
    required: true

preconditions:
  - "Some condition that must be true"

execute:
  - do: "Step 1"
  - do: "Step 2"
  - do: TASK.log("Did something")

postconditions:
  - "Condition to verify success"
```

### 3. Создать primer (опционально)

```markdown
<!-- packages/my-extension/primer.md -->
# MY_CONCEPT Extension

This extension provides...

## Methods
- `do_something(param1)` - Does something useful

## Example
...
```

### 4. Добавить в priming.yml проекта

```yaml
primers:
  extensions:
    - .cm/packages/my-extension/primer.md
```

---

## Принципы разработки пакетов

### 1. Минимальные зависимости
Зависите только от того, что действительно нужно. Это делает пакет более переиспользуемым.

### 2. Четкий интерфейс
Методы должны иметь явные входы, выходы и побочные эффекты.

### 3. Документация
Каждое пакет должно иметь primer с примерами использования.

### 4. Композируемость
Расширения должны хорошо работать вместе, не конфликтуя.

### 5. Обратная совместимость
При обновлении пакета старайтесь не ломать существующие методы.

---

**См. также:**
- [../concepts.md](../concepts.md) - Обзор и философия концептов
- [core.md](core.md) - Концепты ядра
- [advanced.md](advanced.md) - Продвинутые возможности
- [mvp-decisions.md](mvp-decisions.md) - Архитектурные решения для MVP

