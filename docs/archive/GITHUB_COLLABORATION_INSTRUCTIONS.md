# GitHub Collaboration Instructions for SimpleCP

## Repository Information

**GitHub Repository:** https://github.com/JamesKayten/SimpleCP
**Owner:** JamesKayten
**Project:** SimpleCP - Simple macOS Clipboard Manager

## For Web Claude Development

Copy and paste this entire message to web Claude to continue development:

---

I need you to continue developing **SimpleCP**, a macOS clipboard manager with snippet folders functionality.

**GitHub Repository:** https://github.com/JamesKayten/SimpleCP

**Quick Start Instructions:**

1. **Clone the repository:**
```bash
git clone https://github.com/JamesKayten/SimpleCP.git
cd SimpleCP
```

2. **Read the collaboration guide:**
```bash
# Check current status and implementation roadmap
cat docs/WEB_CLAUDE_COLLABORATION_GUIDE.md

# See project overview
cat README.md
```

3. **Test current functionality:**
```bash
# Install dependencies (if not already installed)
pip3 install rumps pyperclip

# Run the basic framework
python3 main.py
```

4. **Start development:**
   - Current status: ✅ Project structure and basic framework complete
   - Next priority: Implement core classes (HistoryStore, SnippetStore, MenuBuilder)
   - See `docs/WEB_CLAUDE_COLLABORATION_GUIDE.md` for detailed implementation plan

5. **Development workflow:**
```bash
# Always start with latest code
git pull origin main

# Make your changes, then:
git add .
git commit -m "feat: description of your changes"
git push origin main
```

**Goal:** Build a simple, non-subscription-based macOS menu bar clipboard manager with organized snippet folders.

**Technologies:** Python + rumps (menu bar) + pyperclip (clipboard) + JSON (storage)

Please start by reading the collaboration guide and implementing the priority features listed there.

---

## Development Workflow Between Local and Web Claude

### Web Claude Responsibilities:
- 🔧 **Core Implementation**: HistoryStore, SnippetStore, MenuBuilder classes
- 🧠 **Business Logic**: Search algorithms, data management, menu generation
- 📝 **Code Enhancement**: Feature implementation, optimization
- 🐛 **Bug Fixes**: Logic errors, feature improvements

### Local Claude Code Responsibilities:
- 🖥️ **System Integration**: Testing on macOS, file operations
- 🔄 **Git Management**: Repository setup, merge conflict resolution
- 📦 **Packaging**: App bundling, installation scripts
- 🧪 **Testing**: Real-world clipboard testing, user experience validation

### Collaboration Pattern:
1. **Web Claude** implements features and pushes to GitHub
2. **Local Claude Code** pulls changes, tests, and handles system-specific tasks
3. **GitHub** serves as the single source of truth
4. Both environments can work in parallel using git workflow

## Current Repository Status

✅ **Complete Project Setup**
- Full project structure with proper Python packages
- Basic working ClipboardManager framework
- Comprehensive documentation and guides
- Example data files showing expected JSON formats
- Git repository with proper .gitignore
- GitHub repository ready for collaboration

🔄 **Ready for Core Implementation**
- HistoryStore class (clipboard history management)
- SnippetStore class (folder-based snippets)
- MenuBuilder class (dynamic menu generation)
- Settings class (configuration management)

## Repository Structure

```
SimpleCP/
├── main.py                          # ✅ Application entry point
├── clipboard_manager.py             # 🔄 Basic framework (needs enhancement)
├── stores/
│   ├── clipboard_item.py           # ✅ Complete data model
│   ├── history_store.py            # 📝 TODO: Implement
│   └── snippet_store.py            # 📝 TODO: Implement
├── ui/
│   └── menu_builder.py             # 📝 TODO: Implement
├── settings.py                      # 📝 TODO: Implement
├── data/
│   └── example_*.json              # ✅ Example data formats
└── docs/
    ├── README.md                    # ✅ Complete project documentation
    └── WEB_CLAUDE_COLLABORATION_GUIDE.md  # ✅ Technical implementation guide
```

## Key GitHub Commands for Web Claude

```bash
# Check repository status
git status
git log --oneline -5

# Get latest changes
git pull origin main

# Make changes and commit
git add .
git commit -m "feat: implement HistoryStore with deduplication"
git push origin main

# Check what's different
git diff
git diff origin/main
```

## Project Goals Reminder

- 🎯 **Simple**: No subscriptions, no over-engineering
- 📋 **Functional**: Reliable clipboard history and organized snippets
- 🚀 **Fast**: Lightweight Python implementation
- 📁 **Organized**: Folder-based snippet management (key differentiator)
- 🔄 **Collaborative**: Designed for both local and web Claude development

The foundation is solid! Ready for feature implementation. 🎉