# CI/CD

Two pipelines, both built on one reusable test workflow so a release can only
ever be cut from a tree CI would have accepted.

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` | push to `main`, any PR, manual | Runs `tests.yml` |
| `release.yml` | push of a `v*` tag, manual | Runs `tests.yml`, then archives, exports an `.ipa`, and attaches it to the GitHub Release |
| `tests.yml` | called by the above | Builds and runs all unit + UI tests on a simulator |

## Cutting a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The tag must look like `vMAJOR.MINOR.PATCH`; it becomes `MARKETING_VERSION`,
and the workflow run number becomes `CURRENT_PROJECT_VERSION` (monotonic per
repository, which is what App Store Connect requires of a build number).

The release job only starts if every test passed. Artifacts published to the
release: the `.ipa`, a zip of the dSYMs (needed to symbolicate crash reports
from that exact build), and `SHA256SUMS.txt`.

## Signing

**Signing is optional.** With no secrets configured the pipeline still runs and
publishes an *unsigned* `.ipa` — useful for inspection or re-signing, but not
installable as-is. Add these repository secrets to get a signed build:

| Secret | What it is |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | Your distribution certificate as a `.p12`, base64-encoded |
| `P12_PASSWORD` | Password you set when exporting that `.p12` |
| `PROVISIONING_PROFILE_BASE64` | The matching `.mobileprovision`, base64-encoded |

To produce the base64 values:

```bash
base64 -i Certificates.p12 | pbcopy
base64 -i BooksMyFriend.mobileprovision | pbcopy
```

The team ID, profile name, and export method are all read out of the profile
itself, so they don't need to be supplied separately. Exporting an app-store
archive with a development profile fails late and confusingly, so the method is
derived rather than assumed — set an `EXPORT_METHOD` repository *variable*
(`app-store`, `ad-hoc`, or `development`) only if you need to override it.

### Uploading to TestFlight

Add an App Store Connect API key as well, and store-method builds will upload
automatically:

| Secret | What it is |
| --- | --- |
| `APPSTORE_API_KEY_ID` | Key ID from App Store Connect → Users and Access → Integrations |
| `APPSTORE_ISSUER_ID` | Issuer ID from the same page |
| `APPSTORE_API_PRIVATE_KEY` | Full contents of the downloaded `AuthKey_*.p8` |

## Runner requirements

The project targets iOS 26.5, so the runner needs an Xcode that ships that SDK.
The workflows default to the `macos-26` image and **fail fast with a clear
message** if the SDK is older, rather than collapsing into hundreds of unrelated
compiler errors.

If your account's runner images differ, change the `runner` input in `ci.yml` /
`release.yml`, or pin `xcode-version` (e.g. `26.6`).

## Notes

- Tests run with `-parallel-testing-enabled NO`. The SwiftData suite shares one
  `ModelContainer` and wipes it between tests, so parallel simulator clones
  would clear each other's fixtures.
- The simulator is chosen by UDID at runtime, picking the newest available
  iPhone. Naming a device instead breaks whenever a runner image changes.
- The `.xcresult` bundle is uploaded on every run, pass or fail — it is the only
  way to see *why* a UI test failed after the fact.
- The shared scheme at `BooksMyFriend.xcodeproj/xcshareddata/xcschemes/` must
  stay committed. Without it `xcodebuild -scheme` has nothing to resolve on a
  clean checkout.
