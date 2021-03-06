#
# xSqlAlias: DSC resource to configure Client Aliases
#

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SQLServerName
	)
    
    Write-Verbose -Message 'Get-TargetResource';

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $returnValue = @{
		    SQLServerName = [System.String]
            Protocol = [System.String]
            ServerName = [System.String]
		    TCPPort = [System.Int32]
            PipeName = [System.String]
		    Ensure = [System.String]
	    }

    if ($null -ne (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName" -ErrorAction SilentlyContinue))
    {
        $ItemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName";
        
        $returnValue.SQLServerName = $SQLServerName;
        $ItemConfig = $ItemValue."$SQLServerName" -split ',';
        if ($ItemConfig[0] -eq 'DBMSSOCN')
        {
            $returnValue.Protocol = 'TCP';
            $returnValue.ServerName = $ItemConfig[1];
            $returnValue.TCPPort = $ItemConfig[2];
        }
        else
        {
            $returnValue.Protocol = 'NP';
            $returnValue.PipeName = $ItemConfig[1];
        }

    }

    $returnValue;

	<#
	$returnValue = @{
		SQLServerName = [System.String]
		TCPPort = [System.Int32]
		Ensure = [System.String]
	}

	$returnValue
	#>



}





function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SQLServerName,

		[ValidateSet("TCP","NP")]
		[System.String]
		$Protocol,

		[System.String]
		$ServerName,

		[System.Int32]
		$TCPPort,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
    
    Write-Verbose -Message 'Set-TargetResource';

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1
    
    $ItemValue = [System.String];
    
    if ($Protocol -eq 'NP')
    {
        $ItemValue = "DBNMPNTW,\\$ServerName\PIPE\sql\query";
    }

    if ($Protocol -eq 'TCP')
    {
        $ItemValue = "DBMSSOCN,$ServerName,$TCPPort";
    }

    #logic based on Ensure value
    if ($Ensure -eq 'Present')
    {

        #Update the registry
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo')
        {
            Write-Debug -Message 'Set-ItemProperty';
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName" -Value $ItemValue;
        }
        else
        {
            Write-Debug -Message 'New-Item';
            New-Item -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' | Out-Null;
            Write-Debug -Message 'New-ItemProperty';
            New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName" -Value $ItemValue | Out-Null;
        }

        Write-Debug -Message 'Check OSArchitecture';
        #If this is a 64 bit machine also update Wow6432Node
        if ((Get-Wmiobject -class win32_OperatingSystem).OSArchitecture -eq '64-bit')
        {
            Write-Debug -Message 'Is 64Bit';
            if (Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo')
            {
                Write-Debug -Message 'Set-ItemProperty';
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName" -Value $ItemValue;
            }
            else
            {
                Write-Debug -Message 'New-Item';
                New-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo';
                Write-Debug -Message 'New-ItemProperty';
                New-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName" -Value $ItemValue;
            }
        }
    }


    #logic based on Ensure value
    if ($Ensure -eq 'Absent')
    {

        #If the base path doesn't exist then we don't need to do anything
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo')
        {
            Write-Debug -Message 'Remove-ItemProperty';
            Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName";
        
            Write-Debug -Message 'Check OSArchitecture';
            #If this is a 64 bit machine also update Wow6432Node
            if ((Get-Wmiobject -class win32_OperatingSystem).OSArchitecture -eq '64-bit' -and (Test-Path -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'))
            {
                Write-Debug -Message 'Remove-ItemProperty Wow6432Node';
                Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName";
            }
        }
    }


}





function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SQLServerName,

		[ValidateSet("TCP","NP")]
		[System.String]
		$Protocol,

		[System.String]
		$ServerName,

		[System.Int32]
		$TCPPort,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
    
    Write-Debug -Message 'Test-TargetResource';

	#Write-Verbose "Use this cmdlet to deliver information about command processing."
    
	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    
    $result = [System.Boolean]$true;

    if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo')
    {
        if ($null -ne (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName" -ErrorAction SilentlyContinue))
        {
            if ($Ensure -eq 'Present')
            {
                $ItemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName";
            
                $ItemConfig = $ItemValue."$SQLServerName" -split ',';

                if ($Protocol -eq 'NP')
                {
                    if ($ItemConfig[0] -ne 'DBNMPNTW') {$result = $false;}
                    if ($ItemConfig[1] -ne "\\$ServerName\PIPE\sql\query") {$result = $false;}
                }

                if ($Protocol -eq 'TCP')
                {
                    if ($ItemConfig[0] -ne 'DBMSSOCN') {$result = $false;}
                    if ($ItemConfig[1] -ne $ServerName) {$result = $false;}
                    if ($ItemConfig[2] -ne $TCPPort) {$result = $false;}
                }

                #If this is a 64 bit machine also check Wow6432Node
                if ((Get-Wmiobject -class win32_OperatingSystem).OSArchitecture -eq '64-bit')
                {
                    if ($null -ne (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName" -ErrorAction SilentlyContinue))
                    {
                        $ItemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name "$SQLServerName";

                        $ItemConfig = $ItemValue."$SQLServerName" -split ',';

                        if ($Protocol -eq 'NP')
                        {
                            if ($ItemConfig[0] -ne 'DBNMPNTW') {$result = $false;}
                            if ($ItemConfig[1] -ne "\\$ServerName\PIPE\sql\query") {$result = $false;}
                        }

                        if ($Protocol -eq 'TCP')
                        {
                            if ($ItemConfig[0] -ne 'DBMSSOCN') {$result = $false;}
                            if ($ItemConfig[1] -ne $ServerName) {$result = $false;}
                            if ($ItemConfig[2] -ne $TCPPort) {$result = $false;}
                        }
                    }
                    else
                    {
                        $result = $false;
                    }
                }
            }
            else
            {
                $result = $false;
            }
        }
        else
        {
            if ($Ensure -eq 'Present') {$result = $false;}
            else {$result = $true;}
        }
    }
    else
    {
        if ($Ensure -eq 'Present') {$result = $false;}
        else {$result = $true;}
    }

	<#
	$result = [System.Boolean]
	
	$result
	#>

    Write-Debug -Message "Test-TargetResource Result: $result";
    
    Return $result;


}





Export-ModuleMember -Function *-TargetResource




