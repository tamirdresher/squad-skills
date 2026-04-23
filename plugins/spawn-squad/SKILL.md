---
name: spawn-squad
description: Create, run, and manage child squads for specific missions. Enables an HQ coordinator to fan out work to purpose-built teams.
confidence: medium
domain: orchestration, multi-agent, squad-management
---

# Spawn Squad

## Context

Sometimes a task is too large, too specialized, or too parallelizable for a single squad. This skill teaches an HQ agent how to **spawn a child squad** — a purpose-built team that handles a specific mission in its own workspace, then reports results back.

Use cases where spawning is the right move:
- **Legacy migration** — one child squad per service/module to modernize
- **Research exploration** — parallel squads each investigating a different hypothesis
- **Crisis response** — a dedicated squad per incident, spun up on-demand
- **Legal / compliance** — a squad per case file or audit scope
- **Template validation** — disposable squads that test prompt changes end-to-end

Use cases where spawning is **NOT** the right move:
- The task fits in a single session — just do it yourself
- You need real-time collaboration between agents — squads are isolated by design
- The work has no clear success criteria — define those first

## Prerequisites

Before spawning, verify these exist. If any check fails, **stop and report the blocker** — do not improvise.

```bash
# Required CLIs
command -v copilot  || echo "BLOCKED: GitHub Copilot CLI not found"
command -v squad    || echo "BLOCKED: Squad CLI not found"
command -v git      || echo "BLOCKED: Git not found"

# On Windows (PowerShell)
Get-Command copilot -ErrorAction SilentlyContinue || Write-Error "BLOCKED: GitHub Copilot CLI not found"
Get-Command squad   -ErrorAction SilentlyContinue || Write-Error "BLOCKED: Squad CLI not found"
Get-Command git     -ErrorAction SilentlyContinue || Write-Error "BLOCKED: Git not found"
```

Verify the Squad agent is available to Copilot:
```bash
copilot agent list 2>/dev/null | grep -q squad || echo "BLOCKED: Squad agent not registered"
```

## Workflow

### Step 0 — Define the mission contract

Before touching the filesystem, write down the contract. This is non-negotiable.

```markdown
## Mission Contract
**Mission ID:** {descriptive-kebab-case-id}
**Objective:** {one sentence — what the child squad must accomplish}
**Scope:** {what's in bounds / what's out of bounds}
**Success criteria:**
- [ ] {specific, verifiable criterion — e.g., "src/api/routes.ts exists and exports a Router"}
- [ ] {another criterion — e.g., "npm test exits 0 with ≥3 passing tests"}
- [ ] {another — e.g., "no files outside src/ were modified"}
**Allowed tools:** {e.g., shell, git, file read/write — or "all"}
**Forbidden actions:** {e.g., "do not push to remote", "do not install global packages"}
**Stop condition:** {e.g., "after 3 failed attempts, return FAIL with diagnostics"}
**Lifecycle:** ephemeral | long-lived
**Expected artifacts:** {list of files/reports the parent expects back}
```

### Step 1 — Create the workspace

Each child squad gets its own isolated workspace. Never share a workspace between squads.

**Ephemeral squad:**
```bash
# Create a disposable workspace
MISSION_ID="legacy-auth-migration"
WORKSPACE="/tmp/squad-mission-${MISSION_ID}"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
git init
```

**Long-lived squad (clone an existing repo):**
```bash
MISSION_ID="customer-acme-modernization"
WORKSPACE="/tmp/squad-mission-${MISSION_ID}"
git clone https://github.com/org/legacy-app.git "$WORKSPACE"
cd "$WORKSPACE"
```

**Windows (PowerShell):**
```powershell
$MissionId = "legacy-auth-migration"
$Workspace = "$env:TEMP\squad-mission-$MissionId"
New-Item -ItemType Directory -Path $Workspace -Force
Set-Location $Workspace
git init
```

### Step 2 — Scaffold the codebase (if needed)

For ephemeral squads, create just enough project structure for the child squad to have something to work with:

