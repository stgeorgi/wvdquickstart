@{
    # General Information #
    # =================== #
    # Environment
    subscriptionId                        = "[subscriptionId]"      # Azure Subscription Id
    tenantId                              = "[tenantId]"            # Azure Active Directory Tenant Id
    objectId                              = "[objectId]"            # Object Id of the serviceprincipal, found in Azure Active Directory / App registrations
  
    # ResourceGroups
    location                              = "[location]"            # Location in which WVD resources will be deployed
    resourceGroupName                     = "[resourceGroupName]"   # Name of the resource group in which WVD resources will be deployed
    #######################

    # Key Vault related #
    # ================= #  
    keyVaultName                          = "[keyVaultName]"        # Name of the keyvault where the admin password is stored as secret
    AdminPasswordSecret                   = "adminPassword"         # Default, name of the secret in the keyvault
    #####################
    
    # Storage related #
    # =============== #
    wvdAssetsStorage                      = "[assetsName]"          # Name of assets storage account
    profilesStorageAccountName            = "[profilesName]"        # Name of the profiles storage account
    storageAccountSku                     = "Standard_LRS"          # default, storage account SKU
    profilesShareName                     = "wvdprofiles"           # Name of the file share in the profiles storage account where profiles will be stored
    ###################

    # Host pool related #
    # ================== #
    hostpoolName                          = "QS-WVD-HP"                         # Name of the WVD host pool
    hostpoolType                          = "Pooled"                            # Type of host pool, can be "Personal" or "Pooled" (default)
    maxSessionLimit                       = 16                                  # default
    loadBalancerType                      = "BreadthFirst"                      # Load-balancing algorithm
    vmNamePrefix                          = "QS-WVD-VM"                         # Prefix for the WVD VMs that will be deployed
    vmSize                                = "Standard_D2s_v3"                   # The VM SKU
    vmNumberOfInstances                   = 2                                   # Number of VMs to be deployed
    vmInitialNumber                       = 1                                   # default
    diskSizeGB                            = 128                                 # Size of the VMs' disk
    vmDiskType                            = "Premium_LRS"                       # SKU of the above disk
    domainJoinUser                        = "[DomainJoinAccountUPN]"            # The domain join account UPN
    domainName                            = "[existingDomainName]"              # domain for the VMs to join, taken from domainJoinUser
    adminUsername                         = "[existingDomainUsername]"          # domain controller admin username, taken from domainJoinUser
    computerName                          = "[computerName]"                    # The name of the VM with the domain controller on it. Required only when using AD Identity Approach.
    vnetName                              = "[existingVnetName]"                # Name of the virtual network with the domain controller
    vnetResourceGroupName                 = "[virtualNetworkResourceGroupName]" # Name of the resource group with the domain controller VM and VNET in it
    subnetName                            = "[existingSubnetName]"              # Name of the subnet for the VMs to join
    enablePersistentDesktop               = $false                              # WVD setting
    ######################

    # App group related #
    # ================== #
    appGroupName                          = "QS-WVD-RAG"                        # Remote app group name
    DesktopAppGroupName                   = "QS-WVD-DAG"                        # Desktop app group name
    targetGroup                           = "[targetGroup]"                     # Name of the user group to be assigned to the WVD environment. Only change to an existing group as group is created only in the initial ARM deployment.
    principalIds                          = "[principalIds]"                    # principal ID of the above test user group
    workSpaceName                         = "QS-WVD-WS"                         # Name of the WVD workspace
    workspaceFriendlyName                 = "WVD Workspace"                     # User-facing friendly name of the above workspace
    ######################

    # Imaging related #
    # ================ #
    imagingResourceGroupName              = "QS-WVD-IMG-RG"                     # [Not used, can be used for custom imaging]
    imageTemplateName                     = "QS-WVD-ImageTemplate"              # [Not used, can be used for custom imaging]
    imagingMSItt                          = "[imagingMSItt]"                    # [Not used, can be used for custom imaging]
    sigGalleryName                        = "[sigGalleryName]"                  # [Not used, can be used for custom imaging]
    sigImageDefinitionId                  = "<sigImageDefinitionId>"            # [Not used, can be used for custom imaging]
    imageDefinitionName                   = "W10-20H1-O365"                     # [Not used, can be used for custom imaging]
    osType                                = "Windows"                           # default
    publisher                             = "MicrosoftWindowsDesktop"           # default
    offer                                 = "office-365"                        # This image includes Office 365
    sku                                   = "20h1-evd-0365"                     # Points to Windows 10 Enterprise Multi-Session, build 2004
    imageVersion                          = "latest"                            # default
    ######################

    # Authentication related
    # ==================== #
    identityApproach                      = "[identityApproach]"                # (AD or Azure AD DS) identity approach to use
}
