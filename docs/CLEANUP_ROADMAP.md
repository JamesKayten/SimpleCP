# Simple-CP-Test Cleanup Roadmap

## Visual Repository Map with Issues Highlighted

```
simple-cp-test/                           [328 MB - BLOATED]
│
├── 🔴 CRITICAL: Root-Level Modules (Should be in backend/)
│   ├── logger.py                         [4.8 KB] ⚠️ DUPLICATE with backend/logger.py
│   ├── monitoring.py                     [7.8 KB] ⚠️ DUPLICATE with backend/monitoring.py
│   ├── version.py                        [3.0 KB] ⚠️ DUPLICATE with backend/version.py
│   ├── test_monitoring.py                [12 KB]  ⚠️ SHOULD BE in tests/unit/
│   ├── test_history.py                   [1.4 KB] ⚠️ SHOULD BE in tests/unit/
│   ├── api/                              [40 KB]  ⚠️ SHOULD BE backend/api/ or merged
│   │   ├── __init__.py                   [40 lines, imports from models]
│   │   ├── __pycache__/
│   │   └── ... (mirrors backend/api/)
│   └── claude                            [471 B]  ⚠️ PURPOSE UNCLEAR, move to scripts/
│
├── 🟡 HIGH PRIORITY: Build Artifacts (Removable - 316 MB!)
│   └── frontend/
│       └── SimpleCP-macOS/
│           ├── .build/                   [~150 MB] ❌ DELETE ME
│           │   ├── index-build/          [~90 MB]
│           │   └── arm64-apple-macosx/debug/ [~60 MB]
│           ├── .swiftpm/                 [~6 MB]  ❌ DELETE ME
│           └── .vscode/
│               ├── launch.json           ✓ KEEP
│               └── settings.json         ✓ KEEP
│
├── 🟡 HIGH PRIORITY: Test Files Scattered (Consolidate to tests/)
│   ├── test_history.py                   → tests/unit/test_history.py
│   ├── test_monitoring.py                → tests/unit/test_monitoring.py
│   ├── backend/
│   │   ├── test_history.py               [106 L] → DELETE (move to tests/unit/)
│   │   ├── test_history_direct.py        [102 L] → DELETE (obsolete?)
│   │   └── test_load.py                  [?]     → DELETE or keep?
│   └── tests/
│       ├── unit/                         ✓ CORRECT LOCATION
│       │   ├── test_api_endpoints.py
│       │   ├── test_clipboard_item.py
│       │   ├── test_clipboard_manager.py
│       │   ├── test_history_store.py
│       │   └── test_snippet_store.py
│       ├── integration/                  ✓ CORRECT LOCATION
│       │   ├── test_api.py
│       │   └── test_workflows.py
│       └── performance/                  ⚠️ HAS EMPTY __init__.py
│           ├── __init__.py               [0 bytes]
│           ├── locustfile.py
│           └── test_benchmarks.py
│
├── 🟡 CONFIG FILES (Multiple Locations - Consolidate!)
│   ├── config/                           [44 KB]
│   │   ├── settings.json                 ✓ PRIMARY (keep this)
│   │   ├── .pre-commit-config.yaml       ⚠️ Move to root?
│   │   ├── requirements-dev.txt          ⚠️ Move to root!
│   │   ├── pytest.ini                    ⚠️ Should be at root
│   │   ├── logging_config.py
│   │   └── settings.py
│   ├── .claude/                          [Correct location]
│   │   ├── settings.json                 ⚠️ DUPLICATE - merge with config/
│   │   ├── settings.local.json           ✓ OK (local overrides)
│   │   ├── commands/
│   │   │   ├── fix-pattern.md
│   │   │   └── works-ready.md
│   │   └── hooks/
│   │       ├── session-start-display.sh  [MODIFIED]
│   │       ├── session-start.sh
│   │       └── works-ready-hook.sh
│   ├── backend/config/
│   │   └── config.json                   ⚠️ ISOLATED - merge with config/
│   ├── .env.example                      ✓ CORRECT
│   ├── pyproject.toml                    ✓ CORRECT
│   └── Dockerfile                        ✓ CORRECT
│
├── 🟡 DOCUMENTATION (46 files - TOO MANY!)
│   ├── 📚 docs/
│   │   ├── ARCHIVE/                      [NEW DIRECTORY]
│   │   │   ├── ⚠️ PHASE1_IMPROVEMENTS.md
│   │   │   ├── ⚠️ PHASE_2_TEST_REPORT.md
│   │   │   ├── ⚠️ TASK_COMPLETION_SUMMARY.md
│   │   │   ├── ⚠️ BUILD_SUMMARY.md
│   │   │   ├── ⚠️ FLYCUT_ARCHITECTURE_ADAPTATION.md
│   │   │   ├── ⚠️ HYBRID_ARCHITECTURE_UPDATE.md
│   │   │   ├── ⚠️ PORT_8000_FIX_IMPLEMENTATION.md
│   │   │   ├── ⚠️ RESTART_PROMPT.md
│   │   │   ├── ⚠️ TESTING_COMPLETE.md
│   │   │   ├── ⚠️ INTEGRATION_TEST_REPORT.md
│   │   │   └── ⚠️ TEST_RESULTS.md
│   │   ├── reference/                    [NEW DIRECTORY]
│   │   │   ├── ⚠️ DISTRIBUTION_MARKETING_STRATEGY.md
│   │   │   ├── ⚠️ GROWTH_TACTICS.md
│   │   │   ├── ⚠️ LAUNCH_CHECKLIST.md
│   │   │   ├── ⚠️ LAUNCH_TEMPLATES.md
│   │   │   ├── ⚠️ QUICK_START_LAUNCH_GUIDE.md
│   │   │   ├── ⚠️ STRATEGY_INDEX.md
│   │   │   └── ⚠️ STRATEGY_OVERVIEW.md
│   │   ├── api/
│   │   │   └── ✓ API_REFERENCE.md
│   │   ├── development/
│   │   │   └── ✓ ARCHITECTURE.md
│   │   ├── occ_communication/            [KEEP as-is]
│   │   │   ├── README.md
│   │   │   └── VIOLATION_REPORT_2025-11-17.md
│   │   ├── ✓ README.md                   [Keep - active project overview]
│   │   ├── ✓ API.md                      [Keep - main API docs]
│   │   ├── ✓ TESTING.md                  [Keep - active test guide]
│   │   ├── ✓ TROUBLESHOOTING.md          [Keep - helpful for users]
│   │   ├── ✓ DEPLOYMENT.md               [Keep - deployment info]
│   │   ├── ✓ MONITORING.md               [Keep - monitoring setup]
│   │   ├── ✓ USER_GUIDE.md               [Keep - but consolidate with README]
│   │   ├── ✓ QUICKSTART.md               [Keep - but consolidate]
│   │   ├── ✓ CONTRIBUTING.md             [Keep - project guidelines]
│   │   ├── ✓ CLAUDE.md                   [Keep - AIM instructions]
│   │   ├── ✓ BOARD.md                    [Keep - task tracking]
│   │   ├── ✓ AI_*.md files               [Keep - AIM framework]
│   │   ├── ⚠️ CHANGELOG.md               [Keep but update]
│   │   ├── ⚠️ STATIC_ANALYSIS.md         [Review for relevance]
│   │   ├── ⚠️ IMPROVEMENTS.md            [Review for relevance]
│   │   └── ⚠️ FOLDER_*.md                [Review - old implementations?]
│   └── ⚠️ SimpleCP.pages                 [96 KB] - Move to design/ or archive
│
├── ✓ BACKEND (Mostly Good Structure)
│   ├── api/
│   │   ├── ⚠️ __init__.py               [0 bytes - EMPTY! Should export models]
│   │   ├── endpoints.py                 [250 L] ✓
│   │   ├── models.py                    [165 L] ✓
│   │   ├── server.py                    [212 L] ✓
│   │   └── __pycache__/
│   ├── stores/
│   │   ├── clipboard_item.py            [245 L] ✓
│   │   ├── history_store.py             [176 L] ✓
│   │   ├── snippet_store.py             [215 L] ✓
│   │   ├── __init__.py                  [14 L]  ✓
│   │   └── __pycache__/
│   ├── ui/
│   │   ├── __init__.py                  ✓
│   │   └── menu_builder.py              ✓
│   ├── data/
│   │   ├── example_config.json          ✓
│   │   ├── example_history.json         ✓
│   │   ├── example_snippets.json        ✓
│   │   ├── history.json                 ✓
│   │   └── snippets.json                ✓
│   ├── config/
│   │   └── config.json                  ⚠️ Merge with root config/
│   ├── tests/                           ⚠️ Old test location, move to root/tests/
│   │   ├── generate_test_data.py
│   │   ├── test_basic_history.py
│   │   ├── test_clipboard_manager.py
│   │   ├── test_misc_api.py
│   │   └── test_snippet_folder.py
│   ├── .coverage                        ⚠️ Remove, regenerate on test
│   ├── clipboard_manager.py             [Main logic] ✓
│   ├── config.py                        ✓
│   ├── daemon.py                        ✓
│   ├── keyboard_shortcuts.py            ✓
│   ├── logger.py                        [184 L] - This one is actual backend
│   ├── main.py                          [131 L] ✓
│   ├── settings.py                      [103 L] ✓
│   ├── VERSION                          ✓
│   ├── requirements.txt                 ✓
│   └── __pycache__/
│
├── ✓ TESTS (Mostly Good - Just Consolidate)
│   ├── unit/                            ✓ CORRECT
│   │   ├── test_api_endpoints.py
│   │   ├── test_clipboard_item.py
│   │   ├── test_clipboard_manager.py
│   │   ├── test_history_store.py
│   │   └── test_snippet_store.py
│   ├── integration/                     ✓ CORRECT
│   │   ├── test_api.py
│   │   └── test_workflows.py
│   ├── performance/                     ⚠️ EMPTY __init__.py (fix or delete)
│   │   ├── __init__.py                  [0 bytes]
│   │   ├── locustfile.py
│   │   └── test_benchmarks.py
│   ├── conftest.py                      ✓
│   └── __pycache__/
│
├── ✓ SCRIPTS (Well-organized)
│   ├── aim-launcher.sh                  ✓
│   ├── activate-occ.sh                  ✓
│   ├── build.sh                         ✓
│   ├── backup.sh                        ✓
│   ├── clean.sh                         ✓
│   ├── restore.sh                       ✓
│   ├── setup_dev.sh                     ✓
│   ├── release.sh                       ✓
│   ├── install.sh                       ✓
│   ├── test_installation.sh             ✓
│   ├── healthcheck.sh                   ✓
│   ├── watch-all.sh                     ✓
│   ├── watch-board.sh                   ✓
│   ├── watch-branches.sh                ✓
│   ├── watcher-status.sh                ✓
│   ├── cleanup-watchers.sh              ✓
│   ├── continue-session.sh              ✓
│   ├── tcc-file-compliance.sh           [MODIFIED]
│   ├── tcc-validate-branch.sh           ✓
│   ├── validation/                      ✓
│   │   ├── common.sh
│   │   ├── run_all_tests.sh
│   │   ├── test_documentation_integrity.sh
│   │   ├── test_git_status.sh
│   │   └── test_repository_structure.sh
│   ├── utilities/
│   │   └── aicm/
│   └── README.md                        ✓
│
├── ✓ GITHUB (Good)
│   └── .github/
│       ├── workflows/
│       │   ├── release.yml              ✓
│       │   └── test.yml                 ✓
│       └── ISSUE_TEMPLATE/
│           ├── bug_report.md            ✓
│           └── feature_request.md       ✓
│
├── ⚠️ TOOLS (Mostly OK)
│   ├── monitoring/
│   │   ├── __init__.py
│   │   ├── health.py
│   │   └── metrics.py
│   ├── scripts/
│   │   ├── build_python.sh
│   │   ├── build_swift.sh
│   │   ├── create_app_bundle.sh
│   │   ├── prepare_signing.sh
│   │   └── version_manager.sh
│   └── kill_backend.sh
│
├── 🟡 CACHES & ARTIFACTS (Remove All!)
│   ├── __pycache__/                     ❌ DELETE
│   ├── .pytest_cache/                   ❌ DELETE
│   ├── htmlcov/                         [952 KB] ❌ DELETE
│   ├── .coverage                        ❌ DELETE
│   ├── backend/.coverage                ❌ DELETE
│   ├── coverage.xml                     ❌ DELETE
│   └── api/__pycache__/                 ❌ DELETE
│
├── ✓ ROOT CONFIG (Correct Locations)
│   ├── .gitignore                       ✓
│   ├── .env.example                     ✓
│   ├── Dockerfile                       ✓
│   ├── docker-compose.yml               ✓
│   ├── Makefile                         ✓
│   ├── pyproject.toml                   ✓
│   ├── pytest.ini                       ⚠️ Move from config/ to root
│   ├── setup.py                         ✓
│   ├── README.md                        ✓
│   ├── LICENSE                          ✓
│   ├── QUICKSTART.md                    ✓
│   ├── CHANGELOG.md                     ✓
│   ├── CONTRIBUTING.md                  ✓
│   └── ANALYSIS_QUICK_REFERENCE.txt     [NEW]
│
├── ✓ .GIT (Healthy)
│   └── [Git history is clean and well-maintained]
│
└── ⚠️ HIDDEN DIRECTORIES
    ├── .claude/                         ✓ Well-structured
    ├── .github/                         ✓ Correct
    ├── .vscode/                         ⚠️ At root - should be in specific projects
    └── frontend/SimpleCP-macOS/.vscode/ ✓ Correct
```

