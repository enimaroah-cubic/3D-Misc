<#
DC requires ABMs in which every mods's AB is registered. This script creates an ABM for all not registered ABs.
The script must be run for both games separately. An additional ABM is created for DC related mods without ABM.

Limitation: The script does not look into list entries, and expects that all character related ABs are located
in abdata\chara and all DC related ABs are inside abdata\craft. Mods not made like this need to get their ABs 
moved and their list/info entries adapted accordingly.

Installation and creating that ABM:
   Store this script in the game's root folder
   Create a shortcut in the game's root folder to SB3UtilityScript.exe with the name SB3UtilityScript.lnk
   Then start it in a Command Prompt with:
   > powershell -noprofile -executionpolicy bypass -file Create_ABM_for_Mods.ps1

Known issues:
   - Game or DC hang on startup after updating an older mod.
     Solution: Run this script again!

History:
03-Feb-25 initial release
05-Feb-25 computing CABString, ABM for DC mods without ABM
08-May-25 fixed bug for game folders containing blanks
#>

cd (Split-Path -Path $PSCommandPath)
$sv = Test-Path -Path abdata\sv_abdata
$hc = Test-Path -Path abdata\abdata
If (!$sv -and !$hc)
{
	'We are neiter in HC nor in SV.'
	Exit
}
$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut((Split-Path -Path $PSCommandPath) + '\SB3UtilityScript.lnk')
If (!$Shortcut.TargetPath.EndsWith('\SB3UtilityScript.exe') -or !(Test-Path $Shortcut.TargetPath))
{
	'SB3UtilityScript.lnk does not exist or is not targeting SB3UtilityScript.exe'
	Exit
}
$Sb3UGSPath = $Shortcut.TargetPath.Substring(0, $Shortcut.TargetPath.LastIndexOf('\'))
[void][Reflection.Assembly]::LoadFile($Sb3UGSPath + '\plugins\UnityBase.dll')

function Get-CABString
{
	param ($ABpath)

	$md4 = [System.Security.Cryptography.MD4]::Create()
	$bytes = [System.Text.Encoding]::UTF8.GetBytes($ABpath)
	$hash = $md4.ComputeHash($bytes)
	'CAB-' + (-join ($hash | ForEach-Object { $_.ToString("x2") }))
}

$clipboard = Get-Clipboard

$registered = Get-ChildItem -Path abdata\sv_a*, abdata\a*, abdata\craft* -Exclude sv_add007_45-MODS_WITHOUT_ABM, add007_45-MODS_WITHOUT_ABM -File -Force | 
	ForEach-Object {
		$l = $_.FullName.LastIndexOf('\abdata\') + 1
		@"
LoadPlugin(PluginDirectory+"UnityPlugin.dll")
unityParser = OpenUnity3d(path="
"@ + $_.FullName.Substring($l, $_.FullName.Length - $l) + 
			@"
")
unityEditor = Unity3dEditor(parser=unityParser)
unityEditor.CopyToClipboardAssetBundleManifest(asset=unityParser.Cabinet.Components[1])
"@ | Set-Content ABM_Into_Clipboard.script
		cmd /c ".\SB3UtilityScript.lnk ""%CD%\ABM_Into_Clipboard.script"""
		Get-Clipboard | Select-String -Pattern '<[^>]*>' -AllMatches | ForEach-Object { $_.Matches[1].Value.Substring(1, $_.Matches[1].Value.Length - 2) }
	} | Sort-Object
Remove-Item ABM_Into_Clipboard.script

$ab_set = Get-ChildItem -Path abdata\*.unity3d -Recurse -Force |
	ForEach-Object {
		$l = $_.FullName.LastIndexOf('\abdata\') + 8
		$_.FullName.Substring($l, $_.FullName.Length - $l).Replace([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
	} | Sort-Object

# https://stackoverflow.com/questions/53361968/powershell-compare-object-sideindicator

$i = 745
Compare-Object -ReferenceObject $registered -DifferenceObject $ab_set |
	Where-Object { $_.SideIndicator -eq '=>' -and ($_.InputObject -NotLike 'sound/data/*' `
											-and ($_.InputObject -NotLike 'craft/*' `
											-and ($_.InputObject -NotLike 'localization/*' `
											-and $_.InputObject -NotLike 'sprite/*'))) } |
	ForEach-Object {
		$ret = "<$i><" + $_.InputObject + '><00000000000000000000000000000000>'
		$i++
		$ret
	} |
	Set-Clipboard

$dest = $(If ($sv) {'sv_'} Else {''}) + 'add007_45-MODS_WITHOUT_ABM'
If ($i -eq 745)
{
	'All ABs were already registered. No need to create an extra ABM for character mods.'
	If ((Test-Path -Path ('abdata\' + $dest)))
	{
		Remove-Item -Path ('abdata\' + $dest)
	}
}
Else
{
	$cab = Get-CABString($dest)
	@"
LoadPlugin(PluginDirectory+"UnityPlugin.dll")
unityParser = OpenUnity3d(path="abdata\
"@ + @(If ($sv) {'sv_'} Else {''}) + 'abdata' + 
		@"
")
unityEditor = Unity3dEditor(parser=unityParser)
unityEditor.PasteFromClipboardAssetBundleManifest(asset=unityParser.Cabinet.Components[1])
unityEditor.RenameCabinet(cabinetIndex=0, name="
"@ + $cab +
		@"
")
unityEditor.SaveUnity3d(path=".\abdata\
"@ + $dest +
		'", keepBackup=False, backupExtension="", background=False, clearMainAsset=True, pathIDsMode=-1, compressionLevel=0, compressionBufferSize=0)' |
		Set-Content Clipboard_Into_ABM.script
	cmd /c ".\SB3UtilityScript.lnk ""%CD%\Clipboard_Into_ABM.script"""
	Remove-Item Clipboard_Into_ABM.script
	If ($sv -and $hc)
	{
		"Untested! Installation with ABMs from both HC and SV!`r`n" +
			'Open ' + $dest + ' with Sb3UGS and "Save As..." ' + $dest.Replace('sv_', '')
	}
}

$i = 1745
Compare-Object -ReferenceObject $registered -DifferenceObject $ab_set |
	Where-Object { $_.SideIndicator -eq '=>' -and ($_.InputObject -Like 'craft/*') } |
	ForEach-Object {
		$ret = "<$i><" + $_.InputObject + '><00000000000000000000000000000000>'
		$i++
		$ret
	} |
	Set-Clipboard

$dest = 'craft' + $(If ($sv) {'027'} Else {'007'}) + '_45-MODS_WITHOUT_ABM'
If ($i -eq 1745)
{
	'All DC related ABs were already registered. No need to create an extra ABM for DC mods.'
	If ((Test-Path -Path ('abdata\' + $dest)))
	{
		Remove-Item -Path ('abdata\' + $dest)
	}
}
Else
{
	$cab = Get-CABString($dest)
	@"
LoadPlugin(PluginDirectory+"UnityPlugin.dll")
unityParser = OpenUnity3d(path="abdata\
"@ + @(If ($sv) {'sv_'} Else {''}) + 'abdata' + 
		@"
")
unityEditor = Unity3dEditor(parser=unityParser)
unityEditor.PasteFromClipboardAssetBundleManifest(asset=unityParser.Cabinet.Components[1])
unityEditor.RenameCabinet(cabinetIndex=0, name="
"@ + $cab +
		@"
")
unityEditor.SaveUnity3d(path=".\abdata\
"@ + $dest +
		'", keepBackup=False, backupExtension="", background=False, clearMainAsset=True, pathIDsMode=-1, compressionLevel=0, compressionBufferSize=0)' |
		Set-Content Clipboard_Into_ABM.script
	cmd /c ".\SB3UtilityScript.lnk ""%CD%\Clipboard_Into_ABM.script"""
	Remove-Item Clipboard_Into_ABM.script
	If ($sv -and $hc)
	{
		"Untested! Installation with ABMs from both HC and SV!`r`n" +
			'Open ' + $dest + ' with Sb3UGS and "Save As..." ' + $dest.Replace('027', '007')
	}
}

Set-Clipboard $clipboard
