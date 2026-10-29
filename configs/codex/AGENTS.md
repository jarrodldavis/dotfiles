# Global Coding Instructions

## Code and Documentation

- Code, comments, documentation, and tests must describe the current
  system and its requirements, not the conversation or development
  history that produced them.
- Do not preserve references to discarded implementations, removed
  functionality, abandoned approaches, or previous iterations.
- Only add comments when they explain non-obvious logic, invariants,
  constraints, or design decisions relevant to the current implementation.
- Prefer self-documenting code over explanatory comments.
- Do not add comments or documentation merely to summarize changes.
- Remove obsolete comments and documentation when refactoring.
- Keep explanations of changes in the final response, not in source files.

## Tests

- Test observable behavior, documented contracts, and meaningful
  invariants rather than incidental implementation details.
- Do not add tests asserting that removed code, symbols, files,
  functions, variables, or implementation patterns are absent.
- Do not turn abandoned approaches or decisions made during
  iteration into permanent regression tests.
- When replacing an implementation, update tests to verify the
  intended behavior of the replacement.
- Do not add tests solely to prove that a requested edit was made.
- Every assertion must protect a meaningful requirement that would
  remain valid independently of the implementation's history.
- Avoid brittle source-text assertions when the relevant behavior
  can be tested directly.
- Remove obsolete tests and assertions when their underlying
  requirements no longer apply.

## Before Finishing

- Review newly added or modified comments, documentation, and tests.
- Remove references that only make sense with knowledge of the
  conversation or previous implementations.
- Ensure every new test assertion verifies a current requirement,
  not merely the absence of a discarded approach.
