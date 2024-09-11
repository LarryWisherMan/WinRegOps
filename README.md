# WinRegOps

<p align="center">
  <img src="https://raw.githubusercontent.com/LarryWisherMan/ModuleIcons/main/WinRegOps.png" 
       alt="WinRegOps Icon" width="400" />
</p>

The **WinRegOps** module provides a comprehensive set of PowerShell functions to
interact with the Windows registry, offering a simplified interface for common
operations such as reading, writing, deleting, and exporting registry keys and
values. It extends the functionality of the `Microsoft.Win32.RegistryKey` .NET
class and enables local and remote registry operations with enhanced error 
handling.

This module is designed to handle registry tasks such as retrieving specific 
values, managing subkeys, and exporting registry keys. Whether performing 
configuration management tasks on local machines or managing registry settings 
across multiple remote systems, **WinRegOps** simplifies interaction with the 
Windows registry.

The module can be used independently or as a dependency for higher-level system 
configuration or management modules, providing flexibility and reliability in 
registry management operations.

---

## **Key Features**

- **Open registry keys** on both local and remote machines using 
  `Get-OpenBaseKey` and `Get-OpenRemoteBaseKey`.
- **Query and retrieve registry values** using `Get-RegistryValue`.
- **Create, delete, and backup registry keys** and their subkeys with functions 
  like `New-RegistryKey`, `Remove-RegistrySubKey`, and `Backup-RegistryKey`.
- **Export registry keys** to files using the `reg.exe` utility, with the 
  `Export-RegistryKey` and `Invoke-RegCommand` functions.
- **Enhanced error handling** for permission issues and remote registry access.
- **Support for multiple registry hives**, such as `HKEY_LOCAL_MACHINE` and 
  `HKEY_CURRENT_USER`.

---

### **Typical Use Cases**

- **Automating system configuration**: Easily modify or retrieve registry 
  settings during system setup or maintenance tasks.
- **Profile and application management**: Use the module to configure profile 
  settings or manage application-specific registry values.
- **Registry backup and recovery**: Export critical registry keys before making 
  changes, ensuring that backups are available if needed.
- **Remote registry management**: Seamlessly access and modify registry keys on 
  remote systems without needing manual intervention.

---

### **Installation**

To install **WisherTools.Helpers**, you have two options:

1. **Install from PowerShell Gallery**  
   You can install the module directly from the [PowerShell Gallery](https://www.powershellgallery.com/packages/WinRegOps)
   using the `Install-Module` command:

   ```powershell
   Install-Module -Name WinRegOps
   ```

1. **Install from GitHub Releases**  
   You can also download the latest release from the [GitHub Releases page](https://github.com/LarryWisherMan/WinRegOps/releases).
   Download the `.zip` file of the release, extract it, and place it in one of
   your `$PSModulePath` directories.

---

### **Usage**

#### Example 1: Opening a Local Registry Key

Use the `Get-OpenBaseKey` function to open a registry hive on the local machine:

```powershell
$registryKey = Get-OpenBaseKey -RegistryHive 'HKEY_LOCAL_MACHINE'
```

This opens the `HKEY_LOCAL_MACHINE` hive on the local machine.

#### Example 2: Exporting a Registry Key

The `Export-RegistryKey` function allows you to export a registry key to a file
for backup purposes:

```powershell
Export-RegistryKey -RegistryPath "HKCU\Software\MyApp" -ExportPath "C:\Backup\MyApp.reg"
```

This exports the registry key `HKCU\Software\MyApp` to the file `C:\Backup\MyApp.reg`.

#### Example 3: Opening a Remote Registry Key

Use the `Get-OpenRemoteBaseKey` function to open a registry key on a remote
computer:

```powershell
$registryKey = Get-OpenRemoteBaseKey -RegistryHive 'HKEY_LOCAL_MACHINE' -ComputerName 'RemotePC'
```

This opens the `HKEY_LOCAL_MACHINE` hive on the remote computer `RemotePC`.

#### Example 4: Removing a Registry Subkey

You can remove a registry subkey using `Remove-RegistrySubKey`:

```powershell
$key = Open-RegistryKey -RegistryPath 'HKLM\Software'
Remove-RegistrySubKey -ParentKey $key -SubKeyName 'MyApp' -WhatIf
```

This will show what would happen if the `MyApp` subkey were deleted without
actually performing the deletion.

#### Example 5: Backing Up a Registry Key

The `Backup-RegistryKey` function allows you to back up a registry key to a
specified backup directory:

```powershell
Backup-RegistryKey -RegistryPath 'HKLM\Software\MyApp' -BackupDirectory 'C:\Backups'
```

This backs up the registry key `HKLM\Software\MyApp` to the `C:\Backups` directory.

---

### **Key Functions**

- **`Get-OpenBaseKey`**: Opens a registry hive on the local computer. Supports
  both 32-bit and 64-bit views.
- **`Get-OpenRemoteBaseKey`**: Opens a registry hive on a remote computer.
  Requires the remote registry service to be running.
- **`Get-RegistryValue`**: Retrieves a specific value from a registry key.
- **`Export-RegistryKey`**: Exports a registry key to a `.reg` file.
- **`Invoke-RegCommand`**: Executes a registry-related command using the `reg.exe`
  utility. This function is used internally for registry exports and other commands.
- **`Backup-RegistryKey`**: Backs up a registry key from a local or remote
  computer to a specified backup file.
- **`Remove-RegistrySubKey`**: Removes a subkey from a specified parent registry
  key, supporting `-WhatIf` and `-Confirm` for safety.

---

### **Contributing**

Contributions are welcome! Feel free to fork this repository, submit pull
requests, or report issues. You can contribute by adding new features, improving
the existing code, or enhancing the documentation.
