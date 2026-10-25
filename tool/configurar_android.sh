#!/usr/bin/env bash
# Ajusta la carpeta android/ que genera "flutter create" en la nube.
set -euo pipefail

MANIFEST=android/app/src/main/AndroidManifest.xml

# Nombre visible de la app
sed -i "s/android:label=\"omega_access\"/android:label=\"Omega Access\"/" "$MANIFEST"

# Permiso de cámara
if ! grep -q "android.permission.CAMERA" "$MANIFEST"; then
  sed -i "s#<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">#&\n    <uses-permission android:name=\"android.permission.CAMERA\"/>#" "$MANIFEST"
fi

# Permitir abrir el navegador y WhatsApp (Android 11 o superior)
if ! grep -q "android.intent.action.VIEW" "$MANIFEST"; then
  BLOQUE='        <intent>\n            <action android:name="android.intent.action.VIEW"/>\n            <data android:scheme="https"/>\n        </intent>'
  if grep -q "<queries>" "$MANIFEST"; then
    sed -i "s#<queries>#<queries>\n$BLOQUE#" "$MANIFEST"
  else
    sed -i "s#</manifest>#    <queries>\n$BLOQUE\n    </queries>\n</manifest>#" "$MANIFEST"
  fi
fi

# Ícono de Omega Access Control
cp -r branding/android/res/. android/app/src/main/res/

echo "--- AndroidManifest.xml ---"
cat "$MANIFEST"
