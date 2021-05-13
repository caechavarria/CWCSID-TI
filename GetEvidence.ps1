<# 
    Author            : Juan Buitrago 
	Date Created	  : 01 June 2018
	Date Updates:	  : 02 Feb 2020
	Version			  : 2
    Script            : to set up advance parameters, create snapshot test and vmotion test, also generate the evidence files ang get the hash for the .csv files.
						1. LatesEvents_$vm$Date.csv: record the latest 30 events to evidence the vmotion and snapshot tests
						2. AdvParameters_$vm$Date.csv: record the advance vmware parameters and their values.
						3. SummaryEvidenc_$Customer.csv: record all the relevant info per VM, these are part of the CSC aceptance critirea
				
    Purpose           : support the handover to the CSC, generating the info requeried for the process
    Pre-requisite     : Create a Text File SourceVMs.txt and populate it with the vmware names for the serves. 
						Get-VMFolderPath.ps1 and Set-VMAdvancedConfiguration.ps1 external funtions
	
#> 

function Show-Menu
{
cls
    param (
        [string]$Title = 'VMware Hypervisor CSC HandOver Process'
    )
    Clear-Host
    Write-Host "================ $Title ========Febrero 2020" -BackgroundColor "Green" -ForegroundColor "Black"
	Write-Host "Populate the file SourceVMs.txt using the vmware name for VMs" -ForegroundColor "Red"
	
    Write-Host "=> Press " -NoNewline
	Write-Host "[0]" -ForegroundColor Yellow -NoNewline 
	Write-Host " to connect to vcenter server                  <=" 
    
	Write-Host "=> Press " -NoNewline
    Write-Host "[1]" -ForegroundColor Yellow -NoNewline
	Write-Host " to generate evidences files                   <=" 
	
	Write-Host "=> Press " -NoNewline
	Write-Host "[2]" -ForegroundColor Yellow -NoNewline 
	Write-Host " to get hash                                   <=" 
    
	Write-Host "=> Press " -NoNewline
	Write-Host "[3]" -ForegroundColor Yellow -NoNewline 
	Write-Host " to set up advance parameters                  <=" 
	
	#Write-Host "=> Press " -NoNewline
	#Write-Host "[4]" -ForegroundColor Yellow -NoNewline 
	#Write-Host " to create vmotion test" -NoNewline
	#Write-Host " Deprecated" -ForegroundColor Red -NoNewline
	#Write-Host "<=" 
	
	Write-Host "=> Press " -NoNewline
	Write-Host "[5]" -ForegroundColor Yellow -NoNewline 
	Write-Host " to create snapshot test                       <=" 
	
	#Write-Host "=> Press " -NoNewline
	#Write-Host "[6]" -ForegroundColor Yellow -NoNewline 
	#Write-Host " to list the servers(SourceVMs.txt)            <=" 
	
	Write-Host "=> Press " -NoNewline
	Write-Host "[x]" -ForegroundColor Yellow -NoNewline 
	Write-Host " to end the vcenter session                    <=" 
	
	if ($global:defaultviserver -eq $Null)
	{ Write-Host "YOU ARE NOT CONNECTED TO  vCenter server=====>>>>>>" -ForegroundColor "Red"
	}else{Write-Host "You are now connected to vCenter: " $global:defaultviserver -ForegroundColor "White" " Lab Ansible Cloud Node :)"
	}
	
	$ListServers = (Get-Content SourceVMs.txt)
    Write-Host "Captioned VMs: " $ListServers -ForegroundColor "Red"

}