```bash
# Example: minimal Node.js project
echo '{"name":"mission-workspace","version":"1.0.0"}' > package.json
mkdir -p src tests
echo "// Entry point" > src/index.ts
git add -A && git commit -m "init: mission workspace for ${MISSION_ID}"
```

For cloned repos, skip this — the codebase already exists.

### Step 3 — Initialize the squad

```bash
squad init
```

Then customize the squad for the mission:

**a) Write the mission brief** — save the contract from Step 0:
```bash
cat > .squad/mission.md << 'EOF'
{paste the mission contract here}
EOF
```

**b) Customize team.md** — tailor roles for the mission domain:
```bash
# Edit .squad/team.md to include mission-relevant roles
# For a migration mission, you might want:
# - An architect who understands the legacy patterns
# - A developer who writes the new code  
# - A tester who verifies behavior preservation
```

**c) Write targeted agent charters** — in `.squad/agents/{role}/charter.md`:
```markdown
# Charter: Migration Developer

## Identity
You are a migration specialist focused on converting legacy patterns to modern equivalents.

## Mission
{paste the objective from the mission contract}

## Constraints
{paste scope boundaries and forbidden actions}
```

**d) Commit the squad configuration:**
```bash
git add -A && git commit -m "squad: configure team for mission ${MISSION_ID}"
```

### Step 4 — Run the mission

Use the Copilot CLI to run sessions against the child squad.

> **`--yolo` flag:** Non-interactive spawning requires `--yolo` to auto-approve file operations. Without it, Copilot CLI blocks on permission prompts that no one is there to click.

**Single-turn mission:**
```bash
copilot --agent squad --yolo \
  -p "Execute the mission described in .squad/mission.md. Follow the success criteria exactly." \
  2>&1 | tee evidence/session-run.log
```

**Multi-step mission** (sequential sessions):
```bash
mkdir -p evidence

# Phase 1: Analysis
copilot --agent squad --yolo \
  -p "Phase 1: Analyze the codebase and create a migration plan in .squad/decisions/migration-plan.md" \
  2>&1 | tee evidence/session-phase1.log

# Phase 2: Implementation  
copilot --agent squad --yolo \
  -p "Phase 2: Execute the migration plan from .squad/decisions/migration-plan.md" \
  2>&1 | tee evidence/session-phase2.log

# Phase 3: Verification
copilot --agent squad --yolo \
  -p "Phase 3: Run tests and verify all success criteria from .squad/mission.md are met" \
  2>&1 | tee evidence/session-phase3.log
```

**Important:** Always capture session logs with `tee` (or `Tee-Object` on Windows). Without logs, failures are undiagnosable.

### Step 5 — Verify outcomes

Check every success criterion from the mission contract. Do not trust session output alone — verify independently.

```bash
# Example verification for a migration mission:

# Criterion 1: expected files exist
test -f src/api/routes.ts || echo "FAIL: routes.ts not found"

# Criterion 2: tests pass
npm test 2>&1 | tee evidence/test-results.log
TEST_EXIT=$?

# Criterion 3: no out-of-scope modifications
CHANGED_FILES=$(git diff --name-only HEAD~1)
echo "$CHANGED_FILES" | grep -v "^src/" && echo "WARN: files outside src/ were modified"

# Criterion 4: git state is clean
git status --porcelain | grep -q . && echo "WARN: uncommitted changes remain"
```

### Step 6 — Record the verdict

Create a structured verdict that the parent coordinator can parse:

```markdown
## Mission: {mission-id}
**Lifecycle:** ephemeral | long-lived
**Result:** PASS | PARTIAL | FAIL
**Phases completed:** {e.g., 3/3}

### Success Criteria
- [x] src/api/routes.ts exists and exports a Router
- [x] npm test exits 0 with 5 passing tests  
- [ ] No files outside src/ were modified — VIOLATION: package-lock.json updated

### Evidence
- evidence/session-phase1.log — analysis phase
- evidence/session-phase2.log — implementation phase
- evidence/session-phase3.log — verification phase
- evidence/test-results.log — test output

### Git State
- Commits: {number of commits made by child squad}
- Branch: {current branch name}
- Clean: yes | no

### Notes
{anything unusual — e.g., "retried phase 2 once due to test failure"}
```

