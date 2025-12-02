# CML - ClearMethod Language

> **Спецификация языка для пользователей**

---

## Введение

**CML (ClearMethod Language)** - это YAML-based предметно-ориентированный язык (DSL) для описания инструкций, которые выполняет ИИ-агент в рамках ClearMethod.

### Философия

CML создан для того, чтобы:
- **Стандартизировать** способ описания действий агента
- **Упростить** понимание и отладку workflows
- **Унифицировать** подход во всех частях фреймворка (команды, методы, состояния)

### Основная идея

Вместо написания программного кода или псевдокода, вы описываете действия в структурированном YAML-формате, который ИИ-агент интерпретирует и выполняет.

---

## Базовые конструкции

### Переменные

Переменные объявляются с помощью `let:` и могут хранить любые значения.

```yaml
# Простое значение
- let: name = "John"
- let: count = 42
- let: is_ready = true

# Результат вызова метода
- let: current_state = TASK.get_state()

# Вычисляемое значение
- let: next_step = current_step + 1
```

**Правила**:
- Имена переменных: буквы, цифры, подчеркивания
- Типы определяются автоматически
- Переменные можно переопределять
- Область видимости: текущий блок и вложенные блоки

---

### Простые инструкции

Инструкции на естественном языке или вызовы методов пишутся как строки в списке.

```yaml
# Natural language инструкции
- "Create project folder structure"
- "Analyze requirements and extract key points"
- "Generate implementation plan"

# Вызовы методов концептов
- TASK.create(task_id, title, content, creator, workflow)
- TASK.set_property(task_id, "priority", "high")
- WORKFLOW.start(task_id)

# Сообщения пользователю
- info: "Operation completed successfully"
- warn: "This action may take a while"
- error: "Critical error occurred"
```

**Важно**: Простые инструкции НЕ требуют префикса `do:`. Просто пишите их в списке.

---

### Условия

Условные конструкции позволяют выполнять действия в зависимости от условий.

```yaml
# Базовый if-then-else
- if: user_confirmed
  then:
    - "Proceed with operation"
    - TASK.log(task_id, "User confirmed")
  else:
    - "Cancel operation"
    - return

# Без else
- if: exists(.cm/)
  then:
    - "ClearMethod is set up"

# Вложенные условия
- if: status == "active"
  then:
    - if: priority == "high"
      then:
        - "Process immediately"
      else:
        - "Add to queue"
```

**Операторы сравнения**:
- `==` - равно
- `!=` - не равно
- `>` - больше
- `>=` - больше или равно
- `<` - меньше
- `<=` - меньше или равно

**Логические операторы**:
- `and` - логическое И
- `or` - логическое ИЛИ
- `not` - логическое НЕ

**Специальные проверки**:
- `is empty` - пусто (строка или массив)
- `is not empty` - не пусто
- `is null` - не определено
- `exists(path)` - файл/папка существует

**Примеры условий**:
```yaml
# Проверка равенства
- if: status == "completed"

# Множественные условия
- if: count > 0 and count < 100

# Проверка пустоты
- if: title is empty
  then:
    - error: "Title is required"

# Проверка существования файла
- if: not exists(.cm/config.yml)
  then:
    - error: "Configuration not found"
```

---

### Циклы

CML поддерживает два типа циклов: по коллекции (`for`) и по условию (`while`).

#### Цикл for

Перебор элементов коллекции.

```yaml
# Простой цикл
- for: item in items
  do:
    - "Process {item}"

# Цикл по массиву из конфига
- read: config.yml
  as: yaml
  into: config

- for: primer in config.primers
  do:
    - info: "Loading: {primer.path}"
    - read: "{primer.path}"

# Вложенные циклы
- for: category in categories
  do:
    - info: "Category: {category.name}"
    - for: item in category.items
      do:
        - "Process item: {item}"
```

#### Цикл while

Выполнение действий пока условие истинно.

