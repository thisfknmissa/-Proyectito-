import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/bus_tracker_provider.dart';
import '../models/bus_stop.dart';
import '../services/bus_estimator.dart';

class StopsScreen extends StatelessWidget {
  const StopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paradas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'Campus Sur · UAT',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.routeBlue.withOpacity(0.2),
          ),
        ),
      ),
      body: Consumer<BusTrackerProvider>(
        builder: (context, tracker, _) {
          final route = tracker.route;
          if (route == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.routeBlue),
            );
          }

          final departure = tracker.activeDepartureTime;

          List<StopEta> etas = [];
          if (departure != null) {
            etas = BusPositionEstimator.computeAllEtas(
              route: route,
              departureTime: departure,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: route.stops.length,
            itemBuilder: (context, index) {
              final stop = route.stops[index];
              final eta = etas.isNotEmpty ? etas[index] : null;
              final estimation = tracker.estimation;

              final isCurrent = estimation != null &&
                  !estimation.hasCompleted &&
                  !estimation.notYetDeparted &&
                  estimation.currentSegmentIndex == index;

              final hasPassed = eta?.hasPassed ?? false;
              final isAhead = !hasPassed && !isCurrent;

              return _buildStopTile(
                context: context,
                stop: stop,
                index: index,
                totalStops: route.stops.length,
                eta: eta,
                isCurrent: isCurrent,
                hasPassed: hasPassed,
                isAhead: isAhead,
                errorMargin: estimation?.errorMarginMinutes ?? 0,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStopTile({
    required BuildContext context,
    required BusStop stop,
    required int index,
    required int totalStops,
    required StopEta? eta,
    required bool isCurrent,
    required bool hasPassed,
    required bool isAhead,
    required double errorMargin,
  }) {
    final Color lineColor;
    final Color dotColor;
    final Color cardBg;
    final Color iconColor;
    final String etaText;

    if (isCurrent) {
      lineColor = AppColors.routeBlue;
      dotColor = AppColors.routeBlue;
      cardBg = AppColors.routeBlue.withOpacity(0.08);
      iconColor = AppColors.routeBlue;
      etaText = 'El bus está cerca';
    } else if (hasPassed) {
      lineColor = AppColors.passed;
      dotColor = AppColors.passed;
      cardBg = Colors.transparent;
      iconColor = AppColors.textMuted;
      etaText = 'Ya pasó';
    } else {
      lineColor = AppColors.routeBlue.withOpacity(0.4);
      dotColor = AppColors.uatOrange;
      cardBg = AppColors.card;
      iconColor = AppColors.uatOrange;
      if (eta != null && eta.etaMinutes > 0) {
        final mins = eta.etaMinutes.round();
        final margin = errorMargin.round();
        etaText = '~$mins min  ±$margin min';
      } else {
        etaText = 'Esperando datos';
      }
    }

    final isLast = index == totalStops - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline visual ──────────────────────────────────────────────
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Línea superior (excepto primera parada)
                if (index > 0)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: lineColor,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),

                // Punto de parada
                Container(
                  width: isCurrent ? 16 : 12,
                  height: isCurrent ? 16 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isCurrent
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.routeBlue.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),

                // Línea inferior (excepto última parada)
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: lineColor,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Tarjeta de parada ─────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: isCurrent
                    ? Border.all(
                        color: AppColors.routeBlue.withOpacity(0.5),
                        width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  // Icono de la parada
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_stopIcon(stop.icon),
                        color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              stop.name,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: hasPassed
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (stop.isTerminal) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.uatOrange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Terminal',
                                  style: TextStyle(
                                    color: AppColors.uatOrange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stop.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasPassed
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: (stop.id == 'caseta' ? AppColors.uatOrange : AppColors.routeBlue).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stop.id == 'caseta' ? '⏱️ Espera: 5-10 min' : '⏱️ Espera: ~2 min',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: stop.id == 'caseta' ? AppColors.uatOrange : AppColors.routeBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ETA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCurrent
                            ? Icons.directions_bus_filled_rounded
                            : hasPassed
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                        color: isCurrent
                            ? AppColors.routeBlue
                            : hasPassed
                                ? AppColors.success
                                : AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        etaText,
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrent
                              ? AppColors.routeBlue
                              : AppColors.textMuted,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _stopIcon(String icon) {
    switch (icon) {
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'books':
        return Icons.menu_book_rounded;
      case 'booth':
        return Icons.security_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'fit':
        return Icons.engineering_rounded;
      case 'fadycs':
        return Icons.balance_rounded;
      case 'fadu':
        return Icons.architecture_rounded;
      case 'fcat':
        return Icons.show_chart_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}
