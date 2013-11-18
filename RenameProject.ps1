<#
PowerShell script to rename C# Project including: 
* Copying project folder to folder with new project name
* Renaming .csproj file and other files with project name
* Changing project name reference in .sln solution file
* Changing RootNamespace and AssemblyName in .csproj file

PREREQUISITES:
* Run script from project folder.
#>
param(
    [parameter(
        HelpMessage="Existing C# Project to rename, without extension.`nUse '*' wildcard to peek project file automatically.",
        Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateScript({
        if (Test-Path -Path ("$_.csproj")) { $true }
        else { throw "Unable to resolve project name as: '$_' + '
        '" }
    })]
    [string]$ProjectFileName,
    
    [parameter(
        HelpMessage="New project file name, without extension.",
        Mandatory=$true)]
    [string]$NewName,
 
    [parameter(
        HelpMessage="Solution path relative to project file.",
        Mandatory=$true)]
    [ValidateScript({
        if (Test-Path -Path $_) { $true }
        else { throw "Unable to resolve solution path: '$_'" }
    })]
    [string]$SolutionPath
)
        
$ProjectPath=Resolve-Path "$ProjectFileName.csproj"
$OldName=[IO.Path]::GetFileNameWithoutExtension($ProjectPath)
 
echo "Renaming project from `"$OldName`" to `"$NewName`""
echo "=========="
echo "1. Copying project folder"
 
copy . "..\$NewName" -Recurse -WhatIf
copy . "..\$NewName" -Recurse
 
echo "Done."
 
echo "----------"
echo "2. Renaming .proj and other files"
cd "..\$NewName"
dir -Include "$OldName.*" -Recurse | ren -NewName {$_.Name -replace [regex]("^"+$OldName+"\b"), $NewName} # -WhatIf
 
echo "Done."
 
echo "----------"
echo "3. Renaming project name in '$SolutionPath' file."
echo "(But first creating solution backup in '$SolutionPath.backup')"
copy "$SolutionPath" "$SolutionPath.backup" -WhatIf
copy "$SolutionPath" "$SolutionPath.backup"
 
(Get-Content "$SolutionPath") |
   % { if ($_ -match ($OldName + "\.csproj")) { $_ -replace [regex]("\b"+$OldName +"\b"), $NewName } else { $_ }} |
   Set-Content "$SolutionPath"
 
echo "Done."
 
echo "----------"
echo "4. Renaming project name inside '$ProjectPath' file: AssemblyName and RootNamespace"
 
(Get-Content "$NewName.csproj") | 
    % { if ($_ -match ("<(?:AssemblyName|RootNamespace)>(" + $OldName +")</")) { $_ -replace $($matches[1]), $NewName } else { $_ }} |
    Set-Content "$NewName.csproj"
 
echo "Done."
 
echo "=========="
echo "TADAH!"