```yaml
# Базовый while
- let: current = 1
- while: current <= 10
  do:
    - "Process step {current}"
    - let: current = current + 1

# While с ограничением (безопасность)
- while: not finished
  max_iterations: 50
  do:
    - "Try operation"
    - "Check if finished"

# Пример: пошаговая реализация
- let: step = 1
- while: step <= total_steps
  do:
    - "Execute step {step}"
    - ask: "Continue?"
      into: continue
    - if: continue == "no"
      then:
        - return
    - let: step = step + 1
```

**Важно о while**:
- По умолчанию максимум 100 итераций (защита от бесконечных циклов)
- Можно указать `max_iterations:` явно
- При превышении лимита: предупреждение и остановка
- Используйте `return` или изменение условия для выхода

---

### Семантическая группировка

Группировка инструкций для структуры и читаемости (без алгоритмической логики).

```yaml
# Группа связанных действий
- group: "Setup project structure"
  do:
    - "Create folder structure"
    - "Copy configuration templates"
    - "Initialize git repository"

# Группа с анализом
- group: "Analyze requirements"
  do:
    - "Read specifications"
    - "Identify technical risks"
    - "List unclear requirements"
    - "Determine dependencies"

# Вложенные группы
- group: "Project initialization"
  do:
    - group: "Create folders"
      do:
        - "Create src/"
        - "Create tests/"
        - "Create docs/"
    
    - group: "Create files"
      do:
        - "Create README.md"
        - "Create .gitignore"
```

**Отличие от циклов и условий**:
- `group:` - только для **семантической структуры**
- Не влияет на алгоритм выполнения
- Агент выполняет все инструкции внутри последовательно
- Помогает понимать контекст и смысл группы действий

**Когда использовать**:
- Для логической группировки связанных действий
- Для улучшения читаемости длинных execute-блоков
- Для документирования намерений

---

### Return

Прерывает выполнение и возвращает значение (опционально).

```yaml
# Выход без значения
- if: not ready
  then:
    - return

# Возврат значения
- return: result

# Ранний выход при ошибке
- if: invalid_input
  then:
    - error: "Invalid input"
    - return
```

---

## Работа с данными

### String Interpolation

Переменные подставляются в строки с помощью синтаксиса `{variable}`.

```yaml
# Простая подстановка
- info: "Hello, {user_name}!"

# Множественные переменные
- info: "Task {task_id}: {status} - {progress}%"

# В путях к файлам
- read: .cm/tasks/{task_id}/status.yml

# В вызовах методов
- TASK.create("{task_id}", "{title}", "", "{user}", "{workflow}")

# Вложенные свойства
- info: "Project: {config.project.name}"
- info: "Extension: {config.extensions[0].id}"
```

**Правила**:
- Работает везде где ожидается строка
- Неопределенные переменные заменяются пустой строкой (нет ошибки)
- Можно комбинировать с текстом
- Для литеральной `{` используйте `\{` (экранирование)

---

### Работа с файлами

#### Чтение файлов

```yaml
# Чтение как текст
- read: path/to/file.md
  into: content

# Чтение и парсинг YAML
- read: .cm/project.yml
  as: yaml
  into: config

# Чтение и парсинг JSON
- read: data.json
  as: json
  into: data

# Чтение с interpolation
- read: .cm/tasks/{task_id}/status.yml
  as: yaml
  into: status
```

**Параметры**:
- `as:` - формат парсинга (`yaml`, `json`, или пропустить для текста)
- `into:` - имя переменной для сохранения результата

---

### Работа с массивами

```yaml
# Доступ по индексу (0-based)
- let: first = items[0]
- let: second = items[1]

# Доступ к вложенным свойствам
- let: primer_path = config.primers[0].path
- let: project_name = config.project.name

# Длина массива
- let: count = length(items)

# Проверка пустоты
- if: items is empty
  then:
    - warn: "No items found"

# Итерация
- for: item in items
  do:
    - "Process {item.name}"
```

---

## Взаимодействие с пользователем

### Запрос информации

