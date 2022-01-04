SKIPUNZIP=1

# Extract files
ui_print "- Extracting module files"
unzip -o "$ZIPFILE" module.prop omc-decoder.jar post-fs-data.sh -d $MODPATH >&2

# Functions
run_jar() {
    local dalvikvm file main 
    #Inspired in the osm0sis method
    if dalvikvm -showversion >/dev/null; then
       dalvikvm=dalvikvm
    elif /system/bin/dalvikvm -showversion >/dev/null; then 
       dalvikvm=/system/bin/dalvikvm
    else
       echo "CANT LOAD DALVIKVM " && return
    fi
    file="$1"
    unzip -o "$file" "META-INF/MANIFEST.MF" -p > "/data/main.tmp"
    main=$(cat /data/main.tmp | grep -m1 "^Main-Class:" | cut -f2 -d: | tr -d " " | dos2unix)
    rm -f /data/main.tmp
    if [ -z "$main" ]; then
       echo "Cant get main: $file " && return
    fi
    shift 1
    $dalvikvm -Djava.io.tmpdir=. -Xnodex2oat -Xnoimage-dex2oat -cp "$file" $main "$@" 2>/dev/null \ || $dalvikvm -Djava.io.tmpdir=. -Xnoimage-dex2oat -cp "$file" $main "$@"
}

add_csc_feature() {
  feature=$1
  value=$2
  lineNumber=0
  lineNumber=`sed -n "/<${feature}>.*<\/${feature}>/=" $MODPATH/$omc_path/cscfeature.xml`
  if [ $lineNumber > 0 ] ; then
    echo "- Found feature $feature in line $lineNumber and changing it to ${value} in $omc_path/cscfeature.xml"
    sed -i "${lineNumber} c<${feature}>${value}<\/${feature}>" $MODPATH/$omc_path/cscfeature.xml
  else
    echo "- Adding feature $feature to the feature set in $omc_path/cscfeature.xml"
    sed -i "/<\/FeatureSet>/i \   \ <${feature}>${value}<\/${feature}>" $MODPATH/$omc_path/cscfeature.xml
  fi
}

# Paths
omc_path=`getprop persist.sys.omc_path`
original_files=`find $omc_path -type f -name '*.xml'`
omc_etcpath=`getprop persist.sys.omc_etcpath`

# Your script starts here
ui_print "- copy omc files"
mkdir -p $MODPATH/$omc_path
cp -aR $omc_path/* $MODPATH/$omc_path
ui_print "- Start decodeing..."
for i in $original_files; do
  if `run_jar "$MODPATH/omc-decoder.jar" -i $MODPATH/$i -o $MODPATH/$i` ; then
    ui_print "- Not decoded $i!"
  else
    ui_print "- Successfully decoded $i!"
  fi
done

add_csc_feature CscFeature_RIL_SupportEsim TRUE
add_csc_feature CscFeature_SystemUI_SupportRecentAppProtection TRUE
add_csc_feature CscFeature_SmartManager_ConfigSubFeatures applock
add_csc_feature CscFeature_VoiceCall_ConfigRecording RecordingAllowed
add_csc_feature CscFeature_Setting_SupportRealTimeNetworkSpeed TRUE
add_csc_feature CscFeature_Common_ConfigSvcProviderForUnknownNumber whitepages,whitepages,whitepages
add_csc_feature CscFeature_VoiceCall_ConfigOpStyleForCallerId ECID,ERI
add_csc_feature CscFeature_Message_EnableSaveVMessage TRUE
add_csc_feature CscFeature_Message_EnableBlackList TRUE
add_csc_feature CscFeature_Setting_EnableMenuBlockCallMsg TRUE
add_csc_feature CscFeature_Common_ConfigSamsungCloudVariation TRUE
add_csc_feature CscFeature_Setting_ConfigMobileHotspotProvisionApp FALSE
add_csc_feature CscFeature_Framework_ConfigOpSetupWizard Global
add_csc_feature CscFeature_SetupWizard_ConfigStepSequenceType VanillaStep
add_csc_feature CscFeature_Setting_ConfigOpMenuStructure Global
add_csc_feature CscFeature_SystemUI_ConfigDefQuickSettingItem Wifi,SilentMode,SoundMode,WindowsLink,Bluetooth,NightMode,FocusMode,Intent,ColorInversion,Ebook,Routines,InstantSession,RotationLock,PowerShare,Flashlight,QRScanner,AirplaneMode,PowerSaving,MobileData,WifiCalling,Performance,BlueLightFilter,WifiHotspot,Hotspot,PersonalMode,SecureFolder,Location,Nfc,Aod,AllShareCast,ShareLive,DeviceVisibility,Dnd,Sync,UDS,BikeMode,PowerPlanning,EdgeLighting,FloatingMessage,RedPacket,DormantMode,NetworkBooster,QuickConnect,SmartStay,SmartPause,AirView,AirBrowse,Toolbox,CarMode,UltraPowerSaving,SFinder,ScreenCapture,ScreenRecorder,VoLte,Dolby,BatteryMode,DailyBoard,DesktopMode,SpenRemote,KidsHome,GrxScreenOnTime,GrxScreenRecord,GrxMultiAction,GrxRecovery

sed -i "s~omc\_path~$omc_path~g" $MODPATH/post-fs-data.sh;

# Extract AppLock
unzip -o "$ZIPFILE" "system/*" -d "$MODPATH" >&2;
mkdir -p $MODPATH/$omc_etcpath
cp -aR $omc_etcpath/* $MODPATH/$omc_etcpath
sed -i "s/AppLock\.apk/AppLock\.apk\.bak/g" $MODPATH/$omc_etcpath/enforceskippingpackages.txt;
sed -i "s~omc\_etcpath~$omc_etcpath~g" $MODPATH/post-fs-data.sh;

# Set executable permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644

# Clean up files
rm -rf $MODPATH/omc-decoder.jar
