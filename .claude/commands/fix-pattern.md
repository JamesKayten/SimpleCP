# Fix Pattern Command

**MANDATORY PATTERN PROPAGATION RULE**

When fixing ANY pattern (hardcoded paths, API changes, config updates):

## Execution Steps

### 1. FIRST - Find ALL instances
```bash
grep -rn "<pattern>" --include="*.sh" --include="*.py" --include="*.swift" --include="*.md" .
```

### 2. LIST all files containing the pattern
Display each file path and line number where the pattern occurs.

### 3. FIX ALL instances
Fix every occurrence found, not just the one originally encountered.

### 4. CHECK SOURCE TEMPLATES
If the pattern came from `aim init`, fix the source templates in the AIM framework repository.

## Usage
`/fix-pattern "hardcoded-string" "replacement"`

## Common Patterns to Check
- Hardcoded paths: `/home/user`, `/Users/`, `/Volumes/`
- Project names: `SimpleCP`, `AI-Collaboration-Management`
- Absolute paths that should be relative
- API endpoints that changed
- Configuration keys that were renamed

## Standard Path Detection
Use this pattern in ALL shell scripts:
```bash
# Use relative paths - detect repo root from script location
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
```

## Validation
After fixing:
1. Search again to confirm all instances resolved
2. Test affected functionality
3. Update any related documentation
4. Check if the fix needs to propagate to AIM init templates

**Remember: Partial fixes create technical debt. Fix the pattern completely or don't fix it at all.**