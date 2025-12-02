# Конфигурация проекта

> Как настроить ClearMethod в вашем проекте

---

## Обзор

ClearMethod использует двухуровневую систему конфигурации:

1. **`project.yml`** - общая конфигурация проекта (хранится в VCS)
2. **`.cm.conf`** - локальные настройки разработчика (не в VCS, в `.gitignore`)

---

## project.yml

**Расположение**: `.cm/project.yml`

**Назначение**: Общие настройки проекта, доступные всем разработчикам через VCS.

### Основная структура

```yaml
project:
  name: "My Project"
  version: "1.0.0"
  description: "Project description"
  primary_language: "python"

extensions:
  - file-task
  - sbd

concept_implementations:
  TASK: file-task.FILE_TASK
  WORKFLOW: sbd.SBD_WORKFLOW
  CONTEXT: core.CONTEXT

workflows:
  default: sbd.feature
  
context:
  primers:
    - path: core/primer.md
      required: true
```

---

## Секция: concept_implementations

**Критически важная секция!** Определяет, какая конкретная реализация используется для каждого абстрактного концепта.

### Формат

```yaml
concept_implementations:
  ABSTRACT_CONCEPT: extension-id.CONCRETE_CONCEPT
```

### Примеры

```yaml
concept_implementations:
  # Управление задачами через файловую систему
  TASK: file-task.FILE_TASK
  
  # Управление workflows через SBD
  WORKFLOW: sbd.SBD_WORKFLOW
  
  # Контекст из ядра (нет альтернатив в MVP)
  CONTEXT: core.CONTEXT
```

### Как это работает?

Когда ИИ-агент видит в CML вызов:
```yaml
- TASK.set_property(task_id, "status", "active")
```

Он выполняет резолвинг:

1. **Парсит вызов**: `TASK.set_property(...)`
2. **Читает `project.yml`** → `concept_implementations.TASK` = `"file-task.FILE_TASK"`
3. **Находит extension**: `file-task`
4. **Находит концепт**: `FILE_TASK`
5. **Читает** `.cm/extensions/file-task/concept.yml`
6. **Находит метод**: `methods.set_property` = `"methods/set_property.yml"`
7. **Выполняет CML** из `.cm/extensions/file-task/methods/set_property.yml`

### Почему это важно?

✅ **Абстракция**: Workflows пишутся с использованием абстрактных концептов (`TASK`), а не конкретных реализаций (`FILE_TASK`)

✅ **Гибкость**: Можно поменять реализацию (например, с файлов на MCP), не меняя workflows

✅ **Множественность**: В будущем может быть несколько реализаций одного концепта

### Альтернативные реализации (будущее)

В будущем могут появиться альтернативные реализации:

```yaml
# Вместо файлов - хранение в MCP сервере
concept_implementations:
  TASK: mcp-task.MCP_TASK

# Вместо файлов - хранение в базе данных
concept_implementations:
  TASK: db-task.DATABASE_TASK

# Вместо SBD - другой workflow engine
concept_implementations:
  WORKFLOW: custom-workflow.CUSTOM_WORKFLOW
```

---

## Секция: extensions

Список активных расширений ClearMethod.

```yaml
extensions:
  - file-task  # Файловое хранилище задач
  - sbd        # Stage-Based Development
```

**Важно**: Расширение должно быть в этом списке, чтобы его можно было использовать в `concept_implementations`.

---

## Секция: workflows

Определяет доступные workflows и workflow по умолчанию.

```yaml
workflows:
  default: sbd.feature  # Используется при /cm-start без параметра workflow
  
  available:
    - id: sbd.feature
      name: "Feature Development"
      description: "7-этапный процесс разработки фичи"
      states: 7
    
    - id: sbd.bugfix
      name: "Bug Fix"
      description: "Упрощенный процесс для исправления багов"
      states: 3
```

**Использование**:
- `/cm-start TASK-123` → использует `default` workflow
- `/cm-start sbd.bugfix TASK-123` → использует указанный workflow

---

## Секция: context

Управление контекстом ИИ-агента.

### Праймеры

Файлы, загружаемые при `/cm-prime`:

```yaml
context:
  primers:
    - path: core/primer.md
      required: true  # Обязательный праймер
    
    - path: extensions/file-task/primer.md
      required: true
    
    - path: extensions/sbd/primer.md
      required: true
```

**Порядок важен**: Праймеры загружаются в указанном порядке.

### Контекст проекта (on-demand)

Файлы, загружаемые по мере необходимости:

```yaml
context:
  project_context:
    - path: context/architecture.md
      on_demand: true  # Загружается только когда нужно
    
    - path: context/api-conventions.md
      on_demand: true
    
    - path: context/database-schema.md
      on_demand: true
```

**Использование**: Агент может запросить загрузку этих файлов, когда ему нужна дополнительная информация о проекте.

---

## Секция: настройки расширений

Каждое расширение может иметь свою секцию настроек.

### file_task

```yaml
file_task:
  tasks_root: ".cm/tasks"      # Где хранятся задачи
  status_file: "status.yml"    # Имя файла статуса
  log_file: "log.md"           # Имя файла лога
```

### sbd

