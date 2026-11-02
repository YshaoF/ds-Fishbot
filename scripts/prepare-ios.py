"""Deterministic Xcode project generation and local web asset sync; no credentials."""
from pathlib import Path
import hashlib, json, shutil, plistlib
root=Path(__file__).resolve().parent.parent
import runpy
runpy.run_path(str(root/'scripts/fetch-vendor.py'),run_name='__main__')
app=root/'ios/Fishbot'
public=app/'public'
public.mkdir(parents=True,exist_ok=True)
for file in (root/'dist').rglob('*'):
    if file.is_file():
        target=public/file.relative_to(root/'dist');target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,target)
project=root/'ios/Fishbot.xcodeproj';project.mkdir(parents=True,exist_ok=True)
uid=lambda value:hashlib.sha256(value.encode()).hexdigest()[:24].upper()
q=lambda value:json.dumps(value,ensure_ascii=False)
sources=['FishbotApp.swift','NativeBridge.swift','SecretStore.swift','BundledAssets.swift','CompanionSession.swift','../Shared/CompanionAttributes.swift']
resources=[('public','folder'),('Assets.xcassets','folder.assetcatalog'),('PrivacyInfo.xcprivacy','text.xml')]
objects=[]
def add(name,body):objects.append(f'{uid(name)} = {{ {body} }};')
for name in sources:
    add('file:'+name,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(name)}; sourceTree = "<group>";')
    add('build:'+name,f'isa = PBXBuildFile; fileRef = {uid("file:"+name)};')
for name,kind in resources:
    add('file:'+name,f'isa = PBXFileReference; lastKnownFileType = {q(kind)}; path = {q(name)}; sourceTree = "<group>";')
    add('build:'+name,f'isa = PBXBuildFile; fileRef = {uid("file:"+name)};')
