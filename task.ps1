param (
    [string]$sourcePath,
    [string]$replicaPath,
    [string]$logFilePath

    )

function Log-Message 
{
    param ([string]$message)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"

    Add-Content -Path $logFilePath -Value $logEntry
    Write-Output $logEntry
}

try {
    if (!(Test-Path -Path $sourcePath -PathType Container)) {
        throw "Source folder does not exist: $sourcePath"
    }
    
    if (!(Test-Path -Path $replicaPath -PathType Container)) {
        throw "Replica folder does not exist: $replicaPath"
    }

    # Making the replica file to be identical to source

    $sourceFiles = Get-ChildItem -Path $sourcePath -File -Recurse
    $replicaFiles = Get-ChildItem -Path $replicaPath -File -Recurse



    # Remove files in replica that don't exist in source
    foreach ($replicaFile in $replicaFiles)
     {
        $sourceFile = $sourceFiles | Where-Object { $_.FullName -eq ($replicaFile.FullName -replace [regex]::Escape($replicaPath), $sourcePath) }
        if ($sourceFile -eq $null) 
        {
            Remove-Item -Path $replicaFile.FullName -Force
            Log-Message "Deleted file: $($replicaFile.FullName)"
        }
    }

    #Overwrite/copy every file fom source folder to replica folder 
    foreach ($sourceFile in $sourceFiles)
     {
        $replicaFile = $replicaFiles | Where-Object { $_.FullName -eq ($sourceFile.FullName -replace [regex]::Escape($sourcePath), $replicaPath) }
        if ($replicaFile -eq $null -or $sourceFile.LastWriteTime -gt $replicaFile.LastWriteTime)
         {
            $destinationPath = $sourceFile.FullName -replace [regex]::Escape($sourcePath), $replicaPath
            Copy-Item -Path $sourceFile.FullName -Destination $destinationPath -Force
            Log-Message "Copied file: $($sourceFile.FullName) to $($destinationPath)"
        }
    }


    Log-Message "Synchronization completed successfully"
}

catch {
    Log-Message "Error code: $_"
    exit 1
}
