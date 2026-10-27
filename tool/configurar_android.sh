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

# WhatsApp visible para la app (Android 11 o superior)
if ! grep -q 'package android:name="com.whatsapp"' "$MANIFEST"; then
  sed -i 's#<queries>#<queries>\n        <package android:name="com.whatsapp"/>\n        <package android:name="com.whatsapp.w4b"/>#' "$MANIFEST"
fi

# Proveedor de archivos para adjuntar imágenes en WhatsApp
if ! grep -q "OmegaFileProvider" "$MANIFEST"; then
  PROVEEDOR='        <provider\n            android:name="com.omegatelecom.omega_access.OmegaFileProvider"\n            android:authorities="${applicationId}.omegafiles"\n            android:exported="false"\n            android:grantUriPermissions="true">\n            <meta-data\n                android:name="android.support.FILE_PROVIDER_PATHS"\n                android:resource="@xml/omega_rutas"/>\n        </provider>\n    </application>'
  sed -i "s#</application>#$PROVEEDOR#" "$MANIFEST"
fi
mkdir -p android/app/src/main/res/xml
cp tool/android/omega_rutas.xml android/app/src/main/res/xml/omega_rutas.xml

# Actividad principal con el canal hacia WhatsApp
find android/app/src/main -name "MainActivity.*" -delete
DESTINO=android/app/src/main/kotlin/com/omegatelecom/omega_access
mkdir -p "$DESTINO"
cp tool/android/MainActivity.kt "$DESTINO/MainActivity.kt"

# Dependencia de androidx.core para FileProvider
if [ -f android/app/build.gradle ]; then
  printf '\ndependencies {\n    implementation "androidx.core:core:1.13.1"\n}\n' >> android/app/build.gradle
elif [ -f android/app/build.gradle.kts ]; then
  printf '\ndependencies {\n    implementation("androidx.core:core:1.13.1")\n}\n' >> android/app/build.gradle.kts
fi

# Ícono de Omega Access Control
cp -r branding/android/res/. android/app/src/main/res/

echo "--- AndroidManifest.xml ---"
cat "$MANIFEST"
