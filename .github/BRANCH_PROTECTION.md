# Branch Protection Policy

This repo has a mandatory quality gate before merge:
- workflow: `Quality Gate`
- jobs: `Backend`, `Admin`, `Contracts`, `Mobile`

## Recommended branch model

1. `feature/*` -> PR into `dev`
2. `dev` -> PR into `main`

## Protect `dev` (required)

In GitHub: `Settings -> Branches -> Add branch protection rule`

Rule:
- Branch name pattern: `dev`

Enable:
- `Require a pull request before merging`
- `Require approvals` (at least 1)
- `Dismiss stale pull request approvals when new commits are pushed`
- `Require status checks to pass before merging`
- `Require branches to be up to date before merging`
- `Require conversation resolution before merging`
- `Do not allow bypassing the above settings`

Required checks:
- `Backend` (or `Quality Gate / Backend`)
- `Admin` (or `Quality Gate / Admin`)
- `Contracts` (or `Quality Gate / Contracts`)
- `Mobile` (or `Quality Gate / Mobile`)

## Protect `main` (required)

Add a second rule:
- Branch name pattern: `main`

Use the same settings and required checks as `dev`.

Optional hardening:
- `Restrict who can push to matching branches`
- include only release maintainers.

## Direct push behavior

If `Require a pull request before merging` is enabled on `dev`, direct pushes to `dev` are blocked.
If this is not enabled, direct pushes can bypass your PR review flow.

## Local preflight before pushing

Run from repo root:

```bash
./scripts/ci/predeploy-check.sh
```