do
 {
 cls
     Show-Menu
	 Write-Host "Select an option or type" -ForegroundColor Green -NoNewline
	 Write-Host " [q] " -ForegroundColor Yellow -NoNewline
	 Write-Host "to exit: " -ForegroundColor Green -NoNewline
$selection = Read-Host
 
     switch ($selection)
     {
        '0' {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		#Add-PSSnapin "VMware.VimAutomation.Core"
		
		
		
		
		
		
		#$vCenter=Read-Host -Prompt 'vCenter IP'
			 $vCenter='10.215.99.55'
             connect-viserver $vCenter
         }  
		 '3' {
             . .\Set-VMAdvancedConfiguration.ps1
			 $VMsAdv = (Get-Content SourceVMs.txt)
			 foreach ($vm in $VMsAdv)
{
#>>>>Numero Maximo de Conexiones por Consola Local<<<<
Get-VM $vm | Set-VMAdvancedConfiguration -key "RemoteDisplay.maxConnections" -value 3 
#Disk shrinking feature - Enabling the VMware Tools shrink option
Get-VM $vm | Set-VMAdvancedConfiguration -key "isolation.tools.diskWiper.disable" -value false
Get-VM $vm | Set-VMAdvancedConfiguration -key "isolation.tools.diskShrink.disable" -value false
#Copy and paste feature
Get-VM $vm | Set-VMAdvancedConfiguration -key "isolation.tools.copy.disable" -value false
Get-VM $vm | Set-VMAdvancedConfiguration -key "isolation.tools.paste.disable" -value false
#Add  Hot memory-CPU
Get-VM $vm | Set-VMAdvancedConfiguration -key "vcpu.hotadd" -value true
Get-VM $vm | Set-VMAdvancedConfiguration -key "mem.hotadd" -value true
#Disabling the HotAdd/HotPlug capability
Get-VM $vm | Set-VMAdvancedConfiguration -key "devices.hotplug" -value $false
#Configuring virtual machine log number
Get-VM $vm | Set-VMAdvancedConfiguration -key "log.keepOld" -value 10
#File to Rotate
Get-VM $vm | Set-VMAdvancedConfiguration -key "log.rotateSize" -value 100000
#>>>>VMX file size<<<<
Get-VM $vm | Set-VMAdvancedConfiguration -key "tool.setInfo.sizelimit" -value 1048576
#>>>>Habilitar que los snapshots se creeen en el Working Directory y no en cada Datastore de la VM<<<<
Get-VM $vm | Set-VMAdvancedConfiguration -key "snapshot.redoNotWithParent" -value $true
#>>>>Restrict Host Info From VM Guest<<<<
Get-VM $vm | Set-VMAdvancedConfiguration -key "tools.guestlib.enableHostInfo" -value $false
set-vm $vm -Version v15 -Confirm:$false
}
         } '5' {
		 cls
             $VMsSnap = (Get-Content SourceVMs.txt)
foreach ($vm in $VMsSnap)
{
cls
get-vm $vm | new-snapshot -Name "Test HandOver" -Description "Test by SID_ID"
get-vm $vm | Get-Snapshot | Remove-Snapshot -confirm:$false

}
cls
Write-Host "Snapshot test completed, please check vmware logs" -ForegroundColor Yellow
         }
'4' { write "**Deprecated***" }
            
		 '1' {
$Customer=Read-Host -Prompt 'Input Customer Name'		 
$location="C:\vmwScripts\GetEvidence\"
New-Item -Path $Location -Name "$Customer" -ItemType "directory"
$fulllocation= "C:\vmwScripts\GetEvidence\$Customer\"	 
cls
$VMsReport = (Get-Content SourceVMs.txt)
#$ReportedVMs=New-Object System.Collections.Arraylist
$Results =@()
. .\Get-VMFolderPath.ps1
foreach ($vm in $VMsReport)
{
Write-Host  "Processing VM:" $vm "..." 

$vNicInfo = Get-VM -Name $vm | Get-NetworkAdapter 
#vNic Info  
$vNics = foreach ($vNic in $VnicInfo) {"{0}={1}"-f ($vnic.Name.split("")[2]), ($vNic.Type)}  
$vnic = $vNics -join (", ")  
$Folder= Get-VM -Name $vm | Get-vmfolderpath
$CdRoomPath= Get-vm -Name $vm | Get-cddrive | select Isopath
$CdRoomConn= Get-vm -Name $vm | Get-cddrive | select connectionstate
$now=Get-Date -format "dd-MMM-yyyy HH:mm"
$nowcsv=Get-Date -format "MMM-dd-yyyy-HH,mm"
Get-VM $vm| Get-AdvancedSetting | Select Name, Value | Export-CSV "$fulllocation\AdvParameters_$vm$nowcsv.csv" -notypeinformation
Get-VM -Name $vm | Get-VIEvent -MaxSamples 30 | Select CreatedTime ,UserName,FullFormattedMessage | Export-CSV "$fulllocation\LatesEvents_$vm$nowcsv.csv" -notypeinformation
$VMview=get-view -viewtype VirtualMachine -filter @{"Name" = "^$($Vm)$"}
#$AdvParameters= $VMview.config.extraconfig


$Grid = New-Object PSObject

$Grid | add-member -MemberType NoteProperty -Name "VM Name" -Value $VMview.Name
$Grid | add-member -MemberType NoteProperty -Name "VM Hostname" -Value $VMview.Guest.HostName
$Grid | add-member -MemberType NoteProperty -Name "VM IP" -Value $VMview.Guest.IpAddress
$Grid | add-member -MemberType NoteProperty -Name "VM PowerState" -Value $VMview.summary.runtime.powerstate
$Grid | add-member -MemberType NoteProperty -Name "VM OverallStatus" -Value $VMview.summary.Overallstatus
$Grid | add-member -MemberType NoteProperty -Name "VM Memory Size (MB)" -Value $VMview.summary.config.MemorySizeMB
$Grid | add-member -MemberType NoteProperty -Name "VM vCPUs #" -Value $VMview.summary.config.NumCpu
$Grid | add-member -MemberType NoteProperty -Name "VM vNICs #" -Value $VMview.summary.config.NumEthernetCards
$Grid | add-member -MemberType NoteProperty -Name "VM vDisks #" -Value $VMview.summary.config.NumVirtualDisks

# Item 1.17 VM Snapshot
if ($VMview.snapshot -ne $null) {
        $Grid | add-member -MemberType NoteProperty -Name "VM Snapshot " -Value " VM has a snapshot"
}
else { $Grid | add-member -MemberType NoteProperty -Name "VM Snapshot " -Value " VM has not snapshot"}


foreach ($CustomAttribute in $VMview.AvailableField){
$Grid | add-member -MemberType NoteProperty -Name $CustomAttribute.Name -Value ($VMview.Summary.CustomValue | ? {$_.Key -eq $CustomAttribute.Key}).value -force
}


foreach ($TriggeredAlarm in $VMview.TriggeredAlarmstate) {
$alarmID = $TriggeredAlarm.Alarm.ToString()
$Grid | add-member -MemberType NoteProperty TriggeredAlarms ("$(Get-AlarmDefinition -Id $alarmID)") 

}

$Grid | add-member -MemberType NoteProperty -Name "VM vNICs" -Value $vNic  
$Grid | add-member -MemberType NoteProperty -Name "VM Folder" -Value $Folder  
$Grid | add-member -MemberType NoteProperty -Name "VM CdRoom Path" -Value $CdRoomPath  
$Grid | add-member -MemberType NoteProperty -Name "VM CdRoom Connection" -Value $CdRoomConn  

# Item 1.12 Guest OS vs Guest OS config file
$Grid | add-member -MemberType NoteProperty -Name "VM Installed OS" -Value $VMview.summary.Guest.GuestFullName
$Grid | add-member -MemberType NoteProperty -Name "VM Setting OS" -Value $VMview.summary.config.GuestFullName

# Item 1.2 vmware tools
$Grid | add-member -MemberType NoteProperty -Name "VM VMtools Status" -Value $VMview.Guest.ToolsStatus
$Grid | add-member -MemberType NoteProperty -Name "VM VMtools Version" -Value $VMview.Guest.ToolsVersionStatus
$Grid | add-member -MemberType NoteProperty -Name "VM VMtools Running" -Value $VMview.Guest.ToolsRunningStatus
$Grid | add-member -MemberType NoteProperty -Name "VM VMtools Version Number" -Value $VMview.Guest.ToolsVersion

# Item 1.1 virtual machine HW
$Grid | add-member -MemberType NoteProperty -Name "VM Machine Version" -Value $VMview.config.version

# Item 1.7 Advanced parameters
$Grid | add-member -MemberType NoteProperty -Name "VM Memory HotAdd" -Value $VMview.config.MemoryHotAddEnabled
$Grid | add-member -MemberType NoteProperty -Name "VM CPU HotAdd" -Value $VMview.config.CpuHotAddEnabled
$Grid | add-member -MemberType NoteProperty -Name "VM + Advanced Parameters" -Value "Check AdvParameters$vm_$vm$nowcsv.csv"

$Grid | add-member -MemberType NoteProperty -Name "VM .vmx Path" -Value $VMview.config.files.vmpathname
# Item 1.9 Enable Logging Option
$Grid | add-member -MemberType NoteProperty -Name "VM Enable Logging" -Value $VMview.config.flags.enablelogging

# Item 1.7 Shares and Limits /Resource (CPU-MEM) Allocation
$Grid | add-member -MemberType NoteProperty -Name "VM Memory Reservation" -Value $VMview.config.memoryallocation.reservation
$Grid | add-member -MemberType NoteProperty -Name "VM Memory Limit" -Value $VMview.config.memoryallocation.Limit
$Grid | add-member -MemberType NoteProperty -Name "VM Memory Shares" -Value $VMview.config.memoryallocation.shares.level
$Grid | add-member -MemberType NoteProperty -Name "VM CPU Reservation" -Value $VMview.config.cpuallocation.reservation
$Grid | add-member -MemberType NoteProperty -Name "VM CPU Limit" -Value $VMview.config.cpuallocation.Limit
$Grid | add-member -MemberType NoteProperty -Name "VM CPU Shares" -Value $VMview.config.cpuallocation.shares.level


# Item 1.13 VM UUID
$Grid | add-member -MemberType NoteProperty -Name "VM UUID" -Value $VMview.summary.config.uuid

# Item 1.6 VM Alarms
$Grid | add-member -MemberType NoteProperty -Name "AlarmActionsEnabled" -Value $VMview.AlarmActionsEnabled
$Grid | add-member -MemberType NoteProperty -Name "Time Stamp" -Value $now
$Results+=$Grid
}

$Results |export-csv "$fulllocation\SummaryEvidence_$Customer_$nowcsv.csv" -notypeinformation


         }
		  '2' {
		  
		  $hashcustomer=Read-Host -Prompt 'Customer'
		  $hashpath=Read-Host -Prompt 'File path (C:\Path\*.*)'
        get-filehash $hashpath | export-csv "Hash_$hashcustomer$nowcsv.csv"
		Write-Host  "Hash done, check the file on C:\vmwScripts\GetEvidence\" -ForegroundColor Yellow
		  
         } 
		 '6' {
		 $ListServers = (Get-Content SourceVMs.txt)
             Write-Host $ListServers -ForegroundColor "Red"
         } 
'x' {
             disconnect-viserver $global:defaultviserver
         }  		 
     }
     pause
	  
 }
 
 until ($selection -eq 'q')

cls

 

