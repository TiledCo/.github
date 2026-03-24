# Agent Workflow Guide

> **Audience:** Tiled devs setting up Copilot.
> This guide walks you through setup, explains how the system works, and teaches the full feature development lifecycle using agent mode at Tiled.

---

## Table of Contents

1. [Setup](#1-setup)
2. [How the System Works](#2-how-the-system-works)
3. [Feature Development Lifecycle (SDLC)](#3-feature-development-lifecycle-sdlc)
4. [Daily Tasks](#4-daily-tasks)
5. [Prompt Cookbook](#5-prompt-cookbook)
6. [Troubleshooting & FAQ](#6-troubleshooting--faq)

---

## 1. Setup

### 1.1 Prerequisites

- **VS Code** 1.100+ (latest stable recommended)
- **Node.js** — check the `.nvmrc` file in the sub-project you're working in (most use Node 22)
- **Git** 2.40+ (worktree support required)
- **GitHub account** with access to the Tiled repositories

### 1.2 Install GitHub Copilot

1. Open VS Code
2. Go to the Extensions panel (`Cmd+Shift+X`)
3. Search for **"GitHub Copilot"** and install it (this installs both Copilot and Copilot Chat)
4. Sign in with your GitHub account when prompted
5. Your account needs to have access to Copilot enabled

### 1.3 Enable Agent Mode

Agent mode is how Copilot goes from "autocomplete helper" to "autonomous coding agent." It can run terminal commands, edit files, search the codebase, and execute multi-step tasks.

1. Open the Copilot Chat panel (`Cmd+Shift+I` or click the Copilot icon in the sidebar)
2. At the top of the chat input, you'll see a **mode selector** — a dropdown that says "Agent", "Ask", or "Plan"
3. Select **"Agent"** — this is where you'll spend most of your time

**The three modes:**

| Mode | What it does | When to use |
|------|-------------|-------------|
| **Ask** | Answers questions, no file changes | Quick questions about code |
| **Edit** | Edits files you specify, no terminal access | Small targeted edits |
| **Agent** | Full autonomy — edits files, runs commands, searches code, dispatches sub-agents | Feature work, debugging, anything multi-step |

### 1.4 Choose a Model

In the chat panel, click the **model selector** (next to the mode selector) to choose which AI model powers the agent.

| Model | Best for | Speed |
|-------|----------|-------|
| **Claude Opus 4** | Design specs, architecture, complex planning, debugging hard issues | Slower, most capable |
| **Claude Sonnet 4** | Implementation, day-to-day coding, code review, quick tasks | Fast, very capable |
| **GPT-4.1** | General coding, alternative perspective | Fast |

**Recommendation:** Use **Claude Opus 4** when you're in "Plan mode" designing features. Switch to **Claude Sonnet 4** when you're executing implementation plans or doing daily tasks. You're free to experiment and find what works for you.

### 1.5 Add the Anthropics Plugin Marketplace

Before installing the agent plugins, you need to add the Anthropics marketplace as a source:

1. Open the Copilot Settings (`Cmd+,`)
2. Go to **Chat > Plugins: Marketplaces**
3. Click **"Add Item"**
4. Enter: `anthropics/claude-plugins-official`

This gives you access to agent plugins and MCP servers from the marketplace.

### 1.6 Install Superpowers

Superpowers is a plugin that gives Copilot a structured skill system — it knows *how* to brainstorm, plan, write tests, debug, and review code using proven workflows instead of ad-hoc responses.

1. Open the Extensions panel (`Cmd+Shift+X`)
2. Search for **"Superpowers"**
3. Install it
4. Restart VS Code when prompted

**Verify it installed:**

The plugin lives on disk at:
```
~/Library/Application Support/Code/agentPlugins/github.com/obra/superpowers/
```

You should see a `skills/` directory inside with folders like `brainstorming/`, `test-driven-development/`, etc.

### 1.7 Install Context7 (MCP Server)

Context7 is a documentation server that lets the agent fetch **live, up-to-date docs** for any library (React, Express, Mongoose, etc.) instead of relying on potentially outdated training data.

1. Open the Extensions panel (`Cmd+Shift+X`)
2. Search for **"Context7"**
3. Install it
4. Restart VS Code when prompted

The agent will automatically use Context7 when it needs library documentation.

### 1.8 Verify Your Setup

Open a new Agent mode chat and type:

```
What sub-projects make up the Tiled platform? List them with their tech stacks.
```

If everything is working, the agent should:
- Read the project's `.github/copilot-instructions.md` automatically
- List all sub-projects (api, hub, mosaic, tiled-ui, ect) with their stacks
- Not ask you for any file paths — it finds them on its own

If it doesn't know about the project structure, check that you have the Tiled workspace folder open in VS Code.

---

## 2. How the System Works

### 2.1 What is Agent Mode?

When you type a message in Agent mode you're giving instructions to an autonomous agent that can:

- **Read and edit files** across the entire workspace
- **Run terminal commands** (npm test, git operations, builds, etc.)
- **Search the codebase** by text, regex, or semantic meaning
- **Dispatch sub-agents** to handle independent tasks in parallel
- **Fetch live documentation** via MCP servers (Context7)

The agent works iteratively: it reads code, makes changes, runs tests, checks results, and continues until the task is complete. You can watch it work in real-time in the chat panel.

### 2.2 Copilot Instructions (Project Context)

When a chat session starts, Copilot automatically loads instruction files that give it context about our codebase. You don't need to do anything — it just works. We can add to the instructions over time and improve them. If you find something off or that could be better, put a PR in to update the instructions.

**Workspace-level:** `.github/copilot-instructions.md`
- Project map (all 10 sub-projects, their stacks, their directories)
- Universal conventions (Prettier, ESLint, npm-only, 2-space indentation)
- The `mosaic` shared SDK rules (never redefine enums locally)
- The `tiled-ui` component library rules
- Testing matrix (which projects use Mocha vs Jest)
- CI/CD details

**Sub-project-level** (loaded when working in those directories):
- `hub/.github/copilot-instructions.md` — Builder architecture, context providers, import aliases, TanStack Query patterns

These files are the agent's "memory" of our codebase conventions. When you ask it to build something, it already knows our patterns. We should continue refining them as we go.

### 2.3 Superpowers Skills

Skills are structured workflows that automatically activate based on what you're doing. You don't invoke them manually — the agent recognizes when a skill applies and follows its process.

**How skills activate:**

1. You send a prompt (e.g., "I want to build a notification system")
2. The agent checks if any skill matches the task type
3. If a match is found, the agent loads the skill and follows its workflow
4. The skill defines the exact steps, quality gates, and outputs

**Skill priority:**
1. **Process skills first** (brainstorming, debugging) — determine *how* to approach the task
2. **Implementation skills second** (TDD, parallel agents) — guide execution

### 2.4 Skill Catalog

| Skill | What it does | When it activates |
|-------|-------------|-------------------|
| **brainstorming** | Explores your idea, asks questions, proposes approaches, writes a design spec | You describe a new feature or change |
| **writing-plans** | Converts a design spec into a step-by-step implementation plan with TDD tasks | After a spec is approved |
| **subagent-driven-development** | Executes a plan by dispatching one sub-agent per task with two-stage review | You ask to execute a plan (with subagent support) |
| **executing-plans** | Executes a plan task-by-task in a single session | You ask to execute a plan (without subagent support) |
| **test-driven-development** | Enforces write-test-first → watch-fail → implement → watch-pass cycle | Any feature implementation or bug fix |
| **systematic-debugging** | Forces root cause investigation before attempting any fix | You report a bug, test failure, or unexpected behavior |
| **verification-before-completion** | Requires fresh test/build output before claiming work is done | Agent is about to claim "done" |
| **using-git-worktrees** | Creates an isolated git worktree for feature work | Starting implementation of a plan |
| **finishing-a-development-branch** | Presents structured options (merge, PR, keep, discard) after work is complete | All tasks done, tests passing |
| **requesting-code-review** | Dispatches a code reviewer sub-agent to check work | Before creating a PR or after major changes |
| **receiving-code-review** | Evaluates review feedback technically before blindly implementing | You share PR review comments |
| **dispatching-parallel-agents** | Splits independent problems across multiple sub-agents | Multiple unrelated issues to solve |
| **writing-skills** | Creates or edits skill definition files | Building new workflow skills |
| **using-superpowers** | Bootstraps skill checking at conversation start | Every conversation (automatic) |

### 2.5 Plan Mode vs Code Mode

VS Code Copilot Chat has a **Plan mode** toggle (the lightbulb icon in the chat input area) that changes how the agent behaves:

| | Plan Mode (ON) | Code Mode (OFF) |
|---|---|---|
| **Purpose** | Research, design, planning | Implementation, execution |
| **File edits** | Proposes changes but does NOT apply them | Applies changes directly to your files |
| **Best for** | Brainstorming features, writing specs, creating plans | Executing plans, fixing bugs, writing code |
| **Model rec.** | Claude Opus 4 | Claude Sonnet 4 |

**Typical flow:**
1. **Plan mode ON** → Design the feature (brainstorming → spec → plan)
2. **Plan mode OFF** → Execute the plan (implement → test → verify → PR)

### 2.6 Context Flow

When you send a prompt, here's what happens behind the scenes:

```
Your prompt
  │
  ├─→ Copilot Instructions (.github/copilot-instructions.md)
  │     Gives the agent our project conventions, structure, and rules
  │
  ├─→ Superpowers Skills (auto-detected from your task)
  │     Gives the agent a structured workflow to follow
  │
  ├─→ Agent Tools
  │     ├── File reading/editing
  │     ├── Terminal commands
  │     ├── Codebase search
  │     ├── Sub-agent dispatch
  │     └── MCP servers (Context7 for live docs)
  │
  └─→ Output
        Code changes, test results, specs, plans, PRs
```

### 2.7 MCP Servers

**Context7** is the only MCP server we use so far. It provides live documentation for libraries and frameworks.

When the agent needs to use a library API (e.g., Mongoose, React, Express, Slack SDK), it automatically:
1. Resolves the library name to a Context7 ID
2. Fetches the relevant docs for your specific question
3. Uses the live docs instead of training data (which may be outdated)

You don't need to do anything — this happens automatically in the background.

---

## 3. Feature Development Lifecycle (SDLC)

This is the core workflow. It takes you from an idea to a merged PR, with the agent handling the heavy lifting at every stage.

```
 Idea + Ticket
      │
      ▼
 ┌─────────────┐    Plan Mode
 │  Stage 1    │    Brainstorming skill
 │  Design     │──→ Design spec (.md)
 │  Spec       │    in docs/superpowers/specs/
 └──────┬──────┘
        │
        ▼
 ┌─────────────┐    Plan Mode
 │  Stage 2    │    Writing-plans skill
 │  Impl.      │──→ Implementation plan (.md)
 │  Plan       │    in docs/superpowers/plans/
 └──────┬──────┘
        │
        ▼
 ┌─────────────┐    Code Mode
 │  Stage 3    │    Subagent-driven-development skill
 │  Execute    │──→ Code + tests + commits
 │  Plan       │    on feature branch in git worktree
 └──────┬──────┘
        │
        ▼
 ┌─────────────┐    Automatic
 │  Stage 4    │    Verification skill
 │  Verify     │──→ Full test suite passes
 └──────┬──────┘
        │
        ▼
 ┌─────────────┐    Code Mode
 │  Stage 5    │    Finishing skill
 │  PR         │──→ PR to dev branch
 └─────────────┘    "TD-1234: Feature name"
```

### Stage 1: Ideation → Design Spec

**Goal:** Turn your idea into a concrete, reviewed design document.

**Setup:**
- Switch to **Plan mode** (lightbulb icon ON)
- Use **Claude Opus 4** (best for complex design thinking, for smaller tasks Sonnet 4 is also fine.)

**Prompt template:**

```
TD-1234: I want to build [describe your feature].

Context:
- [Any constraints, requirements, or background]
- [Who uses it, what problem it solves]
- [Any technical preferences or decisions already made]
- [You can also just paste in a PRD]
```

**Example:**

```
TD-5678: I want to add a bulk export feature that lets admins
download all microapps in a library as a ZIP file.

Context:
- This is for enterprise customers who need offline backups
- Should work for libraries with up to 500 microapps
- Needs to be a background job (too slow for synchronous request)
- Should be gated behind the Enterprise premium feature flag
```

**What happens:**

1. The agent explores the codebase — reads relevant files, checks existing patterns
2. Asks you **one clarifying question at a time** (often multiple choice) to nail down requirements
3. Proposes **2-3 different approaches** with trade-offs and a recommendation
4. Presents the design **section by section**, asking for your approval after each
5. Writes the approved design to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
6. Runs an automated **spec review** loop to catch gaps
7. Asks you to **review the written spec** before moving on

**Your role during this stage:** Answer questions, ask questions, give additional information if you think of it as you go, push back on approaches you don't like, approve or request changes to each design section. The agent proposes, you decide.

**Output:** A design spec file like `docs/superpowers/specs/2026-03-23-bulk-export-design.md`

> **Important:** Include your ticket number (e.g., `TD-5678`) in the initial prompt. The agent will thread it into the branch name, spec header, plan header, commit messages, and PR title automatically for tracking in Jira.

### Stage 2: Design → Implementation Plan

**Goal:** Convert the approved design into a detailed, step-by-step plan that another agent (or developer) can execute.

This stage is usually triggered **automatically** after you approve the spec in Stage 1. If you need to create a plan separately:

**Prompt template:**

```
Create an implementation plan for the spec at
docs/superpowers/specs/2026-03-23-bulk-export-design.md
```

**What happens:**

1. The agent reads the spec and maps out which files will be created or modified
2. Decomposes the work into **bite-sized tasks** (each task is 2-5 minutes of work)
3. Each task follows TDD: write failing test → verify it fails → implement → verify it passes → commit
4. Every step has exact file paths, code snippets, and terminal commands
5. Writes the plan to `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`

**Output:** A plan file with checkbox syntax that tracks progress, like:

```markdown
### Task 1: Create BulkExportJob model

**Files:**
- Create: `api/jobs/bulkExport.js`
- Test: `api/test/jobs/bulkExport.test.js`

- [ ] Step 1: Write the failing test
- [ ] Step 2: Run test to verify it fails
- [ ] Step 3: Write minimal implementation
- [ ] Step 4: Run test to verify it passes
- [ ] Step 5: Commit
```

### Stage 3: Plan → Execution

**Goal:** Execute the plan — write code, write tests, commit after each task.

**Setup:**
- Switch to **Code mode** (Plan mode OFF)
- Use **Claude Sonnet 4** (fast execution)
- Recommended: **Start a new chat session** to keep the context clean

**Why a new session matters — how context works:**

Every chat session has a **context window** — the total amount of text the model can "see" at once. This includes your messages, the agent's responses, file contents it reads, terminal output, and tool calls. Think of it like the agent's short-term memory.

- A long brainstorming + planning session fills the context window with design discussion that's no longer relevant during implementation
- When context fills up, the agent starts losing track of earlier details — it may forget file paths, repeat work, or miss requirements
- Starting a **fresh session** for execution means the agent's context is clean and focused. It reads the plan file (which contains everything it needs) and dedicates its full attention to implementation
- The plan file is the "handoff document" — it carries all the decisions, file paths, and task details from the design phase into the execution phase without consuming context with old conversation history

**Rule of thumb:** One session for design (Stages 1-2), a new session for execution (Stages 3-5). If execution is long (10+ tasks), consider starting a fresh session partway through — the plan file's checkboxes track what's already done. Same as usually, as small we can break down the work at once, the better.

**Prompt template:**

```
Execute the plan at docs/superpowers/plans/2026-03-23-bulk-export.md
```

**What happens:**

1. The agent creates an **isolated git worktree** (so your main workspace is unaffected)
2. Creates a feature branch: `feature/TD-5678-bulk-export`
3. For each task in the plan:
   - Dispatches a **sub-agent** to implement that specific task
   - The sub-agent follows the TDD cycle (write test → fail → implement → pass → commit)
   - After each task, a **spec reviewer** checks the work against the design spec
   - Then a **code quality reviewer** checks for style, patterns, and correctness
   - Issues found are fixed before moving to the next task
4. Progress is tracked via checkboxes in the plan file

**Your role:** Monitor progress. The agent will stop and ask for help if it hits a blocker (missing dependency, unclear requirement, test that won't pass). Otherwise it works autonomously through the plan.

### Stage 4: Verification

**Goal:** Verify that all tests pass and the implementation is complete.

This happens **automatically** as the agent finishes the plan. The agent:

1. Runs the **full test suite** for the affected sub-project(s)
2. Reports the actual command output (not "tests should pass" — actual output with pass/fail counts)
3. Verifies every requirement from the spec is addressed

If tests fail, the agent investigates and fixes before claiming completion.

### Stage 5: Finish & PR

**Goal:** Get the work into a Pull Request targeting `dev`.

After verification, the agent presents **four options:**

```
Implementation complete. What would you like to do?

1. Merge back to dev locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work
```

**Option 2 (most common):** The agent pushes the branch and creates a PR with:
- **Title:** `TD-5678: Add bulk export feature`
- **Body:** Summary of changes, test plan, and link to the spec
- **Target branch:** `dev`

The git worktree is cleaned up automatically after the PR is created.

---

## 4. Daily Tasks

### 4.1 Debugging

When something breaks, the agent uses a structured debugging process instead of guessing at fixes.

**Prompt template:**

```
This test is failing:

[paste the error output]

Help me debug it.
```

Or:

```
Users are reporting that [describe the bug]. Help me investigate.
```

**What happens (systematic-debugging skill):**

1. **Phase 1: Root Cause Investigation** — reads error messages, traces data flow, adds diagnostic logging. No fixes yet.
2. **Phase 2: Pattern Analysis** — finds working examples, compares with the broken code, identifies differences
3. **Phase 3: Hypothesis & Test** — forms a single hypothesis, tests it with the smallest possible change
4. **Phase 4: Implementation** — writes a failing test that exposes the bug, then fixes with one targeted change

The agent will **not** attempt random fixes. If it can't determine root cause, it says so and asks for your help.

### 4.2 Code Review

**Receiving review feedback:**

When you get PR comments, share them with the agent:

```
I got this review feedback on my PR:

[paste the reviewer's comments]

Help me address these.
```

The agent will:
- Read the feedback carefully
- **Verify each suggestion** against the actual codebase
- Implement valid suggestions one at a time, testing each
- Push back with technical reasoning if a suggestion is incorrect or unnecessary

**Requesting a review before PR:**

```
Review the changes on this branch before I create a PR.
Focus on [specific concerns, e.g., "security" or "API design"].
```

The agent dispatches a code reviewer sub-agent that checks:
- Does the implementation match the spec?
- Are there code quality issues?
- Are tests comprehensive?

### 4.3 Ad-Hoc Coding

Not everything needs the full SDLC pipeline. For quick tasks, just describe what you need:

```
Add a `lastLoginAt` timestamp field to the User model in api/db/models/user.js
and update the login route to set it.
```

```
Refactor the hub/src/components/Dashboard.jsx component to use
TanStack Query instead of the Redux action for fetching projects.
```

```
Write tests for the permission checking logic in api/services/permissions.js.
Focus on edge cases around team-level vs org-level permissions.
```

**Tips for effective ad-hoc prompts:**
- **Reference files by path** — `api/services/auth.js`, not "the auth file"
- **State constraints** — "Don't change the public API" or "Must be backwards compatible"
- **Be specific about scope** — "Only the login route" vs "all auth routes"
- **Mention the sub-project** — "In the hub" or "In the API" to set context

---

## 5. Prompt Cookbook

### 5.1 Feature Development Prompts

| Stage | Prompt | What to expect |
|-------|--------|---------------|
| **Design** | `TD-1234: I want to build [feature]. Help me design it.` | Brainstorming skill activates → questions → approaches → spec |
| **Plan** | `Create an implementation plan for docs/superpowers/specs/2026-03-23-feature-design.md` | Writing-plans skill activates → file map → TDD task list |
| **Execute** | `Execute the plan at docs/superpowers/plans/2026-03-23-feature.md` | Worktree created → sub-agents implement task-by-task → commits |
| **Review** | `Review the changes on this branch against the spec.` | Code reviewer dispatched → feedback on spec compliance + quality |
| **Finish** | `I'm done with this feature. Help me create a PR.` | Finishing skill → 4 options → PR to `dev` |

### 5.2 Debugging Prompts

| Scenario | Prompt |
|----------|--------|
| **Test failure** | `This test is failing: [paste output]. Help me debug it.` |
| **Runtime error** | `Getting this error in production logs: [paste]. Investigate the root cause.` |
| **Unexpected behavior** | `When I [do X], I expect [Y] but get [Z]. Help me figure out why.` |
| **Performance issue** | `This API endpoint is slow (2s+ response time). Help me profile and optimize it.` |

### 5.3 Daily Work Prompts

| Task | Prompt |
|------|--------|
| **Understand code** | `Explain how the builder context providers work in hub/src/components/builder/.` |
| **Add a field** | `Add a [field] to the [Model] in api/db/models/[file] and expose it in the API response.` |
| **Write tests** | `Write comprehensive tests for [file path]. Cover edge cases around [specific area].` |
| **Refactor** | `Refactor [file] to [approach]. Keep the public API the same.` |
| **Update dependency** | `Update [package] to the latest version. Check for breaking changes and fix them.` |

### 5.4 Prompt Anti-Patterns

| Don't do this | Do this instead | Why |
|---------------|----------------|-----|
| "Fix the bug" | "This test fails with [error]. Investigate." | Agent needs to see the actual error |
| "Make it better" | "Refactor to use TanStack Query instead of Redux for data fetching" | Vague goals produce vague results |
| "Update the API" | "Add a GET /api/v2/exports/:id endpoint that returns export status" | Specific endpoints and behavior |
| Starting implementation without a plan | Use the full Stage 1-2 pipeline first | Plans prevent rework and missed requirements |
| Ignoring the agent's questions | Answer thoughtfully | Questions prevent wrong assumptions |
| "Just skip the tests" | Never skip tests — the TDD cycle catches bugs early | Tests are the safety net that makes fast iteration possible |

---

## 6. Troubleshooting & FAQ

### Agent doesn't seem to know about our project

**Check:** Is the Tiled workspace folder open in VS Code? The agent reads `.github/copilot-instructions.md` from the workspace root.

**Test:** Ask "What sub-projects are in this workspace?" — it should list all of them.

### Agent isn't following the skill workflows

**Check:** Is the superpowers plugin installed?

```bash
ls ~/Library/Application\ Support/Code/agentPlugins/github.com/obra/superpowers/skills/
```

You should see 14 skill directories. If not, reinstall via the Extensions panel (`Cmd+Shift+X`) → search "Superpowers" → Install

### Context7 MCP errors

**Check:** Is Context7 installed? Open the Extensions panel (`Cmd+Shift+X`) → search "Context7" → Install/reinstall.

Context7 needs internet access to fetch docs. If the agent reports MCP errors, check your network connectivity.

### Agent is using the wrong model

Click the **model selector** in the chat panel and verify the model. If a model isn't available, you may need your admin to enable it in the GitHub Copilot organization settings.

### Agent created files in the wrong location

Make sure you have the correct workspace folder open. If you have multiple workspaces, the agent works in whichever workspace folder contains the file you're currently editing.

### "I don't see Agent mode"

Agent mode requires:
- GitHub Copilot extension version 1.100+
- A Copilot Business or Enterprise subscription
- Agent mode may need to be enabled in your organization's Copilot policy settings

### How do I stop the agent mid-task?

Click the **Stop** button in the chat panel, or press `Escape`. The agent will stop after its current tool call completes. Any files already saved will remain changed — you can use `git checkout .` to revert uncommitted changes.

### Can multiple people work on the same feature with the agent?

Yes, but coordinate like you would normally. The agent works on a feature branch in a git worktree. One person drives the agent session for a given feature. Others can review the PR when it's created.

### How do I update the superpowers plugin?

Open the Extensions panel (`Cmd+Shift+X`) → search "Superpowers" → click Update (if available), or uninstall and reinstall.

---

## Appendix: Recommended `copilot-instructions.md` Additions

To enforce ticket numbers and branching conventions automatically, consider adding these rules to `.github/copilot-instructions.md`:

```markdown
### Git Conventions
- **Branch naming:** `feature/TD-XXXX-short-description` (all feature branches must include the ticket number)
- **PR titles:** `TD-XXXX: Short description` (ticket number required in all PR titles)
- **Target branch:** All feature PRs target `dev`
- **Commit messages:** Include ticket number where relevant: `TD-XXXX: Add export model and tests`
```

This ensures the agent follows these conventions automatically, even if the developer forgets to mention the ticket number mid-conversation.
