# nvidia-subsystem-rewriter
Short script that rewrite videocard subsystem during NVIDIA driver installation

```powershell
Install-NvidiaDriver [-Print] [[-CardName] <string>] [[-Subsystem] <string>] [[-Dev] <string>] [[-DriverFile] <string>] [[-DriverTmpPath] <string>] [[-NvidiaVendorID] <string>]

PARAMETERS:
    -Print [<SwitchParameter>]
        Print all PCI devices with its DeviceName, DEV and SUBSYS.

    -CardName <String>
        Videocard official name regex from NVIDIA. Like 'RTX 3050 Laptop GPU'
        You can get it from Description property of PCI device.

    -Subsystem <String>
        Sequence next to SUBSYS_ in Device Instance ID property of PCI Device.

    -Dev <String>
        Sequence next to DEV_ in Device Instance ID property of PCI Device.

    -DriverFile <String>
        Path to executable driver file which files will be modified.

    -DriverTmpPath <String>
        Path to temporary folder for nvidia driver files which contains nvaci.inf.

    -NvidiaVendorID <String>
```
