---
name: spec-bug-fixer
description: |
  Identify and fix bugs in technical specification documents. Use this skill whenever you need to audit, review, or repair a specification (spec.md, SRS, PRD, API spec, etc.) for consistency, accuracy, missing information, or logical errors. This includes finding cross-reference breaks, timeline conflicts, outdated information, typos, missing sections, contradictions between sections, and vague requirements. Perfect for pre-release quality assurance of technical documents.
---

# Spec Bug Fixer

A systematic skill for auditing and repairing specification documents, identifying structural, semantic, and factual errors.

## When to Use

Trigger this skill when:
- **Auditing specifications** before team review or release
- **Fixing identified bugs** in a spec document
- **Validating consistency** across multiple sections
- **Checking completeness** against a checklist of required elements
- **Detecting conflicts** between sections or requirements
- **Verifying references** (cross-links, table of contents, citations)
- **Identifying vague or ambiguous** language that could cause misinterpretation

## What This Skill Does

The skill performs a **multi-pass audit** of specification documents:

1. **Structural Audit** — Checks formatting, table of contents, section numbering
2. **Terminological Audit** — Finds inconsistent terminology and undefined terms
3. **Factual Audit** — Identifies outdated dates, timeline conflicts, missing data
4. **Cross-Reference Audit** — Validates links between sections and internal citations
5. **Logical Audit** — Detects contradictions and conflicting requirements
6. **Completeness Audit** — Ensures all required sections and criteria are present
7. **Language Audit** — Catches typos, ambiguities, and unclear phrasing

## How to Use

### Step 1: Analyze the Spec

When given a specification document, systematically review it using these categories:

#### A. Structural Issues
- Missing or incorrect section numbering
- Table of contents doesn't match actual structure
- Inconsistent heading hierarchy
- Orphaned sections or broken navigation

#### B. Terminological Issues
- **Inconsistent terminology**: Same concept referred to by different names
  - Example: "lead" vs "prospect" vs "potential customer" used interchangeably
- **Undefined terms**: Jargon used without definition in glossary
- **Terminology conflicts**: Two different meanings for the same term

#### C. Factual/Timeline Issues
- **Outdated dates or deadlines** (compared to current date)
- **Incompatible timelines**: E.g., "30-day sprint" for a 25-day project
- **Missing metrics or measurements**: Requirements without quantifiable targets
- **Missing resource allocations**: Features listed without assigned ownership

#### D. Cross-Reference Issues
- **Broken references**: Section 5.2 mentioned but doesn't exist
- **Incorrect page numbers** or line references
- **Missing citations**: Claims made without source references
- **Orphaned links**: References to external documents not provided

#### E. Logical Conflicts
- **Contradictory requirements**: Feature in scope then listed as out-of-scope
- **Conflicting timelines**: Phase 1 takes 30 days but only 10 days allocated
- **Impossible constraints**: Performance target vs hardware limitation
- **Inconsistent priorities**: Feature marked both critical and low priority

#### F. Completeness Issues
Check that these are present (when applicable):
- [ ] Executive Summary / Overview
- [ ] Clear scope (in-scope + out-of-scope)
- [ ] Architecture / System Design
- [ ] Data Model / Database Schema
- [ ] API Specifications (if relevant)
- [ ] User Roles / Personas
- [ ] Use Cases / User Stories
- [ ] Success Criteria / Acceptance Tests
- [ ] Non-Functional Requirements (performance, security, scalability)
- [ ] Risk Analysis with Mitigations
- [ ] Timeline / Phases with deliverables
- [ ] Team Structure & Responsibilities
- [ ] Glossary of Terms
- [ ] Dependencies & Assumptions

#### G. Language/Clarity Issues
- **Ambiguous language**: "System should be fast" (how fast?)
- **Vague ownership**: "Someone will handle..." (who specifically?)
- **Undefined scope boundaries**: "Etc." or "similar items"
- **Typos and grammar errors** that reduce professionalism

### Step 2: Document Findings

For each bug found, record:
```
BUG ID: [sequential number]
CATEGORY: [Structural | Terminological | Factual | Cross-Reference | Logical | Completeness | Language]
SEVERITY: [Critical | High | Medium | Low]
LOCATION: [Section, Line Number, or Phrase]
DESCRIPTION: [What is the bug?]
IMPACT: [What could go wrong?]
SUGGESTED FIX: [How to fix it]
```

