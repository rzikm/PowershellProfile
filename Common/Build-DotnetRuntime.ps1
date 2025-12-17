function Build-DotnetRuntime {
    [Alias('bdr')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet(
            "Clr", # The full CoreCLR runtime. Equivalent to: clr.native+clr.corelib+clr.tools+clr.nativecorelib+clr.packages+clr.nativeaotlibs+clr.crossarchtools+host.native
            "Clr.NativePrereqs", # Managed tools that support building the native components of the runtime (such as DacTableGen).
            "Clr.ILTools", # The CoreCLR IL tools (ilasm/ildasm).
            "Clr.Runtime", # The CoreCLR .NET runtime. Includes clr.jit, clr.iltools, clr.hosts.
            "Clr.Native", # All CoreCLR native non-test components, including the runtime, jits, and other native tools. Includes clr.hosts, clr.runtime, clr.jit, clr.alljits, clr.paltests, clr.iltools, clr.nativeaotruntime, clr.spmi.
            "Clr.Aot", # Everything needed for Native AOT workloads, including clr.alljits, clr.tools, clr.nativeaotlibs, and clr.nativeaotruntime
            "Clr.NativeAotLibs", # The CoreCLR native AOT CoreLib and other low level class libraries.
            "Clr.NativeAotRuntime", # The stripped-down CoreCLR native AOT runtime.
            "Clr.CrossArchTools", # The cross-targeted CoreCLR tools.
            "Clr.PalTests", # [only runs on demand] The CoreCLR PAL tests.
            "Clr.PalTestList", # [only runs on demand] Generate the list of the CoreCLR PAL tests. When using the command line, use Clr.PalTests instead.
            "Clr.Hosts", # The CoreCLR corerun test host.
            "Clr.Jit", # The JIT for the CoreCLR .NET runtime.
            "Clr.AllJits", # All of the cross-targeting JIT compilers for the CoreCLR .NET runtime.
            "Clr.AllJitsCommunity", # All of the cross-targeting JIT compilers for the CoreCLR .NET runtime, including community targets.
            "Clr.Spmi", # SuperPMI, a tool for CoreCLR JIT testing.
            "Clr.CoreLib", # The managed System.Private.CoreLib library for CoreCLR.
            "Clr.NativeCoreLib", # Run crossgen on System.Private.CoreLib library for CoreCLR.
            "Clr.Tools", # Managed tools that support CoreCLR development and testing.
            "Clr.ToolsTests", # [only runs on demand] Unit tests for the clr.tools subset.
            "Clr.Packages", # The projects that produce NuGet packages for the CoreCLR runtime, crossgen, and IL tools.
            "LinuxDac", # [only runs on demand] The cross-OS Windows->libc-based Linux DAC. Skipped on x86.
            "AlpineDac", # [only runs on demand] The cross-OS Windows->musl-libc-based Linux DAC. Skipped on x86
            "CrossDacPack", # [only runs on demand] Packaging of cross OS DAC. Requires all assets needed to be present at a folder specified by . See 'Microsoft.CrossOsDiag.Private.CoreCLR.proj' for details.
            "Mono", # The Mono runtime and CoreLib. Equivalent to: mono.runtime+mono.corelib+mono.packages+mono.tools+host.native+
            "Mono.Runtime", # The Mono .NET runtime.
            "Mono.EmSDK", # The emsdk provisioning.
            "Mono.AotCross", # The cross-compiler runtime for Mono AOT.
            "Mono.CoreLib", # The managed System.Private.CoreLib library for Mono.
            "Mono.Manifests", # The NuGet packages with manifests defining the mobile and Blazor workloads.
            "Mono.Packages", # The projects that produce NuGet packages for the Mono runtime.
            "Mono.Tools", # Tooling that helps support Mono development and testing.
            "Mono.WasmRuntime", # The Emscripten runtime.
            "Mono.WasiRuntime", # The WASI runtime.
            "Mono.WasmWorkload", # *Helper* subset for building some pre-requisites for wasm workload testing, useful on CI.
            "Mono.MsCorDbi", # The implementation of ICorDebug interface.
            "Mono.Workloads", # [only runs on demand] Builds the installers and the insertion metadata for Blazor workloads.
            "Tools", # Additional runtime tools projects. Equivalent to: tools.illink+tools.cdac
            "Tools.ILLink", # The projects that produce illink and analyzer tools for trimming.
            "Tools.Cdac", # Diagnostic data contract reader and related projects.
            "Tools.ILLinkTests", # [only runs on demand] Unit tests for the tools.illink subset.
            "Tools.CdacTests", # [only runs on demand] Unit tests for the diagnostic data contract reader.
            "Host", # The .NET hosts, packages, hosting libraries, and tests. Equivalent to: host.native+host.tools+host.pkg+host.pretest+host.tests
            "Host.Native", # The .NET hosts.
            "Host.Pkg", # The .NET host packages.
            "Host.Tools", # The .NET hosting libraries.
            "Host.PreTest", # Test assets which are necessary to run the .NET hosting tests.
            "Host.Tests", # The .NET hosting tests.
            "Libs", # The libraries native part, refs and source assemblies, test infra and packages, but NOT the tests (use Libs.Tests to request those explicitly). Equivalent to: libs.native+libs.sfx+libs.oob+libs.pretest
            "Libs.Native", # The native libraries used in the shared framework.
            "Libs.Sfx", # The managed shared framework libraries.
            "Libs.Oob", # The managed out-of-band libraries.
            "Libs.PreTest", # Test assets which are necessary to run tests.
            "Libs.Tests", # [only runs on demand] The test projects. Note that building this doesn't execute tests: you must also pass the '-test' argument.
            "Packs", # Builds the shared framework packs, archives, bundles, installers, and the framework pack tests. Equivalent to: packs.product+packs.installers+packs.tests
            "Packs.Product", # Builds the shared framework packs, archives, bundles, and installers.
            "Packs.Installers", # Builds the shared framework bundles and installers.
            "Packs.Tests", # The framework pack tests.
            "RegenerateDownloadTable", # [only runs on demand] Regenerates the nightly build download table
            "RegenerateThirdPartyNotices", # [only runs on demand] Regenerates the THIRD-PARTY-NOTICES.TXT file based on other repos' TPN files.
            "tasks", # [only runs on demand] Build the repo local task projects.
            "bootstrap", # [only runs on demand] Build the projects needed to build shipping assets in the repo against live assets.
            "AllSubsets" # Includes all available subsets for comprehensive restore/build operations. This includes all regular subsets and on-demand subsets.
        )]
        [Alias('s')]
        [string[]] $Subset = @("Clr", "Libs", "Libs.Tests"),

        # Operating system for which to build
        [Parameter()]
        [ValidateSet("windows", "linux", "osx", "android", "browser", "wasi")]
        [Alias("os")]
        [string] $OperatingSystem,

        # Architecture for which to build
        [Parameter()]
        [ValidateSet("x64", "x86", "arm64", "arm")]
        [Alias("arch")]
        [string] $Architecture,

        # Performs clean build
        [Parameter()]
        [switch] $Clean,

        # Test Native AOT build
        [Parameter()]
        [switch] $TestNativeAot,

        # Build configuration to use for the runtime
        [Parameter()]
        [ValidateSet("Debug", "Checked", "Release")]
        [Alias("rc")]
        [string] $RuntimeConfiguration = "Release",

        [Parameter()]
        [switch] $SanitizeAddresses,

        # Build configuration to use for libraries
        [Parameter()]
        [ValidateSet("Debug", "Release")]
        [Alias("lc")]
        [string] $LibrariesConfiguration = "Debug",

        # Path to the sources root directory
        [Parameter()]
        [string] $RuntimeSourcesRoot = $global:RuntimeSourcesRoot,

        # Disable PGO optimization
        [Parameter()]
        [switch] $NoPgoOptimize
    )

    if ($Clean) {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $RuntimeSourcesRoot/artifacts
    }

    if ($IsWindows) {
        $buildCmd = Join-Path $RuntimeSourcesRoot 'build.cmd'
    }
    else {
        $buildCmd = Join-Path $RuntimeSourcesRoot 'build.sh'
    }

    $params = , '-s' + ($Subset -join '+')
    $params += @(
        '-rc', $RuntimeConfiguration,
        '-lc', $LibrariesConfiguration
    )

    if ($OperatingSystem) {
        $params += @("-os", $OperatingSystem)
    }

    if ($Architecture) {
        $params += @("-arch", $Architecture)
    }

    if ($TestNativeAot) {
        $params += @('/p:TestNativeAot=true')
    }

    if ($SanitizeAddresses) {
        $params += @("-fsanitize", "address")
    }

    if ($NoPgoOptimize) {
        $params += @('/p:NoPgoOptimize=true')
    }

    Write-Host $buildCmd @params
    & $buildCmd @params
}
