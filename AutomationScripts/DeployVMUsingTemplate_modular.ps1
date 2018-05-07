
$vCServer = "10.134.208.207" #"pf-site05-vc.sqa.local"
$vCUserName = "administrator@vsphere.local"
$vCPassword = "VMware1!"

$cluster = "Site05-Cluster"
$vmhost = "w1-hs2-g0805.eng.vmware.com"
$template = "K8SNode"
$template_gfs = "K8SNodeGFS"
$resourcePool = "Anjalir" #"Kubenix"
$dataStore = "Site05-ISCSI-5TB" #"iSCSi_LUN0_3TB"
$dataStore_gfs = "Site05-ISCSI-5TB" #"vsanDatastore" "ISCSI_LUN2-2TB"

$domain = "sqa.local" # Here domain name is sqa.local or vmware.com
$portgroup = "infra-traffic-1092"  #"infra-traffic-137"  #"infra-traffic-170"
$dnsNameserverIps = "10.118.183.252"  # "10.141.66.213" or "192.168.0.10", "192.168.0.20"
$osType = "Linux"  # Linux or Windows
$subnetMaskValue = "255.255.255.0"  # "255.255.254.0"(137) "255.255.252.0"(170)
$gatewayValue = "10.196.173.253"  # "10.134.89.253"(137) "10.134.211.253"(170)
$osCustomizationSpecName = "LinuxCustomization"

$hostNamePrefix = "fi-"

#$static_ip_address_csv_file = "/root/StaticIPs1.csv"
$static_ip_address_csv_file = ''
$static_ip_address_range = "10.196.173.72-80"  #"10.134.88.115-124" #"10.134.208.108-115"
#$static_ip_address_gfs_csv_file = "C://Users//anjalir//StaticIPs.csv"
$static_ip_address_gfs_csv_file = ''
$static_ip_address_gfs_range = "10.196.173.61-63" #"10.134.88.125-126,10.134.88.129" #"10.134.208.116-118"

$no_of_nodes = 9
$no_of_gfs_nodes = 3 # minimum 3
$vmNameTemplate = "K8SNodeAnjalir{0:D3}"
$vmNameGFSTemplate = "K8SNodeGFSAnjalir{0:D3}"

#ScriptDetails
$template_UserName = "root"
$template_Password = "kubernetes"
$script_name = "hostname_modify_k8sNode.sh"
$script_path = '/root/scripts/'
$template_script_path_value = '/'+$template_VM_UserName+'/'
$preTemplate_HostName = "K8SNode.eng.vmware.com"
$preTemplate_NodeName = "K8SNode"
$preTemplateGFS_HostName = "K8SNodeGFS.eng.vmware.com"
$preTemplateGFS_NodeName = "K8SNodeGFS"
$domain_value = "sqa.local" # Here domain name is sqa.local or vmware.com


######  Function to import Powershell Module ######
function Import-PowershellModule {
	Get-Module  -ListAvailable PowerCLI* | Import-Module
}

######  Function to Connect VC Server by passing the arguments Server, VCUserName and VCpassword ######
function Connect-VC {
	param( $VCServer, $VCUserName, $VCPassword )
	Connect-VIServer -Server $VCServer -UserName $VCUserName -Password $VCPassword
}

######  Function to get cluster by passing ClusterName as an argument ######
function GetCluster {
    param( $ClusterName )
	Get-Cluster $ClusterName
}

######  Function to get host by passing HostName as an argument ######
function GetVMHost {
	param( $HostName )
	Get-VMHost $HostName
}

######  Function to get template by passing TemplateName as an argument ######
function GetTemplate {
	param( $TemplateName )
	Get-Template $TemplateName
}

######  Function to get ResourcePool by passing ResourcePoolName as an argument ######
function GetResourcePool {
	param( $ResourcePoolName )
	Get-ResourcePool $ResourcePoolName
}

