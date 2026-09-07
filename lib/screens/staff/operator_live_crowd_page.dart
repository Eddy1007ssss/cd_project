import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/live_crowd_models.dart';
import '../../repositories/live_crowd_repository.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/navigation_scope.dart';
import '../../widgets/navigation/staff_sidebar.dart';
import '../../widgets/tourflow_widgets.dart';
import 'operator_live_crowd_details_page.dart';

class OperatorLiveCrowdPage extends StatefulWidget {
  const OperatorLiveCrowdPage({
    super.key,
  });

  static const routeName = '/live-crowd';

  @override
  State<OperatorLiveCrowdPage> createState() =>
      _OperatorLiveCrowdPageState();
}

class _OperatorLiveCrowdPageState
    extends State<OperatorLiveCrowdPage>
    with WidgetsBindingObserver {
  final LiveCrowdRepository _repository =
  LiveCrowdRepository();

  Timer? _timer;

  List<OperatorLiveCrowdSummary> _attractions =
  const [];

  bool _loading = true;
  bool _refreshing = false;
  bool _foreground = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

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
        silent: _attractions.isNotEmpty,
      );

      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
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
        if (!mounted ||
            !_foreground) {
          return;
        }

        if (ModalRoute.of(context)?.isCurrent !=
            true) {
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
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    if (!silent &&
        _attractions.isEmpty &&
        mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result =
      await _repository
          .fetchOperatorLiveCrowdList();

      if (!mounted) {
        return;
      }

      setState(() {
        _attractions =
            result;

        _error =
        null;

        _loading =
        false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Unable to load live crowd information.';

        _loading =
        false;
      });
    } finally {
      _refreshing =
      false;
    }
  }

  Future<void> _pullRefresh() async {
    await _load(
      silent: true,
    );
  }

  Color _crowdColor(
      String crowdLevel,
      ) {
    switch (crowdLevel.toUpperCase()) {
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

  int _totalCurrentVisitors() {
    return _attractions.fold<int>(
      0,
          (
          total,
          attraction,
          ) {
        return total +
            attraction.currentVisitors;
      },
    );
  }

  Future<void> _handleBack() async {
    if (await Navigator.maybePop(
      context,
    )) {
      return;
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
        navigationScope?.selectedIndex ??
            0;

    return Scaffold(
      backgroundColor:
      TourFlowColors.background,

      drawer:
      OperatorSidebar(
        displayName:
        'Alex Thompson',

        email:
        'alex.thompson@tourflow.com',

        selectedIndex:
        selectedIndex,

        onItemSelected:
        navigationScope
            ?.onItemSelected ??
                (_) {},

        onLogout:
            () async {
          await signOutAndReturnToSignIn(
            context,
          );
        },
      ),

      appBar:
      AppBar(
        automaticallyImplyLeading:
        false,

        leadingWidth:
        96,

        leading:
        Builder(
          builder:
              (context) {
            return Row(
              children: [
                IconButton(
                  tooltip:
                  'Back',

                  onPressed:
                  _handleBack,

                  icon:
                  const Icon(
                    Icons
                        .arrow_back_rounded,
                  ),
                ),

                IconButton(
                  tooltip:
                  'Open menu',

                  onPressed:
                      () {
                    Scaffold.of(
                      context,
                    ).openDrawer();
                  },

                  icon:
                  const Icon(
                    Icons
                        .menu_rounded,
                  ),
                ),
              ],
            );
          },
        ),

        centerTitle:
        false,

        elevation:
        1,

        shadowColor:
        const Color(
          0x140F172A,
        ),

        backgroundColor:
        TourFlowColors.surface,

        surfaceTintColor:
        Colors.transparent,

        title:
        const Text(
          'Live Crowd',

          style:
          TextStyle(
            color:
            TourFlowColors.heading,

            fontSize:
            18,

            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body:
      RefreshIndicator(
        onRefresh:
        _pullRefresh,

        child:
        _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        children:
        const [
          SizedBox(
            height:
            220,
          ),

          Center(
            child:
            CircularProgressIndicator(),
          ),
        ],
      );
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),

      padding:
      const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        32,
      ),

      children: [
        if (_error != null) ...[
          Container(
            width:
            double.infinity,

            padding:
            const EdgeInsets.all(
              13,
            ),

            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFFFF4E5,
              ),

              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),

            child:
            Row(
              children: [
                const Icon(
                  Icons
                      .warning_amber_rounded,

                  color:
                  Color(
                    0xFFD97706,
                  ),
                ),

                const SizedBox(
                  width:
                  8,
                ),

                Expanded(
                  child:
                  Text(
                    _error!,

                    style:
                    const TextStyle(
                      color:
                      Color(
                        0xFF8A5A00,
                      ),

                      fontSize:
                      11,
                    ),
                  ),
                ),

                TextButton(
                  onPressed:
                  _refreshing
                      ? null
                      : () {
                    _load();
                  },

                  child:
                  const Text(
                    'Retry',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
            14,
          ),
        ],

        Row(
          children: [
            Expanded(
              child:
              _SummaryCard(
                label:
                'Attractions',

                value:
                '${_attractions.length}',

                icon:
                Icons
                    .location_city_outlined,
              ),
            ),

            const SizedBox(
              width:
              10,
            ),

            Expanded(
              child:
              _SummaryCard(
                label:
                'Current Visitors',

                value:
                '${_totalCurrentVisitors()}',

                icon:
                Icons
                    .groups_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
          20,
        ),

        const SectionTitle(
          'Select Attraction',
        ),

        const SizedBox(
          height:
          10,
        ),

        if (_attractions.isEmpty)
          const ModuleCard(
            child:
            Padding(
              padding:
              EdgeInsets.symmetric(
                vertical:
                22,
              ),

              child:
              Column(
                children: [
                  Icon(
                    Icons
                        .location_off_outlined,

                    size:
                    36,

                    color:
                    TourFlowColors.muted,
                  ),

                  SizedBox(
                    height:
                    10,
                  ),

                  Text(
                    'No approved attractions are available.',

                    textAlign:
                    TextAlign.center,

                    style:
                    TextStyle(
                      color:
                      TourFlowColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),

        for (final item
        in _attractions) ...[
          _LiveCrowdAttractionCard(
            item:
            item,

            crowdColor:
            _crowdColor(
              item.crowdLevel,
            ),

            onTap:
                () async {
              await Navigator.pushNamed(
                context,

                OperatorLiveCrowdDetailsPage
                    .routeName,

                arguments:
                item,
              );

              if (!mounted) {
                return;
              }

              await _load(
                silent:
                true,
              );
            },
          ),

          const SizedBox(
            height:
            12,
          ),
        ],

        const SizedBox(
          height:
          8,
        ),

        const Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              Icons
                  .swipe_down_alt_rounded,

              size:
              15,

              color:
              TourFlowColors.muted,
            ),

            SizedBox(
              width:
              5,
            ),

            Text(
              'Pull down to refresh',

              style:
              TextStyle(
                color:
                TourFlowColors.muted,

                fontSize:
                10,
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
          5,
        ),

        const Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              Icons
                  .sync_rounded,

              size:
              14,

              color:
              TourFlowColors.muted,
            ),

            SizedBox(
              width:
              5,
            ),

            Text(
              'Live crowd updates automatically every 5 seconds.',

              style:
              TextStyle(
                color:
                TourFlowColors.muted,

                fontSize:
                10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard
    extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return ModuleCard(
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            icon,

            color:
            TourFlowColors.primaryText,

            size:
            22,
          ),

          const SizedBox(
            height:
            10,
          ),

          Text(
            value,

            style:
            const TextStyle(
              color:
              TourFlowColors.heading,

              fontSize:
              22,

              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
            3,
          ),

          Text(
            label,

            style:
            const TextStyle(
              color:
              TourFlowColors.muted,

              fontSize:
              10,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCrowdAttractionCard
    extends StatelessWidget {
  const _LiveCrowdAttractionCard({
    required this.item,
    required this.crowdColor,
    required this.onTap,
  });

  final OperatorLiveCrowdSummary item;
  final Color crowdColor;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    final occupancy =
    item.occupancyPercent.clamp(
      0,
      100,
    );

    return ModuleCard(
      padding:
      EdgeInsets.zero,

      child:
      InkWell(
        onTap:
        onTap,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        child:
        Padding(
          padding:
          const EdgeInsets.all(
            16,
          ),

          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,

            children: [
              Row(
                children: [
                  Container(
                    width:
                    50,

                    height:
                    50,

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFFFF4E3,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        13,
                      ),
                    ),

                    child:
                    const Icon(
                      Icons
                          .location_on_outlined,

                      color:
                      TourFlowColors
                          .primaryText,
                    ),
                  ),

                  const SizedBox(
                    width:
                    12,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        Text(
                          item.attractionName,

                          style:
                          const TextStyle(
                            color:
                            TourFlowColors
                                .heading,

                            fontSize:
                            14,

                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height:
                          5,
                        ),

                        Text(
                          '${item.currentVisitors} / ${item.maximumCapacity} visitors',

                          style:
                          const TextStyle(
                            color:
                            TourFlowColors
                                .body,

                            fontSize:
                            11,

                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,

                    color:
                    TourFlowColors.muted,
                  ),
                ],
              ),

              const SizedBox(
                height:
                14,
              ),

              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal:
                      9,

                      vertical:
                      5,
                    ),

                    decoration:
                    BoxDecoration(
                      color:
                      crowdColor.withValues(
                        alpha:
                        0.10,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),

                    child:
                    Text(
                      item.crowdLevel,

                      style:
                      TextStyle(
                        color:
                        crowdColor,

                        fontSize:
                        10,

                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${item.occupancyPercent}% occupancy',

                    style:
                    const TextStyle(
                      color:
                      TourFlowColors.muted,

                      fontSize:
                      10,

                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                9,
              ),

              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),

                child:
                LinearProgressIndicator(
                  value:
                  occupancy /
                      100,

                  minHeight:
                  6,

                  backgroundColor:
                  const Color(
                    0xFFF2F4F7,
                  ),

                  color:
                  crowdColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}