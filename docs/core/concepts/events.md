# Система событий ClearMethod

> **Событийная архитектура для слабо связанных пакетов**

---

## Содержание

1. [Введение](#введение)
2. [Архитектура](#архитектура)
3. [Концепт EVENT](#концепт-event)
4. [Реализация BASIC_EVENT](#реализация-basic_event)
5. [Типы событий](#типы-событий)
6. [Работа с событиями](#работа-с-событиями)
7. [Обработчики событий](#обработчики-событий)
8. [Подписки и фильтры](#подписки-и-фильтры)
9. [Приоритеты выполнения](#приоритеты-выполнения)
10. [Каскады событий](#каскады-событий)
11. [Отладка и мониторинг](#отладка-и-мониторинг)
12. [Best Practices](#best-practices)
13. [Примеры использования](#примеры-использования)

---

## Введение

### Зачем нужны события?

**Проблема**: В сложной системе с множеством пакетов возникают зависимости:
- `sbd` workflow хочет, чтобы `git-vcs` создал ветку при создании задачи
- `qa-gates` должен проверить качество перед переходом на следующую стадию
- `notifications` нужно уведомить команду о завершении задачи

**Плохое решение**: Прямые вызовы
```yaml
# ❌ Жесткая связанность
- VCS.create_branch(...)  # workflow зависит от git-vcs
- QA.check_quality(...)   # workflow зависит от qa-gates
- NOTIFY.send_slack(...)  # workflow зависит от notifications
```

**Проблемы**:
- Workflow зависит от всех пакетов
- Невозможно удалить пакет без изменения workflow
- Сложно добавить новую интеграцию

**Хорошее решение**: События
```yaml
# ✅ Слабая связанность
- EVENT.emit("task.created", {task_id: "FEAT-001"})

# Расширения подписываются независимо:
# git-vcs → on_task_created → создает ветку
# qa-gates → on_task_created → устанавливает checklist
# notifications → on_task_created → отправляет уведомление
```

**Преимущества**:
- Workflow не знает о пакетах
- Расширения можно добавлять/удалять без изменения workflow
- Каждое пакет работает независимо

---

## Архитектура

### Компоненты системы событий

```
┌─────────────────────────────────────────────────────┐
│ 1. EVENT EMITTER (источник события)                │
│    - Workflow states                                │
│    - Методы концептов                               │
│    - Команды                                        │
│    - Обработчики (cascade)                          │
└─────────────┬───────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────┐
│ 2. EVENT DISPATCHER (диспетчер)                     │
│    - Резолвинг EVENT → BASIC_EVENT                  │
│    - Сохранение события в лог                       │
│    - Поиск подписок                                 │
│    - Фильтрация и сортировка                        │
└─────────────┬───────────────────────────────────────┘
              │
    ┌─────────┴────────┬────────────┬──────────────┐
    ▼                  ▼            ▼              ▼
┌─────────┐      ┌─────────┐  ┌─────────┐    ┌─────────┐
│Handler 1│      │Handler 2│  │Handler 3│    │Handler N│
│Priority │      │Priority │  │Priority │    │Priority │
│   10    │      │   20    │  │   50    │    │  100    │
└────┬────┘      └────┬────┘  └────┬────┘    └────┬────┘
     │                │           │               │
     ▼                ▼           ▼               ▼
┌─────────────────────────────────────────────────────┐
│ 3. РЕЗУЛЬТАТЫ                                       │
│    - Статус выполнения каждого обработчика          │
│    - Логи и ошибки                                  │
│    - Время выполнения                               │
│    - Обновление события в логе                      │
└─────────────────────────────────────────────────────┘
```

### Поток данных

```yaml
1. Эмиссия события
   EVENT.emit("task.created", {task_id: "FEAT-001"})
   
2. Резолвинг
   EVENT → project.yml → basic-events.BASIC_EVENT
   
3. Создание записи
   event_id: evt-001
   type: task.created
   payload: {task_id: "FEAT-001"}
   
4. Сохранение в лог
   .cm/events/events.yml ← append event
   
5. Поиск подписок
   .cm/events/subscriptions.yml → read
   filter by: event_type == "task.created"
   
6. Применение фильтров
   subscription.filter matches payload?
   
7. Сортировка по priority
   [sub1(p:10), sub2(p:20), sub3(p:50)]
   
8. Выполнение обработчиков (в порядке priority)
   for each subscription:
     read handler.yml
     execute with context: {event, payload}
     log result (success/error)
   
9. Обновление события
   event.handlers_executed = [...]
   event.duration_ms = 1234
   event.status = "completed"
```

---

## Концепт EVENT

### Абстрактный интерфейс

`EVENT` - это абстрактный концепт, определенный в `core/concepts/event.yml`.

**Тип**: abstract (интерфейс)

**Методы**:

#### emit()
Эмитирует событие и запускает обработчики.

```yaml
params:
  - event_type: string      # "task.created", "workflow.stage_completed"
  - payload: object         # Данные события
  - sync: boolean           # Синхронное (true) или асинхронное (default: true)

returns:
  - event_id: string        # Уникальный ID события
  - handlers_executed: number  # Количество выполненных обработчиков
  - duration_ms: number     # Время выполнения
```

#### subscribe()
Регистрирует обработчик для типа события.

```yaml
params:
  - event_type: string      # Тип события или wildcard "task.*"
  - extension: string       # Имя пакета
  - handler: string         # Путь к обработчику
  - filter: object          # Условия фильтрации (optional)
  - priority: number        # Приоритет (1-200+, default: 100)
  - enabled: boolean        # Активен ли (default: true)

returns:
  - subscription_id: string # ID подписки для unsubscribe
```

#### unsubscribe()
Удаляет подписку.

```yaml
params:
  - subscription_id: string

returns:
  - success: boolean
```

#### get_history()
Получает историю событий с фильтрацией.

```yaml
params:
  - task_id: string         # Фильтр по задаче (optional)
  - event_type: string      # Фильтр по типу (optional)
  - limit: number           # Макс. событий (default: 50)
  - since: string           # С какого времени (ISO 8601, optional)

returns:
  - events: array           # Массив событий (новые первые)
```

#### list_subscriptions()
Список активных подписок.

```yaml
params:
  - event_type: string      # Фильтр по типу (optional)
  - extension: string       # Фильтр по пакету (optional)
  - enabled_only: boolean   # Только активные (default: true)

returns:
  - subscriptions: array    # Массив подписок
```

---

## Реализация BASIC_EVENT

### Файловая реализация

`BASIC_EVENT` - базовая файловая реализация концепта `EVENT`.

**Расположение**: `packages/basic-events/`

**Тип**: concrete (реализация)

**Implements**: EVENT

### Особенности

✅ **Синхронное выполнение** - обработчики выполняются последовательно
✅ **Приоритеты** - контроль порядка выполнения (1-200+)
✅ **Фильтрация** - условия для запуска обработчиков
✅ **Защита от циклов** - максимальная глубина каскада 10 уровней
✅ **Изоляция ошибок** - сбой одного обработчика не останавливает другие
✅ **Полный аудит** - все события логируются
✅ **Файловое хранилище** - не требует БД

### Хранилище

```
.cm/events/
├── events.yml          # Хронологический лог всех событий
└── subscriptions.yml   # Активные подписки обработчиков
```

#### Формат события

```yaml
# .cm/events/events.yml
- id: evt-001
  type: task.created
  timestamp: 2025-11-25T10:30:00Z
  payload:
    task_id: FEAT-001
    workflow: sbd.feature
    title: "Add user authentication"
    created_by: "John Doe"
  cascade_depth: 0
  handlers_executed:
    - subscription_id: sub-001
      extension: git-vcs
      handler: handlers/on_task_created
      status: success
      duration_ms: 156
    - subscription_id: sub-002
      extension: qa-gates
      handler: handlers/validate_preconditions
      status: success
      duration_ms: 89
  duration_ms: 245
  status: completed
```

#### Формат подписки

```yaml
# .cm/events/subscriptions.yml
subscriptions:
  - id: sub-001
    event_type: task.created
    extension: git-vcs
    handler: handlers/on_task_created
    filter:
      workflow: sbd.feature
    priority: 20
    enabled: true
    created_at: 2025-11-25T09:00:00Z
```

---

## Типы событий

### Стандартные типы

ClearMethod определяет стандартный набор событий для координации пакетов.

#### Жизненный цикл задачи

| Событие | Когда эмитится | Payload |
|---------|---------------|---------|
| `task.created` | Задача создана | task_id, workflow, title, created_by |
| `task.updated` | Свойства задачи обновлены | task_id, changes |
| `task.deleted` | Задача удалена | task_id |
| `task.property_changed` | Одно свойство изменено | task_id, property, old_value, new_value |
| `task.state_changed` | Workflow состояние изменено | task_id, from, to |
| `task.stage_started` | Начало выполнения стадии | task_id, stage |
| `task.stage_completed` | Стадия завершена | task_id, stage, duration_ms |
| `task.workflow_started` | Workflow запущен | task_id, workflow |
| `task.workflow_completed` | Workflow завершен | task_id, workflow, final_state, duration_ms |
| `task.workflow_failed` | Workflow провален | task_id, workflow, error |

#### Качество и валидация

| Событие | Когда эмитится | Payload |
|---------|---------------|---------|
| `quality.gate_checked` | Проверка качества выполнена | task_id, gate_name, stage |
| `quality.gate_passed` | Проверка пройдена | task_id, gate_name, checks |
| `quality.gate_failed` | Проверка провалена | task_id, gate_name, errors |
| `validation.precondition_checked` | Precondition проверен | task_id, stage, result |
| `validation.postcondition_checked` | Postcondition проверен | task_id, stage, result |
| `validation.reality_check_triggered` | Reality check активирован | task_id, check_name, reason |

#### VCS операции

| Событие | Когда эмитится | Payload |
|---------|---------------|---------|
| `vcs.branch_created` | Ветка создана | task_id, branch, from_branch |
| `vcs.commit_created` | Коммит создан | task_id, sha, message, files |
| `vcs.push_completed` | Push выполнен | task_id, branch, commits_count |
| `vcs.pr_created` | Pull Request создан | task_id, pr_url, pr_number, title |
| `vcs.pr_merged` | PR слит | task_id, pr_number, merged_by |

#### Управление контекстом

| Событие | Когда эмитится | Payload |
|---------|---------------|---------|
| `context.loaded` | Контекст загружен | files_count, tokens_used |
| `context.updated` | Контекст обновлен | added_files, removed_files |
| `context.file_added` | Файл добавлен в контекст | file_path, size_bytes |
| `context.optimized` | Контекст оптимизирован | old_tokens, new_tokens |

#### Системные события

| Событие | Когда эмитится | Payload |
|---------|---------------|---------|
| `extension.registered` | Расширение зарегистрировано | extension_name, version |
| `command.executed` | Команда выполнена | command_name, params, duration_ms |
| `error.occurred` | Произошла ошибка | error_type, message, stack_trace |

### Именование событий

**Формат**: `{domain}.{action}_{past_tense}`

**Примеры**:
- ✅ `task.created` - задача создана
- ✅ `workflow.stage_completed` - стадия завершена
- ✅ `vcs.branch_created` - ветка создана
- ❌ `task.create` - неправильно (не past tense)
- ❌ `TaskCreated` - неправильно (не kebab-case)

**Домены**:
- `task` - события задачи
- `workflow` - события workflow
- `quality` - качество и валидация
- `vcs` - version control
- `context` - управление контекстом
- `system` - системные события
- `{extension}` - кастомные события пакетов

---

## Работа с событиями

### Эмиссия события в CML

```yaml
# Базовый вызов
- EVENT.emit("task.created", {
    task_id: "FEAT-001",
    workflow: "sbd.feature",
    title: "Add authentication"
  })

# С захватом результата
- let: result = EVENT.emit("task.stage_completed", {
    task_id: "FEAT-001",
    stage: "designing"
  })
- info: "Event {result.event_id} triggered {result.handlers_executed} handlers in {result.duration_ms}ms"

# В условных блоках
- if: validation_passed
  then:
    - EVENT.emit("quality.gate_passed", {
        task_id: task_id,
        gate_name: "design_review"
      })
  else:
    - EVENT.emit("quality.gate_failed", {
        task_id: task_id,
        gate_name: "design_review",
        errors: validation_errors
      })

# В циклах
- for: file in changed_files
  do:
    - EVENT.emit("vcs.file_modified", {
        task_id: task_id,
        file_path: file
      })
```

### Где эмитировать события

✅ **В workflow states** - изменения состояния
```yaml
# states/creating.yml
instructions:
  - EVENT.emit("task.stage_started", {stage: "creating"})
  # ... логика ...
  - EVENT.emit("task.stage_completed", {stage: "creating"})
```

✅ **В методах концептов** - важные операции
```yaml
# file-task/methods/create.yml
instructions:
  # ... создание файлов ...
  - EVENT.emit("task.created", {task_id: task_id})
```

✅ **В обработчиках** - каскады
```yaml
# git-vcs/handlers/on_task_created.yml
instructions:
  - VCS.create_branch(...)
  - EVENT.emit("vcs.branch_created", {...})
```

❌ **Не эмитируйте в**:
- Тривиальных операциях (get_property)
- Внутренних шагах логики
- Циклических сценариях (риск бесконечного каскада)

---

## Обработчики событий

### Структура обработчика

Обработчик - это CML файл, который выполняется при событии.

**Путь**: `.cm/packages/{extension}/handlers/{handler_name}.yml`

**Формат**:
```yaml
name: handler_name
description: What this handler does

params:
  - name: event      # Полный объект события
    type: object
    description: Event object with id, type, timestamp, payload
  
  - name: payload    # Данные события (shortcut)
    type: object
    description: Event payload data

instructions:
  - info: "Handling {event.type} for task {payload.task_id}"
  
  # Validate preconditions
  - if: !payload.task_id
    then:
      - warn: "No task_id in payload, skipping"
      - return
  
  # Your logic here
  - let: task = TASK.get(payload.task_id)
  - let: branch_name = "feature/{task.id}-{slugify(task.title)}"
  
  # Perform action
  - VCS.create_branch(task.id, branch_name)
  
  # Log action
  - TASK.log(task.id, "Git branch created: {branch_name}")
  
  # Can emit new events (cascade)
  - EVENT.emit("vcs.branch_created", {
      task_id: task.id,
      branch: branch_name,
      triggered_by: event.id
    })
```

### Параметры обработчика

#### event (object)
Полный объект события:
```yaml
event:
  id: "evt-001"
  type: "task.created"
  timestamp: "2025-11-25T10:30:00Z"
  payload: {...}
  cascade_depth: 0
```

#### payload (object)
Данные события (для удобства):
```yaml
payload:
  task_id: "FEAT-001"
  workflow: "sbd.feature"
  title: "Add authentication"
```

### Контекст выполнения

Обработчик выполняется с изолированным контекстом:
- Имеет доступ к `event` и `payload`
- Может вызывать методы концептов (TASK, VCS, QA_GATE и т.д.)
- Может эмитировать новые события
- **Не имеет доступа к переменным workflow** (изоляция!)

---

## Подписки и фильтры

### Регистрация подписки

#### Вручную (в subscriptions.yml)

```yaml
# .cm/events/subscriptions.yml
subscriptions:
  - id: sub-git-001
    event_type: task.created
    extension: git-vcs
    handler: handlers/on_task_created
    filter:
      workflow: sbd.feature
    priority: 20
    enabled: true
```

#### Программно (в CML)

```yaml
# В setup скрипте пакета
- let: sub_id = EVENT.subscribe(
    "task.created",
    "git-vcs",
    "handlers/on_task_created",
    {
      filter: {workflow: "sbd.feature"},
      priority: 20
    }
  )
- info: "Subscribed with ID: {sub_id}"
```

### Фильтры

Фильтры позволяют ограничить выполнение обработчика определенными условиями.

#### Простой фильтр
```yaml
filter:
  workflow: sbd.feature  # Только для sbd.feature
```

#### Множественные значения (OR)
```yaml
filter:
  workflow: [sbd.feature, sbd.bugfix]  # feature ИЛИ bugfix
```

#### Множественные условия (AND)
```yaml
filter:
  workflow: sbd.feature  # И
  stage: [designing, implementing]  # И
```

#### Вложенные объекты
```yaml
filter:
  payload.metadata.priority: high
```

### Wildcard event types

Поддержка wildcards в `event_type`:

```yaml
# Все события задачи
event_type: task.*

# Все события качества
event_type: quality.*

# Все события
event_type: "*"
```

---

## Приоритеты выполнения

### Концепция приоритетов

**Приоритет** (priority) - число, определяющее порядок выполнения обработчиков.

**Правило**: Меньшее число = выше приоритет (выполняется раньше)

**Диапазоны**:
- **1-10**: Критичные обработчики (валидация, безопасность, pre-checks)
- **11-50**: Пре-действия (quality gates, preconditions, автоматизация)
- **51-100**: Нормальные обработчики (интеграции, автоматизация)
- **101-200**: Пост-действия (уведомления, логирование, аналитика)
- **201+**: Низкоприоритетные (cleanup, архивация)

**Default**: 100

### Примеры использования приоритетов

#### Валидация перед действием
```yaml
# Priority 5 - выполнится первым
- id: sub-validation
  event_type: task.transition_requested
  handler: qa-gates/handlers/validate_transition
  priority: 5

# Priority 50 - выполнится после валидации
- id: sub-git
  event_type: task.transition_requested
  handler: git-vcs/handlers/on_transition
  priority: 50
```

#### Действия → Уведомления
```yaml
# Priority 20 - создать ветку
- id: sub-create-branch
  event_type: task.created
  handler: git-vcs/handlers/create_branch
  priority: 20

# Priority 100 - уведомить после создания ветки
- id: sub-notify
  event_type: task.created
  handler: notifications/handlers/notify_team
  priority: 100
```

### Детерминированность

При одинаковых приоритетах порядок выполнения определяется:
1. По `subscription_id` (лексикографически)
2. По дате создания подписки

**Рекомендация**: Всегда указывайте разные приоритеты если порядок важен.

---

## Каскады событий

### Что такое каскад?

**Каскад** - когда обработчик события эмитирует новое событие, которое запускает другие обработчики.

```yaml
EVENT.emit("task.created")
  └─> git-vcs.on_task_created()
      └─> VCS.create_branch()
          └─> EVENT.emit("vcs.branch_created")  ← Каскад!
              └─> notifications.on_branch_created()
                  └─> NOTIFIER.send_slack()
```

### Cascade Depth

**cascade_depth** - уровень вложенности каскада.

- Начальное событие: `cascade_depth = 0`
- Событие из обработчика: `cascade_depth = 1`
- Событие из обработчика обработчика: `cascade_depth = 2`
- И так далее...

**Максимальная глубина**: 10 уровней

**Защита от бесконечных циклов**:
```yaml
# В emit.yml
- if: cascade_depth > 10
  then:
    - error: "Maximum cascade depth exceeded. Possible infinite loop."
```

### Tracking каскадов

Каждое событие в каскаде знает кто его вызвал:

```yaml
# Исходное событие
- id: evt-001
  type: task.created
  cascade_depth: 0

# Событие из обработчика
- id: evt-002
  type: vcs.branch_created
  payload:
    triggered_by: evt-001  # ← ссылка на родителя
  cascade_depth: 1
```

### Best Practices для каскадов

✅ **DO:**
- Используйте каскады для логических последовательностей действий
- Эмитируйте специфичные события (`vcs.branch_created`, не `task.updated`)
- Ограничивайте глубину каскада (оптимально 1-2 уровня)

❌ **DON'T:**
- Избегайте циклических зависимостей (A → B → A)
- Не эмитируйте общие события из обработчиков (риск циклов)
- Не полагайтесь на каскады глубже 3 уровней

---

## Отладка и мониторинг

### Просмотр истории событий

#### В файловой системе
```bash
# Все события
cat .cm/events/events.yml

# Последние 20 событий
tail -n 100 .cm/events/events.yml

# События конкретной задачи
grep "task_id: FEAT-001" .cm/events/events.yml

# События конкретного типа
grep "type: task.created" .cm/events/events.yml
```

#### Программно в CML
```yaml
# Все последние события
- let: recent = EVENT.get_history(limit: 20)
- for: event in recent
  do:
    - info: "[{event.timestamp}] {event.type} → {event.handlers_executed.length} handlers"

# События задачи
- let: task_events = EVENT.get_history(task_id: "FEAT-001")
- info: "Found {task_events.length} events for FEAT-001"

# События типа
- let: created_events = EVENT.get_history(event_type: "task.created", limit: 10)
```

### Просмотр подписок

#### В файловой системе
```bash
# Все подписки
cat .cm/events/subscriptions.yml

# Подписки пакета
grep "extension: git-vcs" .cm/events/subscriptions.yml

# Отключенные подписки
grep "enabled: false" .cm/events/subscriptions.yml
```

#### Программно в CML
```yaml
# Все подписки
- let: all_subs = EVENT.list_subscriptions()
- info: "Total subscriptions: {all_subs.length}"

# Подписки на событие
- let: subs = EVENT.list_subscriptions(event_type: "task.created")
- for: sub in subs
  do:
    - info: "  [{sub.priority}] {sub.extension}.{sub.handler}"

# Подписки пакета
- let: git_subs = EVENT.list_subscriptions(extension: "git-vcs")
```

### Анализ производительности

```yaml
# Найти медленные обработчики
- let: recent = EVENT.get_history(limit: 100)
- for: event in recent
  do:
    - for: handler in event.handlers_executed
      do:
        - if: handler.duration_ms > 500
          then:
            - warn: "Slow handler: {handler.extension}.{handler.handler} took {handler.duration_ms}ms"

# Статистика по типам событий
- let: all_events = EVENT.get_history(limit: 1000)
- let: stats = group_by(all_events, "type")
- for: [type, events] in stats
  do:
    - info: "{type}: {events.length} events"
```

### Отладка ошибок

```yaml
# Найти failed handlers
- let: recent = EVENT.get_history(limit: 50)
- for: event in recent
  do:
    - for: handler in event.handlers_executed
      do:
        - if: handler.status == "error"
          then:
            - error: "Handler {handler.handler} failed: {handler.error}"
            - info: "  Event: {event.type} ({event.id})"
            - info: "  Payload: {yaml(event.payload)}"
```

---

## Best Practices

### Проектирование событий

#### ✅ DO

**Используйте специфичные типы событий**
```yaml
# Good
- EVENT.emit("task.stage_completed", {stage: "designing"})
- EVENT.emit("vcs.branch_created", {branch: "feature/FEAT-001"})

# Bad
- EVENT.emit("task.updated", {field: "stage"})  # Слишком общее
```

**Включайте необходимый контекст в payload**
```yaml
# Good
payload:
  task_id: "FEAT-001"
  stage: "designing"
  previous_stage: "creating"
  duration_ms: 45000

# Bad
payload:
  task_id: "FEAT-001"  # Недостаточно контекста
```

**Эмитируйте события в правильных местах**
```yaml
# Good - events в workflow states
instructions:
  - EVENT.emit("task.stage_started", {stage: "creating"})
  # ... logic ...
  - EVENT.emit("task.stage_completed", {stage: "creating"})

# Bad - events в середине сложной логики
instructions:
  - do_step_1()
  - EVENT.emit("step1.completed")  # Слишком детально
  - do_step_2()
```

#### ❌ DON'T

**Не создавайте слишком общие события**
```yaml
# Bad
- EVENT.emit("something.happened", {data: {...}})
- EVENT.emit("task.changed", {task_id: "FEAT-001"})
```

**Не эмитируйте события в циклах без причины**
```yaml
# Bad
- for: file in files
  do:
    - EVENT.emit("file.processed", {file: file})  # Будет 100 событий!

# Good
- for: file in files
  do:
    - process(file)
- EVENT.emit("files.processed", {count: files.length})  # Одно событие
```

**Не полагайтесь на порядок обработчиков без приоритетов**
```yaml
# Bad - undefined order
- id: sub1
  priority: 100
- id: sub2
  priority: 100  # Порядок не гарантирован!

# Good - explicit priorities
- id: sub1
  priority: 50
- id: sub2
  priority: 100
```

### Проектирование обработчиков

#### ✅ DO

**Делайте обработчики фокусными**
```yaml
# Good - single responsibility
name: create_git_branch
instructions:
  - VCS.create_branch(payload.task_id, branch_name)

# Bad - multiple responsibilities
name: on_task_created_do_everything
instructions:
  - VCS.create_branch(...)
  - QA.setup_checklist(...)
  - NOTIFIER.send_slack(...)
  # Слишком много обязанностей!
```

**Проверяйте preconditions**
```yaml
# Good
instructions:
  - if: !payload.task_id
    then:
      - warn: "No task_id, skipping"
      - return
  
  - let: task = TASK.get(payload.task_id)
  - if: !task
    then:
      - error: "Task {payload.task_id} not found"
      - return
  
  # ... main logic ...
```

**Логируйте действия**
```yaml
# Good
instructions:
  - info: "Creating branch for {payload.task_id}"
  - VCS.create_branch(...)
  - TASK.log(payload.task_id, "Branch created: {branch_name}")
  - info: "Branch created successfully"
```

#### ❌ DON'T

**Не делайте долгие операции в обработчиках**
```yaml
# Bad - blocks execution
instructions:
  - for: i in range(10000)
    do:
      - heavy_computation(i)  # Блокирует на минуты!

# Good - emit event for async processing
instructions:
  - EVENT.emit("heavy.task_queued", {task_id: payload.task_id})
  # Separate worker will process it
```

**Не игнорируйте ошибки молча**
```yaml
# Bad
instructions:
  - try:
      - risky_operation()
    catch:
      - pass  # Тихо игнорируем ошибку!

# Good
instructions:
  - try:
      - risky_operation()
    catch:
      - error: "Risky operation failed: {error.message}"
      - TASK.log(payload.task_id, "ERROR: {error.message}")
```

---

## Примеры использования

### Пример 1: Auto-create Git Branch

**Задача**: При создании задачи автоматически создавать git ветку.

#### Подписка
```yaml
# .cm/events/subscriptions.yml
- id: sub-git-001
  event_type: task.created
  extension: git-vcs
  handler: handlers/auto_branch
  filter:
    workflow: sbd.feature  # Только для feature tasks
  priority: 20
  enabled: true
```

#### Обработчик
```yaml
# .cm/packages/git-vcs/handlers/auto_branch.yml
name: auto_branch
description: Automatically create git branch when task is created

params:
  - name: event
  - name: payload

instructions:
  - info: "Git VCS: Creating branch for {payload.task_id}"
  
  # Get task details
  - let: task = TASK.get(payload.task_id)
  
  # Generate branch name
  - let: branch_name = "feature/{task.id}-{slugify(task.title)}"
  
  # Create branch
  - VCS.create_branch(task.id, branch_name)
  
  # Log to task
  - TASK.log(task.id, "Git branch created: {branch_name}")
  
  # Emit cascade event
  - EVENT.emit("vcs.branch_created", {
      task_id: task.id,
      branch: branch_name,
      from_branch: "main",
      triggered_by: event.id
    })
  
  - info: "Branch {branch_name} created successfully"
```

#### Использование в workflow
```yaml
# states/creating.yml
instructions:
  - TASK.create(task_id, workflow_id, title)
  
  # Emit event - git-vcs will automatically create branch
  - EVENT.emit("task.created", {
      task_id: task_id,
      workflow: workflow_id,
      title: title,
      created_by: user_name
    })
```

---

### Пример 2: Quality Gate Validation

**Задача**: Проверять качество перед переходом на следующую стадию.

#### Подписка
```yaml
# .cm/events/subscriptions.yml
- id: sub-qa-001
  event_type: task.stage_completed
  extension: qa-gates
  handler: handlers/validate_stage
  filter:
    stage: [designing, implementing, verifying]
  priority: 5  # High priority - validate first!
  enabled: true
```

#### Обработчик
```yaml
# .cm/packages/qa-gates/handlers/validate_stage.yml
name: validate_stage
description: Validate quality gate for completed stage

params:
  - name: event
  - name: payload

instructions:
  - info: "QA Gates: Validating {payload.stage} for {payload.task_id}"
  
  # Get gate definition
  - let: gate = QA_GATE.get_for_stage(payload.stage)
  
  # Run checks
  - let: result = QA_GATE.check(payload.task_id, gate)
  
  # Handle result
  - if: result.passed
    then:
      - TASK.log(payload.task_id, "✅ Quality gate passed for {payload.stage}")
      
      - EVENT.emit("quality.gate_passed", {
          task_id: payload.task_id,
          stage: payload.stage,
          gate_name: gate.name,
          checks: result.checks
        })
    else:
      - TASK.log(payload.task_id, "❌ Quality gate failed for {payload.stage}")
      
      - EVENT.emit("quality.gate_failed", {
          task_id: payload.task_id,
          stage: payload.stage,
          gate_name: gate.name,
          errors: result.errors
        })
      
      # Optionally block transition
      - error: "Quality gate failed. Fix issues before proceeding:\n{yaml(result.errors)}"
```

---

### Пример 3: Team Notifications

**Задача**: Уведомлять команду о важных событиях через Slack.

#### Multiple Subscriptions
```yaml
# .cm/events/subscriptions.yml

# Notify on task creation
- id: sub-notify-001
  event_type: task.created
  extension: notifications
  handler: handlers/notify_task_created
  priority: 100
  enabled: true

# Notify on workflow completion
- id: sub-notify-002
  event_type: task.workflow_completed
  extension: notifications
  handler: handlers/notify_task_completed
  filter:
    workflow: sbd.feature
  priority: 100
  enabled: true

# Notify on quality gate failure
- id: sub-notify-003
  event_type: quality.gate_failed
  extension: notifications
  handler: handlers/notify_quality_issue
  priority: 50  # Higher priority - alert immediately
  enabled: true
```

#### Handlers
```yaml
# .cm/packages/notifications/handlers/notify_task_created.yml
name: notify_task_created

params:
  - name: event
  - name: payload

instructions:
  - let: message = "🎯 New task created: {payload.title}\n" +
                   "ID: {payload.task_id}\n" +
                   "Workflow: {payload.workflow}\n" +
                   "By: {payload.created_by}"
  
  - NOTIFIER.send_slack("#dev", message)
  
  - TASK.log(payload.task_id, "Team notified via Slack")
```

```yaml
# .cm/packages/notifications/handlers/notify_quality_issue.yml
name: notify_quality_issue

params:
  - name: event
  - name: payload

instructions:
  - let: message = "⚠️ Quality gate failed!\n" +
                   "Task: {payload.task_id}\n" +
                   "Stage: {payload.stage}\n" +
                   "Gate: {payload.gate_name}\n" +
                   "Errors:\n{format_errors(payload.errors)}"
  
  - NOTIFIER.send_slack("#alerts", message)
  
  - TASK.log(payload.task_id, "Quality issue escalated to team")
```

---

### Пример 4: Cascading Events

**Задача**: Автоматизировать полный flow: задача → ветка → коммит → PR.

```yaml
# Event 1: task.created
EVENT.emit("task.created")
  ↓
  Handler: git-vcs.create_branch
    VCS.create_branch()
    ↓
    # Event 2: vcs.branch_created
    EVENT.emit("vcs.branch_created")
      ↓
      Handler: qa-gates.setup_checklist
        QA_GATE.create_checklist()
        ↓
        # Event 3: quality.checklist_created
        EVENT.emit("quality.checklist_created")
          ↓
          Handler: notifications.notify_ready
            NOTIFIER.send_slack("Task ready for work")
```

**cascade_depth tracking**:
```yaml
evt-001: task.created (depth: 0)
evt-002: vcs.branch_created (depth: 1, triggered_by: evt-001)
evt-003: quality.checklist_created (depth: 2, triggered_by: evt-002)
```

---

## Заключение

Система событий ClearMethod обеспечивает:

✅ **Слабую связанность** - пакета независимы  
✅ **Расширяемость** - легко добавлять новые интеграции  
✅ **Прозрачность** - полная история всех событий  
✅ **Гибкость** - фильтры, приоритеты, каскады  
✅ **Надежность** - изоляция ошибок, защита от циклов  

**См. также:**
- [core.md](core.md) - Базовые концепты ядра
- [extensions.md](extensions.md) - Концепты пакетов
- [advanced.md](advanced.md) - Продвинутые возможности
- `packages/basic-events/README.md` - Документация BASIC_EVENT
- `packages/basic-events/primer.md` - Праймер для AI агентов