###### Function to get the list of IP address by passing either CSV file or Range of IP addresses ######
function Static_ip_address_list {
	param( [string]$ip_address_csv_file, [string]$ip_address_range )
 $ip_address_List = [System.Collections.ArrayList]@()
 if ($ip_address_csv_file){
	 try{
		$static_ip=Import-CSV $ip_address_csv_file	 
	    for ($i=0; $i -lt $static_ip.Length; $i++) {
		     $ip_address_List.Add($static_ip[$i].IP) | Out-Null
	    } 
	 }
	 catch{
		Write-Output "Ran into an issue: $($PSItem.ToString())"
	 }
	 	 
 }
 elseif ($ip_address_range){
	 $list=$ip_address_range.split(',')
	 for ($i=0; $i -lt $list.Length; $i++){
	        if ($list[$i] -like "*-*"){
				$ip_address=$list[$i].split('-')
				$ip_address_List.Add($ip_address[0]) | Out-Null
				$prefix=$ip_address[0].replace($ip_address[0].split('.')[-1],'')
				$suffix=[int]($ip_address[0].split('.')[-1]) + 1
				for ($j=[int]$suffix ; $j -le $ip_address[1]; $j++) {
						$ip_address_List.Add($prefix+$j) | Out-Null
				}
			}
	    	else{
				$ip_address_List.Add($list[$i]) | Out-Null
			}
	 }
 }
 else {
   Write-Host "Please Provide Static IP addresses"
 }
 $ip_address_List
}

###### Function to create New VM by passing the arguments no_of_vms, vmName, vmHostName, vmResourceName, vmTemplateName #######
function CreateNewVM {
	param( $node_count, $vmNodeName, $vmHostName, $resourcePoolName, $templateName, $dataStoreName )
	$vmList = @()
	for ($i=0; $i -lt [int]$node_count; $i++) {
		$vmName=("$vmNodeName" -f $i)
		$vmList += New-VM -Name $vmName -VMHost $vmHostName -ResourcePool $resourcePoolName -Template $templateName -Datastore $dataStoreName
	}
	$vmList
}

###### Function to create OS Customization Spec by passing SpecName, domainname, dnsnameserverIPs and OsType as arguments ######
function CreateOSCustomizationSpec {
	param( $osCustomSpecName, $domainName, $dnsIps, $ostype )
	# Persistent and Nonpersistent Usage https://blogs.vmware.com/PowerCLI/2014/06/working-customization-specifications-powercli-part-3.html
	$linuxSpec = New-OSCustomizationSpec -Name $osCustomSpecName -Domain $domainName -DnsServer $dnsIps -NamingScheme VM -OSType $ostype -Type NonPersistent
	$linuxSpec
}

function ModifyHostName {
    param( $newHostName, $ip, $template_VM_UserName, $template_VM_Password, $script_file_path, $script_file_name, $template_script_path, $preTemplateHostName, $preTemplateNodeName, $domain )
		sleep 30s
		ssh-keygen -f "/root/.ssh/known_hosts" -R $ip
		sshpass -p ${template_VM_Password} scp -o StrictHostKeyChecking=no ${script_file_path}${script_file_name} ${template_VM_UserName}@${ip}:${template_script_path}
		ssh-keygen -f "/root/.ssh/known_hosts" -R $ip
		sshpass -p ${template_VM_Password} ssh -o StrictHostKeyChecking=no ${template_VM_UserName}@${ip} sh ${template_script_path}${script_file_name} $newHostName $preTemplateHostName $preTemplateNodeName $domain
		ssh-keygen -f "/root/.ssh/known_hosts" -R $ip
		sleep 30s
		sshpass -p ${template_VM_Password} ssh -o StrictHostKeyChecking=no ${template_VM_UserName}@${ip} rm -rf ${template_script_path}${script_file_name}
}

