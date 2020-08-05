#Script to setup golden image with Azure Image Builder

#Create temp folder
New-Item -Path 'C:\temp' -ItemType Directory -Force | Out-Null

#Disable Automatic Updates

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1
Start-Sleep -Seconds 10

#Set Time Zone Redirection

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fEnableTimeZoneRedirection"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fEnableTimeZoneRedirection" -PropertyType "DWORD"  -Value 1 -Force
Start-Sleep -Seconds 5

#Start sleep
Start-Sleep -Seconds 10


#Enable FS Logix Profile Containers
New-Item -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "Enabled"
Set-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "Enabled" -PropertyType "DWORD" -Value 1 -Force
New-Item -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VHDLocations" 
Set-ItemProperty -Path  "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VHDLocations"  -PropertyType "MultiString" -Value "\\fslogix profile container UNC path" -Force
Start-Sleep -Seconds 10

#Enable FS Logix Office Containers
New-Item -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "Enabled" 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "Enabled"  -PropertyType "DWORD" -Value 1 -Force
New-Item -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "VHDLocations" 
Set-ItemProperty -Path  "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "VHDLocations"  -PropertyType "MultiString" -Value "\\fslogix profile container UNC path" -Force
Start-Sleep -Seconds 10


#Enable Power configuration for maximum performance

powercfg /setactive SCHEME_MIN

#Start sleep
Start-Sleep -Seconds 10

#Use the below script block if onedrive needs to be setup as the default location for saving user files
    #For silent Account Config and Files On Demand
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "SilentAccountConfig" -PropertyType "DWORD" -Value 1 -Force
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "FilesOnDemandEnabled" -PropertyType "DWORD" -Value 1 -Force
    #To trigger OneDrive in a RemoteApp
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\" -Name RailRunonce -Force 
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RailRunonce\" -Name "OneDrive" -Force 
    Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Control\Terminal Server\RailRunonce\" -Name "OneDrive" -Value "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background" -Type String 

    #Enable First Time Users 
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "EnableDAL"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "EnableDAL" -Value "2" -Type "DWORd" -Force

    
    #Redirect and move Windows known folders to OneDrive  
    New-Item -Path "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptIn"
    Set-ItemProperty -Path "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptIn" -Value "Your AAD ID Goes Here" -Type String -Force

# Enable File and Printer sharing for ping 

Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True 

# Limit number of concurrent sessions 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name "MaxInstanceCount" -Value 4294967295 -Type DWord -Force

# Session Reconnect Options

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "fDisableAutoReconnect" -Value 0 -Type DWord -Force 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name "fInheritReconnectSame" -Value 1 -Type DWord -Force 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name "fReconnectSame" -Value 0 -Type DWord -Force

# Session Set keep-alive value 

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "KeepAliveEnable" -Value 1  -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "KeepAliveInterval" -Value 1  -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name "KeepAliveTimeout" -Value 1 -Type DWord -Force 

# Listener is listening on every network interface 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name "LanAdapter" -Value 0 -Type DWord -Force  

# Set Windows services to defaults

Set-Service -Name dhcp -StartupType Automatic 
Set-Service -Name IKEEXT -StartupType Automatic 
Set-Service -Name iphlpsvc -StartupType Automatic 
Set-Service -Name netlogon -StartupType Manual 
Set-Service -Name netman -StartupType Manual 
Set-Service -Name nsi -StartupType Automatic 
Set-Service -Name termService -StartupType Manual 
Set-Service -Name RemoteRegistry -StartupType Automatic 
Set-Service -Name Winrm -startuptype Automatic 

# Remove the WinHTTP proxy 
netsh winhttp reset proxy 
 