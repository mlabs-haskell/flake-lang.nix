# Developer guidelines

## Versioning and changelogging

Packages in this repository must be versioned using [PVP][pvp] for Haskell and
PureScript packages, and [Semantic Versioning 2.0.0][semver] for other languages.

Most importantly, minor and patch changes must not include any breaking changes:
no entity is removed, and there's no change in type definitions and functionality
of preexisting exported entities. If any of this occurs, a major version must be
bumped. Disregarding this rule can end up in breaking client package updates.

Any changes must be logged in `CHANGELOG.md`, which must comply with [Keep A
Changelog](https://keepachangelog.com/en/1.1.0/) requirements. Each entry should
also provide a link to the GitHub issue and/or Pull Request that corresponds to
the entry.

An example entry is below:

```lang-none
* Something is fixed
  [#123](https://github.com/mlabs/plutus-ledger-api-rust/issues/123)
```

## Release flow

In this repository we adopted a flow with multiple release branches, one for
each major version. This means that users of these packages can point to these
branches and use `nix flake update` without having to deal with breaking changes.
These branches must follow the pattern of `v-MAJOR(.MAJOR)` (`v1`, `v2` etc. for
Semantic Versioning, or v1.0 for PVP).

Furthermore, release versions are pushed as `git tags`. The CI is configured to
execute some release tasks on tag push, such as bundling binaries, publish a
GitHub release, publish to package repository etc.

Stable versions should always be pushed to their respective release branches
in a reasonable schedule (weekly or monthly depending on the project).
In most cases this would also mean a release, which requires some additional
manual tasks:

1. bump versions in package manifest files (*.cabal, Cargo.toml, etc.)
2. update lock file if necessary
3. push git tag

## Monorepo versioning policies

If a repository has multiple packages, these can evolve independently and
their release cycle could be different. To keep things consistent, we require
that major versions are aligned between packages on releases. If a package has
no major changes, it's unnecessary to release a new major version, but when it is
occasionally changed its major version must match the latest major version
in the repository, even if it requires skipping some versions.

The only exception to this rule is if a package is still in beta, in which case
a 0 major version can be used regardless of the other package versions.

If a Semantic Versioning and PVP are used simultaneously, the first major number
of PVP must always be 1 (or 0 if in a beta state).

Versioning policies when updating dependencies are well explained in the
[PVP][pvp] and [Semver][semver] documents, the same rules apply to dependencies
inside the same repository. In short, if a dependency update does not have any
effect on the public interface of the upstream package, it can be considered a
minor or patch release.

> As an example if we have three packages `HaskellApp-v1.3.4.1`,
> `HaskellLib-v1.3.0.0` and `RustApp-v0.1.0`, we could bump `HaskellApp` to `1.4.0.0`
> without touching the other two if `HaskellLib` is unchanged. After this, when
> `RustApp` reaches a stable state, we must jump to `4.0.0` straight away, to align
> versions. Similarly, if `HaskellLib` is only updated after of `HaskellApp`
> reached `1.5.0.0`, it must also jump to `1.5.0.0`.
>
> In another scenario, if we refactor `HaskellLib` and push a new major version
> `1.6.0.0`, while `HaskellApp` can update it's dependency of `HaskellLib` without
> changing its own public interface (e.g. CLI is completely unchanged), it's
> sufficient to do a minor (or patch) bump from `1.5.0.0` to `1.5.0.1`

[pvp]: https://pvp.haskell.org/
[semver]: https://semver.org/