```yaml
sbd:
  require_stage_approval: true   # Требовать подтверждение при переходах
  context_reset_on_stage: false  # Сброс контекста между этапами (будущее)
```

---

## .cm.conf (локальный файл)

**Расположение**: `.cm.conf` (в корне проекта)

**Назначение**: Локальные настройки конкретного разработчика.

**В `.gitignore`**: Да, этот файл НЕ должен попадать в VCS.

### Содержимое

```yaml
# Локальные настройки разработчика
user:
  name: "John Doe"
  email: "john@example.com"
  
# IDE-специфичные настройки (например, для Cursor)
ide:
  type: "cursor"
  commands_synced: true
  
# Личные предпочтения
preferences:
  verbose_logging: true
  auto_confirm: false  # Автоматически подтверждать действия (осторожно!)
```

### Приоритет

При конфликте настроек:
1. `.cm.conf` (локальный) - высший приоритет
2. `project.yml` (общий) - базовые настройки

**Пример**: 
- `project.yml` может задать `workflows.default`
- `.cm.conf` может переопределить его на личный preferred workflow

---

## Создание конфигурации

### При setup

При выполнении setup (`/cm-setup` или через `setup/SETUP.md`):

1. Агент копирует `setup/templates/project.yml.tpl` → `.cm/project.yml`
2. Заполняет плейсхолдеры (`{{PROJECT_NAME}}` и т.д.)
3. Создает `.cm.conf` с данными пользователя
4. Добавляет `.cm.conf` в `.gitignore`

### Ручное редактирование

Вы можете редактировать оба файла вручную:

```bash
# Общие настройки проекта
vim .cm/project.yml

# Личные настройки
vim .cm.conf
```

**Рекомендация**: После изменения `project.yml` выполните `/cm-prime` чтобы агент перезагрузил конфигурацию.

---

## Best Practices

### 1. Минимум в project.yml

Храните в `project.yml` только то, что действительно должно быть общим для всех разработчиков.

### 2. Документируйте изменения

При изменении `concept_implementations` добавьте комментарий:

```yaml
concept_implementations:
  # 2025-11-24: Switched to MCP for better performance
  TASK: mcp-task.MCP_TASK
```

### 3. Версионируйте workflows

При изменении workflows обновляйте `project.version`:

```yaml
project:
  version: "1.1.0"  # Bumped for new workflow
```

### 4. Не коммитьте .cm.conf

Убедитесь, что `.cm.conf` в `.gitignore`:

```gitignore
# ClearMethod local config
.cm.conf
```

### 5. Предоставляйте .cm.conf.example

Создайте пример локального конфига для новых разработчиков:

```bash
cp .cm.conf .cm.conf.example
# Удалите личную информацию из .cm.conf.example
git add .cm.conf.example
```

---

## Troubleshooting

### "Концепт X не имеет активной реализации"

**Причина**: Отсутствует маппинг в `concept_implementations`.

**Решение**: Добавьте маппинг в `.cm/project.yml`:
```yaml
concept_implementations:
  X: extension-id.CONCRETE_X
```

### "Extension Y не найден"

**Причина**: Расширение не в списке `extensions`.

**Решение**: Добавьте расширение в список:
```yaml
extensions:
  - Y
```

### "Метод X.Y не найден"

**Причина**: Метод не реализован в активной реализации концепта.

**Решение**: 
1. Проверьте `.cm/extensions/{extension}/concept.yml`
2. Убедитесь, что метод описан в секции `methods`
3. Если метод отсутствует - это баг в расширении

---

## Пример полной конфигурации

```yaml
# .cm/project.yml
project:
  name: "Awesome App"
  version: "2.1.0"
  description: "Modern web application"
  primary_language: "typescript"

extensions:
  - file-task
  - sbd
  - quality-gates  # Дополнительное расширение

concept_implementations:
  TASK: file-task.FILE_TASK
  WORKFLOW: sbd.SBD_WORKFLOW
  CONTEXT: core.CONTEXT
  QUALITY_GATE: quality-gates.STANDARD_GATE

workflows:
  default: sbd.feature
  
  available:
    - id: sbd.feature
      name: "Feature Development"
      states: 6
    
    - id: sbd.bugfix
      name: "Bug Fix"
      states: 3
    
    - id: sbd.hotfix
      name: "Hotfix"
      states: 2

context:
  primers:
    - path: core/primer.md
      required: true
    - path: extensions/file-task/primer.md
      required: true
    - path: extensions/sbd/primer.md
      required: true
  
  project_context:
    - path: context/architecture.md
      on_demand: true
    - path: context/api-guide.md
      on_demand: true

file_task:
  tasks_root: ".cm/tasks"
  status_file: "status.yml"
  log_file: "log.md"

sbd:
  require_stage_approval: true
  context_reset_on_stage: false

quality_gates:
  lint_on_verify: true
  test_coverage_threshold: 80

metadata:
  created_at: "2025-01-15T10:00:00Z"
  clearmethod_version: "0.1.0-mvp"
  last_updated: "2025-11-24T15:30:00Z"
```

---

## См. также

- [Core Concepts](/docs/core/concepts.md) - Архитектура концептов
- [Extensions](/docs/core/concepts/extensions.md) - Работа с расширениями
- [Setup Guide](/setup/setup.md) - Установка ClearMethod

