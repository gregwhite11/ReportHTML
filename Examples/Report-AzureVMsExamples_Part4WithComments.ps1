﻿param (
	$ReportOutputPath
)

Import-Module ReportHtml
Get-Command -Module ReportHtml

if (!$ReportOutputPath) 
{
	$ReportOutputPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
} 
$ReportName = "Azure VMs"

# see if we already have a session. If we don't don't re-authN
if (!$AzureRMAccount.Context.Tenant) {
    $AzureRMAccount = Add-AzureRmAccount 		
}

# Get arrary of VMs from ARM
$RMVMs = get-azurermvm 

$RMVMArray = @() ; $TotalVMs = $RMVMs.Count; $i =1 
# Loop through VMs
foreach ($vm in $RMVMs)
{
  # Tracking progress
  Write-Progress -PercentComplete ($i / $TotalVMs * 100) -Activity "Building VM array" -CurrentOperation  ($vm.Name + " in resource group " + $vm.ResourceGroupName)
    
  # Get VM Status (for Power State)
  $vmStatus = Get-AzurermVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status

  # Generate Array
  $RMVMArray += New-Object PSObject -Property @{`

    # Collect Properties
   	ResourceGroup = $vm.ResourceGroupName
	ID = $VM.id
	Name = $vm.Name;
    PowerState = (get-culture).TextInfo.ToTitleCase(($vmStatus.statuses)[1].code.split("/")[1]);
    Location = $vm.Location;
    Tags = $vm.Tags
    Size = $vm.HardwareProfile.VmSize;
    ImageSKU = $vm.StorageProfile.ImageReference.Sku;
    OSType = $vm.StorageProfile.OsDisk.OsType;
    OSDiskSizeGB = $vm.StorageProfile.OsDisk.DiskSizeGB;
    DataDiskCount = $vm.StorageProfile.DataDisks.Count;
    DataDisks = $vm.StorageProfile.DataDisks;
    }
	$i++
}
  
Function Test-Report 
{
	param (
		$TestName
	)
	$rptFile = join-path $ReportOutputPath ($ReportName.replace(" ","") + "-$TestName" + ".mht")
	$rpt | Set-Content -Path $rptFile -Force
	Invoke-Item $rptFile
	sleep 1
}

####### Example 12 ########
# The two logo files are stored in the report path 
$MainLogoFile =  join-path $ReportOutputPath "ACELogo.jpg"
$ClientLogoFile = join-path $ReportOutputPath "YourLogo.jpg"

$rpt = @()
$rpt += Get-HtmlOpen -TitleText  ($ReportName + " Example 12")
$rpt += Get-HtmlContentOpen -HeaderText "Size Summary"
$rpt += Get-HtmlContentTable ($RMVMArray | group Size | select name, count | sort count -Descending)
$rpt += Get-HtmlContentClose 

# In this case we are going to swap the logos around using ClientLogoFile and MainLogoFile parameters and switching the files used
$rpt += Get-HtmlClose -ClientLogoFile $MainLogoFile -MainLogoFile $ClientLogoFile 
Test-Report -TestName Example12 

####### Example 13 ########
$rpt = @()
$rpt += Get-HtmlOpen -TitleText  ($ReportName + " Example 13")
$rpt += Get-HtmlContentOpen -HeaderText "Size Summary"
$rpt += Get-HtmlContentTable ($RMVMArray | group Size | select name, count | sort count -Descending)
$rpt += Get-HtmlContentClose 

# We have been using Get-HTMLClose up until now which has a default of ClientLogo1
# In this case we can specify ClientLogo5
$rpt += Get-HtmlClose -ClientLogoType ClientLogo5

Test-Report -TestName Example13

Invoke-Item $ReportOutputPath
