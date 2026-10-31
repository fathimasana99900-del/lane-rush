#!/bin/bash
# Lane Rush: builds a test APK (test ads) and a signed release APK (live ads)
set -e
mkdir -p www assets
cp "$(ls *.html | head -1)" www/index.html
cp "$(ls *icon-only*.png | head -1)" assets/icon-only.png
cp "$(ls *icon-foreground*.png | head -1)" assets/icon-foreground.png
cp "$(ls *icon-background*.png | head -1)" assets/icon-background.png
echo '{"name":"lane-rush","version":"1.0.0","private":true,"dependencies":{"@capacitor/core":"^7.0.0","@capacitor/android":"^7.0.0","@capacitor-community/admob":"^7.0.0"},"devDependencies":{"@capacitor/cli":"^7.0.0"}}' > package.json
echo '{"appId":"com.artrading.lanerush","appName":"Lane Rush","webDir":"www"}' > capacitor.config.json
npm install
npx cap add android
npx @capacitor/assets generate --android
sed -i 's#</application>#<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-5059428712375364~4084700689"/></application>#' android/app/src/main/AndroidManifest.xml
npx cap sync android
(cd android && chmod +x gradlew && ./gradlew assembleDebug)
cp android/app/build/outputs/apk/debug/app-debug.apk LaneRush-test.apk
sed -i 's/const TEST=true/const TEST=false/' www/index.html
npx cap copy android
(cd android && ./gradlew assembleRelease)
echo "$KS_B64" | base64 -d > lane.jks
BT=$(ls -d $ANDROID_HOME/build-tools/* | sort -V | tail -1)
$BT/zipalign -p 4 android/app/build/outputs/apk/release/app-release-unsigned.apk aligned.apk
$BT/apksigner sign --ks lane.jks --ks-pass pass:"$KS_PASS" --key-pass pass:"$KS_PASS" --ks-key-alias stacktower --out LaneRush-release.apk aligned.apk
