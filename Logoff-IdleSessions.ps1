# Logoff-IdleSessions.ps1

# edit this value to adjust how long a user has to be idle before the script will log them off
$IdleThreshold = 180 #minutes

# edit this line if you don't want logging to go to C:\Temp
Start-Transcript -Append -Path C:\Temp\Logoff-IdleSessions.log

# using quser, we're going to get the user info and turn them all into objects using new-object
$loggedonusers = try {
    quser | Select-Object -Skip 1 | ForEach-Object {
        $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
        $HashProps = @{UserName = $CurrentLine[0]}
#        LogonTime is no longer used in this script, but I'm keeping it here in case of future development
        if ($CurrentLine[2] -eq 'Disc') {
                $HashProps.SessionName = $null
                $HashProps.Id = $CurrentLine[1]
                $HashProps.State = $CurrentLine[2]
                $HashProps.IdleTime = $CurrentLine[3]
#                $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
#                $HashProps.LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '        } else {
                $HashProps.SessionName = $CurrentLine[1]
                $HashProps.Id = $CurrentLine[2]
                $HashProps.State = $CurrentLine[3]
                $HashProps.IdleTime = $CurrentLine[4]
#                $HashProps.LogonTime = $CurrentLine[5..($CurrentLine.GetUpperBound(0))] -join ' '        }
        New-Object -TypeName PSCustomObject -Property $HashProps |
        Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
    }
} catch {
    New-Object -TypeName PSCustomObject -Property @{
        ComputerName = "localhost"
        Error = $_.Exception.Message
    } | Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
}

# now that we have all the users as objects, we iterate through them with simple if/else statements

foreach($user in $loggedonusers){
    if ($user.SessionName -eq 'console') {
        "$($user.UserName) on session $($user.Id) is logged into the console and not eligible to be logged off"
    }
    elseif ($user.State -eq 'Disc') {
        try {
            if ([int]$user.IdleTime -lt $IdleThreshold) {
                "$($user.UserName) on session $($user.Id) is not logged into the console, but hasn't been idle long enough to be logged off. Idle for $([int]$user.IdleTime) minutes"
            }
            elseif ([int]$user.IdleTime -gt $IdleThreshold) {
                "$($user.UserName) on session $($user.Id) is idle for $([int]$user.IdleTime) and will be logged off" 
                try {
                    logoff $user.Id
                    "$($user.UserName) has been logged off"
                }
                catch {
                    "Error in logging user off"
                }
            }
        }
        catch{
            "$($user.UserName) on session $($user.Id) is not logged into the console, but hasn't been idle long enough to be logged off. Idle for $($user.IdleTime) minutes"
        }
    }
}
Stop-Transcript