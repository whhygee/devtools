---
title: Go Conventions
---

Coding conventions and best practices, primarily Go-flavored. Based on review feedback and [Uber's Go style guide](https://github.com/uber-go/guide/blob/62b6af70a7dc17deeb065010de4166f5f59c5372/style.md).

## Naming

- **Short variable names** (`b`, `c`) are fine when the scope is narrow. Loop iteration variables should be short — see [Go Code Review Comments: Variable Names](https://go.dev/wiki/CodeReviewComments#variable-names).
- **No snake_case in Go.** Use camelCase or PascalCase.
- **Receiver names** should be one or two letter abbreviations (e.g. `t` for `Team`).
- **Struct field names** shouldn't repeat the type. If the struct is `Team`, use `ID` not `TeamID`.
- **Initialisms and acronyms** (`URL`, `NATO`, `ID`) should have consistent casing — all caps or all lower, not mixed.
- **`isXX` prefix** implies a bool return. For non-bool checks, use `validateXX` instead.
- **Remove redundant type identifiers** in variable/field names.

## Error Handling

- **Handle errors immediately**, not in batches. The reason try-catch exists in exception-based systems is that errors should be dealt with on the spot. If the error is in a simple internal function, handling one layer up is acceptable.
- **When calling an external service**, wrap the error immediately. Internal upper layers can just return the error as-is.
- **`"failed to"` is unnecessary** in error context — it's already obvious something failed, and you'll end up with a chain of `"failed to"` when wrapping multiple errors.
- **Use `%w` for error propagation** so callers can unwrap:
  ```go
  var ErrNotFound = errors.New("not found")

  fmt.Errorf("user %s is not found in organization: %w", login, ErrNotFound)
  ```
- **`fmt.Errorf` vs `errors.New`** — `fmt.Errorf` is useful when wrapping a downstream error with `%w`. Otherwise, `errors.New` is enough.
- **Tell the user what to do** in error messages. E.g., if archiving a repository fails, tell them they must resolve secret scanning alerts first.
- **Always validate input arguments** before using them. An invalid argument shouldn't crash the app — an attacker can exploit this to break the system.

## Function Design

- **Avoid side effects.** Functions should not mutate arguments passed by reference unless the function name makes this explicit. Code with many side effects becomes harder to maintain as complexity grows.
- **Avoid edit/update arguments and pass-by-reference** as much as possible. Prefer returning new values.
- **Break up large API methods** into smaller internal functions that distribute the load.
- **For complex responses**, build the result at the end of the function. Define sub-types (error slices, nested structs) at the top, populate them through the function, and assemble the final response at the end:
  ```go
  var errors []*Error
  // ... processing ...
  return &Response{
      Field1: value1,
      Errors: errors,
  }
  ```
- **Reduce redundant references.** If you're accessing `fileErrors.Message` repeatedly, pull it into a local variable like `var messages []string`.

## Go-Specific

- **Use nil slices** for initialization instead of empty slices (`var s []string` not `s := []string{}`).
- **Table-driven tests:** prefer `map[string]struct{}` for test data because:
  - Reduces a field in the struct.
  - Map iteration order is non-deterministic in Go, which avoids implicit dependencies between test cases based on ordering.

## Comments

- **Always leave comments when using implicit specifications.** Explain *why* something works, not just *what* it does.
  ```go
  // Repository name is always at index 1 because file paths
  // follow the structure: org/repo/...
  repositoryName := strings.Split(file, "/")[1]
  ```

## Service Architecture

- **Service boundaries create interdependencies** if not carefully considered. In microservices this is fatal. Even in a modular monolith, prefer some duplication over inter-service communication.
- **Internal layers should have no knowledge of external layers.** No inter-service dependencies within internal layers either.
- **PubSub event payloads should be minimal.** Only include data that doesn't need verification and won't have breaking effects on downstream subscribers. For example, when syncing a repository, send just the repo name in the event — let the subscriber fetch the full spec internally. If you include the spec in the request payload, an attacker could send a malicious spec and cause unintended changes.
