# log-off-idle-sessions.ps1

$IdleThreshold = 180 #minutes

Start-Transcript -Append -Path C:\Temp\log-off-idle-sessions.log

# using quser, get the users and turn them into objects using new-object

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

# now that we have all the users as objects, we iterate through them with simple if/then statements

Foreach($user in $loggedonusers){
    if ($user.SessionName -eq 'console') {
        "$($user.UserName) on session $($user.Id) is logged into the console and not eligible to be logged off. Idle time reported is $($user.IdleTime)"
    } else { 
#        possible bug: $user.IdleTime is a string that should only equal 'none' or a number. If this were to ever not be the case, you may have to nest another try/catch here if [int]$user.IdleTime errors out
        if ($user.IdleTime -eq 'none') {
            "$($user.UserName) on session $($user.Id) is not logged into the console, but hasn't been idle long enough to be logged off. Idle for $($user.IdleTime)"
        }
        if ([int]$user.IdleTime -lt $IdleThreshold) {
            "$($user.UserName) on session $($user.Id) is not logged into the console, but hasn't been idle long enough to be logged off. Idle for $([int]$user.IdleTime)"
        }
        elseif ([int]$user.IdleTime -gt $IdleThreshold) {
            "$($user.UserName) on session $($user.Id) is idle for $([int]$user.IdleTime) and will be logged off"
            try {
                logoff $user.Id
                "$($user.UserName) has been logged off"
            } catch {
                "Error in logging user off"
            }
        } else {
            "Something else happened. $($user.SessionName) was not logged off."
        }
    }
}
Stop-Transcript