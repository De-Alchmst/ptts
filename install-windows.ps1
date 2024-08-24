$local = $false

# args
if ($args.length -gt 0) {
	if ($args.length -eq 1 -and $args[0] -eq "-l") {
		$local = $true
	} else {
		echo "Usage: install-windows.ps1 {-l}"
		echo "  -l  Install locally"
		exit 1
	}
}

#test for admin
if (-not $local) {
	# a hack??
	if ((fltmc.exe).Count -eq 3) {
		echo "Cannot install globally without admin privileges"
		echo "Run install-linux.sh -l to install locally"
		exit 1
	}
}

# dependencies
if (-not (get-command crystal -ErrorAction silentlyContinue)) {
	echo "crystal nont found, can not compile"
	exit 1
}

if (-not (get-command shards -ErrorAction silentlyContinue)) {
	echo "shards not found for some reason found, can not compile"
	exit 1
}

cd src

echo "Installing shards..."
shards install
if (-not $?) {
   cd ..
   echo "shards install failed, aborting installation"
   exit 1
}

echo "Compiling..."
crystal build ptts.cr
if (-not $?) {
   cd ..
   echo "crystal build failed, aborting installation"
   exit 1
}

# install
$binDir = "C:\ProgramFiles\ptts\"
$dataDir = "C:\ProgramFiles\ptts\fonts\"

if ($local) {
   $binDir = "$env:LOCALAPPDATA\ptts\"
   $dataDir = "$env:LOCALAPPDATA\ptts\fonts\"
}

echo "making directories"
new-item -path $binDir -itemType directory -force -ErrorAction silentlyContinue
new-item -path $dataDir -itemType directory -force -ErrorAction silentlyContinue

echo "copying files"
cp ptts.exe $binDir
cp ..\data\Hack\* $dataDir

echo "adding to $PATH"

if ($local) {
	$userPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
	if ($userPath -notcontains $binDir) {
		[Environment]::SetEnvironmentVariable("PATH", "$userPath;$binDir", [EnvironmentVariableTarget]::User)
	}
} else {
	$machinePath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
	if ($machinePath -notcontains $binDir) {
		[Environment]::SetEnvironmentVariable("PATH", "$machinePath;$binDir", [EnvironmentVariableTarget]::Machine)
	}
}

cd ..

echo "done!"

# check for latex
if (-not (get-command shards -ErrorAction silentlyContinue)) {
	echo "WARNING: xelatex not found, exporting to pdf won't work!"
	exit 1
}