# agentfill Project

This file provides context and instructions for AI coding agents working on this project. [Read the README](./README.md) to understand what this project is about.

## Documentation

This project maintains detailed documentation in the `docs/` directory:

- **[docs/AGENTS.md](docs/AGENTS.md)** - Documentation index and formatting guidelines
- **[docs/Comparison.md](docs/Comparison.md)** - Comprehensive comparison with similar projects (Ruler, OpenSkills, CCS, etc.)
- **[docs/agents/](docs/agents/)** - Per-agent configuration references

**For AI Agents**: When you need context about:
- Agent configuration formats and file locations
- How specific agents work
- Config file structures and hierarchies

Read the relevant documentation in `docs/agents/<Agent>.md` first.

**To understand the ecosystem**: Read [docs/Comparison.md](docs/Comparison.md) for analysis of similar projects, alternative approaches, and how this project compares to Ruler, OpenSkills, symlinks, and other solutions.

**When you learn new information** about agents or configuration:
- Update the relevant docs in `docs/agents/`
- Update [docs/Comparison.md](docs/Comparison.md) if you learn about competing/related projects
- Keep documentation accurate and up-to-date
- Add sources for new information

## Test Suite Context

When working on test files or testing-related code (anything in the `tests/` directory), you should read **[tests/AGENTS.md](tests/AGENTS.md)** to understand:

- Test suite organization and structure
- How to run different test categories (unit tests, agent integration tests)
- Shared test utilities in `tests/_common/`
- Test isolation principles and why they matter
- Guidelines for writing new tests

This applies when:
- Modifying existing test files
- Creating new tests
- Debugging test failures
- Working on test runner scripts
- Understanding test output or behavior

## Pre-Commit Checklist

**CRITICAL**: Before committing any changes to this repository, you MUST:

1. **Compile**: If you modified any `src/` files, run `./scripts/compile.sh` to regenerate `site/install`
2. **Update polyfills**: If you modified install source files, run `./install.sh` in the repository to update `.agents/polyfills/` with the latest templates
3. **Run unit tests**: Execute `./tests/test-unit.sh` and ensure all tests pass
4. **Verify changes**: Review that polyfill files match the templates and `site/install` is up to date

These steps ensure:
- Code changes don't break existing functionality
- `site/install` stays in sync with `src/` modules
- Polyfill files stay in sync with install script templates
- CI checks will pass when the PR is created

**Example workflow**:
```sh
# After modifying src/ files
./scripts/compile.sh           # Regenerate site/install from src/
./install.sh                   # Update polyfills from templates
./tests/test-unit.sh           # Run all unit tests
git add -A                     # Stage everything
git commit -m "Your message"   # Commit together
```

