/// Version of the running build. CI passes these with `--dart-define`: the
/// version from `pubspec.yaml`, the workflow run number (also the Android
/// versionCode and the release tag's `-b<n>`) and the commit. Nothing here is
/// edited by hand, so the number follows every build. Local builds say `dev`.
class AppVersion {
  const AppVersion._();

  static const name = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'dev',
  );
  static const build = String.fromEnvironment('APP_BUILD');
  static const commit = String.fromEnvironment('APP_COMMIT');

  /// e.g. `0.2.0 (82)`, or `dev`.
  static String get label => formatAppVersion(name, build);

  /// e.g. `ca51b2e`, empty when unknown.
  static String get shortCommit => shortenCommit(commit);
}

String formatAppVersion(String name, String build) =>
    build.isEmpty ? name : '$name ($build)';

String shortenCommit(String commit) =>
    commit.length > 7 ? commit.substring(0, 7) : commit;
