#!/usr/bin/env python3
"""Fixture-only checks for SDK wiring and archive verification. No SDK is fabricated for use."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

SCRIPTS = Path(__file__).resolve().parent
class SDKTools(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='socks5-test-fixture-', dir=SCRIPTS)
        self.root = Path(self.temp.name)
    def tearDown(self): self.temp.cleanup()
    def run_script(self, script, *args, success=True):
        result = subprocess.run([sys.executable, '-I', str(script), *map(str,args)], capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result
    def fixture(self):
        app = self.root/'app'; (app/'scripts').mkdir(parents=True)
        shutil.copy2(SCRIPTS/'connect-local-socks5-sdk.py', app/'scripts')
        (app/'LinphoneApp.xcodeproj').mkdir()
        shutil.copy2(SCRIPTS.parent/'LinphoneApp.xcodeproj/project.pbxproj', app/'LinphoneApp.xcodeproj')
        package = self.root/'explicit-test-fixture-not-an-sdk'
        (package/'XCFrameworks').mkdir(parents=True)
        (package/'Sources/linphonesw').mkdir(parents=True)
        (package/'Package.swift').write_text('.binaryTarget(name: "test", path: "XCFrameworks/test.zip")')
        (package/'XCFrameworks/test.zip').write_bytes(b'fixture, not a framework')
        (package/'Sources/linphonesw/LinphoneWrapper.swift').write_text('func setSocks5Proxy(host: String) {}')
        (package/'SOCKS5_BUILD.json').write_text(json.dumps({'api':1,'revision':'1'*40}))
        return app, package
    def test_validation_does_not_modify_project(self):
        app, package = self.fixture(); project=app/'LinphoneApp.xcodeproj/project.pbxproj'; old=project.read_bytes()
        self.run_script(app/'scripts/connect-local-socks5-sdk.py', package)
        self.assertEqual(project.read_bytes(), old)
    def test_apply_only_fixture_project(self):
        app, package = self.fixture()
        self.run_script(app/'scripts/connect-local-socks5-sdk.py', package, '--apply')
        text=(app/'LinphoneApp.xcodeproj/project.pbxproj').read_text()
        self.assertIn('isa = XCLocalSwiftPackageReference;',text)
        self.assertIn('LINPHONE_SOCKS5_SDK',text)
        self.assertNotIn('package = C618BF542D75CA03005A00E0',text)
        self.assertNotIn('repositoryURL = "https://github.com/BelledonneCommunications/linphone-sdk-swift-ios.git"',text)
    def test_official_wrapper_rejected(self):
        app, package = self.fixture()
        (package/'Sources/linphonesw/LinphoneWrapper.swift').write_text('// official SDK lacks proxy API')
        self.run_script(app/'scripts/connect-local-socks5-sdk.py', package, '--apply', success=False)
    def archive(self, name='linphone-sdk-swift-ios/Package.swift'):
        path=self.root/'download.zip'
        with zipfile.ZipFile(path,'w') as z: z.writestr(name,'fixture')
        dest=self.root/'empty-extract'; dest.mkdir()
        return path, hashlib.sha256(path.read_bytes()).hexdigest(), dest
    def test_checksum_failure_before_extract(self):
        path, digest, dest=self.archive()
        self.run_script(SCRIPTS/'unpack-sdk-asset.py',path,'0'*64,dest,success=False)
        self.assertEqual(list(dest.iterdir()),[])
    def test_traversal_rejected(self):
        path,digest,dest=self.archive('../outside')
        self.run_script(SCRIPTS/'unpack-sdk-asset.py',path,digest,dest,success=False)
        self.assertFalse((self.root/'outside').exists())
    def test_archive_extract(self):
        path,digest,dest=self.archive()
        self.run_script(SCRIPTS/'unpack-sdk-asset.py',path,digest,dest)
        self.assertEqual((dest/'linphone-sdk-swift-ios/Package.swift').read_text(),'fixture')
if __name__ == '__main__': unittest.main()
