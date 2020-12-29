import-module GarminConnect -Force

$config = Get-Content .\Configuration.json -Raw | ConvertFrom-Json

$influxDbUri = $config.InfluxDbUri

$password = $config.Password | ConvertTo-SecureString -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $config.UserName, $password

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

            Invoke-RestMethod -Uri $influxDbUri -Method POST -Body "$metric,UserProfile=$userProfile value=$value $timeStamp"
        }
    }
}


