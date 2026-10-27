/// Native builds have neither a web app badge nor a web wake lock.
enum BadgePermission { granted, denied, notAsked, unsupported }

BadgePermission badgePermission() => BadgePermission.unsupported;

Future<BadgePermission> requestBadgePermission() async =>
    BadgePermission.unsupported;

void setAppBadge(int count) {}

void keepScreenOn(bool on) {}
