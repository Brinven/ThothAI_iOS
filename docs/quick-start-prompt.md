# Quick Start Prompt for New Conversations

Copy and paste this into a new conversation to quickly get up to speed:

---

**You are working in the thothai-ios repository.**

**Read and obey:**
- `.cursor/rules.md` — Development guidelines
- `docs/behavioral-spec.md` — Behavioral specification (source of truth)
- `docs/task-plan.md` — Implementation phases
- `docs/project-summary.md` — Current project state

**Current Status:**
- **Phase**: 1c-A2 (GGUF inference integration)
- **Last Work**: llama.cpp bridge implementation complete, needs Xcode configuration
- **Key Files**: See `docs/project-summary.md` for full structure

**Project Overview:**
ThothAI iOS is a native iOS app for local knowledge bases and on-device AI. Two modes: RAG (document-grounded) and Chatbot (conversational). All processing on-device, no data leaves device.

**Architecture:**
- SwiftUI + Swift
- llama.cpp for GGUF inference (CPU-only)
- AppCore manages global state (AppState, ModelManager, ModeController, LLMRuntime)
- Models stored in app-managed storage
- Observable state via Combine

**Key Constraints:**
- Offline-first, no cloud
- Models are data assets (not executable code)
- All errors must be user-visible and actionable
- Don't add features not in behavioral spec

**Current Task:**
[Describe what you're working on]

---

**For detailed context, see `docs/project-summary.md`**

