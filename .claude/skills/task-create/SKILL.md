---
name: task-creator
description: |
  Create structured, actionable tasks from ideas, requirements, or specifications. Use this skill whenever you need to convert loose requirements, user stories, bugs, feature requests, or project goals into well-defined tasks ready for a team to execute. This includes breaking down large projects into subtasks, creating sprints, estimating effort, assigning ownership, defining acceptance criteria, and formatting tasks for tools like Jira, Linear, GitHub, Asana, or Monday.com. Perfect for task planning, sprint planning, ticket creation, and workflow automation.
---

# Task Creator Skill

A comprehensive system for converting ideas, requirements, and goals into structured, executable tasks.

## When to Use This Skill

Trigger this skill when you need to:

- **Convert specs into tasks** — Break down technical specifications into development tasks
- **Create sprint backlogs** — Plan tasks for a sprint (1–4 week cycle)
- **Build project roadmaps** — Organize tasks into phases with timelines
- **Structure bug reports** — Convert bug descriptions into reproducible, assignable tasks
- **Create feature requests** — Turn user stories into implementation tasks
- **Bulk task creation** — Generate multiple related tasks from one brief
- **Task dependencies** — Map out task sequencing and blockers
- **Estimation & planning** — Size and schedule tasks for teams
- **Export to tools** — Generate formatted output for Jira, Linear, GitHub Issues, etc.

## Task Anatomy

A complete, actionable task contains these elements:

```
TASK ID:           [unique identifier, auto-generated or manual]
TITLE:             [Short, clear, max 80 chars]
TYPE:              [Feature | Bug | Improvement | Documentation | Testing | Refactoring]
PRIORITY:          [Critical | High | Medium | Low]
STATUS:            [Backlog | To Do | In Progress | In Review | Done]
EPIC/PROJECT:      [Parent epic or project name]
ASSIGNEE:          [Name or team]
ESTIMATE:          [Story points: 1,2,3,5,8,13 | Hours: 2h, 4h, 8h]
DUE DATE:          [YYYY-MM-DD]

DESCRIPTION:
[2-3 sentence summary of what needs to be done]

ACCEPTANCE CRITERIA:
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

TECHNICAL DETAILS / CONTEXT:
[Any relevant background, related docs, edge cases]

SUBTASKS (if complex):
- [ ] Subtask 1 (owner, estimate)
- [ ] Subtask 2 (owner, estimate)
- [ ] Subtask 3 (owner, estimate)

DEPENDENCIES:
- Blocked by: [Task ID]
- Blocks: [Task ID]
- Related: [Task ID]

NOTES:
[Questions, risks, assumptions, follow-ups]
```

## Task Types & Patterns

### 1. Feature Task

```
TYPE: Feature
TEMPLATE:
As a [user role], I want to [action], so that [benefit]

DESCRIPTION:
[2-3 sentences describing what feature does and why]

ACCEPTANCE CRITERIA:
- [ ] Feature implemented and integrated
- [ ] Unit tests written (>80% coverage)
- [ ] UI/UX matches design mockup
- [ ] Documented in API docs or user guide
- [ ] Code reviewed and approved
- [ ] Tested on [device/browser/OS]
```

**Example**:
```
TYPE: Feature
TITLE: Add dark mode toggle to dashboard

As a user, I want to toggle dark mode on the dashboard,
so that I can reduce eye strain during night sessions.

ACCEPTANCE CRITERIA:
- [ ] Toggle button visible in settings menu
- [ ] Dark mode applies to all pages (not just home)
- [ ] User preference persisted to localStorage
- [ ] Colors meet WCAG AA contrast ratio
- [ ] Performance: page load < 100ms slower in dark mode
```

---

### 2. Bug Task

```
TYPE: Bug
TEMPLATE:
DESCRIPTION: Clear, reproducible steps

ACCEPTANCE CRITERIA:
- [ ] Root cause identified and documented
- [ ] Fix implemented and tested
- [ ] Regression test added
- [ ] No similar bugs in codebase
- [ ] Fix deployed to staging and verified

CONTEXT:
Reported by: [name]
Affected Users: [number or percentage]
Severity: [Critical | High | Medium | Low]
Found in: [version or date]
```