```yaml
# Простой вопрос
- ask: "What is your name?"
  into: user_name

# С значением по умолчанию
- ask: "Task title?"
  into: title
  default: "Untitled Task"

# С использованием переменной как default
- ask: "Workflow ID?"
  into: workflow_id
  default: "{config.defaults.workflow}"

# Подтверждение
- ask: "Are you sure? (yes/no)"
  into: confirmation

- if: confirmation != "yes"
  then:
    - info: "Operation cancelled"
    - return
```

**Использование**:
- Для сбора недостающих параметров
- Для подтверждения важных действий
- Для интерактивного взаимодействия

---

### Сообщения

```yaml
# Информационное сообщение
- info: "Task created successfully"

# Предупреждение (выполнение продолжается)
- warn: "This operation may take several minutes"

# Ошибка (выполнение прерывается)
- error: "Configuration file not found"

# Логирование в журнал задачи
- TASK.log(task_id, "Completed design phase")
```

---

## Валидация

Проверка условий с автоматической остановкой при ошибке.

```yaml
# Проверка существования файла
- validate: exists(.cm/)
  error: "ClearMethod not set up. Run setup first."

# Проверка формата
- validate: task_id matches "^[A-Z]+-[0-9]+$"
  error: "Invalid task-id format. Use: TASK-123"

# Проверка значения
- validate: workflow_id is not empty
  error: "Workflow ID is required"

# Проверка с условием
- validate: count > 0 and count <= 100
  error: "Count must be between 1 and 100"
```

**Отличие от if**:
- `validate` останавливает выполнение при ошибке
- `if` позволяет выбрать альтернативное действие

---

## Вызовы методов концептов

CML позволяет вызывать методы концептов ClearMethod.

```yaml
# TASK методы
- TASK.create(task_id, title, content, creator, workflow)
- TASK.get_state()
- TASK.set_state(task_id, "implementing")
- TASK.get_property(task_id, "priority")
- TASK.set_property(task_id, "priority", "high")
- TASK.log(task_id, "Action performed")

# WORKFLOW методы
- WORKFLOW.start(task_id)
- WORKFLOW.next(task_id)
- WORKFLOW.go(task_id, "designing")

# С сохранением результата
- let: current_state = TASK.get_state()
- info: "Current state: {current_state}"
```

---

## Встроенные функции

### Файловая система

- `exists(path)` - проверка существования файла/папки
```yaml
- if: exists(.cm/config.yml)
  then:
    - "Config found"
```

### Коллекции

- `length(array)` - количество элементов
```yaml
- let: count = length(items)
- info: "Found {count} items"
```

### Строки

- `matches(string, pattern)` - проверка regex
```yaml
- validate: task_id matches "^[A-Z]+-[0-9]+$"
  error: "Invalid format"
```

---

## Структура CML файла

### Команда

```yaml
command: cm-start
description: "Start new task and workflow"

parameters:
  - name: workflow_id
    type: string
    required: false
  
  - name: task_id
    type: string
    required: false

execute:
  # Collect parameters
  - ask: "Workflow ID?"
    into: workflow_id
    default: "sbd.feature"
  
  - ask: "Task ID?"
    into: task_id
  
  # Validate
  - validate: task_id matches "^[A-Z]+-[0-9]+$"
    error: "Invalid task-id"
  
  # Execute
  - TASK.create(task_id, title, "", user, workflow_id)
  - WORKFLOW.start(task_id)
  - info: "Task started"
```

### Состояние workflow

```yaml
state: implementing
description: "Implementation phase"

preconditions:
  - description: "Design approved"
    check: "TASK.get_property(task_id, 'design_approved') == true"

execute:
  - read: .cm/tasks/{task_id}/design.md
    into: design
  
  - "Extract implementation steps"
  - let: total = steps_count
  - let: current = 1
  
  - while: current <= total
    do:
      - "Implement step {current}"
      - let: current = current + 1
  
  - TASK.set_property(task_id, "implementation_complete", true)

postconditions:
  - description: "Implementation complete"
    check: "TASK.get_property(task_id, 'implementation_complete') == true"
```

### Метод концепта

