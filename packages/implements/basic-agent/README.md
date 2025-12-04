# Basic Agent

**Default implementation of AGENT concept.**

Works in any environment using available tools or approximate estimation.

---

## Philosophy

"Best effort" approach:
- Use accurate tools when available
- Fall back to approximation when not
- Always provide an answer, never block

---

## Methods

### get_info()

Returns agent information (model, provider, context_window).

```yaml
- let: info = AGENT.get_info()
- info: "Running {info.model} on {info.provider}"
```

**Strategy:**
1. Use self-knowledge (AI knows its own model)
2. Check project config
3. Return defaults if unknown

---

### get_tokens_used()

Estimates tokens currently in context.

```yaml
- let: used = AGENT.get_tokens_used()
- info: "Context: {used} tokens used"
```

**Strategy:**
1. Use platform token counter if available
2. Approximate from character count (~4 chars/token)
3. Conservative 50% estimate as last resort

---

### get_tokens_available()

Returns remaining token capacity.

```yaml
- let: available = AGENT.get_tokens_available()
- if: available < 10000
  then:
    - warn: "Running low on context space"
```

---

### estimate_tokens(text)

Estimates tokens in given text.

```yaml
- let: tokens = AGENT.estimate_tokens(file_content)
- info: "File would use ~{tokens} tokens"
```

**Ratios:**
- English text: ~4 chars/token
- Code: ~3 chars/token
- Non-Latin (Cyrillic, CJK): ~2 chars/token

---

### can_fit(tokens)

Checks if content fits in available space.

```yaml
- let: tokens = AGENT.estimate_tokens(large_file)
- if: AGENT.can_fit(tokens)
  then:
    - "Load full file"
  else:
    - "Load summary only"
```

---

## Configuration

Override defaults in `.cm/project.yml`:

```yaml
agent:
  model: "gpt-4o"
  provider: "openai"
  context_window: 128000
```

---

## Limitations

1. **Token counting is approximate** — actual tokenization varies by model
2. **Context tracking is session-based** — resets with new conversation
3. **Self-knowledge depends on AI** — some models don't know their identity

---

## Files

```
packages/implements/basic-agent/
├── package.yml
├── concept.yml
├── README.md
├── primer.md
└── methods/
    ├── get_info.yml
    ├── get_tokens_used.yml
    ├── get_tokens_available.yml
    ├── estimate_tokens.yml
    └── can_fit.yml
```

---

**Status:** MVP  
**Version:** 0.1.0  
**License:** MIT

