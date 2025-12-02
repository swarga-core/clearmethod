# File-Kanban Package - Agent Primer

## Концепт

**FILE_KANBAN** - конкретная реализация абстрактного концепта **KANBAN**.

Предоставляет визуализацию workflow через файловую kanban-доску.

## Методы

### Основные операции

```yaml
# Обновить доску
KANBAN.update_board(force?)
# → {columns[], total_tasks, last_updated}

# Переместить задачу
KANBAN.move_task(task_id, to_column, update_state?)
# → {task_id, from_column, to_column, state_updated}

# Получить состояние доски
KANBAN.get_board_state()
# → {columns[], config, last_updated}

# Получить задачи колонки
KANBAN.get_column_tasks(column_name)
# → [{id, title, state, properties}, ...]
```

### Управление колонками

```yaml
# Добавить колонку
KANBAN.add_column(column_name, states[], position?)
# → {column_name, states, position}

# Удалить колонку
KANBAN.remove_column(column_name, move_tasks_to?)
# → boolean

# Сгенерировать markdown
KANBAN.generate_markdown(include_properties?)
# → string (markdown content)
```

## Автоматизация через события

File-Kanban слушает события и автоматически обновляет доску:

```yaml
# Новая задача создана
on: task.created
  → Определить колонку по state
  → Установить kanban_column property
  → Обновить доску

# State задачи изменился
on: task.state_changed
  → Определить новую колонку
  → Обновить kanban_column
  → Обновить доску

# Workflow завершен
on: task.workflow_completed
  → Переместить в Done column
  → Обновить доску
```

## События

File-Kanban эмитит события:

```yaml
kanban.board_updated       # После обновления доски
kanban.task_moved          # После перемещения задачи
kanban.column_added        # После добавления колонки
kanban.column_removed      # После удаления колонки
```

## Хранение данных

### Task Properties

```yaml
# Каждая задача имеет property:
kanban_column: "🔄 In Progress"
```

### Board State Cache

```yaml
# .cm/kanban/board-state.yml
columns:
  - name: "📋 Backlog"
    states: [creating]
    tasks: [TASK-001, TASK-002]
    count: 2
total_tasks: 5
last_updated: "2025-11-25T..."
```

### Generated Board

```markdown
# .cm/kanban/board.md
# Kanban Board

> Last updated: 2025-11-25T...

**Total tasks:** 5

---

## 📋 Backlog (2)

- **[TASK-001]** Add user authentication
  - State: `creating`

- **[TASK-002]** Implement caching
  - State: `creating`

---

## 🔄 In Progress (1)

- **[TASK-003]** Fix login bug
  - State: `implementing`

---
```

## Конфигурация

Читается из `.cm/project.yml`:

```yaml
packages:
  file_kanban:
    enabled: true
    output_file: ".cm/kanban/board.md"
    auto_update: true
    
    columns:
      - name: "📋 Backlog"
        states: [creating]
        color: "grey"
      
      - name: "🔄 In Progress"
        states: [analyzing, designing, implementing]
        color: "blue"
      
      - name: "🔍 Review"
        states: [verifying]
        color: "yellow"
      
      - name: "✅ Done"
        states: [completing]
        color: "green"
    
    show_properties: [priority, assignee]
    show_task_links: true
```

## Примеры использования

### Обновить доску вручную

```yaml
instructions:
  - KANBAN.update_board(true)  # force regeneration
    into: board_state
  
  - info: "Board updated: {board_state.total_tasks} task(s)"
```

### Переместить задачу

```yaml
instructions:
  - KANBAN.move_task("TASK-001", "🔄 In Progress", true)
    into: result
  
  - info: "Moved: {result.from_column} → {result.to_column}"
```

### Получить задачи из колонки

```yaml
instructions:
  - KANBAN.get_column_tasks("🔄 In Progress")
    into: tasks
  
  - for: task in tasks
    do:
      - info: "Task: {task.id} - {task.title}"
```

### Добавить кастомную колонку

```yaml
instructions:
  - KANBAN.add_column("⚠️ Blocked", ["blocked"], 2)
    into: new_col
  
  - info: "Added column at position {new_col.position}"
```

## Важно

1. **Колонки настраиваемые** - каждый проект может определить свою структуру
2. **State-based mapping** - колонки автоматически мапятся на workflow states
3. **Auto-update** - доска обновляется при изменении задач (если enabled)
4. **Markdown output** - человекочитаемый формат, git-friendly
5. **Property-based** - использует `kanban_column` property для tracking

## Интеграция с workflow

File-Kanban автоматически интегрируется с SBD workflows:

- **task.created** → добавить в Backlog
- **state: implementing** → переместить в In Progress
- **state: verifying** → переместить в Review
- **workflow_completed** → переместить в Done

Всё настраивается через mapping колонок!

