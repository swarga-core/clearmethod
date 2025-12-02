# FILE_TASK Primer

> **Для ИИ-агента**: Расширение для файлового хранилища задач

---

## Что это?

**FILE_TASK** - простая реализация концепта TASK через файловую систему.

**Реализует**: `TASK` (core)

---

## Структура задачи

Каждая задача = папка с файлами:

```
.cm/tasks/
  TASK-123/
    status.yml    - свойства задачи (id, title, status, etc)
    specs.md      - спецификация задачи
    log.md        - журнал действий
    design.md     - создается в процессе workflow
    ... другие артефакты ...
```

---

## Основные методы

### Создание задачи

```
FILE_TASK.create(task_id, title, content, creator, workflow)
```

**Создает**:
- Папку `.cm/tasks/{task_id}/`
- Файл `status.yml` с базовыми свойствами
- Файл `specs.md` с описанием
- Файл `log.md` с первой записью

**Пример**:
```
FILE_TASK.create("TASK-123", "Add notifications", "User story...", "andrey", "psd.feature")
```

### Работа с состоянием

```
current = FILE_TASK.get_state(task_id)
FILE_TASK.set_state(task_id, new_state)
```

**Пример**:
```
FILE_TASK.set_state("TASK-123", "implementing")
current = FILE_TASK.get_state("TASK-123")  # → "implementing"
```

### Работа со свойствами

```
value = FILE_TASK.get_property(task_id, property_name)
FILE_TASK.set_property(task_id, property_name, value)
```

**Пример**:
```
FILE_TASK.set_property("TASK-123", "priority", "high")
FILE_TASK.set_property("TASK-123", "design_approved", true)
priority = FILE_TASK.get_property("TASK-123", "priority")  # → "high"
```

### Логирование

```
FILE_TASK.log(task_id, message)
log = FILE_TASK.get_log(task_id)
```

**Пример**:
```
FILE_TASK.log("TASK-123", "Started implementation phase")
FILE_TASK.log("TASK-123", "Created API endpoint /notifications")
```

---

## Формат status.yml

```yaml
id: TASK-123
title: "Add notification system"
workflow: psd.feature
status: implementing
created_at: 2025-11-23T10:00:00Z
created_by: andrey
last_updated_at: 2025-11-23T12:30:00Z
last_updater: ai-agent

# Кастомные свойства (добавляются динамически)
specs_ready: true
design_approved: true
priority: high
```

---

## Важные правила

### 1. Автоматические обновления

При любом изменении (set_state, set_property):
- Автоматически обновляется `last_updated_at`
- Автоматически обновляется `last_updater = "ai-agent"`

### 2. Логирование

Логируй ЧАСТО:
- Переходы состояний
- Важные действия
- Создание артефактов
- Ошибки и предупреждения

Формат: `[ISO8601 timestamp] message`

### 3. Проверки

Всегда проверяй:
- Существование задачи (перед любой операцией кроме create)
- Успешность записи файлов
- Postconditions после выполнения

### 4. Артефакты

Все файлы задачи хранятся в папке задачи:
- `design.md` - дизайн
- `implementation.md` - заметки по реализации
- `test-results.md` - результаты тестирования
- ... любые другие ...

---

## Типичные ошибки

❌ **Не проверил существование задачи**
```
FILE_TASK.get_state("NONEXISTENT")  # Error!
```

✅ **Правильно**
```
if exists(.cm/tasks/TASK-123):
  state = FILE_TASK.get_state("TASK-123")
```

❌ **Забыл логировать**
```
FILE_TASK.set_state("TASK-123", "implementing")
```

✅ **Правильно**
```
FILE_TASK.set_state("TASK-123", "implementing")
# set_state сам логирует, но добавь детали:
FILE_TASK.log("TASK-123", "Transition to implementing: all preconditions met")
```

❌ **Прямое редактирование файлов**
```
# Не используй прямую работу с файлами!
Write "new status" to .cm/tasks/TASK-123/status.yml
```

✅ **Правильно - используй методы**
```
FILE_TASK.set_state("TASK-123", "new_status")
```

---

## Расположение файлов

**В проекте** (после setup):
- `.cm/packages/file-task/extension.yml` - описание пакета
- `.cm/packages/file-task/concept.yml` - концепт FILE_TASK
- `.cm/packages/file-task/methods/*.yml` - реализации методов

**Задачи**:
- `.cm/tasks/` - все задачи здесь

---

**Ты готов использовать FILE_TASK!** 📁

