function Build-DotnetRuntime
{
    [Alias('bdr')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet(
             "Clr", # The CoreCLR runtime, LinuxDac, CoreLib (+ native), tools and packages.
             "Clr.NativePrereqs", # Managed tools that support building the native components of the runtime (such as DacTableGen).
             "Clr.ILTools", # The CoreCLR IL tools.
             "Clr.Runtime", # The CoreCLR .NET runtime.
             "Clr.Native", # All CoreCLR native non-test components, including the runtime, jits, and other native tools.
             "Clr.NativeAotLibs", # The CoreCLR native AOT CoreLib, runtime, and other low level class libraries.
             "Clr.PalTests", #[only runs on demand] The CoreCLR PAL tests.
             "Clr.PalTestList", # [only runs on demand]", #" Generate the list of the CoreCLR PAL tests. When using the command line, use Clr.PalTests instead.
             "Clr.Hosts", # The CoreCLR corerun test host.
             "Clr.Jit", # The JIT for the CoreCLR .NET runtime.
             "Clr.AllJits", # All of the cross-targeting JIT compilers for the CoreCLR .NET runtime.
             "Clr.Spmi", # SuperPMI, a tool for CoreCLR JIT testing.
             "Clr.CoreLib", # The managed System.Private.CoreLib library for CoreCLR.
             "Clr.NativeCoreLib", # Run crossgen on System.Private.CoreLib library for CoreCLR.
             "Clr.Tools", # Managed tools that support CoreCLR development and testing.
             "Clr.Packages", # The projects that produce NuGet packages for the CoreCLR runtime, crossgen, and IL tools.
             "LinuxDac", # The cross-OS Windows->libc-based Linux DAC. Skipped on x86.
             "AlpineDac", # [only runs on demand]", #" The cross-OS Windows->musl-libc-based Linux DAC. Skipped on x86
             "CrossDacPack", # [only runs on demand]", #" Packaging of cross OS DAC. Requires all assets needed to be present at a folder specified by . See 'Microsoft.CrossOsDiag.Private.CoreCLR.proj' for details.
             "Mono", # The Mono runtime and CoreLib.
             "Mono.Runtime", # The Mono .NET runtime.
             "Mono.AotCross", # The cross-compiler runtime for Mono AOT.
             "Mono.CoreLib", # The managed System.Private.CoreLib library for Mono.
             "Mono.Packages", # The projects that produce NuGet packages for the Mono runtime.
             "Mono.WasmRuntime", # The WebAssembly runtime.
             "Mono.MsCorDbi", # The implementation of ICorDebug interface.
             "Mono.Workloads", # [only runs on demand]", #" Builds the installers and the insertion metadata for Blazor workloads.
             "Host", # The .NET hosts, packages, hosting libraries, and tests.
             "Host.Native", # The .NET hosts.
             "Host.Pkg", # The .NET host packages.
             "Host.Tools", # The .NET hosting libraries.
             "Host.Tests", # The .NET hosting tests.
             "Libs", # The libraries native part, refs and source assemblies, test infra and packages, but NOT the tests (use Libs.Tests to request those explicitly)
             "Libs.Native", # The native libraries used in the shared framework.
             "Libs.Ref", # The managed reference libraries.
             "Libs.Src", # The managed implementation libraries.
             "Libs.PreTest", # Test assets which are necessary to run tests.
             "Libs.Packages", # The projects that produce NuGet packages from libraries.
             "Libs.Tests", # [only runs on demand]", #" The test projects. Note that building this doesn't execute tests: you must also pass the '-test' argument.
             "Packs", # Builds the shared framework packs, archives, bundles, installers, and the framework pack tests.
             "Packs.Product", # Builds the shared framework packs, archives, bundles, and installers.
             "Packs.Installers", # Builds the shared framework bundles and installers.
             "Packs.Tests", # The framework pack tests.
             "publish", # [only runs on demand]", #" Generate asset manifests and prepare to publish to BAR.
             "RegenerateDownloadTable" # [only runs on demand]", #" Regenerates the nightly build download table
         )]
        [string[]] $Subset = @("Clr", "Libs", "Libs.Tests"),

        [Parameter()]
        [ValidateSet("Debug", "Checked", "Release")]
        [Alias("rc")]
        [string] $RuntimeConfiguration = "Release",

        [Parameter()]
        [ValidateSet("Debug", "Release")]
        [Alias("lc")]
        [string] $LibrariesConfiguration = "Debug",

        # Path to the sources root directory
        [Parameter()]
        [string] $RuntimeSourcesRoot = $global:RuntimeSourcesRoot
    )

    if ($IsWindows)
    {
        $buildCmd = Join-Path $RuntimeSourcesRoot 'build.cmd'
    }
    elseif ($IsLinux)
    {
        $buildCmd = Join-Path $RuntimeSourcesRoot 'build.sh'
    }

    & ($buildCmd) -s ($Subset -join '+') -rc $RuntimeConfiguration -lc $LibrariesConfiguration
}
