function Test-CloudFlare {
    <#
    .SYNOPSIS
    Tests a computers network connection to one.one.one.one and saves the results

    .DESCRIPTION
    Opens a session with the desired computer and runs a Test-Connection to one.one.one.one. Once the job is completed
    it is saved as testresults.txt in a designated location.

    .PARAMETER computername
    The computer(s) to be tested by the script. 

    .PARAMETER destination
    Can be used to set the location to save the test results document to a desired location, default is current users 
    home directory

    .PARAMETER output
    Desides which kind of output is produced; 
        Host    Writes output to screen
        Text    Saves output in a text file
        CSV     Saves output in a CSV
    The default is Host.

    .Example
    Test-CloudFlare -computername Server1
        Runs the test on computer named Server1

    .Example
    Test-Cloudflare -computername Server1 -output CSV
        Runs the test on computer Server1 and puts the results into a CSV file

    .Example
    Test-CloudFlare -computername Server1 -destination "C:\" -output Text
        Runs the test on computer Server1, puts the output into a text file, and saves it in the root of the C Drive

    .Notes
    Author:     Brandon Ngo
    Last Edit:  11/23/2020
    Version:    1.9
    Changes:    Added Try/Catch block for error handling options
                Creates OBJ variable with an accelerator
                Stops current For loop when an error is detected

  #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory=$True,
                    ValueFromPipeline=$True)]
        [Alias('CN', 'Name')]
        [string[]]$computername,

        $destination= $Env:USERPROFILE,

        [ValidateSet ('Host', 'Text', 'CSV')]
        $output='Host'
    )# Param block

    Begin{#Empty
    }

    Process{
        ForEach ($testingcomputer in $computername) {

            Try{
                #Creates a variable containing the remote session for the test
                Write-Verbose -Message "Connecting to $testingcomputer"
                $Params= @{ ComputerName= $testingcomputer
                                    ErrorAction= Stop
                                } # Params
                $session= New-PSSession @Params

                Enter-PSSession -Session $session

                $DateTime= get-date 

                #Runs the actual test and stores it in a variable
                Write-Verbose -Message "Running test on $testingcomputer"
                $TestCF= Test-Netconnection 1.1.1.1 -InformationLevel Detailed

                #Creates new object with custom properties
                $OBJ= [PSCustomObject]@{
                    ComputerName= $testingcomputer
                    PingSuccess= $TestCF.PingSucceeded
                    NameResolve= $TestCF.NameResolutionSucceeded
                    ResolvedAddress= $TestCF.ResolvedAddresses
                }#OBJ

                #Exits current session and cleans up session list
                Exit-PSSession
                Remove-PSSession -Session $session

                Switch ($output) {
                    Host    {$OBJ}
                
                    #Saves results in a text file
                    Text    {
                             $OBJ | Out-File TestResults.txt
                            Write-Verbose -Message 'Generating file'
                            Add-Content -path $destination\RemTestNet.txt -Value $computername,$DateTime,(Get-Content .\TestResults.txt)
                            Write-Verbose -Message 'Opening File'
                            Start-Process -FilePath notepad "$destination\RemTestNet.txt"
                            Remove-Item -path 'TestResults.txt'
                    }# Text
            
                    #Saves results in a CSV file
                    CSV     {
                            Write-Verbose -Message 'Generating File'
                            $OBJ | Export-Csv $destination\JobResults.csv
                    }# CSV
                }# Switch

            } Catch {
                Write-Error "Remote connection to $testingcomputer failed."
            }# Try/Catch

        }# ForEach
    }# Process

    End{Write-Verbose -Message 'Finsihed running test'}

}# Function