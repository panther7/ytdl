# config
# directory/folder for downloading videos from youtube
$outputDir = "r:\youtube-dl\"
# template/mask filename downloaded file (youtube-dl)
$outputTemplate = "%(title)s-%(id)s.%(ext)s"
# minimum available free space on disk, if is less, older files from outputDir will be remove
$freeSpaceOnDisk = 600 # in MegaBytes
# youtube-dl script absolute path
$script = "d:\apps\youtube-dl\youtube-dl.exe"
# audio/video player abolute path
$player = "c:\Program Files (x86)\JetAudio\JetAudio.exe"
# playlist config (will be sometime future)
$playlist = ""


$yt=$args[0]


# clear screen
Clear-Host
Write-Host "Youtube-dl by Panther"


Function freeSpace() {
	if ( Split-Path "$outputDir" -IsAbsolute ) {
		$deviceId = (Split-Path "$outputDir" -Qualifier)
	} else {
		$deviceId = (Split-Path "$PWD.Path" -Qualifier)
	}
	$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$deviceId'"
	return $disk.FreeSpace
}


Function isSpace() {
	Write-Host "Free space on the disk is " -NoNewLine
	$freeSpace = (freeSpace) / 1MB
	if ( $freeSpace -gt $freeSpaceOnDisk ) {
		Write-Host "ok"
		return $true
	} else {
		Write-Host "not ok"
		return $false
	}
}


Function removeOldFiles() {
	$files = (Get-ChildItem "$outputDir" -File | Sort-Object CreationTime | Select Name, FullName, @{Name="Size";Expression={$_.Length / 1MB}})
	$freeSpace = (freeSpace) / 1MB
	ForEach ($file in $files) {
		if ( $freeSpace -gt $freeSpaceOnDisk ) {
			break
		} else {
			$freeSpace += $file.Size
			Write-Host "Removing... "$file.Name
			Remove-Item $file.FullName
		}
	}
}


Function validUrl([string]$url="") {
	$p = Start-Process "$script" -ArgumentList "-q -s $url" -WindowStyle Minimized -Wait -PassThru
	if ( $p.ExitCode -eq 0 ) { return $true } else { return $false }
	#& $script -q -s $url
	#if ( $LastExitCode -eq 0 ) { return $true } else { return $false }
}


Function getFilename([string]$url="", [bool]$restrict=$true) {
    if ( $restrict ) {
        return & $script --restrict-filenames --max-quality mp4 --get-filename -o "$outputTemplate" $url
    } else {
        return & $script --max-quality mp4 --get-filename -o "%(title)s" $url
    }
}


Function downloadYT([string]$url="") {
	#$filename = getFilename $url
	#Write-Host "Donwloading..."
	#Write-Host "* Filename: " -NoNewLine
	#Write-Host $filename -backgroundcolor "Yellow" -foregroundcolor "Black"
	#Write-Host "* Url:"$url
	#$p = Start-Process "$script" -ArgumentList "--restrict-filenames --buffer-size 16K -w --max-quality mp4 -o ""$outputDir$outputTemplate"" $url" -WindowStyle Minimized -Wait -PassThru
	#return $p.ExitCode
	& $script --restrict-filenames --buffer-size 16K -w --max-quality mp4 -o "$outputDir$outputTemplate" $url
}


Function play([string]$fn="") {
	$playerProcess = "pid"

	if ( ($fn -eq "") -Or !(Test-Path $fn) ) {
		Write-Host "nothing for play"
		return $false
	}

	if ( Test-Path $playerProcess ) {
		$p = Get-Content $playerProcess -Raw | ConvertFrom-Json
		if ( $p.ProcessName -eq "JetAudio" ) {
             #Get-Process -Id $p.Id -ErrorAction SilentlyContinue | %{
             #   $_.CloseMainWindow();
             #   Wait-Process -Id $_.Id -Timeout 1 -ErrorAction SilentlyContinue
             #   Stop-Process -Id $_.Id -ErrorAction SilentlyContinue
             #}
		}
	}
	
	$p = Start-Process "$player" -ArgumentList "$fn" -WindowStyle Minimized -PassThru
	$p | Select Id, ProcessName | ConvertTo-Json > $playerProcess

	Write-Host "Playing by "$p.ProcessName" ( pid:"$p.Id")"

    return $true
}


Function error() {
	Write-Host "ERROR: "$args[0] -backgroundcolor "Red"
}


if ( !(validUrl $yt) ) {
	error "Youtube URL is not valid, try again it with new"
	return
} 


if ( !(isSpace) ) {
	Write-Host "Is is time for cleaning..."
	removeOldFiles
}


downloadYT $yt
if ( $LastExitCode -gt 0 ) {
	error "ERROR: Something is wrong with downloading video"
} else {
	$filename = getFilename $yt
	if ( play $outputDir$filename ) {
        getFilename $yt $false > "nowplaying"
    }
}
