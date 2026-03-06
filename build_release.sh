#!/usr/bin/env sh
set -eu

VERSION="${1:-1.0.0}"
ADDON_NAME="${2:-order_objects}"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DIST_DIR="$SCRIPT_DIR/dist"
TMP_ROOT="$DIST_DIR/.build_tmp_${ADDON_NAME}_$$"
STAGING_DIR="$TMP_ROOT/$ADDON_NAME"
ZIP_NAME="$ADDON_NAME-$VERSION-blender4.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

FILES_TO_PACKAGE="__init__.py auto_load.py ui_hello.py README.md LICENSE"

for file in $FILES_TO_PACKAGE; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo "Missing required file: $file" >&2
        exit 1
    fi
done

mkdir -p "$DIST_DIR"

if [ -e "$TMP_ROOT" ]; then
    echo "Temporary build directory already exists: $TMP_ROOT" >&2
    exit 1
fi

mkdir -p "$STAGING_DIR"

for file in $FILES_TO_PACKAGE; do
    cp "$SCRIPT_DIR/$file" "$STAGING_DIR/$file"
done

rm -f "$ZIP_PATH"

if command -v zip >/dev/null 2>&1; then
    (
        cd "$TMP_ROOT"
        zip -r "$ZIP_NAME" "$ADDON_NAME" >/dev/null
    )
    mv "$TMP_ROOT/$ZIP_NAME" "$ZIP_PATH"
else
    python3 - <<PY
import os
import zipfile

dist_dir = r"$DIST_DIR"
addon_name = r"$ADDON_NAME"
zip_path = r"$ZIP_PATH"
staging_dir = r"$STAGING_DIR"

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(staging_dir):
        for file_name in files:
            full_path = os.path.join(root, file_name)
            arcname = os.path.join(addon_name, os.path.relpath(full_path, staging_dir))
            zf.write(full_path, arcname)
PY
fi

# Controlled cleanup without recursive delete.
for file in $FILES_TO_PACKAGE; do
    rm -f "$STAGING_DIR/$file"
done
rmdir "$STAGING_DIR"
rmdir "$TMP_ROOT"

echo "ZIP created: $ZIP_PATH"
echo "Install in Blender: Edit > Preferences > Add-ons > Install..."
