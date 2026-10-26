# Layouts: <project name>

One `## LAY-<name>` section per shell. Every region is a `- region: <name>` line, and the
plans phase must carry one task per region with the token `LAY-<name>/<region>`.

## LAY-app Mobile app shell {#lay-app}

- region: topbar
- region: content
- region: bottom-nav

Responsive behavior: the bottom navigation becomes a side rail above 1024 px; the topbar
keeps its height. Screens that use it: every screen of the user role.
