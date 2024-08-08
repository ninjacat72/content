# Install the Microsoft.Graph module if not already installed
Install-Module Microsoft.Graph -Scope CurrentUser

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementConfiguration.Read.All, Group.ReadWrite.All, Device.Read.All"

# Define the Azure group ID
$groupId = "f8109f2f-f672-4254-b964-9f3fbd89eaf5"

# Get all devices in the specified Azure group
$devices = Get-MgGroupMember -GroupId $groupId -All

# Get all managed devices from Intune
$managedDevices = Get-MgDeviceManagementManagedDevice -All

# Rotate the BitLocker recovery key for each device
foreach ($device in $devices) {
    $objectId = $device.Id
    
    # Get the detailed device information to retrieve the Azure AD Device ID
    $deviceDetail = Get-MgDevice -DeviceId $objectId
    
    $azureDeviceId = $deviceDetail.DeviceId
    
    if ($azureDeviceId) {
        # Find the corresponding Intune device
        $intuneDevice = $managedDevices | Where-Object { $_.AzureADDeviceId -eq $azureDeviceId }

        if ($intuneDevice) {
            $intuneDeviceId = $intuneDevice.Id
            
            # Rotate the BitLocker keys for the Intune Device ID
            Invoke-MgGraphRequest -Method POST -Uri "beta/deviceManagement/managedDevices('$intuneDeviceId')/rotateBitLockerKeys"
            Write-Output "BitLocker keys were successfully rotated for Intune Device ID: $intuneDeviceId"
        } else {
            Write-Output "No Intune device found for Azure Device ID: $azureDeviceId"
        }
    } else {
        Write-Output "No Azure Device ID found for Object ID: $objectId"
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
