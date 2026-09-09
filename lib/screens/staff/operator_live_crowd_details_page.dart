import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/live_crowd_models.dart';
import '../../services/crowd_updates.dart';
import '../../repositories/live_crowd_repository.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/navigation/navigation_scope.dart';
import '../../widgets/navigation/staff_sidebar.dart';
import '../../widgets/tourflow_widgets.dart';

class OperatorLiveCrowdDetailsPage extends StatefulWidget {
  const OperatorLiveCrowdDetailsPage({
    super.key,
  });

  static const routeName = '/live-crowd-details';

  @override
  State<OperatorLiveCrowdDetailsPage> createState() =>
      _OperatorLiveCrowdDetailsPageState();
}

class _OperatorLiveCrowdDetailsPageState
    extends State<OperatorLiveCrowdDetailsPage>
    with WidgetsBindingObserver {
  final LiveCrowdRepository _repository =
  LiveCrowdRepository();

  Timer? _timer;
  CrowdUpdates? _updates;

  OperatorLiveCrowdSummary? _summary;
  OperatorLiveCrowdDetails? _details;

  bool _initialized = false;
  bool _loading = true;
  bool _refreshing = false;
  bool _foreground = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    if (arguments is! OperatorLiveCrowdSummary) {
      setState(() {
        _loading = false;
        _error = 'Attraction information is missing.';
      });

      return;
    }

    _summary = arguments;
    _updates = CrowdUpdates(() {
      if (mounted && _foreground) _load(silent: true);
    })..start(attractionId: arguments.attractionId);

    _load();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    _foreground =
        state == AppLifecycleState.resumed;

    if (_foreground) {
      _load(
        silent: _details != null,
      );

      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _updates?.dispose();
    _timer?.cancel();

    WidgetsBinding.instance.removeObserver(
      this,
    );

    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    if (!_foreground) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(
        seconds: 5,
      ),
          (_) {
        if (!mounted || !_foreground) {
          return;
        }

        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        _load(
          silent: true,
        );
      },
    );
  }

  Future<void> _load({
    bool silent = false,
  }) async {
    final summary = _summary;

    if (summary == null || _refreshing) {
      return;
    }

    _refreshing = true;

    if (!silent &&
        _details == null &&
        mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result =
      await _repository.fetchOperatorLiveCrowdDetails(
        summary.attractionId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _details = result;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Unable to load live crowd details.';
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _pullRefresh() async {
    await _load(
      silent: true,
    );
  }

  Future<void> _handleBack() async {
    if (await Navigator.maybePop(
      context,
    )) {
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      TourFlowRoutes.operatorDashboard,
          (route) => false,
    );
  }

  Color _crowdColor(
      String level,
      ) {
    switch (level.toUpperCase()) {
      case 'FULL':
        return const Color(
          0xFFB91C1C,
        );

      case 'HIGH':
        return const Color(
          0xFFEA580C,
        );

      case 'MODERATE':
        return const Color(
          0xFFD97706,
        );

      case 'LOW':
        return const Color(
          0xFF15803D,
        );

      default:
        return const Color(
          0xFF667085,
        );
    }
  }

  String _crowdTitle(
      String level,
      ) {
    switch (level.toUpperCase()) {
      case 'FULL':
        return 'Full';

      case 'HIGH':
        return 'High crowd';

      case 'MODERATE':
        return 'Moderate crowd';

      case 'LOW':
        return 'Low crowd';

      default:
        return level;
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final navigationScope =
    TourFlowNavigationScope.maybeOf(
      context,
    );

    final selectedIndex =
        navigationScope?.selectedIndex ?? 0;

    return Scaffold(
      backgroundColor:
      TourFlowColors.background,

      drawer: OperatorSidebar(
        displayName: 'Alex Thompson',
        email: 'alex.thompson@tourflow.com',
        selectedIndex: selectedIndex,
        onItemSelected:
        navigationScope?.onItemSelected ??
                (_) {},
        onLogout: () async {
          await signOutAndReturnToSignIn(
            context,
          );
        },
      ),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,

        leading: Builder(
          builder: (context) {
            return Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: _handleBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),
                ),

                IconButton(
                  tooltip: 'Open menu',
                  onPressed: () {
                    Scaffold.of(context)
                        .openDrawer();
                  },
                  icon: const Icon(
                    Icons.menu_rounded,
                  ),
                ),
              ],
            );
          },
        ),

        centerTitle: false,
        elevation: 1,

        shadowColor: const Color(
          0x140F172A,
        ),

        backgroundColor:
        TourFlowColors.surface,

        surfaceTintColor:
        Colors.transparent,

        title: const Text(
          'Live Crowd Details',
          style: TextStyle(
            color: TourFlowColors.heading,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 220,
          ),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    final details = _details;

    if (details == null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          32,
        ),
        children: [
          ModuleCard(
            child: Text(
              _error ??
                  'Live crowd details are unavailable.',
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        32,
      ),
      children: [
        _buildDetails(
          details,
        ),
      ],
    );
  }

  Widget _buildDetails(
      OperatorLiveCrowdDetails details,
      ) {
    final crowdColor =
    _crowdColor(
      details.crowdLevel,
    );

    final occupancy =
    details.occupancyPercent.clamp(
      0,
      100,
    );

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Container(
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFF4E5,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(
                  0xFFB45309,
                ),
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),
        ],

        ModuleCard(
          color: const Color(
            0xFFFFFAE8,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                    BoxDecoration(
                      color:
                      crowdColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: crowdColor,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Text(
                      details.attractionName,
                      style:
                      const TextStyle(
                        color:
                        TourFlowColors.heading,
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              Text(
                '${_crowdTitle(details.crowdLevel)} · '
                    '${details.currentVisitors} / '
                    '${details.maximumCapacity}',
                style: TextStyle(
                  color: crowdColor,
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                '${details.currentVisitors} visitors are currently inside the attraction.',
                style: const TextStyle(
                  color:
                  TourFlowColors.muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration:
                    BoxDecoration(
                      color: crowdColor,
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      '${details.occupancyPercent}% OCCUPANCY',
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${details.currentVisitors} / '
                        '${details.maximumCapacity}',
                    style:
                    const TextStyle(
                      color:
                      TourFlowColors.heading,
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                child:
                LinearProgressIndicator(
                  value:
                  occupancy / 100,
                  minHeight: 8,
                  backgroundColor:
                  Colors.white,
                  color: crowdColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        Row(
          children: [
            Expanded(
              child: _MiniMetricCard(
                icon:
                Icons.login_rounded,
                value:
                '+${details.visitorsLast1Hour}',
                label:
                'Last 1 Hour',
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: _MiniMetricCard(
                icon:
                Icons.schedule_rounded,
                value:
                '${details.expectedVisitors}',
                label:
                'Expected',
                subLabel:
                'Next 1 Hour',
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: _MiniMetricCard(
                icon:
                Icons.timer_outlined,
                value:
                '${details.avgVisitMinutes}m',
                label:
                'Avg Visit',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        ModuleCard(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color:
                    TourFlowColors.primaryText,
                    size: 20,
                  ),

                  SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      'Visitors by Hour',
                      style: TextStyle(
                        color:
                        TourFlowColors.heading,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 4,
              ),

              const Text(
                'Last 6 Hours',
                style: TextStyle(
                  color:
                  TourFlowColors.muted,
                  fontSize: 10,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _LiveCrowdBarChart(
                values:
                details.hourlyIntervals,
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        ModuleCard(
          color: const Color(
            0xFFF8FAFC,
          ),
          child: const Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color:
                TourFlowColors.muted,
              ),

              SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  'Current crowd is calculated from visitors who have checked in but have not checked out. Expected visitors are based on confirmed bookings for the next hour.',
                  style: TextStyle(
                    color:
                    TourFlowColors.muted,
                    fontSize: 9,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    this.subLabel,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? subLabel;

  @override
  Widget build(
      BuildContext context,
      ) {
    return ModuleCard(
      child: Column(
        children: [
          Icon(
            icon,
            color:
            TourFlowColors.primaryText,
            size: 19,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            value,
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              color:
              TourFlowColors.primaryText,
              fontSize: 19,
              fontWeight:
              FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            label,
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              color:
              TourFlowColors.muted,
              fontSize: 9,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          if (subLabel != null) ...[
            const SizedBox(
              height: 2,
            ),

            Text(
              subLabel!,
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color:
                TourFlowColors.muted,
                fontSize: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveCrowdBarChart extends StatelessWidget {
  const _LiveCrowdBarChart({
    required this.values,
  });

  final List<LiveCrowdInterval> values;

  @override
  Widget build(
      BuildContext context,
      ) {
    if (values.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No crowd data available yet.',
            style: TextStyle(
              color:
              TourFlowColors.muted,
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    final maxValue =
    values.fold<int>(
      0,
          (
          current,
          item,
          ) {
        if (item.visitors > current) {
          return item.visitors;
        }

        return current;
      },
    );

    final safeMax =
    maxValue <= 0
        ? 1
        : maxValue;

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.end,
        children: [
          for (final item in values)
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.end,
                  children: [
                    Text(
                      '${item.visitors}',
                      style:
                      const TextStyle(
                        color:
                        TourFlowColors.body,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Expanded(
                      child: Align(
                        alignment:
                        Alignment.bottomCenter,
                        child:
                        FractionallySizedBox(
                          heightFactor:
                          item.visitors == 0
                              ? 0.04
                              : item.visitors /
                              safeMax,
                          child: Container(
                            width: 30,
                            decoration:
                            const BoxDecoration(
                              color:
                              TourFlowColors.primary,
                              borderRadius:
                              BorderRadius.vertical(
                                top:
                                Radius.circular(
                                  7,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      item.label,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        color:
                        TourFlowColors.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
