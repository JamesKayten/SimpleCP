# Assistant Notes – simple-cp-test

## 1. Project Overview
- **Project type:** macOS menu bar app with Python backend
- **Main technologies:** Swift, SwiftUI, AppKit, SwiftPM; Python 3.11, FastAPI, Uvicorn
- **High-level goal:** Production-ready clipboard manager with searchable history and saved snippets, backed by a local Python REST API.

## 2. Current State
- **Branch / main line assumptions:** Working directly on `main` in this local clone.
- **Build status:**
  - macOS app (SimpleCP) builds and runs via Xcode and `swift build`.
  - Backend installs via `pip install -e .` in a `.venv` and starts cleanly.
- **Known major limitations:**
  - “Save as Snippet” dialog: saving closes the dialog but does not create/show a new snippet and can reappear on next run.
  - Some SwiftLint warnings remain; not functionally blocking.

## 3. Active Problems / TODOs for the Assistant
_(Items you specifically want my help with, technical or architectural)_

- **[ID-001] Save Snippet dialog doesn’t persist snippets**  
  - Status: `open`  
  - Description:  
    - “Save as Snippet” closes the dialog, but no new snippet appears under the chosen folder.  
    - On app restart, the dialog can reappear with the same content.  
  - Notes / Attempts so far:  
    - Verified `Save Snippet` button tap logs in console.  
    - Need to confirm `saveSnippet()` runs and that `ClipboardManager.saveAsSnippet` updates state/UI correctly.

- **[ID-002] Backend health / lifecycle edge cases**  
  - Status: `in-progress`  
  - Description:  
    - Backend is started by the app using the project `.venv`, but we previously had port-8000 conflicts and manual runs.  
  - Notes / Attempts so far:  
    - Added dev-path shortcut in `findProjectRoot()` and `.venv`-aware `findPython3()`.  
    - Auto-start and health checks now pass; needs more soak testing.

- **[ID-003] GUI polish & UX improvements**  
  - Status: `open`  
  - Description:  
    - Once core flows (clips, snippets, backend) are stable, focus on layout/appearance/interaction polish.  
  - Notes / Attempts so far:  
    - Not started; waiting until ID‑001/002 are stable.

## 4. Design Decisions & Conventions
_(Summarize any decisions we have made together so far)_

- **Architecture:**  
  - Backend process managed by `BackendService` (Swift, @MainActor) and a Python FastAPI server under `backend/`.  
  - Clipboard/snippet state in `ClipboardManager` and extensions; UI in `Views/` and `Components/`.

- **Coding style conventions:**  
  - Prefer single-command / single-edit instructions with the assistant.  
  - Preserve existing comments and documentation.

- **Error handling / logging policy:**  
  - Use `Logger` with subsystem `com.simplecp.app` and category `backend` / `clipboard` for lifecycle events.  
  - Use `AppError` + `lastError` / `showError` for user-facing errors.

## 5. Historical Log of Assistant Sessions
_(Chronological log of changes or insights that matter for future context)_

### Session 2025-12-03 – Backend bring-up & macOS app wiring
- **Summary:**
  - Fixed Swift concurrency/actor issues in backend service/monitoring so the app builds.  
  - Set up the Python backend in `.venv`, created `version.py` and `requirements.txt`, and got `pip install -e .` working.  
  - Wired the macOS app to auto-start the backend from `.venv`, fixed project-root detection, and stabilized connection status.  
  - Began debugging the “Save as Snippet” dialog flow (still open issue).
- **Files touched / relevant:**  
  - `frontend/SimpleCP-macOS/Sources/SimpleCP/Services/BackendService.swift`  
  - `frontend/SimpleCP-macOS/Sources/SimpleCP/Services/BackendService+Monitoring.swift`  
  - `frontend/SimpleCP-macOS/Sources/SimpleCP/Services/BackendService+Utilities.swift`  
  - `frontend/SimpleCP-macOS/Sources/SimpleCP/Managers/ClipboardManager.swift`  
  - `frontend/SimpleCP-macOS/Sources/SimpleCP/Managers/ClipboardManager+Snippets.swift`  
  - `frontend/SimpleCP-macOS/Sources/SimpleCP/Components/SaveSnippetDialog.swift`  
  - `backend/main.py`, `backend/api/server.py`, `backend/daemon.py`, `backend/version.py`  
  - Root: `version.py`, `requirements.txt`, `pyproject.toml`, `setup.py`
- **Outstanding follow-ups:**  
  - [ID-001] Make Save Snippet actually persist and show snippets; stop dialog from reappearing on next run.  
  - [ID-002] Continue verifying backend lifecycle, no stray processes or port 8000 conflicts.  
  - [ID-003] After stability, do GUI polish work.

## 6. Quick Reference / Notes
_(Scratchpad for snippets, commands, or facts you want me to remember)_

- **Build/run commands:**
  - Backend:  
    - `python3 -m venv .venv`  
    - `source .venv/bin/activate`  
    - `pip install -e .`  
  - macOS app:  
    - Open `frontend/SimpleCP-macOS/Package.swift` in Xcode and run the `SimpleCP` scheme.

- **External services / APIs used:**
  - Local FastAPI server at `http://127.0.0.1:8000` (`/health`, `/api/...` endpoints).

- **Misc technical notes:**
  - `findProjectRoot()` currently uses a hardcoded dev path to this checkout; adjust if project path changes.  
  - `findPython3()` prefers `.venv/bin/python3` over system Pythons.  
  - `ClipboardManager` uses `ignoreNextChange` to avoid reacting to programmatic clipboard updates.