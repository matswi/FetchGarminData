Set-Location $PSScriptRoot

import-module ./GarminConnect/ -Force

$config = Get-Content ./Configuration.json -Raw | ConvertFrom-Json

$influxDbUri = $config.InfluxDbUri

$password = $config.Password | ConvertTo-SecureString -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $config.UserName, $password

while ($true) {

    $hour = [int](Get-Date -Format HH)
    # Only run every second hour between 7AM and 10PM
    while ($hour -ge 7 -and $hour -le 22) {

        $login = New-GarminConnectLogin -Credential $credential

        if ($login) {

            $sleepData = Get-GarminSleepData -UserDisplayName $config.DisplayName

            if ($sleepData.dailySleepDTO.lightSleepSeconds -gt 0) {
                
                # Convert date to Unix timestamp with nanoseconds
                [datetime]$date = $sleepData.dailySleepDTO.calendarDate
                $timeStamp = [long]((New-TimeSpan -Start (Get-Date -Date '1970-01-01') -End (($Date).ToUniversalTime())).TotalSeconds * 1E9)

                # Need to check if the result is already in the database
                $dbQuery = "SELECT * FROM LightSleepSeconds WHERE time = $timeStamp"
                $queryResult = (Invoke-RestMethod -Uri "$influxDbUri&q=$dbQuery").results.series

                if (-not $queryResult) {

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

                        Invoke-RestMethod -Uri $influxDbUri -Method POST -Body "$metric,UserProfile=$userProfile value=$value $timeStamp"
                    }
                }

                else {
                    Write-Output "Measurement already in the databas"
                }
            }
        }

        Start-Sleep -Seconds 7200
        $hour = [int](Get-Date -Format HH)
    }

    # Main loop every 5 min.
    Start-Sleep -Seconds 300
}