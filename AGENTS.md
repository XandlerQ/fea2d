# Repository Instructions

## File Modification Restrictions
- Only create, modify, rename, move, or delete `.gd` files unless the user explicitly authorizes changes to other file types.
- This restriction includes Godot scenes (`.tscn`), resources (`.tres`), project configuration, and other repository files.
- Reading any files for context is allowed.

## Git Restrictions
- Never execute Git commands, including read-only operations, unless the user explicitly requests a specific Git operation.

## Design vs. Implementation
- Treat design and implementation as separate activities.
- **Design:** When the user asks to design, plan, explore, or discuss a solution, provide recommendations and implementation approaches in chat only. Do not modify any files.
- **Implement:** file modification is allowed, if a design was discussed then follow it, otherwise implement the feature and explain the design in your response.
- If it is unclear whether the user wants design or implementation, ask for clarification before modifying files.

## Code Changes
- Make minimal, focused changes that directly address the user's request.
- Do not refactor, rename, or reorganize unrelated code.
- Follow existing code style, naming conventions, and architectural patterns.
- Prefer existing utilities and systems over introducing new abstractions.
- Do not add unnecessary complexity or speculative functionality.

## Behavior
- Inspect relevant code before making changes.
- Do not make assumptions about unclear requirements that could significantly affect the implementation. Ask for clarification instead.
- Do not implement additional features or improvements beyond the requested scope.
- If a task requires modifying restricted files, explain why and request permission before proceeding.
- Do not silently work around restrictions.

## Formatting
- For floating-point literals with no non-zero fractional digits, omit the trailing zero but preserve the decimal point (e.g., 3.0 → 3.).