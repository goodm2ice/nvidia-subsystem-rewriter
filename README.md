# nvidia-subsystem-rewriter
Short script that rewrite videocard subsystem during NVIDIA driver installation

```powershell
    C:\Users\Мышь\Desktop\Install-NvidiaDriver.ps1 -Print [<CommonParameters>]

    C:\Users\Мышь\Desktop\Install-NvidiaDriver.ps1 [-CardName <String>] [-Subsystem <String>] [-Dev <String>] [-DriverF
    ile <String>] [-DriverTmpPath <String>] [-NvidiaVendorID <String>] [<CommonParameters>]

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
