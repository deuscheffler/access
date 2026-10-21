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

# Kotlin 1.9 (lo requieren versiones recientes de los complementos)
for f in android/settings.gradle android/settings.gradle.kts; do
  if [ -f "$f" ]; then
    sed -i -E 's/(org\.jetbrains\.kotlin\.android"\)? version )"[0-9.]+"/\1"1.9.24"/' "$f"
  fi
done

# Ícono de Omega Access Control
cp -r branding/android/res/. android/app/src/main/res/

echo "--- AndroidManifest.xml ---"
head -n 12 "$MANIFEST"
echo "--- settings.gradle ---"
grep -h "kotlin" android/settings.gradle* || true
