#!/usr/bin/env python3
"""Connect only a real, locally generated SOCKS5 SDK package; never invent a URL.
Run with Python -I. Without --apply, validate and print the proposed package only.
Baseline policy: build the fork revision recorded in SOCKS5_BUILD.json together
with its own generated Swift wrapper, never mix master binaries with 5.5.18.
A successful check is not a claim of source/API compatibility: Xcode must build.
"""
import argparse
import json
import os
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('package', type=Path)
parser.add_argument('--apply', action='store_true')
args = parser.parse_args()
package = args.package.resolve(strict=True)
app = Path(__file__).resolve().parents[1]
manifest = (package / 'Package.swift').read_text(encoding='utf-8')
metadata = json.loads((package / 'SOCKS5_BUILD.json').read_text(encoding='utf-8'))
if metadata.get('api') != 1 or not re.fullmatch('[0-9a-f]{40}', metadata.get('revision', '')):
    raise SystemExit('Not a supported fork SDK build marker')
wrapper = (package / 'Sources/linphonesw/LinphoneWrapper.swift').read_text(encoding='utf-8')
if 'func setSocks5Proxy(' not in wrapper:
    raise SystemExit('SDK wrapper lacks the required SOCKS5 API; official 5.5.18 cannot be used')
paths = re.findall(r'path:\s*"(XCFrameworks/[^"\n]+)"', manifest)
if not paths or 'url:' in manifest:
    raise SystemExit('Expected SDK-generated local binary targets, not remote URLs')
for path in paths:
    candidate = (package / path).resolve(strict=True)
    if package not in candidate.parents or candidate.stat().st_size == 0:
        raise SystemExit('Missing or invalid XCFramework target')
relative = os.path.relpath(package, app).replace(os.sep, '/')
if any(c in relative for c in ('"', '\n', '\r')):
    raise SystemExit('Unsupported package path characters')
project = app / 'LinphoneApp.xcodeproj/project.pbxproj'
text = project.read_text(encoding='utf-8')
pattern = re.compile(r'(\t\t[0-9A-F]+ /\* XCRemoteSwiftPackageReference "linphone-sdk-swift-ios" \*/ = \{).*?\n\t\t\};', re.S)
text, count = pattern.subn(lambda m: m.group(1).replace('XCRemoteSwiftPackageReference', 'XCLocalSwiftPackageReference') + '\n\t\t\tisa = XCLocalSwiftPackageReference;\n\t\t\trelativePath = "' + relative + '";\n\t\t};', text)
# Upstream contains an orphan GitLab package object while the project lists
# the GitHub object. Both product references must target the listed local SDK.
text = text.replace('package = C618BF542D75CA03005A00E0', 'package = D7127F822FE995D400631F65')
if count == 0:
    raise SystemExit('No remote SDK references to replace; inspect the already modified project before reconnecting')
# Project-wide conditions propagate to both main app and extensions and both configurations.
text = re.sub(r'(SWIFT_ACTIVE_COMPILATION_CONDITIONS = )([^;]+);',
    lambda m: m.group(1) + '"' + m.group(2).strip('"') + ' LINPHONE_SOCKS5_SDK";', text)
# Release targets often have no explicit conditions. Add to every settings block;
# duplicate settings are avoided by modifying blocks independently.
def conditions(match):
    block = match.group(0)
    if 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' not in block:
        block = block.replace('buildSettings = {', 'buildSettings = {\n\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "$(inherited) LINPHONE_SOCKS5_SDK";', 1)
    return block
text = re.sub(r'buildSettings = \{.*?\n\t\t\t\};', conditions, text, flags=re.S)
print('Validated experimental SDK revision:', metadata['revision'])
print('Local package:', package)
if args.apply:
    project.write_text(text, encoding='utf-8')
    lock = app / 'LinphoneApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
    if lock.exists():
        data = json.loads(lock.read_text(encoding='utf-8'))
        data['pins'] = [p for p in data['pins'] if p['identity'] != 'linphone-sdk-swift-ios']
        lock.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    print('Project now uses the local package. Run Xcode build; this is not a packaged or signed app.')
else:
    print('No project changes made. Pass --apply after reviewing this package.')
