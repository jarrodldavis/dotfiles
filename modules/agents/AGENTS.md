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

## Tool Availability

- The GitHub CLI (`gh`) is installed on the host and should be preferred for
  GitHub operations.
- Sandboxed environments may hide host executables or restrict network access.
  Failure to locate or execute `gh` inside a sandbox does not establish that it
  is unavailable.
- When sandbox restrictions prevent using `gh`, retry outside the sandbox with
  appropriate permissions when supported.
- Do not install or replace `gh` solely because it is inaccessible from a
  sandbox.

### `gh` Authentication

If `gh` is unauthenticated, ask the human to provision a repository-scoped
fine-grained personal access token.

Run `gh provision-pat --show-defaults` to inspect the default permissions.
Determine whether the task requires additional or elevated permissions, and
include them as `KEY=VALUE` arguments when necessary.

Provide the human with the following instructions, substituting the actual
repository owner, name, and any additional permissions:

1. Run `gh provision-pat OWNER/REPO [KEY=VALUE ...]` on an authenticated host
   machine. This opens a browser with a prefilled fine-grained PAT creation
   form.
2. Under **Repository access**, choose **Only select repositories** and select
   the specified repository. Repository selection is not automatically
   populated.
3. Review the requested permissions, generate the token, and copy it.
4. Inside the isolated environment, run `gh auth login --hostname github.com
   --git-protocol https --with-token`.
5. Paste the token, press Enter, and then Ctrl+D.

Always provide the exact provisioning command rather than leaving placeholders
for the human to resolve.

Request only the permissions necessary for the task. Verify successful
authentication using `gh auth status` before proceeding.

Do not initiate account-wide OAuth authentication, ask the human to paste the
token into the conversation, or attempt to access credentials outside the
current environment.

## Before Finishing

- Review newly added or modified comments, documentation, and tests.
- Remove references that only make sense with knowledge of the
  conversation or previous implementations.
- Ensure every new test assertion verifies a current requirement,
  not merely the absence of a discarded approach.
