# ClearMethod Priming Configuration
# Defines what context to load when agent starts (/cm-prime)

primers:
  # Core framework (REQUIRED)
  core:
    - path: .cm/core/primer.md
      required: true
    
    - path: .cm/core/cml/primer.md
      required: true
  
  # Active extensions (in load order)
  extensions:
    - path: .cm/packages/file-task/primer.md
      required: true
    
    - path: .cm/packages/sbd/primer.md
      required: true
  
  # Project-specific context (OPTIONAL)
  project:
    - path: .cm/context/architecture.md
      required: false
    
    - path: .cm/context/tech-stack.md
      required: false
    
    - path: .cm/context/conventions.md
      required: false

# Estimated total tokens: ~5-8K
# Target: Load maximum useful context with minimum tokens

