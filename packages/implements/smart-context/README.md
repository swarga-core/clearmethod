# Smart Context Package

**Intelligent context management for AI agents with JIT loading and automatic optimization.**

> Status: **Planned** (Concept only, no implementation yet)

---

## Problem

Manual context management has issues:
- ❌ Too much irrelevant information loaded
- ❌ Agent wastes tokens on unused context
- ❌ Difficult to know what to load when
- ❌ Context grows unbounded
- ❌ No adaptation to workflow stage

---

## Solution

**Smart Context** automatically manages the agent's context window:
- ✅ JIT (Just-In-Time) loading - load only when needed
- ✅ Semantic search - find relevant files automatically
- ✅ Stage-aware - different context for different stages
- ✅ Auto-pruning - remove irrelevant information
- ✅ Budget optimization - stay within token limits

---

## Key Features

### 1. JIT Context Loading

```yaml
# Agent is implementing a feature
instructions:
  - CONTEXT.smart_load("authentication")
  
# Smart Context:
#   1. Identifies current stage (implementing)
#   2. Finds relevant files (auth module, tests, docs)
#   3. Loads only top-5 most relevant
#   4. Stays within token budget
```

### 2. Semantic Search

```yaml
# Find files related to concept
- CONTEXT.load_similar("JWT token validation")

# Returns:
#   - src/auth/jwt-validator.ts
#   - tests/auth/jwt.test.ts
#   - docs/security/jwt-best-practices.md
```

### 3. Stage-Aware Context

Different stages need different information:

**Designing stage:**
- Architecture documents
- Design patterns
- Similar implementations
- API contracts

**Implementing stage:**
- Source files
- API documentation
- Test examples
- Code style guide

**Verifying stage:**
- Test files
- Coverage reports
- Acceptance criteria
- QA checklists

### 4. Auto-Pruning

```yaml
# Context grows too large
- if: CONTEXT.get_budget().used > 0.8
  then:
    - CONTEXT.prune()  # Remove least relevant content
```

### 5. Budget Management

```yaml
- CONTEXT.get_budget()
  into: budget

# Returns:
#   max_tokens: 100000
#   used_tokens: 75000
#   available: 25000
#   percentage: 0.75
#   status: "warning"
```

---

## Use Cases

### UC-1: Feature Implementation

```yaml
# Agent starts implementing
- WORKFLOW.go("TASK-001", "implementing")

# Smart Context automatically loads:
#   ✅ Related source files (semantic search)
#   ✅ Tests for similar features
#   ✅ API documentation
#   ✅ Design document from previous stage
#   ❌ Architecture docs (not needed now)
#   ❌ Deployment configs (not relevant)
```

### UC-2: Bug Investigation

```yaml
# Agent needs to understand error
- CONTEXT.smart_load("PaymentProcessingError")

# Loads:
#   - src/payments/processor.ts (where error occurs)
#   - src/payments/types.ts (error definition)
#   - tests/payments/error-handling.test.ts (test cases)
#   - logs/recent-errors.log (context)
```

### UC-3: Context Optimization

```yaml
# Before verifying stage
- CONTEXT.optimize_for_stage("verifying")

# Prunes:
#   - Implementation details (not needed)
#   - Architecture docs (not relevant)
  
# Loads:
#   - Test files
#   - Acceptance criteria
#   - QA checklist
```

---

## API (Planned)

### CONTEXT.prime()
Load initial context from `.cm/priming.yml`.

### CONTEXT.load(context_info)
Load specific context segment.

### CONTEXT.smart_load(query)
Auto-determine and load relevant context based on query and current stage.

**Parameters:**
- `query` (string) - What agent is looking for

**Returns:**
```yaml
{
  loaded_files: [string],
  total_tokens: number,
  relevance_scores: [number]
}
```

### CONTEXT.prune(strategy?)
Remove irrelevant context to free up tokens.

**Strategies:**
- `lru` - Least Recently Used (default)
- `low_relevance` - Remove lowest relevance items
- `stage_irrelevant` - Remove items not relevant to current stage

### CONTEXT.get_budget()
Get current token usage statistics.

**Returns:**
```yaml
{
  max_tokens: number,
  used_tokens: number,
  available: number,
  percentage: number,
  status: "ok" | "warning" | "critical"
}
```

### CONTEXT.optimize_for_stage(stage)
Optimize context for specific workflow stage.

---

## Configuration

```yaml
packages:
  smart_context:
    enabled: true
    
    # Token budget
    max_tokens: 100000
    reserved_for_output: 8000
    warning_threshold: 0.8
    
    # Auto-loading
    auto_load:
      enabled: true
      on_stage_change: true
      on_property_access: true
    
    # Semantic search
    semantic_search:
      enabled: true
      model: "text-embedding-3-small"
      top_k: 5
      min_similarity: 0.7
    
    # Stage contexts
    stage_contexts:
      designing:
        categories:
          - architecture
          - design_patterns
          - similar_code
        max_files: 10
      
      implementing:
        categories:
          - source_code
          - api_docs
          - tests
        max_files: 15
      
      verifying:
        categories:
          - tests
          - acceptance_criteria
          - qa_checklist
        max_files: 8
    
    # Pruning
    auto_prune:
      enabled: true
      trigger_threshold: 0.85
      strategy: "lru"
      keep_pinned: true
      min_relevance: 0.3
```

---

## Technical Approach

### Semantic Search

1. **Embeddings**: Generate embeddings for all project files
2. **Index**: Store in vector database (or simple file)
3. **Query**: Convert query to embedding
4. **Search**: Find top-K most similar files
5. **Load**: Load files into context

### Relevance Scoring

```python
relevance = (
  semantic_similarity * 0.4 +
  stage_relevance * 0.3 +
  recency * 0.2 +
  access_frequency * 0.1
)
```

### Context Budget

```
Total Tokens = 100K
Reserved for Output = 8K
Available for Context = 92K

Current Usage:
  Primers: 15K
  Task Data: 5K
  Source Files: 45K
  Docs: 20K
  ─────────────
  Total: 85K (92% of budget)
  
Status: ⚠️ Warning (trigger pruning)
```

---

## Integration with Workflows

Smart Context hooks into workflow events:

```yaml
# SBD workflow integration
on: task.stage_started
  - CONTEXT.optimize_for_stage(event.payload.stage)
  - CONTEXT.smart_load(event.payload.stage_goal)

on: task.property_changed
  if: property == "design_doc_path"
  - CONTEXT.load(new_value)

on: workflow.stage_completed
  - CONTEXT.prune("stage_irrelevant")
```

---

## Benefits

1. **Token Efficiency** - No wasted tokens on irrelevant info
2. **Automatic** - Agent doesn't need to manually manage context
3. **Stage-Aware** - Adapts to current workflow needs
4. **Scalable** - Works with large codebases
5. **Smart** - Learns from patterns and usage

---

## Future Enhancements

- **Learning**: Learn from agent's actual file usage
- **Predictive**: Preload files likely to be needed
- **Multi-modal**: Handle images, diagrams, etc.
- **Collaborative**: Share context between agents
- **Compression**: Smart summarization of large files

---

## Dependencies

- `core-concept` - CONTEXT, TASK, WORKFLOW abstractions
- `file-task` - For task access

---

## See Also

- [CONTEXT Concept](../../concepts/core-concept/context.yml)
- [Core Concepts](../../concepts/core-concept/)
- [Workflow Integration](../sbd/)

---

**Status:** Planned  
**Priority:** High (foundational for agent efficiency)  
**Complexity:** High (requires embeddings, semantic search)