## Color Legend

- 🔴 **CRITICAL** - Must fix for production readiness
- 🟡 **HIGH PRIORITY** - Should fix for professional standards
- ⚠️ **ISSUE** - Needs attention/review
- ✓ **GOOD** - Correct location/structure
- ❌ **DELETE** - Safe to remove, recreates on rebuild/test

## Summary Statistics

| Category | Count | Status |
|----------|-------|--------|
| Critical Issues | 3 | MUST FIX |
| High Priority Issues | 4 | SHOULD FIX |
| Duplicate Files | 5-6 | REMOVE |
| Obsolete Docs | 15+ | ARCHIVE |
| Empty Files | 6 | REMOVE/FIX |
| Removable Artifacts | 4 types | DELETE |
| Root Python Modules | 5 | DELETE |
| Config File Locations | 4-6 | CONSOLIDATE |
| Hardcoded Paths | 251+ | FIX |

## Action Items by Priority

### Immediate (Do First)
- [ ] Delete Swift build artifacts (saves 316 MB)
- [ ] Remove root-level duplicate modules
- [ ] Move test files to tests/ directory
- [ ] Clean up Python caches

### Short Term (Next)
- [ ] Consolidate config files
- [ ] Archive obsolete documentation
- [ ] Move marketing docs
- [ ] Fix empty __init__.py files

### Medium Term (Then)
- [ ] Fix 251+ hardcoded paths
- [ ] Consolidate documentation duplicates
- [ ] Set up pre-commit validation
- [ ] Document scripts and utilities

### Long Term (Finally)
- [ ] Improve test coverage measurements
- [ ] Automated cleanup prevention
- [ ] Complete BOARD.md functionality
- [ ] Comprehensive documentation review

---

*This roadmap was generated by comprehensive repository analysis on 2025-12-03.*
*See STRUCTURE_ANALYSIS.md for detailed technical findings.*