### Step 7 — Report back or persist

**Ephemeral squad** — extract the verdict file, copy any artifacts the parent needs, then clean up:
```bash
# Copy verdict and artifacts to parent workspace
cp evidence/verdict.md /path/to/parent-workspace/results/${MISSION_ID}-verdict.md
cp -r evidence/ /path/to/parent-workspace/results/${MISSION_ID}/

# Clean up
cd /
rm -rf "$WORKSPACE"
```

**Long-lived squad** — leave the workspace intact. Record its location for future sessions:
```bash
echo "${MISSION_ID}=${WORKSPACE}" >> /path/to/parent-workspace/.squad/active-missions.txt
```

## Parallel Fan-Out

To run multiple child squads simultaneously:

1. Create separate workspaces per mission (Step 1)
2. Initialize and configure each independently (Steps 2-3)
3. Run them in parallel using background processes or separate terminals:

```bash
# Launch 3 parallel missions
for MISSION in auth-migration data-layer api-gateway; do
  (
    cd /tmp/squad-mission-${MISSION}
    copilot --agent squad --yolo \
      -p "Execute the mission in .squad/mission.md" \
      2>&1 | tee evidence/session-run.log
  ) &
done
wait  # Wait for all to complete

# Collect verdicts
for MISSION in auth-migration data-layer api-gateway; do
  cat /tmp/squad-mission-${MISSION}/evidence/verdict.md
done
```

**Isolation rule:** Each squad MUST have its own workspace directory and its own git repository. Never run parallel squads on the same repo or branch — they will corrupt each other's state.

## Recursive Spawning

A child squad can itself use this skill to spawn grandchild squads. This is powerful but dangerous.

**Hard limit:** Maximum spawn depth of 3 (HQ → child → grandchild). Beyond that, complexity becomes unmanageable and failures are nearly impossible to diagnose.

**Rule:** Every level must report its verdict up to its parent. The parent is responsible for aggregating child verdicts into its own verdict.

## Anti-Patterns

- **Spawning without a mission contract.** If you can't write concrete success criteria, you can't verify the outcome. Don't spawn.
- **Sharing workspaces between squads.** Git state, files, and logs will collide. One workspace per squad, always.
- **Trusting session output as proof.** Agents can claim they wrote a file without actually writing it. Always verify git state and file existence independently.
- **Spawning for simple tasks.** If the work fits in a single prompt, spawning a full squad is overhead with no benefit. Just do it.
- **Unbounded parallel fan-out.** Each child squad consumes compute, API calls, and context. Start with 2-3 parallel squads and scale up only after validating the pattern works.
- **Skipping preflight checks.** If `copilot`, `squad`, or `git` aren't available, the entire workflow will fail silently or produce garbage. Always check first.
- **No cleanup for ephemeral squads.** Disposable workspaces accumulate fast. Always clean up after extracting results.
- **Letting child squads modify the parent repo directly.** Child squads work in their own workspace. Results flow back via explicit artifact copying, not shared file access.

## Tips

- **Name workspaces descriptively:** `squad-mission-auth-migration`, not `test1`.
- **One mission per workspace.** Don't reuse workspaces across unrelated missions — state leaks.
- **Always capture session logs.** They're the only way to debug what went wrong.
- **Windows users:** Use PowerShell. `Tee-Object` replaces `tee`. Paths use `\`. Use `$env:TEMP` instead of `/tmp`.
- **Start small.** Your first spawn should be a single ephemeral squad with a trivial mission. Get comfortable with the workflow before attempting parallel fan-out.

## Confidence

medium — Pattern validated through e2e-template-testing skill (PR #1022 in bradygaster/squad) and design conversations with production teams. The core workflow (create workspace → init squad → run sessions → verify → report) is proven. Advanced patterns (parallel fan-out, recursive spawning, long-lived squads) need more field validation.