###### Function to set the customization spec to vm and also to PowerOn VM by passing the vmList, IPAddressList, LinuxSpec, subnetMask, gateway and portGroupName as arguments ######
function SetAndStartVM {
	param( $vmList, $staticIpList, $linuxSpec, $subnetMask, $gateway, $portgroupName, $template_VM_UserName, $template_VM_Password, $script_file_path, $script_file_name, $template_script_path, $preTemplateHostName, $preTemplateNodeName, $domain )
	$ip_hostname = @{}
	if ( $staticIpList.Length -eq 0 ){
		Write-Host "Please Provide Static IP addresses"
	}
	else{
		if ( $vmList.Length -eq $staticIpList.Length ) {
			for ($i = 0; $i -lt $vmList.Count; $i++) {
				# Acquire a new static IP from the list
				$ip = $staticIpList[$i]

				# The specification has a default NIC mapping ‚ retrieve it and update it with the static IP
				Get-OSCustomizationNicMapping -OSCustomizationSpec $linuxSpec | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ip -SubnetMask $subnetMask -DefaultGateway $gateway

				# Apply the customization
				Set-VM -VM $vmList[$i] -OSCustomizationSpec $linuxSpec -Confirm:$false	
				Get-VM $vmList[$i] | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $portgroupName -Confirm:$false	
				Start-VM $vmList[$i]
				$ip_hostname.add($ip,$vmList[$i])
				$newHostName = $hostNamePrefix+$ip.replace('.','-').split('-',[int](3))[-1]
				ModifyHostName $newHostName $ip $template_VM_UserName $template_VM_Password $script_file_path $script_file_name $template_script_path $preTemplateHostName $preTemplateNodeName $domain
			}
		}
		else {
			Write-Host "Existing VM's count is $vmList.Length but Provided IP addresses count is $staticIpList.Length.. Provide correct number of IP addresses.."
		}
	}	
	$ip_hostname
}


function main {
	try{
		Import-PowershellModule
		Connect-VC -VCServer $vCServer -VCUserName $vCUserName -VCPassword $vCPassword
		Write-Host "ClusterInfo: $cluster"
		$cluster = GetCluster $cluster
		$cluster
		Write-Host "HostInfo: $vmhost"
		$vmhost = GetVMHost $vmhost
		$vmhost
		Write-Host "TemplateInfo: $template"
		$template = GetTemplate $template
		$template
		Write-Host "ResourcePoolInfo: $resourcePool"
		$resourcePool = GetResourcePool $resourcePool
		$resourcePool

		Write-Host "IP"
		$output_ip_addresses = Static_ip_address_list -ip_address_csv_file $static_ip_address_csv_file -ip_address_range $static_ip_address_range
		$output_ip_addresses
		$vmList_opt = CreateNewVM $no_of_nodes $vmNameTemplate $vmhost $resourcePool $template $dataStore
		$vmList_opt
		$linuxSpec_opt = CreateOSCustomizationSpec $osCustomizationSpecName $domain $dnsNameserverIps $osType
		$linuxSpec_opt
		$ip_hostname_opt = SetAndStartVM $vmList_opt $output_ip_addresses $linuxSpec_opt $subnetMaskValue $gatewayValue $portgroup $template_UserName $template_Password $script_path $script_name $template_script_path_value $preTemplate_HostName $preTemplate_NodeName $domain_value
		$ip_hostname_opt

		Write-Host "GFS IP"
		$output_gfs_ip_addresses = Static_ip_address_list -ip_address_csv_file $static_ip_address_gfs_csv_file -ip_address_range $static_ip_address_gfs_range
		$output_gfs_ip_addresses
		$vmList_gfs_opt = CreateNewVM $no_of_gfs_nodes $vmNameGFSTemplate $vmhost $resourcePool $template_gfs $dataStore_gfs
		$vmList_gfs_opt
		#$linuxSpec_opt = CreateOSCustomizationSpec $osCustomizationSpecName $domain $dnsNameserverIps $osType
		#$linuxSpec_opt
		$ip_hostname_gfs_opt = SetAndStartVM $vmList_gfs_opt $output_gfs_ip_addresses $linuxSpec_opt $subnetMaskValue $gatewayValue $portgroup $template_UserName $template_Password $script_path $script_name $template_script_path_value $preTemplateGFS_HostName $preTemplateGFS_NodeName $domain_value
		$ip_hostname_gfs_opt
	}
	catch{
		Write-Output "Ran into an issue: $($PSItem.ToString())"
		Exit(1)
	}
}

main