# Changelog for WinRegOps

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.2.0] - 2024-09-08

### Added

- Added core functions
- Added comment-based help to all public functions in the `WinRegOps` module for improved usability:
  - `Backup-RegistryKey`
  - `Export-RegistryKey`
  - `Get-RegistryValue`
  - `Open-RegistryKey`
  - `Open-RegistrySubKey`
  - `Remove-RegistrySubKey`
- Added unit test skeletons for all public functions in the WinRegOps

### Changed
- Added 'WisherTools.Helpers' to Nested Modules
- Updated `build.yaml` to exclude `Modules/WisherTools.Helpers` from code coverage analysis.
- ### Changed
- Refactored `Open-RegistryKey` function to use new helper functions `Get-OpenBaseKey` and `Get-OpenRemoteBaseKey` to abstract static method calls for opening registry keys locally or remotely. This improves testability and modularity of the code.
