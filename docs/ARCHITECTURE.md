# GREAT SAGE Mobile — Architecture

## Principles

1. The mobile app is standalone.
2. The PC version is never required for normal operation.
3. Online AI is optional and isolated behind a provider interface.
4. Android-only capabilities stay behind platform services.
5. UI, assistant logic, voice, storage, and overlay are separate concerns.

## Planned layers

- **UI** — Flutter screens, Raphael presentation, settings and chat.
- **Assistant** — conversation/session orchestration.
- **AI providers** — local and remote model adapters.
- **Voice** — speech-to-text and text-to-speech adapters.
- **Storage** — local preferences, conversations and assistant state.
- **Android bridge** — floating-window permission/service and other platform APIs.

## Milestones

### M0 — Foundation
Project structure, theme, navigation and documentation.

### M1 — Raphael
Replace the placeholder with the Raphael visual layer and interaction states.

### M2 — Chat
Conversation UI and assistant service abstraction.

### M3 — Voice
Speech input and spoken responses.

### M4 — Android overlay
Optional floating Raphael with explicit Android overlay permission.

### M5 — AI providers
Connect configurable online and/or local inference without coupling the app to a PC.

### M6 — Packaging
Release configuration, signed APK/AAB workflow and installation documentation.
