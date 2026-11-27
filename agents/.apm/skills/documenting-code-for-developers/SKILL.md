---
name: documenting-code-for-developers
description: Use when asked to write developer documentation, technical docs, crate docs, module docs, architecture docs, or integration guides for a codebase. Triggers on "document this", "write docs", "add documentation", "create developer guide", "document this crate/module/library".
---

# Documenting Code for Developers

## Overview

Developer documentation answers three questions a developer has when encountering code: How is it structured? How do I use it? How do I configure it?

Output is always written in **English**, regardless of the conversation language.

## Output Recipe

Produce these four sections **in this order**. Every section is required.

### 1. Architecture

Show the structural picture before anything else.

- Crate/module map: one line per public module, what it owns
- Inter-crate or inter-module dependencies (who imports whom)
- Key abstractions: the 1-3 types that everything else revolves around
- Data flow: how data moves through the system at a high level

Format: short prose + a dependency list or ASCII diagram. No API details here.

### 2. Usage

Show a developer how to instantiate and call the code.

- Minimal working example: create the main type, call 2-3 primary operations
- Code block in the library's language, runnable as-is
- Annotate the example with inline comments explaining the WHY, not the what
- Cover the primary happy path only — edge cases go in API Reference

```rust
// Example skeleton
let db = AppDb::open("app.db")?;            // opens + runs migrations
let accounts = db.account_list()?;          // read path
db.transaction_insert(...)?;                // write path
```

### 3. Configuration

Enumerate everything a developer must decide before the code works correctly.

- Initialization parameters and what each controls
- Runtime options (feature flags, environment variables, PRAGMA settings)
- What happens with defaults (safe? opinionated? surprising?)
- Any configuration that must happen before first use

Only include what is actually configurable from the calling code. Do not invent options.

### 4. Error Handling

- Error type(s) exposed by the public API
- Variants and when each is returned
- How to handle: which errors are recoverable vs fatal

## Language Rule

Always write in English. Even if the conversation is in German or another language, the documentation output is English. Code and identifiers stay in their original language.

## Perspective Rule

Write for a developer who is **integrating or extending** the code — not an end user, not a maintainer doing archaeology. Answer: "What do I need to know to build against this?"

**Source fidelity:** Document only what is visible in the provided source files. If a detail (a path, a config value, a behavior) is not in the code shown, do not include it. A blank slot in the Configuration section is correct; an invented value is wrong.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Start with API reference, skip architecture | Architecture always comes first |
| No code example in Usage | Every doc needs a runnable snippet |
| Invent details not in source | Only document what is actually in the code |
| Write in conversation language | Output is always English |
| Describe every method equally | Lead with the 2-3 methods callers use most |
