$scriptVersion = "0.0.0.3"

Set-Location $PSScriptRoot

import-module ./GarminConnect/ -Force

$startTime = Get-Date
$pswhVersion = $PSVersionTable.psversion.ToString()

$config = Get-Content ./Configuration.json -Raw | ConvertFrom-Json

$influxUri = $config.InfluxUri
$influxDb = $config.InfluxDb

$password = $config.Password | ConvertTo-SecureString -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $config.UserName, $password

while ($true) {

    Write-Output "`nMain loop time: $(Get-Date)"

    $hour = [int](Get-Date -Format HH)
    # Only run every second hour between 7AM and 10PM
    while ($hour -ge 7 -and $hour -le 22) {

        [datetime]$today = Get-Date -Format yyyy-MM-dd
        $unixTimeStamp = [long]((New-TimeSpan -Start (Get-Date -Date '1970-01-01') -End (($today).ToUniversalTime())).TotalSeconds * 1E9)

        # Need to check if the result is already in the database
        $dbQuery = "SELECT * FROM LightSleepSeconds WHERE time = $unixTimeStamp"
        $dbQueryUri = $influxUri + "query?db=" + $influxDb + "&q=" + $dbQuery
        $queryResult = (Invoke-RestMethod -Uri $dbQueryUri).results.series

        if (-not $queryResult) {

            $login = New-GarminConnectLogin -Credential $credential

            if ($login) {

                $sleepData = Get-GarminSleepData -UserDisplayName $config.DisplayName

                if ($sleepData.dailySleepDTO.lightSleepSeconds -gt 0) {
                    
                    # Convert date to Unix timestamp with nanoseconds
                    [datetime]$date = $sleepData.dailySleepDTO.calendarDate
                    $timeStamp = [long]((New-TimeSpan -Start (Get-Date -Date '1970-01-01') -End (($Date).ToUniversalTime())).TotalSeconds * 1E9)

                    $userProfile = $sleepData.dailySleepDTO.userProfilePK

                    $sleep = @{
                        SleepTimeSeconds = $sleepData.dailySleepDTO.sleepTimeSeconds
                        UnmeasurableSleepSeconds = $sleepData.dailySleepDTO.unmeasurableSleepSeconds
                        DeepSleepSeconds = $sleepData.dailySleepDTO.deepSleepSeconds
                        LightSleepSeconds = $sleepData.dailySleepDTO.lightSleepSeconds
                        REMSleepSeconds = $sleepData.dailySleepDTO.remSleepSeconds
                        AwakeSleepSeconds = $sleepData.dailySleepDTO.awakeSleepSeconds
                    }

                    foreach ($metric in $sleep.Keys) {
                        
                        $value = $sleep.$metric
                        $dbWriteUri = $influxUri + "write?db=" + $influxDb
                        $null = Invoke-RestMethod -Uri $dbWriteUri -Method POST -Body "$metric,UserProfile=$userProfile value=$value $timeStamp"
                    }
                }                    
            }
        }
        else {
            Write-Output "Measurement with timestamp: $timeStamp ($today) already exist in the databas"
        }

        Write-Output "`nChild loop time: $(Get-Date)"
        Write-Output "Powershell version: $pswhVersion"
        Write-Output "Hostname: $(hostname)"
        Write-Output "Scrip start Time: $startTime"
        $Duration = ((get-date) - $startTime).TotalHours
        Write-Output ("Duration: {0:F2} Hours" -f $Duration)
        Write-Output "Child loop wait: 7200 sec"
        Write-Output "End loop $(Get-Date)"

        Start-Sleep -Seconds 7200
        $hour = [int](Get-Date -Format HH)
    }

    # Main loop every 5 min.
    Write-Output "`nMain loop wait: 300 sec"
    Start-Sleep -Seconds 300
}