```yaml
method:
  name: create
  concept: TASK
  version: "0.1.0"

parameters:
  - name: task_id
    type: string
    required: true
  
  - name: title
    type: string
    required: true

execute:
  - validate: not exists(.cm/tasks/{task_id})
    error: "Task already exists"
  
  - "Create folder .cm/tasks/{task_id}"
  - "Create status.yml"
  - "Create log.md"
  - TASK.log(task_id, "Task created")
```

---

## Best Practices

### 1. Используйте понятные имена переменных

❌ Плохо:
```yaml
- let: x = 5
- let: tmp = config.items[0]
```

✅ Хорошо:
```yaml
- let: max_retries = 5
- let: first_primer = config.primers[0]
```

### 2. Валидируйте входные данные

❌ Плохо:
```yaml
- TASK.create(task_id, title, "", user, workflow)
```

✅ Хорошо:
```yaml
- validate: task_id is not empty
  error: "Task ID required"

- validate: task_id matches "^[A-Z]+-[0-9]+$"
  error: "Invalid task-id format"

- TASK.create(task_id, title, "", user, workflow)
```

### 3. Логируйте важные действия

```yaml
- TASK.create(task_id, title, "", user, workflow)
- TASK.log(task_id, "Task created by {user}")

- TASK.set_state(task_id, "implementing")
- TASK.log(task_id, "Moved to implementing stage")
```

### 4. Обрабатывайте ошибки gracefully

```yaml
- if: not exists(.cm/)
  then:
    - error: "ClearMethod not set up"
    - return

- read: .cm/config.yml
  as: yaml
  into: config

- if: config is null
  then:
    - error: "Failed to read configuration"
    - return
```

### 5. Используйте while с осторожностью

```yaml
# Всегда указывайте max_iterations
- while: not finished
  max_iterations: 50  # Защита от бесконечного цикла
  do:
    - "Try operation"
```

### 6. Комментируйте сложную логику

```yaml
execute:
  # Collect required parameters
  - ask: "Task ID?"
    into: task_id
  
  # Validate format
  - validate: task_id matches "^[A-Z]+-[0-9]+$"
    error: "Invalid format"
  
  # Create task structure
  - TASK.create(task_id, title, "", user, workflow)
```

---

## Отладка CML

### Проверка значений переменных

```yaml
- let: count = 5
- info: "Count is: {count}"  # Вывод для отладки

- read: config.yml
  as: yaml
  into: config
- info: "Config loaded: {config}"  # Проверка загрузки
```

### Пошаговое выполнение

Добавьте запросы подтверждения:

```yaml
- "Step 1: Create folder"
- ask: "Continue?"
  into: continue

- "Step 2: Create files"
- ask: "Continue?"
  into: continue
```

### Логирование

```yaml
- TASK.log(task_id, "DEBUG: Starting validation")
- validate: condition
  error: "Validation failed"
- TASK.log(task_id, "DEBUG: Validation passed")
```

---

## Часто задаваемые вопросы

### Можно ли использовать вложенные циклы?

Да:
```yaml
- for: category in categories
  do:
    - for: item in category.items
      do:
        - "Process {item}"
```

### Как прервать цикл досрочно?

Используйте `return` или измените условие:
```yaml
- while: current < total
  do:
    - if: error_occurred
      then:
        - return  # Выход из всего блока
    
    - let: current = current + 1
```

### Можно ли модифицировать массив?

Напрямую нет, но можно создать новый:
```yaml
- let: new_items = []
- for: item in items
  do:
    - if: item.valid
      then:
        - "Add {item} to new_items"
```

### Как обработать отсутствующий файл?

```yaml
- if: not exists(file.yml)
  then:
    - warn: "File not found, using defaults"
    - let: config = default_config
  else:
    - read: file.yml
      as: yaml
      into: config
```

---

## Заключение

CML - это мощный, но простой язык для описания действий ИИ-агента. Основные принципы:

1. **Читабельность** - код понятен человеку
2. **Структурированность** - YAML обеспечивает четкую структуру
3. **Безопасность** - валидация и ограничения циклов
4. **Гибкость** - от простых команд до сложных workflows

Начните с простых примеров и постепенно осваивайте продвинутые возможности!

