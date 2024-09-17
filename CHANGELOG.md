# Changelog for WinRegOps

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Get-RegistrySubKey` to replace `Open-RegistrySubKey`. This implementation follows
the .net class better

- `Invoke-DeleteSubKey` and `Invoke-DeleteSubKeyTree` private functions for removing
subkeys

- `Remove-RegistrySubKey` and `Removing-RegistryKeyTree` public
public implementation

### Fixed

- Error Handling for `[System.Security.SecurityException]` in `Open-RegistryKey`

### Changed

- `Get-RegistrySubKey` includes an alias for `Open-RegistrySubKey` to for compatibility

## [0.3.0] - 2024-09-11

### Added

- Added module icon and Psd1 private data
- Quality Tests for functions and comment based help

### Changed

- Updated Icon png
- Changed `WisherTools.Helpers` to a RequiredModule module vs a nested module

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

- Updated `build.yaml` to exclude `Modules/WisherTools.Helpers` from code 
coverage analysis.

- Refactored `Open-RegistryKey` function to use new helper functions `Get-OpenBaseKey`
and `Get-OpenRemoteBaseKey` to abstract static method calls for opening registry
keys locally or remotely. This improves testability and modularity of the code.