**Example**:
```
TYPE: Bug
TITLE: Login fails on Safari when cookies disabled

DESCRIPTION:
When a user tries to login on Safari with "Prevent cross-site tracking"
enabled, they see an infinite redirect loop and are stuck on /login.

STEPS TO REPRODUCE:
1. Open Safari
2. Settings > Privacy > Uncheck "Allow privacy-preserving ad measurement"
3. Navigate to app.example.com/login
4. Enter valid credentials
5. Click login
EXPECTED: Redirect to /dashboard
ACTUAL: Stuck on /login, no error message

ACCEPTANCE CRITERIA:
- [ ] Root cause: Session cookie not persisting in Safari strict mode
- [ ] Fix: Use sessionStorage fallback when cookies unavailable
- [ ] Added test: test_login_with_cookies_disabled.ts
- [ ] Verified on Safari 15, 16, 17
```

---

### 3. Improvement / Refactoring Task

```
TYPE: Improvement
TITLE: [Keep it concrete and measurable]

DESCRIPTION:
Current State: [How it works now]
Desired State: [How it should work]
Benefit: [Why this improves the product/codebase]

ACCEPTANCE CRITERIA:
- [ ] Code refactored without changing behavior
- [ ] Performance improves by [X%]
- [ ] Tests pass (no new test failures)
- [ ] Code review approved
```

**Example**:
```
TYPE: Refactoring
TITLE: Consolidate 5 similar API endpoints into 1 parameterized endpoint

DESCRIPTION:
Currently have: GET /users, GET /users/active, GET /users/inactive, 
GET /users/banned, GET /users/new
Should be: GET /users?status=all|active|inactive|banned|new

Benefit: Reduces code duplication, easier to maintain, smaller bundle

ACCEPTANCE CRITERIA:
- [ ] New parameterized endpoint tested with all status values
- [ ] Old endpoints deprecated (return 301 to new endpoint for 1 version)
- [ ] Client code updated to use new endpoint
- [ ] API docs updated
- [ ] No performance regression
```

---

### 4. Documentation Task

```
TYPE: Documentation
TITLE: [Document X for [audience]]

DESCRIPTION:
What needs to be documented and for whom

ACCEPTANCE CRITERIA:
- [ ] Document written in [Markdown/Confluence/Notion]
- [ ] Includes [code examples | screenshots | diagrams]
- [ ] Reviewed by [SME / tech lead]
- [ ] Published to [docs site | wiki]
- [ ] Linked from relevant pages
```

**Example**:
```
TYPE: Documentation
TITLE: Write API authentication guide for external developers

DESCRIPTION:
Create a comprehensive guide showing how to authenticate to our API
using OAuth2, JWT, and API keys. Include examples in Python, Node, cURL.

ACCEPTANCE CRITERIA:
- [ ] Guide covers 3 auth methods with code examples
- [ ] Flow diagrams for each method included
- [ ] Troubleshooting section with common errors
- [ ] Published to docs.example.com/auth
- [ ] Reviewed by API team
```

---

### 5. Testing Task

```
TYPE: Testing
TITLE: Write integration tests for [feature/module]

DESCRIPTION:
Test scope: [what scenarios to cover]
Test type: [unit | integration | e2e | performance]

ACCEPTANCE CRITERIA:
- [ ] Test file created: [path]
- [ ] Covers [X] test cases with 100% pass rate
- [ ] Edge cases tested: [list specific edge cases]
- [ ] Runs in < [X] seconds
- [ ] CI/CD integrated and passing
```

**Example**:
```
TYPE: Testing
TITLE: Add E2E tests for checkout flow

DESCRIPTION:
Test scope: Happy path (add item → enter address → select payment → confirm order),
error paths (invalid card, network timeout, address not found)

ACCEPTANCE CRITERIA:
- [ ] 8 test cases written (4 happy path, 4 error path)
- [ ] Uses Playwright for cross-browser testing
- [ ] Runs in CI on PR creation
- [ ] All tests pass on Chrome, Firefox, Safari
- [ ] Test execution time < 60 seconds
```

---

## Task Creation Workflow

### Step 1: Gather Input

Collect or clarify:
- **What problem does this task solve?** (context)
- **Who will do this work?** (assignee / team)
- **When is it needed?** (due date / phase)
- **How will we know it's done?** (acceptance criteria)
- **What could block this?** (dependencies, risks)

### Step 2: Write a Clear Title