### Step 3: Prioritize Fixes

Apply this severity matrix:

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Breaks understanding or execution | Contradictory requirements, broken timeline, undefined critical terms |
| **High** | Causes confusion or delays | Missing section, outdated dates, inconsistent terminology |
| **Medium** | Reduces clarity or professionalism | Typos, vague language, missing glossary entry |
| **Low** | Minor polish | Formatting inconsistency, extra whitespace |

### Step 4: Generate Fixed Document

Produce a corrected version of the specification with:
1. All critical and high-severity bugs fixed
2. Footnote or comment explaining each fix (optional, for transparency)
3. Updated table of contents if structure changed
4. Version number incremented (e.g., v1.0 → v1.1)
5. Change log documenting all fixes

## Common Patterns to Watch For

### Pattern 1: Timeline Creep
**Detection**: 25-day project with 30-day task in Phase 1
**Fix**: Adjust timeline or re-scope feature

### Pattern 2: Inconsistent Terminology
**Detection**: "Lead" in section 1.2, "prospect" in 2.1, "customer" in 3.0
**Fix**: Choose canonical term, add to glossary, replace throughout

### Pattern 3: Missing Acceptance Criteria
**Detection**: Feature listed but no "how to verify it works" criteria
**Fix**: Add Definition of Done or Success Criteria section

### Pattern 4: Orphaned Sections
**Detection**: References to "Section 5.2.3" that doesn't exist
**Fix**: Update cross-references or restructure

### Pattern 5: Scope Creep Conflicts
**Detection**: Feature listed in "In Scope" and "Out of Scope" separately
**Fix**: Move to correct section and add reasoning

### Pattern 6: Undefined Roles
**Detection**: "QA will verify X" but no QA role defined
**Fix**: Add role to team structure or specify alternative responsible party

## Tools and Checks

### Quick Checklist

Run these checks in order:
- [ ] Document has a version number and date
- [ ] All section references (e.g., "see Section 3.2") are valid
- [ ] Glossary contains all specialized terms used
- [ ] Timeline adds up (phases don't exceed total project duration)
- [ ] All "TBD" or "TODO" items are resolved or clearly marked
- [ ] Roles/responsibilities are clearly assigned (no "TBD" for critical roles)
- [ ] Success criteria are measurable (not just "good" or "fast")
- [ ] Technical constraints (budget, tools, team size) are realistic
- [ ] Dependencies between sections are documented
- [ ] Change history is up to date

### Regex Patterns (for automated scanning)

Search for these red flags:
- `TBD|TODO|FIXME|XXX` — Unresolved placeholders
- `\bet al\.|etc\.` — Vague references
- `should|could|might` — Wishy-washy requirements (should be "must" or "may")
- `As Soon As Possible|ASAP|URGENT` — Undefined timelines
- `\?{2,}` — Uncertainty markers
- `(rough|approximate|about|around)` — Imprecise measurements

## Output Format

When fixing a spec, provide:

1. **Bug Summary Report** — Table of all bugs found
2. **Fixed Specification** — Complete corrected document
3. **Change Log** — Itemized list of all changes made
4. **Notes** — Any areas requiring human judgment or further review

## Example Bug Entry

```
BUG #7
CATEGORY: Logical Conflict
SEVERITY: Critical
LOCATION: Section 2.1 and Section 2.2
DESCRIPTION: 
  "Webhook WhatsApp Integration" is marked as CRITICAL (Section 2.1)
  but also listed as "Out of Scope — MVP" (Section 2.2)
IMPACT: 
  Development team won't know whether to build this feature,
  causing schedule delays or incomplete MVP.
SUGGESTED FIX: 
  Move to IN SCOPE section with clear priority and timeline,
  or remove from both sections with explanation of why it's deferred.
```

## Tips for Success

- **Read the entire document first** before fixing, so you understand context
- **Use a consistent pass strategy**: One pass per category (structural, then terminology, etc.)
- **Cross-reference often**: When you find a term, check if it's used the same way elsewhere
- **Ask "who" and "when"**: Vague requirements often lack owner or deadline
- **Test logic**: Walk through user flows and decision trees to find contradictions
- **Compare against standards**: If this is an SRS, check against IEEE 830 structure
- **Involve domain experts**: Factual bugs may need stakeholder validation

---

**Version**: 1.0  
**Last Updated**: April 2026