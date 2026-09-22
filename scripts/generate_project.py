#!/usr/bin/env python3
"""Generate the dependency-free native Xcode app project with stable object IDs."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent.parent
objects = []

def uid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()

def add(name, value):
    objects.append(f'{uid(name)} = {{ {value} }};')
    return uid(name)

def listing(values):
    return '(' + ', '.join(values) + (',' if values else '') + ')'

sources = []
children = []
for path in sorted((root / 'Sources').rglob('*.swift')):
    relative = str(path.relative_to(root))
    file_id = add(relative, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {json.dumps(relative)}; sourceTree = SOURCE_ROOT;')
    children.append(file_id)
    sources.append(add(relative + ':build', f'isa = PBXBuildFile; fileRef = {file_id};'))

fixture = add('fixture', 'isa = PBXFileReference; lastKnownFileType = text.html; path = "Fixtures/safari-input.html"; sourceTree = SOURCE_ROOT;')
children.append(fixture)
fixture_build = add('fixture:build', f'isa = PBXBuildFile; fileRef = {fixture};')
icon = add('icon', 'isa = PBXFileReference; lastKnownFileType = image.icns; path = "Resources/AppIcon.icns"; sourceTree = SOURCE_ROOT;')
children.append(icon)
icon_build = add('icon:build', f'isa = PBXBuildFile; fileRef = {icon};')
product = add('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = TextInjector.app; sourceTree = BUILT_PRODUCTS_DIR;')
products = add('products', f'isa = PBXGroup; children = ({product},); name = Products; sourceTree = "<group>";')
add('main', f'isa = PBXGroup; children = {listing(children + [products])}; sourceTree = "<group>";')
source_phase = add('sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {listing(sources)}; runOnlyForDeploymentPostprocessing = 0;')
resource_phase = add('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({fixture_build}, {icon_build},); runOnlyForDeploymentPostprocessing = 0;')
framework_phase = add('frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')

for name in ['Debug', 'Release']:
    optimization = '-Onone' if name == 'Debug' else '-O'
    add('project:' + name, f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ SDKROOT = macosx; MACOSX_DEPLOYMENT_TARGET = 13.0; SWIFT_VERSION = 6.0; CLANG_ENABLE_MODULES = YES; SWIFT_OPTIMIZATION_LEVEL = "{optimization}"; }};')
    add('target:' + name, f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ PRODUCT_NAME = TextInjector; PRODUCT_BUNDLE_IDENTIFIER = io.github.gyeyeon385.TextInjector; INFOPLIST_FILE = Resources/Info.plist; CODE_SIGN_IDENTITY = "-"; CODE_SIGN_STYLE = Manual; ENABLE_APP_SANDBOX = NO; ENABLE_HARDENED_RUNTIME = YES; COMBINE_HIDPI_IMAGES = YES; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks"; }};')
for scope in ['project', 'target']:
    add(scope + ':config', f'isa = XCConfigurationList; buildConfigurations = {listing([uid(scope + ":Debug"), uid(scope + ":Release")])}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
add('target', f'isa = PBXNativeTarget; buildConfigurationList = {uid("target:config")}; buildPhases = {listing([source_phase, framework_phase, resource_phase])}; buildRules = (); dependencies = (); name = TextInjector; productName = TextInjector; productReference = {product}; productType = "com.apple.product-type.application";')
add('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; }}; buildConfigurationList = {uid("project:config")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hant"; hasScannedForEncodings = 0; knownRegions = (en, "zh-Hant", Base); mainGroup = {uid("main")}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({uid("target")},);')
project = root / 'TextInjector.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(objects) + f'\n}}; rootObject = {uid("project")}; }}\n')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target")}" BuildableName="TextInjector.app" BlueprintName="TextInjector" ReferencedContainer="container:TextInjector.xcodeproj"/>'
(schemes / 'TextInjector.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries></BuildAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(project)
