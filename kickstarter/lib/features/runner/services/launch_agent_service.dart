part of 'services.dart';

/// Service for registering and removing the macOS LaunchAgent (`~/Library/LaunchAgents/kickstarter.plist`).
final class LaunchAgentService {
  const LaunchAgentService({required this.baseDir});

  final String baseDir;

  String get plistPath =>
      '${Platform.environment['HOME']}/Library/LaunchAgents/kickstarter.plist';

  bool get isInstalled => File(plistPath).existsSync();

  /// Installs `kickstarter.plist` and removes legacy `kickstarter-host` / `kickstarter-vm` agents.
  Future<String> install() async {
    final uidRes = await Process.run('/usr/bin/id', ['-u']);
    final uid = (uidRes.stdout as String).trim();
    final domain = 'gui/$uid';

    for (final old in ['kickstarter-host', 'kickstarter-vm', 'kickstarter']) {
      await Process.run('/bin/launchctl', ['bootout', '$domain/$old']);
      final oldPlist = File(
        '${Platform.environment['HOME']}/Library/LaunchAgents/$old.plist',
      );
      if (old != 'kickstarter' && oldPlist.existsSync()) {
        await oldPlist.delete();
      }
    }

    var appBinary =
        '$baseDir/build/macos/Build/Products/Release/kickstarter.app/Contents/MacOS/kickstarter';
    if (!File(appBinary).existsSync()) {
      appBinary = Platform.resolvedExecutable;
    }

    final launchAgentsDir = Directory(
      '${Platform.environment['HOME']}/Library/LaunchAgents',
    );
    if (!launchAgentsDir.existsSync()) {
      await launchAgentsDir.create(recursive: true);
    }

    final plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>Label</key>
\t<string>kickstarter</string>
\t<key>ProgramArguments</key>
\t<array>
\t\t<string>$appBinary</string>
\t</array>
\t<key>WorkingDirectory</key>
\t<string>$baseDir</string>
\t<key>EnvironmentVariables</key>
\t<dict>
\t\t<key>KICKSTARTER_DIR</key>
\t\t<string>$baseDir</string>
\t</dict>
\t<key>RunAtLoad</key>
\t<true/>
\t<key>LimitLoadToSessionType</key>
\t<string>Aqua</string>
</dict>
</plist>
''';
    await File(plistPath).writeAsString(plist);
    await Process.run('/bin/launchctl', ['enable', '$domain/kickstarter']);
    return 'LaunchAgent installed: $plistPath';
  }

  /// Boots out and deletes `kickstarter.plist`.
  Future<String> uninstall() async {
    final uidRes = await Process.run('/usr/bin/id', ['-u']);
    final uid = (uidRes.stdout as String).trim();
    await Process.run('/bin/launchctl', ['bootout', 'gui/$uid/kickstarter']);
    final file = File(plistPath);
    if (file.existsSync()) {
      await file.delete();
    }
    return 'LaunchAgent removed.';
  }
}
