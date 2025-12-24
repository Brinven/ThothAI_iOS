ThothAI iOS — Task Plan (MVP → v1.1)
Purpose

This document defines the implementation order, module responsibilities, and definition of done for building ThothAI iOS.

The Behavioral Specification (v1.1) is the sole source of truth for what the app does.
This plan defines how work is sequenced, not architectural patterns or UI layouts.

Global Rules (Non-Negotiable)

Offline-first: all processing occurs on-device

No cloud inference, no telemetry, no external data transmission

Model files are treated as data assets, not executable code

iOS sandbox rules must be respected at all times

Do not invent features or shortcuts not present in the spec

If behavior is ambiguous → create an Open Question instead of assuming

Locked Product Decisions (DO NOT REVISIT)
Duplicate PDF Handling

If a PDF with the same content hash already exists in a knowledge base:

The app prompts the user: Re-import / Skip

Silent overwrite is not allowed

Memory Policy

Chatbot Mode

Session memory enabled by default

Optional persisted memory via explicit user toggle

RAG Mode

Never uses conversational memory for generation

Each query is stateless and document-grounded

Phase 0 — App Skeleton & Global State
Modules

AppCore

ModeController

StorageManager

Tasks

Define global AppState

activeKnowledgeBase

activeModel

activeMode

activeProfile

memoryPolicy

Implement ModeController

Mode switching

Memory policy enforcement

Guardrail: RAG mode cannot access chat memory

Implement StorageManager

App-managed directories (KBs, models, settings)

Atomic write helpers

Free space checks (basic)

Definition of Done

App launches cleanly

Mode switching works and persists

No crashes on background/foreground

No feature logic yet — only state + scaffolding

Phase 1 — Models & Generation (Minimal Viable Inference)
Modules

ModelManager

LLMRuntime

ProfileManager

Tasks

ModelManager (MVP)

Import model via Files app

Store model in app-managed storage

List models

Set active model

Delete model

LLMRuntime (MVP)

Load active model

Generate response from plain prompt

Return:

output text

timing metrics

Surface actionable errors:

insufficient memory

corrupted model

incompatible format

ProfileManager

Default profile per model (non-deletable)

Validate parameter ranges

Persist profiles

Switch active profile

Definition of Done

User can import a model

User can select model + profile

App can generate a response to a simple prompt

Errors are visible and actionable

Phase 2 — Knowledge Bases & PDFs
Modules

KnowledgeBaseManager

DocumentImportManager

PDFViewerCoordinator (basic)

Tasks

KnowledgeBaseManager

Create / rename / duplicate / delete KB

Set active KB

Persist KB metadata

DocumentImportManager

Import PDFs via document picker / share sheet

Copy files into app-managed storage

Validate PDFs

Detect duplicates (hash-based)

Prompt Re-import / Skip on duplicates

PDFViewerCoordinator (MVP)

Open PDFs

Navigate pages

Handle missing/corrupt PDFs gracefully

Definition of Done

User can create a KB

User can import PDFs into a KB

PDFs are viewable

KB isolation is enforced

Phase 3 — Ingestion & Retrieval (RAG Core)
Modules

IngestionEngine

VectorIndex

CitationResolver

Tasks

IngestionEngine

Extract text from PDFs

Chunk text

Generate embeddings

Persist chunks + embeddings

Emit progress updates

Guarantee:

completed docs are queryable

partial docs are never queryable

interruptions do not corrupt KB

VectorIndex

Store embeddings per KB

Perform similarity search

Return ranked hits with metadata

Cleanly report “no relevant chunks”

CitationResolver

Convert hits → citations

Include page number when reliable

Otherwise provide clearly labeled location hints

Provide navigation targets for PDFViewer

Definition of Done

PDFs can be ingested into KB

KB becomes queryable only after successful ingestion

RAG queries return answers with citations

Clicking citations navigates to source PDFs

Phase 4 — Query Orchestration & Mode Semantics
Modules

ChatMemoryStore

QueryOrchestrator

Tasks

ChatMemoryStore

Session memory storage

Optional persisted memory toggle

Clear memory on request

Enforced exclusion from RAG mode

QueryOrchestrator

RAG pipeline:

embed query

vector search

context assembly

generation

citation resolution

Chatbot pipeline:

memory (if enabled)

generation

User-visible status updates

Definition of Done

RAG mode answers are stateless and cited

Chatbot mode maintains conversation memory

Switching modes changes behavior immediately

No memory leaks between modes

Phase 5 — Model Downloads (v1.1 Enhancements)
Modules

ModelManager (extended)

Tasks

Recommended Model Download

Offer optional first-run download

Explicit user consent

Resume-capable download

Safe cancellation

Hugging Face Support

MVP:

Paste direct model file URL

Next:

Repo + file selection

Optional:

User-provided HF access token for gated models

Definition of Done

App can function without bundled models

User can download recommended model

User can import models from Hugging Face

Downloads do not break if app backgrounds

Phase 6 — Resource Awareness & Polishing
Tasks

Storage usage reporting (KBs / models / PDFs)

Battery & thermal warnings

“Lower Power” configuration preset

Improved ingestion resume handling

UX polish (progress, errors, confirmations)

Definition of Done

App degrades gracefully under pressure

Users understand resource costs

No silent failures

MVP Completion Criteria

The MVP is complete when a user can:

Import or download a model

Create a knowledge base

Ingest PDFs

Ask document-grounded questions with citations

Chat conversationally with memory

Switch modes safely

Operate fully offline

Understand and recover from errors

Final Note to Cursor

If at any point a requested behavior is not explicitly defined:

STOP

Add it to an Open Questions list

Do not guess