Good titles:
- ✅ "Add two-factor authentication via SMS"
- ✅ "Fix memory leak in image upload processing"
- ✅ "Refactor payment retry logic to use exponential backoff"
- ✅ "Write API authentication guide for OAuth2"

Bad titles:
- ❌ "Update stuff"
- ❌ "Fix it"
- ❌ "Do the thing"
- ❌ "Urgent work on backend"

**Title Formula**: `[Action Verb] + [What] + [Context]`
- Action Verb: Add, Fix, Update, Refactor, Write, Optimize, Investigate
- What: feature name, bug name, file/module name
- Context: (optional) for clarity

### Step 3: Define Acceptance Criteria

Acceptance Criteria (AC) are **testable conditions** that prove a task is complete.

**Good AC**:
- ✅ "Login response time < 500ms under load test"
- ✅ "UI matches Figma mockup (link: ...)"
- ✅ "All 5 test cases in test_suite_X.ts pass"
- ✅ "Code review approved by [tech lead]"

**Bad AC**:
- ❌ "It works"
- ❌ "No bugs"
- ❌ "As good as possible"
- ❌ "Done"

**Formula for AC**:
```
- [ ] [Measurable outcome] [specific metric or verification method]
```

### Step 4: Estimate Effort

Use one system consistently (don't mix story points and hours in same team):

#### Story Points (Agile)
- **1 point** = Can finish today, minimal uncertainty (~2 hours)
- **2 points** = Confident, clear approach (~4 hours)
- **3 points** = Somewhat complex, might hit one surprise (~6 hours)
- **5 points** = Complex, multiple unknowns (~2 days)
- **8 points** = Very complex, needs investigation (~3 days)
- **13 points** = Epic in disguise, break it down

#### Hours (Waterfall/Traditional)
- **2h** = Simple, obvious solution
- **4h** = Moderate, clear but not trivial
- **8h** = 1 day, complex with some unknowns
- **16h** = 2 days, significant effort
- **>24h** = Likely needs breakdown into subtasks

**Rule**: If > 8 points or 16 hours, break into subtasks first.

### Step 5: Identify Dependencies & Blockers

Ask:
- Does this task depend on any other task being done first?
- What other tasks depend on this one?
- Are there external dependencies (API keys, third-party APIs, designs, requirements)?
- What could block this task? (Resource, clarification, approval)

Format:
```
DEPENDENCIES:
- Blocked by: TASK-123 (Authentication infrastructure)
- Blocks: TASK-456 (Payment processing) and TASK-789 (Reports)
- Related: TASK-111 (Similar refactor in module X)
```

### Step 6: Assign & Prioritize

**Priority Matrix**:
| Priority | Business Impact | Urgency | Due Date | Example |
|----------|---|---|---|---|
| **Critical** | High | Urgent | < 24h | Production outage, security breach |
| **High** | High | Soon | < 1 week | Major feature for demo, customer blocker |
| **Medium** | Medium | Moderate | < 2 weeks | Standard feature, planned improvement |
| **Low** | Low | Flexible | > 2 weeks | Nice-to-have, tech debt, future roadmap |

**Assignment**: 
- Assign to a person (not a team) for clear ownership
- Consider skill match (senior for complex, junior + mentor for learning)
- Balance workload across team

### Step 7: Set Due Dates

- **Feature tasks**: Based on release date + 2-day buffer for QA
- **Bug fixes**: Critical (24h), High (3 days), Medium (1 week), Low (2 weeks)
- **Documentation**: Should ship same release as feature it documents
- **Tech debt**: End of sprint or backlog if not blocking

---

## Task Organization Patterns

### Pattern 1: Epic Breakdown

Large feature → Epic → Tasks → Subtasks

```
EPIC: Build Payment Processing System
├─ TASK-101: Design payment flow (UX + architecture)
├─ TASK-102: Implement Stripe integration
│  ├─ Subtask: OAuth with Stripe
│  ├─ Subtask: Handle webhook notifications
│  └─ Subtask: Error handling & retries
├─ TASK-103: Build payment UI (checkout page)
├─ TASK-104: Write integration tests
├─ TASK-105: Document API endpoints
└─ TASK-106: Load testing & optimization
```

### Pattern 2: Sprint Planning

1 sprint = 10 tasks (rough guide)

```
SPRINT 15 (April 15-26, 2 weeks)
├─ TASK-201: (8pts) Backend: Implement export API
├─ TASK-202: (5pts) Frontend: Export button UI
├─ TASK-203: (3pts) Bug: Fix chart rendering on mobile
├─ TASK-204: (5pts) Refactor: Consolidate auth middleware
├─ TASK-205: (3pts) Docs: Write export API guide
├─ TASK-206: (8pts) Testing: E2E tests for export flow
├─ TASK-207: (2pts) Improve: Faster CSV generation
├─ TASK-208: (5pts) Feature: Dark mode toggle (continued from Sprint 14)
├─ TASK-209: (3pts) Infra: Update CI/CD for new deployment region
└─ TASK-210: (2pts) Bug: Fix typo in error messages

Total: 44 points (realistic for 2-week sprint with 4-person team)
```

### Pattern 3: Bug Triage (by Priority)

```
CRITICAL (Resolve immediately):
├─ TASK-300: Production: Database connection pool exhausted
└─ TASK-301: Security: XSS vulnerability in comment field

HIGH (This sprint):
├─ TASK-302: App crashes on Android 12
├─ TASK-303: Payment confirmation email not sending
└─ TASK-304: Dashboard slow on large datasets

MEDIUM (This month):
├─ TASK-305: Search doesn't index new documents
└─ TASK-306: Export format missing some fields

LOW (Backlog):
├─ TASK-307: Typo in settings page
└─ TASK-308: Button color slightly off in dark mode
```

### Pattern 4: Dependency Chain

```
TASK-401: Setup database schema
  ↓
TASK-402: Create ORM models
  ↓
TASK-403: Build API endpoints ← BLOCKED until TASK-402 done
  ├─ TASK-404: Add authentication ← Also depends on TASK-401
  └─ TASK-405: Add validation
        ↓
TASK-406: Build frontend → (can start once API spec is ready in TASK-403)
```

---

## Templates by Tool

### Jira Format

```
PROJECT: [PROJECT-KEY]
ISSUE TYPE: Story | Bug | Task | Improvement | Technical Debt
KEY: [AUTO-GENERATED]
SUMMARY: [Title, max 80 chars]
DESCRIPTION: [Full description with formatting]
PRIORITY: Critical | High | Medium | Low
ASSIGNEE: [Name]
REPORTER: [Name]
DUE DATE: [YYYY-MM-DD]
ESTIMATE: [Story Points or Time Estimate]
COMPONENT: [Component name]
LABELS: [tag1, tag2, tag3]
FIX VERSION: [Sprint name or Release version]

ACCEPTANCE CRITERIA:
- [ ] Criterion 1
- [ ] Criterion 2
...

LINKED ISSUES:
- blocks: TASK-123
- is blocked by: TASK-456
- relates to: TASK-789
```

### GitHub Issues Format

```markdown
---
title: [Title]
labels: [bug, enhancement, documentation, urgent]
assignees: [username]
milestone: [Sprint name or Release]
---

## Description
[Description of task]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Related Issues
- Blocks #123
- Blocked by #456
- Related to #789

## Labels
bug, feature, high-priority
```

### Linear Format

```
TITLE: [Title]
TYPE: [Backlog | Active | Completed]
STATE: [Backlog | Todo | In Progress | In Review | Done]
PRIORITY: [Urgent | High | Medium | Low]
ASSIGNEE: [Team member]
DUE DATE: [YYYY-MM-DD]
ESTIMATE: [Story points]

DESCRIPTION:
[Description and context]

ACCEPTANCE CRITERIA:
- [ ] Criterion 1
- [ ] Criterion 2

CHILD ISSUES:
- Subtask 1
- Subtask 2
```

### Markdown Checklist Format

```markdown
## Task: [Title]

- Type: Feature | Bug | Improvement | Documentation | Testing
- Priority: Critical | High | Medium | Low
- Estimate: [points or hours]
- Assignee: [Name]
- Due Date: [YYYY-MM-DD]
- Status: Backlog | To Do | In Progress | In Review | Done

### Description
[2-3 sentences explaining the task]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Subtasks (if any)
- [ ] Subtask 1 (owner, estimate)
- [ ] Subtask 2 (owner, estimate)

### Dependencies
- Blocked by: [Task reference]
- Blocks: [Task reference]

### Notes
[Any additional context, questions, or risks]
```

---

## Common Pitfalls & How to Fix Them

| Pitfall | Example | Fix |
|---------|---------|-----|
| **Vague title** | "Fix backend issue" | "Fix N+1 query in user dashboard causing 5s load time" |
| **No acceptance criteria** | "Build login" | "[ ] JWT tokens issued, [ ] Password hashed, [ ] 2FA optional, [ ] < 200ms response" |
| **Over-scoped task** | "Build entire payment system" | Break into: Design → Stripe Integration → UI → Testing → Docs |
| **No assignee** | "Someone should test" | "Assigned to: Luiz (QA Lead)" |
| **Impossible estimate** | "13 points for a 25-day sprint task" | Break into 8pts + 5pts across sprints |
| **Broken dependency** | "Implement feature X" (but API spec task not started) | Make task depend on API spec task; update start date |
| **Unclear AC** | "Make it better" | "Response time < 200ms (measured via Chrome DevTools)" |
| **Missing context** | "Fix redirect issue" | "User gets 404 on /dashboard after oauth callback (Prod only, affects 5% of users)" |

---

## Quick Checklist Before Submitting a Task

- [ ] **Title**: Clear, actionable, < 80 characters
- [ ] **Type**: Correctly categorized (Feature/Bug/Improvement/Docs/Testing)
- [ ] **Description**: 2-3 sentences; someone unfamiliar can understand it
- [ ] **Acceptance Criteria**: 3+ testable conditions, measurable outcomes
- [ ] **Estimate**: 1–8 points (or break down if larger)
- [ ] **Assignee**: Named person, not a team
- [ ] **Due Date**: Set (or sprint assignment)
- [ ] **Priority**: Reflects business impact
- [ ] **Dependencies**: Identified if they exist
- [ ] **Subtasks**: Broken out if task > 8 points
- [ ] **Labels/Tags**: Added for easy filtering

---

## AI-Assisted Task Generation

When generating multiple tasks from a spec or project plan:

1. **Extract requirements** from source document
2. **Map requirements to task types** (feature, bug, test, docs, etc.)
3. **Define acceptance criteria** for each
4. **Estimate effort** based on complexity
5. **Identify dependencies** between tasks
6. **Suggest sprint assignment** based on priority + capacity
7. **Export in requested format** (Jira, GitHub, CSV, Markdown, etc.)

**Example input**:
```
Specification snippet:
"Build an export feature allowing users to download reports as CSV. 
Reports should include date range filtering. Must integrate with 
S3 for large exports. < 2 second response time required."
```

**Generated tasks**:
```
1. TASK: Design export API spec
   Type: Documentation
   Estimate: 3 pts
   AC: API spec documented with request/response examples

2. TASK: Implement CSV export endpoint
   Type: Feature
   Estimate: 5 pts
   AC: Endpoint returns CSV, handles dates, < 2s response
   Depends on: Task 1

3. TASK: Add S3 integration for large exports
   Type: Feature
   Estimate: 8 pts
   AC: Files > 10MB upload to S3, user gets signed URL
   Depends on: Task 2

4. TASK: Build export button UI
   Type: Feature
   Estimate: 3 pts
   AC: Button visible, date picker works, triggers download
   Depends on: Task 2

5. TASK: Add date range filtering to export
   Type: Feature
   Estimate: 3 pts
   AC: Filter applied, only selected dates included in CSV
   Depends on: Task 2

6. TASK: Write integration tests for export flow
   Type: Testing
   Estimate: 5 pts
   AC: 8 test cases (happy path, error cases), CI integrated
   Depends on: Task 2

7. TASK: Document export API for developers
   Type: Documentation
   Estimate: 2 pts
   AC: API docs include cURL examples, published to docs site
   Depends on: Task 1
```

---

## Quick Start

To create tasks right now:

1. **Have your source** (spec, user story, bug report, feature idea)
2. **Ask Claude** with this prompt:
   ```
   "Create tasks from this [spec/idea/bug]:
    [paste your content]
    
    I want:
    - Format: [Jira | GitHub | Linear | Markdown]
    - Team size: [2-5 people]
    - Timeline: [1 sprint | 2 weeks | 1 month]
    - Include: [subtasks | dependencies | estimates]"
    ```
3. **Review the tasks** generated
4. **Ask for adjustments** ("split task X into 3 smaller tasks", "add subtasks for task Y")
5. **Export or copy** to your task management tool

---

**Version**: 1.0  
**Last Updated**: April 2026