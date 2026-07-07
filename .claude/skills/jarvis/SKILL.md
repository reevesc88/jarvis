```markdown
# jarvis Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development patterns and conventions used in the `jarvis` TypeScript codebase. It covers file organization, code style, commit practices, and testing patterns, providing clear examples and step-by-step workflows to help you contribute effectively.

## Coding Conventions

### File Naming
- Use **kebab-case** for all file names.
  - Example: `user-service.ts`, `api-handler.test.ts`

### Import Style
- Use **relative imports** for modules within the project.
  - Example:
    ```typescript
    import { fetchData } from './utils/fetch-data';
    ```

### Export Style
- Use **named exports** for all exported functions, types, or constants.
  - Example:
    ```typescript
    // In fetch-data.ts
    export function fetchData() { ... }
    export const API_URL = '...';
    ```

### Commit Messages
- Follow **conventional commit** format.
- Use the `feat` prefix for new features.
  - Example:
    ```
    feat: add support for user authentication
    ```

## Workflows

### Adding a New Feature
**Trigger:** When implementing a new feature or module  
**Command:** `/add-feature`

1. Create a new file using kebab-case (e.g., `new-feature.ts`).
2. Write your code using named exports.
3. Use relative imports for any dependencies.
4. If applicable, create a corresponding test file named `new-feature.test.ts`.
5. Commit your changes with a conventional commit message:
   ```
   feat: short description of the feature
   ```
6. Push your changes and open a pull request.

### Writing Tests
**Trigger:** When adding or updating functionality  
**Command:** `/write-test`

1. Create a test file with the pattern `*.test.ts` (e.g., `user-service.test.ts`).
2. Write tests for your exported functions or modules.
3. Use the project's (unknown) test framework conventions.
4. Run tests to ensure correctness before committing.

## Testing Patterns

- Test files follow the `*.test.ts` naming convention.
- Each test file should correspond to a source file and test its named exports.
- The specific test framework is not detected; follow existing test patterns in the codebase.

## Commands
| Command        | Purpose                                      |
|----------------|----------------------------------------------|
| /add-feature   | Guide for adding a new feature/module        |
| /write-test    | Steps for writing and organizing tests       |
```