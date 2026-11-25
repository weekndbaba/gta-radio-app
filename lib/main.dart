import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_handler.dart';
import 'stations.dart';

const kBg = Color(0xFF1C1F23);
const kBg2 = Color(0xFF2D3034);
const kAccent = Color(0xFFEA2A33);
const kMuted = Color(0xFFC7CACE);

late RadioHandler handler;
late List<StationGroup> groups;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  handler = await AudioService.init(
    builder: () => RadioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.gta_radio.channel.audio',
      androidNotificationChannelName: 'Radio playback',
    ),
  );
  groups = await loadGroups();
  runApp(const RadioApp());
  Permission.notification.request(); // Android 13+: show the player notification
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Retro Radio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kAccent, surface: kBg2),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const MiniPlayer(),
        body: SafeArea(
          child: CustomScrollView(slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Retro Radio',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Choose a station group', style: TextStyle(color: kMuted)),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1),
                itemCount: groups.length,
                itemBuilder: (_, i) => GroupCard(groups[i]),
              ),
            ),
          ]),
        ),
      );
}

class GroupCard extends StatelessWidget {
  final StationGroup g;
  const GroupCard(this.g, {super.key});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => GroupPage(g))),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [g.color, kBg2]),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('${g.stations.length} stations',
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ],
          ),
        ),
      );
}

class GroupPage extends StatefulWidget {
  final StationGroup g;
  const GroupPage(this.g, {super.key});
  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final _pc = PageController(viewportFraction: 0.55);
  double _vol = 1;

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    return Scaffold(
      appBar: AppBar(
          title: Text(g.name), backgroundColor: kBg, surfaceTintColor: kBg),
      bottomNavigationBar: const MiniPlayer(),
      body: Column(children: [
        const SizedBox(height: 16),
        const Text('RADIO STATION',
            style: TextStyle(color: kMuted, letterSpacing: 2, fontSize: 12)),
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: g.stations.length,
            itemBuilder: (_, i) {
              final s = g.stations[i];
              return ValueListenableBuilder<Station?>(
                valueListenable: handler.current,
                builder: (_, cur, __) {
                  final sel = cur?.url == s.url;
                  return GestureDetector(
                    onTap: () => handler.playGroup(g.stations, i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [s.color, kBg2]),
                        border: Border.all(
                            color: sel ? kAccent : Colors.transparent, width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(sel ? Icons.graphic_eq : Icons.radio, size: 56),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(s.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            const Icon(Icons.volume_up, color: kMuted),
            Expanded(
              child: Slider(
                value: _vol,
                activeColor: kAccent,
                onChanged: (v) {
                  setState(() => _vol = v);
                  handler.setVol(v);
                },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<MediaItem?>(
        stream: handler.mediaItem,
        builder: (_, snap) {
          final item = snap.data;
          if (item == null) return const SizedBox.shrink();
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: kBg2, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(item.album ?? '',
                            style: const TextStyle(color: kMuted, fontSize: 12)),
                      ]),
                ),
                IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: handler.skipToPrevious),
                StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  builder: (_, s) {
                    final st = s.data;
                    final busy = st?.processingState == AudioProcessingState.loading ||
                        st?.processingState == AudioProcessingState.buffering;
                    if (busy) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3)),
                      );
                    }
                    final playing = st?.playing ?? false;
                    return IconButton(
                      iconSize: 36,
                      color: kAccent,
                      icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
                      onPressed: playing ? handler.pause : handler.play,
                    );
                  },
                ),
                IconButton(
                    icon: const Icon(Icons.skip_next), onPressed: handler.skipToNext),
              ]),
            ),
          );
        },
      );
}
