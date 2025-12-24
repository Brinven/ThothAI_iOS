ThothAI iOS — Behavioral Specification (v1.1)
Document Purpose

This specification defines what the ThothAI iOS application does from the user’s perspective.
It intentionally avoids implementation details, UI layout prescriptions, and framework choices.

The goal is to describe observable behavior, data handling guarantees, and mode semantics suitable for a native iOS application.

1. Application Overview
1.1 Core Purpose

ThothAI iOS allows users to:

Build local knowledge bases from PDF documents

Query those knowledge bases using on-device AI

Interact with a local LLM in two distinct modes:

RAG Mode (document-grounded, stateless)

Chatbot Mode (conversational, optional memory)

All processing occurs entirely on the device.
No user data is transmitted externally.

2. Modes of Operation
2.1 RAG Mode (Retrieval-Augmented Generation)

Answers are grounded only in ingested documents

Each query is independent

No conversational memory is used

Context is derived solely from retrieved document chunks

Responses include source citations

RAG Mode prioritizes:

Accuracy

Verifiability

Reproducibility

2.2 Chatbot Mode

Operates without document retrieval

Supports conversation memory

Intended for general reasoning, exploration, and discussion

Memory behavior:

Session memory is enabled by default

Persistent chat history is optional and user-controlled

Switching away from Chatbot Mode disables memory usage

3. Knowledge Base Management
3.1 Knowledge Bases

Users can create, rename, duplicate, and delete knowledge bases

Each knowledge base is fully isolated

Only one knowledge base is active at a time

Queries operate exclusively on the active knowledge base

3.2 Document Ingestion

Users add PDF files via:

iOS document picker

Share sheet

External providers (e.g., iCloud, Dropbox)

Behavioral guarantees:

Selected PDFs are imported into app-managed storage

External references are not relied upon for offline use

Ingestion progress is visible

Ingestion can be paused, resumed, or retried

If ingestion is interrupted (backgrounding, termination):

Previously completed documents remain valid

Partial work does not corrupt the knowledge base

The app resumes ingestion when possible

4. Query Behavior
4.1 RAG Queries

For each query:

Relevant document chunks are retrieved

Context is constructed from retrieved content

The LLM generates a response using that context

Sources are presented alongside the answer

Citations:

Include document name

Include page number when reliably available

Otherwise indicate approximate location clearly

If no relevant content is found:

The app returns a clear “insufficient context” response

Behavior is consistent and predictable

4.2 Chatbot Queries

Responses are generated directly from the model

No document search is performed

Conversation state is respected only in Chatbot Mode

5. Model Management
5.1 Supported Model Sources

The app supports acquiring models from:

Recommended Models

Curated by the application

Offered on first launch as an optional download

Downloaded only with user consent

Hugging Face

Users may provide:

A direct model file URL

A repository identifier and file selection

Optional user-provided access token for gated models

Local Import

Users may import model files via the Files app

5.2 Model Storage & Activation

All models are stored in app-managed storage

Models are treated as data assets

Users may:

Activate one model at a time

Remove unused models

View model metadata (size, source)

If a model cannot be loaded:

The app reports the issue clearly

Provides actionable guidance (e.g., memory limits, corruption)

6. Configuration Profiles

Configuration profiles define model behavior:

System prompt

Sampling parameters

Token limits

Profiles are:

Model-specific

Persisted across sessions

A default profile always exists and cannot be deleted

Switching models:

Does not alter knowledge bases

Activates the last-used profile for that model

7. Data Handling & Privacy
7.1 Storage Guarantees

All data remains on-device

No cloud synchronization

No telemetry or analytics uploads

No external inference services

Stored data includes:

PDFs

Embeddings

Knowledge base metadata

Model files

Configuration profiles

7.2 Data Integrity

Knowledge bases are always in a consistent state

Partial ingestion results are not queryable

Deletion is explicit and confirmed

8. Platform Constraints (Behavioral Impact)

The application respects iOS constraints:

Sandboxed file access

Limited background execution

Memory pressure handling

Thermal and battery awareness

User-visible behaviors include:

Progress indicators for long operations

Warnings for resource-intensive models

Graceful degradation under system pressure

9. Error Handling

All error states are:

User-visible

Non-destructive

Actionable

Examples:

Model incompatibility

Insufficient storage

Corrupted PDFs

Interrupted ingestion

Missing models

The app never silently fails.

10. Explicit Non-Goals

This specification does not include:

Cloud sync or collaboration

Multi-model simultaneous execution

Remote APIs or server mode

OCR processing

Exporting knowledge bases

Plugin systems

Arbitrary filesystem browsing

11. Success Criteria

The application is successful if users can:

Build multiple independent knowledge bases

Ingest PDFs reliably with visible progress

Query documents with verifiable sources

Use Chatbot Mode with optional memory

Manage and switch on-device models

Operate fully offline after setup

Understand and recover from errors

Trust that their data never leaves the device

Document History

v1.0 — Initial desktop-derived draft

v1.1 — iOS-native behavioral rewrite (this document)

Date — 2025-12-22

Final verdict (important)

This spec is now:

✅ iOS-legal

✅ Cursor-friendly

✅ App-Review-safe

✅ Architecture-agnostic

✅ Ready to drive implementation

What I recommend next

Lock this spec (no more feature creep)

Define MVP vs v2 boundaries

Create an empty SwiftUI shell

Let Cursor scaffold from this document only

If you want, next I can:

Mark MVP-only vs later behaviors

Translate this into a Cursor system prompt

Draft the Model Manager and Mode Controller responsibilities

Help you pre-empt App Review questions