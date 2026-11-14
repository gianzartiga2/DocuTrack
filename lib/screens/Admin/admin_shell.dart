import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/docutrack_service.dart';
import '../../ui.dart';

import 'admin_documents_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_students_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.profile,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final StudentProfile profile;
  final bool isDarkMode;
  final Future<void> Function(bool enabled) onDarkModeChanged;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final pages = [
      _AdminOverview(onSelect: (index) => setState(() => _index = index)),
      const AdminStudentsScreen(),
      const AdminDocumentsScreen(),
      const AdminRequestsScreen(),
      AdminProfileScreen(
        profile: widget.profile,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              NavigationRail(
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.paleBlue,
                selectedIconTheme: IconThemeData(color: AppColors.primary),
                selectedLabelTextStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                selectedIndex: _index,
                onDestinationSelected: (index) =>
                    setState(() => _index = index),
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: BrandLogo(size: 48, showName: false),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Overview'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Students'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.description_outlined),
                    selectedIcon: Icon(Icons.description),
                    label: Text('Documents'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment),
                    label: Text('Requests'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.manage_accounts_outlined),
                    selectedIcon: Icon(Icons.manage_accounts_rounded),
                    label: Text('Profile'),
                  ),
                ],
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: AnimatedIndexedStack(index: _index, children: pages),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: .8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .24),
                      blurRadius: 22,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (index) =>
                        setState(() => _index = index),
                    backgroundColor: Colors.transparent,
                    indicatorColor: AppColors.paleBlue,
                    height: 70,
                    elevation: 0,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: 'Overview',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people_rounded),
                        label: 'Students',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.description_outlined),
                        selectedIcon: Icon(Icons.description_rounded),
                        label: 'Documents',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.assignment_outlined),
                        selectedIcon: Icon(Icons.assignment_rounded),
                        label: 'Requests',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.manage_accounts_outlined),
                        selectedIcon: Icon(Icons.manage_accounts_rounded),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    children: [
      Row(
        children: [
          const Expanded(
            child: ScreenHeader(
              title: 'Admin Dashboard',
              subtitle: 'Manage students, documents, and requests.',
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => DocuTrackService.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _OverviewBanner(onReviewRequests: () => onSelect(3)),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 3 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 1.75 : 1.42,
            children: const [
              _CountCard(
                title: 'Students',
                icon: Icons.people_outline,
                collection: 'users',
                filterField: 'role',
                filterValue: 'student',
                tint: AppColors.primaryDark,
              ),
              _CountCard(
                title: 'Active Documents',
                icon: Icons.description_outlined,
                collection: 'documentTypes',
                filterField: 'active',
                filterValue: true,
                tint: AppColors.green,
              ),
              _CountCard(
                title: 'All Requests',
                icon: Icons.assignment_outlined,
                collection: 'requests',
                tint: AppColors.primaryDark,
              ),
              _CountCard(
                title: 'Pending',
                icon: Icons.pending_actions_outlined,
                collection: 'requests',
                filterField: 'status',
                filterValue: 'Pending',
                tint: AppColors.orange,
              ),
              _CountCard(
                title: 'Processing',
                icon: Icons.sync_outlined,
                collection: 'requests',
                filterField: 'status',
                filterValue: 'Processing',
                tint: AppColors.primaryDark,
              ),
              _CountCard(
                title: 'Ready for Claim',
                icon: Icons.inventory_2_outlined,
                collection: 'requests',
                filterField: 'status',
                filterValue: 'Ready for Claim',
                tint: AppColors.green,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      const SectionTitle('Request analytics'),
      const SizedBox(height: 10),
      const _AdminCharts(),
      const SizedBox(height: 22),
      const SectionTitle('Quick actions'),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 3 : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 4.4 : 2.5,
            children: [
              _AdminAction(
                title: 'Manage Students',
                subtitle: 'Create and update accounts',
                icon: Icons.people,
                onTap: () => onSelect(1),
              ),
              _AdminAction(
                title: 'Manage Documents',
                subtitle: 'Update the document catalog',
                icon: Icons.description,
                onTap: () => onSelect(2),
              ),
              _AdminAction(
                title: 'Review Requests',
                subtitle: 'Move requests through each step',
                icon: Icons.assignment,
                onTap: () => onSelect(3),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _AdminCharts extends StatelessWidget {
  const _AdminCharts();

  static const _statuses = [
    'Pending',
    'Processing',
    'Ready for Claim',
    'Completed',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: DocuTrackService.instance.watchRequests(
          admin: true,
          uid: '',
          limit: 500,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ChartPanel(
              child: Text(
                'Unable to load request analytics: ${snapshot.error}',
                style: TextStyle(color: AppColors.red, fontSize: 12),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const _ChartPanel(
              child: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final requests = snapshot.data!.docs
              .map(DocumentRequest.fromSnapshot)
              .toList();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dailyCounts = List<int>.generate(7, (index) {
            final day = today.subtract(Duration(days: 6 - index));
            return requests.where((request) {
              final createdAt = request.createdAt;
              return createdAt != null &&
                  createdAt.year == day.year &&
                  createdAt.month == day.month &&
                  createdAt.day == day.day;
            }).length;
          });
          final statusCounts = List<int>.generate(
            _statuses.length,
            (index) => requests
                .where((request) => request.status == _statuses[index])
                .length,
          );
          final statusColors = [
            AppColors.orange,
            AppColors.primary,
            AppColors.green,
            const Color(0xFF14A578),
            AppColors.red,
          ];
          final unknownStatuses = requests
              .where((request) => !_statuses.contains(request.status))
              .length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final trend = _ChartPanel(
                child: _RequestsTrendChart(
                  counts: dailyCounts,
                  dates: List<DateTime>.generate(
                    7,
                    (index) => today.subtract(Duration(days: 6 - index)),
                  ),
                ),
              );
              final status = _ChartPanel(
                child: _RequestStatusChart(
                  statuses: _statuses,
                  colors: statusColors,
                  counts: statusCounts,
                  unknownCount: unknownStatuses,
                  total: requests.length,
                ),
              );
              if (constraints.maxWidth >= 650) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: trend),
                    const SizedBox(width: 12),
                    Expanded(child: status),
                  ],
                );
              }
              return Column(
                children: [trend, const SizedBox(height: 12), status],
              );
            },
          );
        },
      );
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border.withValues(alpha: .8)),
      borderRadius: BorderRadius.circular(19),
    ),
    child: child,
  );
}

class _RequestsTrendChart extends StatelessWidget {
  const _RequestsTrendChart({required this.counts, required this.dates});

  final List<int> counts;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final total = counts.fold<int>(
      0,
      (runningTotal, requestCount) => runningTotal + requestCount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requests this week',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$total submitted in the last 7 days',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 134,
          width: double.infinity,
          child: CustomPaint(
            painter: _RequestsTrendPainter(
              counts: counts,
              lineColor: AppColors.primary,
              gridColor: AppColors.border.withValues(alpha: .65),
              textColor: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dates.length,
            (index) => Text(
              const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][dates[index].weekday -
                  1],
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestsTrendPainter extends CustomPainter {
  const _RequestsTrendPainter({
    required this.counts,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<int> counts;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 23.0;
    const right = 6.0;
    const top = 12.0;
    const bottom = 8.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final maxCount = counts.fold<int>(
      1,
      (maximum, requestCount) =>
          requestCount > maximum ? requestCount : maximum,
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: textColor, fontSize: 9);

    for (var level = 0; level < 3; level++) {
      final y = chart.bottom - chart.height * level / 2;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final label = TextPainter(
        text: TextSpan(
          text: (maxCount * level / 2).round().toString(),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final points = List<Offset>.generate(counts.length, (index) {
      final x = counts.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (counts.length - 1);
      final y = chart.bottom - chart.height * counts[index] / maxCount;
      return Offset(x, y);
    });
    if (points.isEmpty) return;

    final area = Path()..moveTo(points.first.dx, chart.bottom);
    area.lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      area.lineTo(point.dx, point.dy);
    }
    area
      ..lineTo(points.last.dx, chart.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          colors: [
            lineColor.withValues(alpha: .25),
            lineColor.withValues(alpha: .01),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(chart),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final pointPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 3.5, pointPaint);
      canvas.drawCircle(point, 1.5, Paint()..color = AppColors.surface);
    }
  }

  @override
  bool shouldRepaint(covariant _RequestsTrendPainter oldDelegate) =>
      counts != oldDelegate.counts ||
      lineColor != oldDelegate.lineColor ||
      gridColor != oldDelegate.gridColor ||
      textColor != oldDelegate.textColor;
}

class _RequestStatusChart extends StatelessWidget {
  const _RequestStatusChart({
    required this.statuses,
    required this.colors,
    required this.counts,
    required this.unknownCount,
    required this.total,
  });

  final List<String> statuses;
  final List<Color> colors;
  final List<int> counts;
  final int unknownCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final allCounts = [...counts, if (unknownCount > 0) unknownCount];
    final allColors = [...colors, if (unknownCount > 0) AppColors.muted];
    final allLabels = [...statuses, if (unknownCount > 0) 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requests by status',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Up to 500 most recent requests shown',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            SizedBox(
              width: 108,
              height: 108,
              child: CustomPaint(
                painter: _StatusDonutPainter(
                  counts: allCounts,
                  colors: allColors,
                  total: total,
                  backgroundColor: AppColors.border.withValues(alpha: .55),
                  centerColor: AppColors.surface,
                  textColor: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                children: List.generate(allLabels.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: allColors[index],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            allLabels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          allCounts[index].toString(),
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusDonutPainter extends CustomPainter {
  const _StatusDonutPainter({
    required this.counts,
    required this.colors,
    required this.total,
    required this.backgroundColor,
    required this.centerColor,
    required this.textColor,
  });

  final List<int> counts;
  final List<Color> colors;
  final int total;
  final Color backgroundColor;
  final Color centerColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bounds = Rect.fromCircle(center: center, radius: size.width / 2);
    const strokeWidth = 13.0;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    if (total == 0) {
      ringPaint.color = backgroundColor;
      canvas.drawArc(
        bounds.deflate(strokeWidth / 2),
        0,
        2 * 3.141592653589793,
        false,
        ringPaint,
      );
    } else {
      var start = -3.141592653589793 / 2;
      for (var index = 0; index < counts.length; index++) {
        if (counts[index] == 0) continue;
        final sweep = 2 * 3.141592653589793 * counts[index] / total;
        ringPaint.color = colors[index];
        canvas.drawArc(
          bounds.deflate(strokeWidth / 2),
          start,
          sweep,
          false,
          ringPaint,
        );
        start += sweep;
      }
    }
    canvas.drawCircle(
      center,
      size.width / 2 - strokeWidth,
      Paint()..color = centerColor,
    );
    final label = TextPainter(
      text: TextSpan(
        text: total.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset(center.dx - label.width / 2, center.dy - label.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) =>
      counts != oldDelegate.counts ||
      colors != oldDelegate.colors ||
      total != oldDelegate.total ||
      backgroundColor != oldDelegate.backgroundColor ||
      centerColor != oldDelegate.centerColor ||
      textColor != oldDelegate.textColor;
}

class _OverviewBanner extends StatelessWidget {
  const _OverviewBanner({required this.onReviewRequests});

  final VoidCallback onReviewRequests;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: .28),
          AppColors.surfaceRaised,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: AppColors.primary.withValues(alpha: .20)),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'ADMIN WORKSPACE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Keep every request moving.',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            letterSpacing: -.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Review submissions and keep students informed at every step.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onReviewRequests,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('Review requests'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ],
    ),
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.title,
    required this.icon,
    required this.collection,
    this.tint = AppColors.primaryDark,
    this.filterField,
    this.filterValue,
  });

  final String title;
  final IconData icon;
  final String collection;
  final String? filterField;
  final Object? filterValue;
  final Color tint;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: filterField == null
        ? DocuTrackService.instance.firestore.collection(collection).snapshots()
        : DocuTrackService.instance.firestore
              .collection(collection)
              .where(filterField!, isEqualTo: filterValue)
              .snapshots(),
    builder: (context, snapshot) {
      final count = snapshot.data?.docs.length;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.border.withValues(alpha: .8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .13),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: tint, size: 19),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.hasError ? 'Error' : count?.toString() ?? '...',
                  style: TextStyle(
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: snapshot.hasError ? AppColors.red : AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: WhiteCard(
      padding: 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted, size: 19),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
