import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bus_tracker_provider.dart';
import '../models/bus_stop.dart';
import '../services/bus_estimator.dart';

class StopsScreen extends StatelessWidget {
  const StopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paradas y Tiempos'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<BusTrackerProvider>(
        builder: (context, tracker, _) {
          final route = tracker.route;
          if (route == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final departure = tracker.activeDepartureTime;

          List<StopEta> etas = [];
          if (departure != null) {
            etas = BusPositionEstimator.computeAllEtas(
              route: route,
              departureTime: departure,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: route.stops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final stop = route.stops[index];
              final eta = etas.isNotEmpty ? etas[index] : null;
              final estimation = tracker.estimation;

              // Determine status
              final isCurrent = estimation != null &&
                  !estimation.hasCompleted &&
                  !estimation.notYetDeparted &&
                  estimation.currentSegmentIndex == index;

              final hasPassed = eta?.hasPassed ?? false;
              final isAhead = !hasPassed && !isCurrent;

              return _buildStopCard(
                context: context,
                stop: stop,
                index: index,
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

  Widget _buildStopCard({
    required BuildContext context,
    required BusStop stop,
    required int index,
    required StopEta? eta,
    required bool isCurrent,
    required bool hasPassed,
    required bool isAhead,
    required double errorMargin,
  }) {
    Color cardColor;
    Color iconColor;
    IconData statusIcon;
    String etaText;

    if (isCurrent) {
      cardColor = const Color(0xFFE65100).withOpacity(0.08);
      iconColor = const Color(0xFFE65100);
      statusIcon = Icons.directions_bus;
      etaText = 'El bus está cerca';
    } else if (hasPassed) {
      cardColor = Colors.grey.shade100;
      iconColor = Colors.grey;
      statusIcon = Icons.check_circle;
      etaText = 'Ya pasó';
    } else {
      cardColor = Colors.white;
      iconColor = const Color(0xFFE65100);
      statusIcon = Icons.schedule;
      if (eta != null && eta.etaMinutes > 0) {
        final mins = eta.etaMinutes.round();
        final margin = errorMargin.round();
        etaText = 'En ~$mins min ± $margin min';
      } else {
        etaText = 'Esperando datos';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: const Color(0xFFE65100), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(_stopIcon(stop.icon), color: iconColor, size: 22),
            ),
            if (isCurrent)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE65100),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bus,
                      color: Colors.white, size: 9),
                ),
              ),
          ],
        ),
        title: Text(
          stop.name,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            color: hasPassed ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          stop.description,
          style: TextStyle(
              fontSize: 12,
              color: hasPassed ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(statusIcon,
                color: isCurrent
                    ? const Color(0xFFE65100)
                    : hasPassed
                        ? Colors.green
                        : Colors.grey,
                size: 18),
            const SizedBox(height: 4),
            Text(
              etaText,
              style: TextStyle(
                fontSize: 11,
                color: isCurrent ? const Color(0xFFE65100) : Colors.grey,
                fontWeight:
                    isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  IconData _stopIcon(String icon) {
    switch (icon) {
      case 'gym':
        return Icons.fitness_center;
      case 'books':
        return Icons.menu_book;
      case 'booth':
        return Icons.local_police;
      case 'food':
        return Icons.restaurant;
      case 'fit':
        return Icons.engineering;
      case 'fadycs':
        return Icons.gavel;
      case 'fadu':
        return Icons.architecture;
      case 'fcat':
        return Icons.biotech;
      default:
        return Icons.place;
    }
  }
}
