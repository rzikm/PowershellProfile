function Run-FrameworkTest {
    [CmdletBinding()]
    param(
        # Enter an interactive session on the VM instead of running the repro
        [switch] $EnterSession,

        # Install prerequisites on the VM, only needed once
        [switch] $Prereqs,

        # Build the .NET Framework locally before deploying
        [switch] $BuildFramework,

        # Deploy local .NET Framework build to the VM before running
        [switch] $Deploy,

        # Path to the directory containing the target binaries to run on the target VM, expected to be built already (no VS assumed on the VM)
        [string] $LocalReproPath,

        # Name of the repro executable to run on the target VM, expected to be built already (no VS assumed on the VM)
        [string] $ReproExe,

        # Arguments to pass to the repro executable when running on the target VM
        [string[]] $ReproArgs,

        # Name of the target VM to deploy to
        [string] $VmName = "win11",

        # Credentials to the target VM
        [string] $Username = "User",

        # Password to the target VM
        [string] $Password = "password",

        # list of assemblies to replace in the GAC on the target VM with the locally built binaries, expected to be built already (no VS assumed on the VM)
        [string[]] $AssembliesToReplace = @("System.dll"),

        # local path to the .NET Framework enlistment
        [string] $NetFxPath = "C:\source\NetFx\Net481Rel1Last_C\src\",

        # Path to where local .NET Framework enlistment creates build outputs
        [string] $LocalNetFxArtifactsPath = "C:\binaries.amd64ret"
    )
    # path to where NCLTools is located locally
    $nclToolsRoot = "C:\source\NCLTools\"

    $ErrorActionPreference = 'stop'

    # credentials to the target VM
    $creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, (ConvertTo-SecureString $password -AsPlainText -Force))

    $vm = Get-VM -Name $VmName

    # Root directory on the VM where all files will be copied to
    $destinationRoot = "C:\tmp\"
    $remoteReproRoot = Join-Path $destinationRoot "Repro"
    $remoteNclToolsRoot = Join-Path $destinationRoot "NCLTools"
    $remoteNetFxArtifactsPath = Join-Path $destinationRoot "NetFxArtifacts"

    try {
        
        if ($vm.State -ne "Running") {
            Write-Host "Starting VM..."
            Start-VM -Name $VmName
            Write-Host "Waiting for VM to start..."
            $vm | Wait-VM -For IPAddress
        }

        if ($Prereqs) {
            if (!(Test-Path $nclToolsRoot -PathType Container)) {
                Write-Error "NCLTools path does not exist: $nclToolsRoot"
            }

            if ((Get-VMFirmware -VM $vm | Select-Object -ExpandProperty SecureBoot) -ne "Off") {
                Write-Host "Stopping VM to disable Secure Boot..."
                Stop-VM -VM $vm -Force

                Write-Host "Disabling Secure Boot on VM to allow running unsigned code..."
                Set-VMFirmware -EnableSecureBoot Off -VMName $vmName

                Write-Host "Restarting VM..."
                Start-VM -VM $vm
            }

            Write-Host "Establishing session to VM..."
            $session = New-PSSession -VMName $vmName -Credential $creds

            Write-Host "Copying prereqs to VM..."
            Invoke-Command -Session $session -ScriptBlock { New-Item -Path $using:destinationRoot -ItemType Directory -ErrorAction SilentlyContinue | Out-Null }
            Copy-Item -Force -Verbose -Path $nclToolsRoot -Destination $remoteNclToolsRoot -Recurse -ToSession $session

            Write-Host "Installing StrongNameHijack MSI on VM..."
            Invoke-Command -Session $session -ScriptBlock {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$using:remoteNclToolsRoot\StrongNameHijack.msi`" /qn" -Wait
            }

            Write-Host "Enabling test signing on VM..."
            Invoke-Command -Session $session -ScriptBlock {
                bcdedit /set testsigning on
            }

            Remove-PSSession $session

            Write-Host "Rebooting VM to apply prereqs..."
            Restart-VM -VM $vm -For IPAddress -Force -Wait -Type Reboot
        }

        if ($BuildFramework) {
            # we want to deploy the newly built binaries later
            $Deploy = $true

            Write-Host "Building .NET Framework binaries..."
    
            @"
@echo off
cdncl
pushd .
set disable_core_build=1
build -z System.csproj && nclsign
popd
"@ | C:\Windows\SysWOW64\cmd.exe /k cd $netfxPath "&&" $netfxPath\tools\razzle.cmd no_oacr ret amd64 no_certcheck
        }

        Write-Host "Establishing session to VM..."
        $session = New-PSSession -VMName $vmName -Credential $creds

        if ($EnterSession) {
            Write-Host "Entering interactive session on VM..."
            Enter-PSSession -Session $session
            exit
        }

        if ($Deploy) {
            Write-Host "Deploying local .NET Framework build to VM..."
            Invoke-Command -Session $session -ScriptBlock {
                Remove-Item -Path $using:remoteNetFxArtifactsPath -Recurse -Force -ErrorAction SilentlyContinue
                New-Item -Path $using:remoteNetFxArtifactsPath -ItemType Directory | Out-Null
            }

            foreach ($assembly in $assembliesToReplace) {
                Copy-Item -Path "$localNetFxArtifactsPath\$assembly" -Destination "$remoteNetFxArtifactsPath\$assembly" -ToSession $session
            }

            Write-Host "Replacing system assemblies on VM..."
            Invoke-Command -Session $session -ScriptBlock {
                foreach ($assembly in $using:assembliesToReplace) {
                    Write-Host "Replacing $assembly..."
                    & "$using:remoteNclToolsRoot\\ReplaceAssemblies\ReplaceSystemAssemblies\ReplaceAssembly.cmd" "$using:remoteNetFxArtifactsPath\$assembly"
                }
            }
        }

        if ($LocalReproPath) {
            Write-Host "Copying repro to VM..."
            Invoke-Command -Session $session -ScriptBlock {
                Remove-Item -Path $using:remoteReproRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
            Copy-Item -Path $localReproPath -Destination $remoteReproRoot -Recurse -ToSession $session
        }


        Write-Host "Starting repro on VM..."
        Write-Host "==================="
        Invoke-Command -Session $session -ScriptBlock {
            & "$using:destinationRoot\Repro\$using:reproExe" @using:reproArgs
        }
        Write-Host "==================="
        Write-Host "Repro ended"

    }
    finally {
        if ($session) {
            Remove-PSSession $session
        }
    }
}
