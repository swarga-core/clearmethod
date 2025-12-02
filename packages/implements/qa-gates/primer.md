# QA Gates Package - Agent Primer

## Концепт

**BASIC_QA_GATE** - конкретная реализация абстрактного концепта **QA_GATE**.

Предоставляет систему quality gates для валидации кода на каждой стадии workflow.

## Методы

### Основные операции

```yaml
# Выполнить проверки для gate
QA_GATE.check(gate_name, task_id, config?)
# → {gate_name, passed, checks[], summary, timestamp}

# Валидировать stage (throws error если не прошел)
QA_GATE.validate(task_id, stage)
# → boolean (или error)

# Получить конфигурацию gates
QA_GATE.get_config(gate_name?)
# → object (config)

# Получить историю проверок
QA_GATE.get_results(task_id, gate_name?, limit?)
# → [{gate_name, passed, checks_passed, checks_total}, ...]
```

### Отдельные проверки

```yaml
# Запустить linter
QA_GATE.run_linter(files?, fix?)
# → {total_issues, errors, warnings, fixed, raw_output}

# Запустить тесты
QA_GATE.run_tests(test_pattern?, coverage?)
# → {total, passed, failed, duration_ms, coverage, failed_tests}

# Проверить coverage
QA_GATE.check_coverage(threshold?)
# → {passed, coverage, threshold, uncovered_files}
```

## Автоматизация через события

QA-Gates слушает события и автоматически запускает проверки:

### Auto-check на завершении стадий

```yaml
# Подписка на событие
on: task.stage_completed

# Если gate настроен для stage → QA_GATE.check(stage)
# Если failed и block_progression: true → блокирует переход
```

### Quick check после коммита

```yaml
# Подписка на событие
on: vcs.commit_created

# Запускает linter и basic tests (если настроено)
# Только предупреждения, не блокирует
```

## События

QA-Gates эмитит события:

```yaml
quality.gate_checked       # После проверки gate
quality.gate_passed        # Gate прошел
quality.gate_failed        # Gate не прошел
quality.linter_completed   # Linter завершился
quality.tests_completed    # Тесты завершились
quality.coverage_low       # Coverage ниже threshold
```

## Типы проверок

### Linter
- Проверяет code quality
- Может auto-fix (если `fix: true`)
- Считает errors и warnings
- Fail on error (configurable)

### Tests
- Запускает test suite
- Собирает coverage (опционально)
- Парсит результаты (passed/failed)
- Список failed tests

### Coverage
- Проверяет code coverage %
- Сравнивает с threshold
- Эмитит `coverage_low` если не достигнут
- Может блокировать progression

### Design Document
- Проверяет наличие design doc
- Используется на стадии `designing`

## Конфигурация gates по стадиям

```yaml
packages:
  qa_gates:
    enabled: true
    gates:
      implementing:
        enabled: true
        checks:
          - linter
          - basic_tests
      
      verifying:
        enabled: true
        checks:
          - linter
          - all_tests
          - coverage
        tests:
          min_coverage: 80
      
      completing:
        enabled: true
        checks:
          - linter
          - all_tests
        require_all_passed: true  # Блокирует если не прошел
```

## Примеры использования

### Автоматическая проверка при completing stage

```yaml
# В workflow state completing.yml
instructions:
  # Выполнить финальную проверку
  - QA_GATE.validate(task_id, "completing")
  
  # Если не прошло → error, workflow блокируется
  # Если прошло → продолжаем
```

### Ручной запуск linter

```yaml
instructions:
  # Запустить linter
  - QA_GATE.run_linter()
    into: linter_result
  
  - if: linter_result.errors > 0
    then:
      - error: "Fix {linter_result.errors} linter error(s) first"
```

### Проверка coverage

```yaml
instructions:
  - QA_GATE.check_coverage(85)  # требуем 85%
    into: coverage_result
  
  - if: !coverage_result.passed
    then:
      - warn: "Coverage {coverage_result.coverage}% < 85%"
```

## Блокировка прогрессии

Если gate не прошел и `block_progression: true`:

```yaml
# В workflow перед WORKFLOW.next()
instructions:
  - TASK.get_property(task_id, "qa_gate_blocked")
    into: blocked
  
  - if: blocked
    then:
      - error: "Cannot progress: quality gate failed. Fix issues first."
```

QA-Gates автоматически устанавливает `qa_gate_blocked` property.

## Важно

1. **Gates конфигурируются по стадиям** - разные требования для разных stages
2. **Validate throws error** - используй для блокировки progression
3. **Check возвращает результат** - используй для информирования
4. **Linter и tests - external tools** - нужно настроить команды в config
5. **События для интеграции** - другие пакеты могут реагировать на quality events

## Интеграция с workflow

QA-Gates автоматически интегрируется с SBD workflows:

- **implementing stage** → linter + basic tests
- **verifying stage** → linter + all tests + coverage (STRICT)
- **completing stage** → final checks, блокирует если не прошел

Всё настраивается в конфиге!

