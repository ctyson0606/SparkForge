# SparkForge

A workflow framework layer for AI coding agents, copied into a new project. It
carries no project knowledge of its own — only two things: a mechanism for
accumulating project knowledge, and a methodology for judging whether evidence
holds.

## What SparkForge does not include

These describe the boundaries of the framework itself — what SparkForge does
not ship. They say nothing about what a project using SparkForge may do.

- No built-in task tracking, kanban board, or task cards.
- No cold-start scan of an existing codebase. SparkForge is designed only for
  projects that adopt it from their first commit.
- No design for non-software work.
- No UI design system and no mockup gate.
- No module whose value depends on the whole team adopting it. This is the
  admission test for any new module: if exactly one person on the team uses it,
  is it still worth having?
