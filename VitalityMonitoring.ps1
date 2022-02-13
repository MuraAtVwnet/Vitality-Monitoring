#######################################################################
#
# 死活監視
#
#######################################################################


#######################################################################
# ping
#######################################################################
function TestPing( $TergetNode ){
	# Windows PowerShell
	if($PSVersionTable.PSVersion.Major -eq 5){
		if( (Test-NetConnection $TergetNode -WarningAction SilentlyContinue ).PingSucceeded ){
			return $true
		}
		else{
			return $false
		}
	}
	# PowerShell Core
	else{
		if( (Test-Connection $TergetNode -Count 1  -ErrorAction SilentlyContinue).Status -eq [System.Net.NetworkInformation.IPStatus]::Success){
			return $true
		}
		else{
			return $false
		}
	}
}

#######################################################################
# port
#######################################################################
function TestPort( [string]$TergetNode, [int]$TertgetPort ){
	# 5 秒待つ
	$TimeOut = 5

	# Windows PowerShell
	if($PSVersionTable.PSVersion.Major -eq 5){
		$JobStatus = Start-Job -ScriptBlock {(Test-NetConnection $args[0] -Port $args[1]).TcpTestSucceeded} -ArgumentList $TergetNode, $TertgetPort
	}
	else{
		$JobStatus = Start-Job -ScriptBlock {Test-Connection $args[0] -TcpPort $args[1] } -ArgumentList $TergetNode, $TertgetPort
	}

	$Dummy = Wait-Job $JobStatus -Timeout $TimeOut
	if( $JobStatus.State -eq "Completed"){
		$JobReturn = Receive-Job $JobStatus
		if( $JobReturn ){
			return $true
		}
		else{
			return $false
		}
	}
	else{
		# タイムアウト
		$JobReturn = $false
		# Stop-Job $JobStatus
		# Remove-Job $JobStatus
		return $false
	}
}

#######################################################################
# VM
#######################################################################
function TestVM( $TergetNode ){
	# Windows Server 確認
	if( (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue) -ne $null ){
		# Hyper-V インストール確認
		if((Get-WindowsFeature Hyper-V).Installed){
			# VM 状態
			$VM = Get-VM -Name $TergetNode -ErrorAction SilentlyContinue
			if( $VM -eq $null ){
				return $false
			}
			else{
				if( $VM.State -eq [Microsoft.HyperV.PowerShell.VMState]::Running ){
					return $true
				}
				else{
					return $false
				}
			}
		}
	}
	return $false
}


# Progress Preference 抑制
$SaveProgressPreference = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

$ReturnValuse = TestVM "www"
echo $ReturnValuse

# Progress Preference 回復
$ProgressPreference = $SaveProgressPreference

# 後始末
[array]$Jobs = Get-Job
foreach($TergetJob in $Jobs){
	Remove-Job -Id $TergetJob.Id
}
