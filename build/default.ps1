properties {
	$pwd = Split-Path $psake.build_script_file	
	$build_directory  = "$pwd\output\condep-execution"
	$configuration = "Release"
	$preString = "-beta"
	$releaseNotes = ""
	$nuget = "$pwd\..\tools\nuget.exe"
}
 
include .\..\tools\psake_ext.ps1

function GetNugetAssemblyVersion($assemblyPath) {
	$versionInfo = Get-Item $assemblyPath | % versioninfo

	return "$($versionInfo.FileMajorPart).$($versionInfo.FileMinorPart).$($versionInfo.FileBuildPart)$preString"
}

task default -depends Build-All, Test-All, Pack-All
task ci -depends Build-All, Pack-All

task Build-All -depends Clean, ResotreNugetPackages, Build, Create-BuildSpec-ConDep-Execution
task Pack-All -depends Pack-ConDep-Dsl

task ResotreNugetPackages {
	Exec { & $nuget restore "$pwd\..\src\condep-execution.sln" }
}

task Build {
	Exec { msbuild "$pwd\..\src\condep-execution.sln" /t:Build /p:Configuration=$configuration /p:OutDir=$build_directory /p:GenerateProjectSpecificOutputFolder=true}
}

task Clean {
	Write-Host "Cleaning Build output"  -ForegroundColor Green
	Remove-Item $build_directory -Force -Recurse -ErrorAction SilentlyContinue
}

task Create-BuildSpec-ConDep-Execution {
	Generate-Nuspec-File `
		-file "$build_directory\condep.execution.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\ConDep.Execution\ConDep.Execution.dll) `
		-id "ConDep.Execution" `
		-title "ConDep.Execution" `
		-licenseUrl "http://www.con-dep.io/license/" `
		-projectUrl "http://www.con-dep.io/" `
		-description "API for executing ConDep. ConDep is a highly extendable Domain Specific Language for Continuous Deployment, Continuous Delivery and Infrastructure as Code on Windows." `
		-iconUrl "https://raw.github.com/condep/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote aws azure" `
		-dependencies @(
			@{ Name="ConDep.Dsl"; Version="[3.0.0]"},
			@{ Name="DotNetZip"; Version="[1.9.6,2)"},
		) `
		-files @(
			@{ Path="ConDep.Dsl\ConDep.Execution.dll"; Target="lib/net40"}, 
			@{ Path="ConDep.Dsl\ConDep.Execution.xml"; Target="lib/net40"}
		)
}

task Pack-ConDep-Execution {
	Exec { & $nuget pack "$build_directory\condep.execution.nuspec" -OutputDirectory "$build_directory" }
}