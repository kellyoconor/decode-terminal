# TODOS

## High Priority

### Move GitMonitor git commands to background thread — DONE (278250b)
**Fixed:** 2026-03-19. Git polling now runs in a detached Task off main thread.

## Deferred (from design review 2026-03-19)

### Status colors dark mode desaturation — DONE (d36bcd8)
### Type/spacing scale — DONE (f67c550, 4f5f077)
### Empty state icon — DONE (99628b8)
### Onboarding animation curves — DONE (4f5f077)

## Future Features (out of scope)

- Multi-session support (TODO in DecodeApp.swift:35)
- Non-Claude agent grammars (Codex, Aider — protocol exists, needs implementations)
- Session restore UI (persistence works, no browse/restore UI)
- Rate limiting / cost controls for Claude API usage
- App sandboxing + notarization for distribution
- Accessibility: Dynamic Type, keyboard navigation audit
