#!/bin/bash
set -e

echo "Compiling ASCEND iOS Native Application..."
mkdir -p /tmp/ModuleCache /tmp/ascend_app_build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun -sdk iphonesimulator swiftc \
    -module-cache-path /tmp/ModuleCache \
    -target arm64-apple-ios17.0-simulator \
    -parse-as-library \
    -c \
    $(find ASCEND -name "*.swift") \
    -output-file-map <(python3 -c '
import json, glob
files = glob.glob("ASCEND/**/*.swift", recursive=True)
mapping = {f: {"object": f"/tmp/ascend_app_build/{i}.o"} for i, f in enumerate(files)}
mapping[""] = {"swift-dependencies": "/tmp/ascend_app_build/deps.swiftdeps"}
print(json.dumps(mapping))
')

echo "Successfully compiled ASCEND iOS Native Target!"
ls -lh /tmp/ascend_app_build/*.o | head -n 10
