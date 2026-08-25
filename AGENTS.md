# AGENTS.md

Provides a build environment for the Rockchip RK3576 Linux SDK and
may also be compatible with other Rockchip SoCs.

## ## Project Overview



## Project Structure


## Commit Message Guidelines

- Use a scoped subject in the form `<scope>: <concise change summary>`.
- Keep the subject focused on the main behavior change. Add a short parenthesized summary when several closely
  related aspects need to be called out.
- Separate the subject from the body with a blank line.
- For non-trivial changes, write the body as `- <component>: <change and reason/impact>` bullet points.
- Group related changes by component instead of writing narrative paragraphs. Indent wrapped continuation lines by
  two spaces.
- Include relevant tests, documentation, compatibility behavior, and runtime verification in their own bullets.
- Keep trivial documentation or typo-only commits to a subject line when no body adds useful context.

Example:

```text
dispfilter: fix gst-kms startup on NV12 source (plane resolve, convert gating, fallback caps)

- kms_target_resolver: enable universal planes and log the selected target
- video_filter_pipeline: derive fallback caps from the resolved display format
- tests/docs: cover the fix and document the resulting behavior
```

### Comments

Comments are required for non-trivial code. Prefer useful explanatory comments over overly sparse comments.

#### General Principles

- Add comments where they improve understanding of intent, assumptions, constraints, side effects, ownership, lifecycle, or control flow.
- Explain **why** something is done, not merely **what** the code does.
- Do not omit comments simply because the implementation is readable to its author.
- Prefer slightly more useful comments over too few comments.
- When in doubt about whether a non-trivial piece of code needs explanation, add a concise comment.
- Preserve useful existing comments unless they are incorrect, obsolete, or misleading.

#### Function and API Documentation

- Add a brief documentation comment for:
  - Public APIs.
  - Exported functions, methods, classes, types, modules, commands, and reusable components.
  - Non-trivial internal functions whose purpose is not immediately obvious.
- Document, when relevant:
  - Purpose.
  - Important parameters.
  - Return values.
  - Side effects.
  - Preconditions and assumptions.
  - Error behavior.
  - Ownership or lifetime rules.
  - Concurrency or thread-safety requirements.
- Trivial getters, setters, wrappers, and obvious one-line helpers may omit documentation.

#### Complex Logic

Add explanatory comments before or around non-obvious logic, including:

- Complex conditions and branches.
- Multi-step algorithms.
- Nested loops.
- State machines and state transitions.
- Retry and recovery logic.
- Error handling with non-obvious behavior.
- Parsing and serialization.
- Protocol handling.
- Concurrency, synchronization, locks, atomics, channels, queues, and asynchronous flows.
- Resource acquisition and cleanup.
- Buffer management.
- Memory ownership and lifetime.
- Performance optimizations.
- Compatibility workarounds.
- Platform-specific behavior.
- Hardware-specific behavior.
- Security-sensitive logic.
- Race-condition avoidance.
- Unusual ordering requirements.

For multi-step operations, add short comments separating the major logical stages.

#### Variables, Constants, and State

Comment variables, fields, constants, or configuration values when their meaning is not obvious.

Especially document:

- Units, such as milliseconds, bytes, frames, percentages, or timestamps.
- Valid ranges.
- Special sentinel values.
- Bit masks and flags.
- Magic numbers.
- Buffer sizes.
- Timeout and retry values.
- State variables.
- Ownership rules.
- Lifetime constraints.
- Environment-dependent values.
- Protocol or hardware constants.

Prefer replacing unexplained magic values with named constants where practical.

#### Non-Obvious Constraints

Document constraints that a future maintainer could accidentally violate, such as:

- "Must be called before ..."
- "Must remain in this order because ..."
- "Cannot run concurrently with ..."
- "Buffer must remain valid until ..."
- "Do not remove this check because ..."
- "This value must match ..."
- "The external API requires ..."
- "This workaround is required for ..."

Such comments should explain the reason for the constraint.

#### TODO Comments

Use the language-appropriate comment syntax with `TODO:` for pending work.

Examples:

```text
// TODO: ...
# TODO: ...
```
