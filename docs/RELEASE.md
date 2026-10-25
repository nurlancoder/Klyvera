# Release process

Klyvera is pre-release. There is no published package, ISO or stable website
deployment yet. This document defines the checks required before a public
artifact can exist; it is not evidence that those checks have passed.

## Versioning

- Rust crates use the workspace version in `core/Cargo.toml`.
- PKGBUILD versions must match the Rust version. `build-packages.sh` checks this.
- The website package version is independent and follows the project release.
- Tags use the form `vX.Y.Z` or a clearly marked pre-release such as
  `v0.1.0-prototype`.
- Interfaces may change during the prototype. Do not promise compatibility.

## Release gates

A public release requires all of the following:

- [ ] The target manual checklist in `docs/MANUAL_TEST.md` has passed on Arch.
- [ ] Packages install with a dependency-resolved pacman transaction.
- [ ] Package checksums are real values, not `SKIP`.
- [ ] Packages are signed and the public verification key and keyring are
      distributed with instructions.
- [ ] The ISO has been built in a disposable environment, booted in a VM and
      installed offline or the network dependency is documented.
- [ ] The ISO checksum and signature are published.
- [ ] The website has passed the Pages workflow and the live deployment has been
      reviewed.
- [ ] `docs/STATUS.md` has no unresolved mandatory target items and lists every
      remaining limitation honestly.
- [ ] No secrets, tokens, private paths or local build output are in the tree.
- [ ] The changelog and release notes match the artifacts.

Until package signing exists, the project must not describe a build as a
production or installable release.

## Local release candidate checks

From a clean checkout:

```bash
./scripts/check.sh
```

Expected: zero failures. Every skip must have a stated reason and be covered by
CI or the target checklist.

Website:

```bash
cd web
npm ci
npm run build -- --base=/Klyvera/
npm run check -- --base /Klyvera/
npm run preview -- --base=/Klyvera/ --host 127.0.0.1 --port 4173
```

In another terminal:

```bash
cd web
BASE_URL=http://127.0.0.1:4173/Klyvera npm run test:browser
```

Packages on Arch, from a clean tree:

```bash
packaging/pkgbuild/build-packages.sh
```

Inspect the packages, run `namcap`, verify file lists and perform a real
dependency-resolved install in a disposable environment.

ISO, in a disposable VM host:

```bash
packaging/pkgbuild/build-packages.sh
sudo ./packaging/archiso/build.sh
sha256sum packaging/archiso/out/*.iso
```

Do not run the ISO build on a workstation with valuable data. The profile uses a
prototype local repository with `TrustAll` and is not a release configuration.

## Artifact manifest

A release candidate must record:

- commit SHA and tag;
- crate, package and site versions;
- package filenames and SHA-256 values;
- ISO filename and SHA-256 value;
- signature files and fingerprint;
- the exact Arch, kernel and container versions used;
- workflow run URLs for CI, packaging and Pages;
- links to the completed manual test record;
- known limitations and unverified items.

Artifacts live outside the repository unless a deliberate, reviewed release
directory is added. Do not commit package archives, ISO files, signing keys or
local repositories.

## Signing status

Not implemented:

- PKGBUILDs currently use `sha256sums=('SKIP')` for the prototype build.
- The local pacman repository is unsigned.
- The live image uses `TrustAll` for its local repository.
- There is no published release keyring or signed ISO workflow.

These are release blockers. Local checksums are useful for detecting corruption
but do not establish who produced an artifact.

## Publishing a release

Only after every release gate is satisfied:

1. Update `CHANGELOG.md`, `docs/STATUS.md`, package versions and the website.
2. Run the full local suite and the target checklist from the exact commit.
3. Build packages and ISO from that commit; record checksums and signatures.
4. Tag the commit with a signed tag.
5. Publish release notes with the artifact manifest and known limitations.
6. Deploy the website and verify the live base path, links, metadata and theme.
7. Record the published URLs and verification results in `docs/STATUS.md`.

The maintainer performs the push, tag and publication. Automation may build
artifacts but must not hold release credentials in the repository.

## Rollback

- Packages: reinstall the previous known version and verify the service state.
- Configuration: stop the daemon, verify the pre-restore backup and restore with
  explicit confirmation.
- Website: redeploy the previous verified commit through the Pages workflow.
- ISO: withdraw the artifact, publish the checksum mismatch, and do not reuse the
  release name.

Never delete the only backup, rewrite published tags or force-push a release
commit.

## Current state

As of the Phase 7 documentation update:

- Local checks pass except checks skipped by missing workstation tooling.
- Arch package builds and a `--nodeps` smoke install ran in a container.
- `mkarchiso`, ISO boot, target installation and a live session are unverified.
- Package and ISO signing are unimplemented.
- The Pages workflow is committed but has not run on GitHub.
- No release exists.
