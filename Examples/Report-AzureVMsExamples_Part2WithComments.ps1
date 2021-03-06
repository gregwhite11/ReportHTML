param (
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

####### Example 6 ########
# We need to set some variables for building the URLs to the Azure Resource
$Base = "https://portal.azure.com/#resource/subscriptions/"
$SubID = $AzureRMAccount.Context.Subscription.SubscriptionId
$RG = "/resourceGroups/"
$vm = "/providers/Microsoft.Compute/virtualMachines/"

$rpt = @()
$rpt += Get-HtmlOpen -TitleText  ($ReportName + " Example 6")
$rpt += Get-HtmlContentOpen -HeaderText "Virtual Machines"

# Using the expression we can create an expression for each record.
# We string the base URL with the subscription ID add the resource group and VM name,
# This link is used between URL01 and URL02 we reuse the VM name for the link name and add URL03
$rpt += Get-HtmlContentTable ($RMVMArray | select ResourceGroup, `
@{Name="Azure VM";Expression={"URL01" + $Base + $SubID + $RG + $_."ResourceGroup" + $vm + $_."Name" + "URL02" + $_."Name" + "URL03" }}, `
location, Size,PowerState,  DataDiskCount, ImageSKU ) -GroupBy ResourceGroup

$rpt += Get-HtmlContentClose 
$rpt += Get-HtmlClose

Test-Report -TestName Example6


####### Example 7 ########
$VMs = ($RMVMArray | select  ResourceGroup, Name, Location, Size,PowerState,  DataDiskCount, ImageSKU ) 

# You must use single quotes here for the expression
$Red = '$this.DataDiskCount -ge 2'
$Yellow = '$this.DataDiskCount -eq 1'
$Green = '$this.DataDiskCount -lt 1'

# call the function and pass the array and color expressions
$VMsColoured = Set-TableRowColor $VMs -Red $Red -Yellow $Yellow -Green $Green

# let's just see what the function did
$VMsColoured | select ResourceGroup ,name, datadiskcount , RowColor -first 30

$rpt = @()
$rpt += Get-HtmlOpen -TitleText  ($ReportName + "Example 7")
$rpt += Get-HtmlContentOpen -HeaderText "Virtual Machines"
$rpt += Get-HtmlContentTable $VMsColoured
$rpt += Get-HtmlContentClose 
$rpt += Get-HtmlClose

Test-Report -TestName Example7

####### Example 8 ########
$rpt = @()
$rpt += Get-HtmlOpen -TitleText  ($ReportName + "Example 8")
$rpt += Get-HtmlContentOpen -HeaderText "Virtual Machines"

# here we can sort the rows so the colours are grouped together
$rpt += Get-HtmlContentTable ( $VMsColoured | sort DataDiskCount)
$rpt += Get-HtmlContentClose 
$rpt += Get-HtmlClose

Test-Report -TestName Example8

Invoke-Item $ReportOutputPath
