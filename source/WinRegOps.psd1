#
# Module manifest for module 'WinRegOps'
#
# Generated by: LarryWisherMan
#
# Generated on: 9/6/2024
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'WinRegOps.psm1'

    # Version number of this module.
    ModuleVersion        = '0.0.1'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID                 = 'eb12e370-5823-4240-8b84-19f48e900808'

    # Author of this module
    Author               = 'LarryWisherMan'

    # Company or vendor of this module
    CompanyName          = 'LarryWisherMan'

    # Copyright statement for this module
    Copyright            = '(c) 2024 LarryWisherMan. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'The WinRegOps module provides a comprehensive set of PowerShell functions to interact with the Windows registry, offering a simplified interface for common operations such as reading, writing, and deleting registry keys and values. It acts as a wrapper around the Microsoft.Win32.RegistryKey .NET class, extending its functionality for both local and remote registry operations.

The module is designed to handle tasks like retrieving specific registry values, exporting registry keys, managing subkeys, and removing keys with enhanced error handling. It allows for seamless interaction with the Windows registry across various environments and use cases, such as system configuration, profile management, and application settings.

This module can be used independently or as a dependency for higher-level management modules, offering flexibility and reliability in registry operations.

Key features:

- Open registry keys (local and remote).
- Query and retrieve registry values.
- Create, delete, and backup registry keys and subkeys.
- Built-in error handling for permission issues and remote access.
- Works with multiple registry hives (e.g., HKEY_LOCAL_MACHINE, HKEY_CURRENT_USER).

Typical use cases include:
- Simplifying registry access in complex automation tasks.
- Providing a reliable registry management layer for other modules like ProfileManagement.
- Managing the lifecycle of registry keys during system configuration changes.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.0'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules        = ''

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @()

    # List of all modules packaged with this module
    ModuleList           = @('WisherTools.Helpers')

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            Prerelease   = ''
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Windows', 'Registry', 'RemoteRegistry', 'ProfileManagement', 'SystemConfiguration', 'RegistryOperations', 'Automation', 'PowerShell')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/LarryWisherMan/WinRegOps/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/LarryWisherMan/WinRegOps'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'https://raw.githubusercontent.com/LarryWisherMan/WinRegOps/main/WinRegOps/assets/WinRegOps.png'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
