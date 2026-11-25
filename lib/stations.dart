import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

Color _hex(String? h, Color fallback) {
  if (h == null || !h.startsWith('#') || h.length != 7) return fallback;
  return Color(int.parse(h.substring(1), radix: 16) | 0xFF000000);
}

class Station {
  final String name, url, group;
  final bool syncLoop; // true = looping file that joins mid-track like a live broadcast
  final Color color;
  Station(this.name, this.url, this.group, this.syncLoop, this.color);
}

class StationGroup {
  final String name;
  final Color color;
  final List<Station> stations;
  StationGroup(this.name, this.color, this.stations);
}

Future<List<StationGroup>> loadGroups() async {
  final data = jsonDecode(await rootBundle.loadString('assets/stations.json'));
  return (data['groups'] as List).map((g) {
    final gc = _hex(g['color'], const Color(0xFFEA2A33));
    final name = g['name'] as String;
    final stations = (g['stations'] as List)
        .map((s) => Station(s['name'], s['url'], name, s['sync_loop'] == true,
            _hex(s['color'], const Color(0xFF585B5F))))
        .toList();
    return StationGroup(name, gc, stations);
  }).toList();
}
