# ClearMethod Project Configuration
# Этот файл хранится в VCS и является общим для всех разработчиков проекта

project:
  name: "{{PROJECT_NAME}}"
  version: "{{PROJECT_VERSION}}"
  description: "{{PROJECT_DESCRIPTION}}"
  
  # Язык проекта (для контекста)
  primary_language: "{{PRIMARY_LANGUAGE}}"  # например: python, typescript, go
  
  # Корневая папка проекта
  root: "{{PROJECT_ROOT}}"

# Активные пакета ClearMethod
extensions:
  - file-task  # Файловое хранилище задач
  - sbd        # Stage-Based Development workflows

# Маппинг абстрактных концептов на конкретные реализации
# Формат: "ABSTRACT_CONCEPT: extension-id.CONCRETE_CONCEPT"
concept_implementations:
  # TASK - управление задачами
  TASK: file-task.FILE_TASK
  
  # WORKFLOW - управление рабочими процессами
  WORKFLOW: sbd.SBD_WORKFLOW
  
  # CONTEXT - управление контекстом агента
  CONTEXT: core.CONTEXT

# Workflows, доступные в проекте
workflows:
  default: sbd.feature  # Workflow по умолчанию
  
  available:
    - id: sbd.feature
      name: "Feature Development"
      description: "Полноценный цикл разработки фичи (6 этапов)"
      states: 6

# Настройки для FILE_TASK extension
file_task:
  tasks_root: ".cm/tasks"
  status_file: "status.yml"
  log_file: "log.md"

# Настройки для SBD extension
sbd:
  require_stage_approval: true  # Требовать подтверждение перед переходом между этапами
  context_reset_on_stage: false # Сброс контекста между этапами (пока не реализовано)

# Настройки контекста
context:
  # Праймеры, загружаемые при /cm-prime
  primers:
    - path: core/primer.md
      required: true
    
    - path: packages/file-task/primer.md
      required: true
    
    - path: packages/sbd/primer.md
      required: true
  
  # Контекст проекта (загружается при необходимости)
  project_context:
    - path: context/architecture.md
      on_demand: true
    
    - path: context/conventions.md
      on_demand: true

# Настройки Quality Gates (будет реализовано позже)
quality_gates:
  enabled: false
  
# Настройки Reality Checks (будет реализовано позже)
reality_checks:
  enabled: false

# Настройки безопасности (будет реализовано позже)
security:
  pii_detection: false
  secret_detection: false

# Метаданные (автоматически обновляются)
metadata:
  created_at: "{{CREATED_AT}}"
  clearmethod_version: "0.1.0-mvp"
  last_updated: "{{LAST_UPDATED}}"