add('file:Info.plist','isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>";')
add('product','isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Fishbot.app; sourceTree = BUILT_PRODUCTS_DIR;')
add('sources','isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(uid('build:'+n) for n in sources)+'); runOnlyForDeploymentPostprocessing = 0;')
add('resources','isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(uid('build:'+n) for n,_ in resources)+'); runOnlyForDeploymentPostprocessing = 0;')
add('frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
add('group:app','isa = PBXGroup; children = ('+','.join(uid('file:'+n) for n in sources+[n for n,_ in resources]+['Info.plist'])+'); path = Fishbot; sourceTree = "<group>";')
add('group:products',f'isa = PBXGroup; children = ({uid("product")},{uid("widget:product")}); name = Products; sourceTree = "<group>";')
add('group:root',f'isa = PBXGroup; children = ({uid("group:app")},{uid("widget:group")},{uid("group:products")}); sourceTree = "<group>";')
add('target',f'isa = PBXNativeTarget; buildConfigurationList = {uid("config:target")}; buildPhases = ({uid("sources")},{uid("frameworks")},{uid("resources")},{uid("widget:embed")}); buildRules = (); dependencies = ({uid("widget:dependency")}); name = Fishbot; productName = Fishbot; productReference = {uid("product")}; productType = "com.apple.product-type.application";')
for scope in ['project','target']:
    for mode in ['Debug','Release']:
        settings={'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'16.4','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','ENABLE_USER_SCRIPT_SANDBOXING':'YES'} if scope=='project' else {'PRODUCT_BUNDLE_IDENTIFIER':'com.fishbot.assistant.ios','PRODUCT_NAME':'$(TARGET_NAME)','INFOPLIST_FILE':'Fishbot/Info.plist','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','TARGETED_DEVICE_FAMILY':'1,2','MARKETING_VERSION':'0.2.0','CURRENT_PROJECT_VERSION':'2','CODE_SIGN_STYLE':'Automatic','SWIFT_EMIT_LOC_STRINGS':'NO','GENERATE_INFOPLIST_FILE':'NO','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]':'Fishbot/Simulator.entitlements','SUPPORTS_MACCATALYST':'NO'}
        if scope=='project':settings.update({'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','SWIFT_COMPILATION_MODE':'singlefile' if mode=='Debug' else 'wholemodule','DEBUG_INFORMATION_FORMAT':'dwarf' if mode=='Debug' else 'dwarf-with-dsym'})
        settings_text=' '.join(q(k)+' = '+q(v)+';' for k,v in settings.items())
        add('config:'+scope+':'+mode,'isa = XCBuildConfiguration; buildSettings = {'+settings_text+'}; name = '+mode+';')
    add('config:'+scope,'isa = XCConfigurationList; buildConfigurations = ('+','.join(uid('config:'+scope+':'+m) for m in ['Debug','Release'])+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
widget_sources=['FishbotWidgets.swift','../Shared/WhaleMark.swift','../Shared/CompanionAttributes.swift']
for name in widget_sources:
    if name not in sources:
        add('file:'+name,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(name)}; sourceTree = "<group>";')
    add('widget:build:'+name,f'isa = PBXBuildFile; fileRef = {uid("file:"+name)};')
add('widget:info','isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>";')
add('widget:group','isa = PBXGroup; children = ('+','.join(uid('file:'+n) for n in widget_sources if n not in sources)+','+uid('widget:info')+'); path = FishbotWidgets; sourceTree = "<group>";')
add('widget:product','isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = FishbotCompanion.appex; sourceTree = BUILT_PRODUCTS_DIR;')
add('widget:sources','isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(uid('widget:build:'+n) for n in widget_sources)+'); runOnlyForDeploymentPostprocessing = 0;')
add('widget:frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
add('widget:embed-file',f'isa = PBXBuildFile; fileRef = {uid("widget:product")}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy,); }};')
add('widget:embed',f'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = ({uid("widget:embed-file")}); name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;')
add('widget:proxy',f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("widget:target")}; remoteInfo = FishbotCompanion;')
add('widget:dependency',f'isa = PBXTargetDependency; target = {uid("widget:target")}; targetProxy = {uid("widget:proxy")};')
for mode in ['Debug','Release']:
    settings={'PRODUCT_BUNDLE_IDENTIFIER':'com.fishbot.assistant.ios.companion','PRODUCT_NAME':'FishbotCompanion','INFOPLIST_FILE':'FishbotWidgets/Info.plist','TARGETED_DEVICE_FAMILY':'1,2','MARKETING_VERSION':'0.2.0','CURRENT_PROJECT_VERSION':'2','CODE_SIGN_STYLE':'Automatic','GENERATE_INFOPLIST_FILE':'NO','APPLICATION_EXTENSION_API_ONLY':'YES','SKIP_INSTALL':'YES','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','SUPPORTS_MACCATALYST':'NO','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'}
    add('widget:config:'+mode,'isa = XCBuildConfiguration; buildSettings = {'+' '.join(q(k)+' = '+q(v)+';' for k,v in settings.items())+'}; name = '+mode+';')
add('widget:config','isa = XCConfigurationList; buildConfigurations = ('+','.join(uid('widget:config:'+m) for m in ['Debug','Release'])+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
add('widget:target',f'isa = PBXNativeTarget; buildConfigurationList = {uid("widget:config")}; buildPhases = ({uid("widget:sources")},{uid("widget:frameworks")}); buildRules = (); dependencies = (); name = FishbotCompanion; productName = FishbotCompanion; productReference = {uid("widget:product")}; productType = "com.apple.product-type.app-extension";')
add('project',f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{ {uid("target")} = {{ CreatedOnToolsVersion = 16.0; }}; {uid("widget:target")} = {{ CreatedOnToolsVersion = 16.0; }}; }}; }}; buildConfigurationList = {uid("config:project")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base,"zh-Hans"); mainGroup = {uid("group:root")}; productRefGroup = {uid("group:products")}; projectDirPath = ""; projectRoot = ""; targets = ({uid("target")},{uid("widget:target")});')
(project/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+'\n}; rootObject = '+uid('project')+'; }\n',encoding='utf-8')
schemes=project/'xcshareddata/xcschemes';schemes.mkdir(parents=True,exist_ok=True)
ref=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target")}" BuildableName="Fishbot.app" BlueprintName="Fishbot" ReferencedContainer="container:Fishbot.xcodeproj"/>'
(schemes/'Fishbot.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"/><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''',encoding='utf-8')
for name in ['Info.plist','PrivacyInfo.xcprivacy']:plistlib.loads((app/name).read_bytes())
plistlib.loads((root/'ios/FishbotWidgets/Info.plist').read_bytes())
print('Prepared Fishbot.xcodeproj and bundled assets. Xcode compilation still required.')
