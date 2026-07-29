// The example's own design system: palette, artwork tiles and the four page
// bodies. None of this is part of the package — it exists so the bar has a
// convincing app to sit in, and something worth blurring behind it.

import 'package:flutter/material.dart';

const Color kBackground = Color(0xFF0B0B12);
const Color kText = Color(0xFFF3F3F8);
const Color kMuted = Color(0xFF9A9AB8);
const Color kSurface = Color(0x14FFFFFF);
const Color kBorder = Color(0x1FFFFFFF);

const List<List<Color>> _artGradients = [
  [Color(0xFF6C5CE7), Color(0xFF00C2A8)],
  [Color(0xFFFF4D8D), Color(0xFFFFA14A)],
  [Color(0xFF2E86FF), Color(0xFF9B5CFF)],
  [Color(0xFF00C2A8), Color(0xFF2E86FF)],
  [Color(0xFFFFA14A), Color(0xFFFF4D8D)],
  [Color(0xFF9B5CFF), Color(0xFF00C2A8)],
];

/// Gradient stand-in for cover art, so the example needs no image assets.
class ArtSurface extends StatelessWidget {
  const ArtSurface({
    super.key,
    required this.seed,
    this.radius = 18,
    this.glyph,
    this.glyphSize = 26,
  });

  final int seed;
  final double radius;
  final IconData? glyph;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final colors = _artGradients[seed % _artGradients.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: glyph == null
          ? null
          : Center(
              child: Icon(
                glyph,
                size: glyphSize,
                color: const Color(0x4DFFFFFF),
              ),
            ),
    );
  }
}

/// A fixed-size [ArtSurface].
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.seed,
    required this.width,
    required this.height,
    this.radius = 18,
    this.glyph,
    this.glyphSize = 26,
  });

  final int seed;
  final double width;
  final double height;
  final double radius;
  final IconData? glyph;
  final double glyphSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ArtSurface(
      seed: seed,
      radius: radius,
      glyph: glyph,
      glyphSize: glyphSize,
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kText,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ),
  );
}

/// Soft colour fields behind everything, so the glass has depth to pick up.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B0B12), Color(0xFF15102A), Color(0xFF0B0B12)],
      ),
    ),
    child: Stack(
      children: [
        _Blob(Alignment(-1.1, -0.9), Color(0xFF6C5CE7), 400),
        _Blob(Alignment(1.2, -0.15), Color(0xFF00C2A8), 340),
        _Blob(Alignment(-0.7, 0.95), Color(0xFFFF4D8D), 360),
      ],
    ),
  );
}

class _Blob extends StatelessWidget {
  const _Blob(this.alignment, this.color, this.size);

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
        ),
      ),
    ),
  );
}

/// Scroll padding that keeps content clear of the header and the bar.
EdgeInsets _pagePadding(BuildContext context) {
  final view = MediaQuery.paddingOf(context);
  return EdgeInsets.only(top: view.top + 76, bottom: view.bottom + 120);
}

const List<(String, String)> _albums = [
  ('Neon Skyline', 'Aria Vale'),
  ('Paper Moons', 'Kite Society'),
  ('Slow Rivers', 'Emmet Hale'),
  ('Glass Gardens', 'Noor & Co'),
  ('Velvet Static', 'Juno Park'),
  ('Amber Halls', 'Lantern'),
];

const List<(String, String, String)> _releases = [
  ('Cassette Weather', 'Marlow', '3:42'),
  ('Low Tide Radio', 'Sena Ito', '4:05'),
  ('Dust and Gold', 'The Fernwood', '2:58'),
  ('Blue Hour', 'Ilse Byrne', '5:21'),
];

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pagePadding(context),
      children: [
        const _FeaturedCard(),
        const SectionHeader(title: 'Continue listening', action: 'See all'),
        SizedBox(
          height: 194,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _albums.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final (title, artist) = _albums[index];
              return SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Artwork(
                      seed: index,
                      width: 140,
                      height: 140,
                      glyph: Icons.album_outlined,
                      glyphSize: 30,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SectionHeader(title: 'New releases'),
        for (var index = 0; index < _releases.length; index++)
          _TrackRow(
            seed: index + 2,
            title: _releases[index].$1,
            subtitle: _releases[index].$2,
            trailing: _releases[index].$3,
          ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 168,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7A5CFF), Color(0xFFFF4D8D)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7A5CFF).withValues(alpha: 0.32),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Midnight Drive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '32 tracks · 2 hr 14 min',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF17121F),
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.seed,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.leadingNumber,
  });

  final int seed;
  final String title;
  final String subtitle;
  final String? trailing;
  final int? leadingNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
      child: Row(
        children: [
          if (leadingNumber != null)
            SizedBox(
              width: 26,
              child: Text(
                '$leadingNumber',
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Artwork(
            seed: seed,
            width: 54,
            height: 54,
            radius: 14,
            glyph: Icons.music_note_rounded,
            glyphSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(color: kMuted, fontSize: 12.5),
            ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pagePadding(context),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0x33FF4D8D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF4D8D),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Liked songs',
                      style: TextStyle(
                        color: kText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '128 tracks · updated today',
                      style: TextStyle(color: kMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Recently liked'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _albums.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (context, index) {
            final (title, artist) = _albums[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ArtSurface(
                          seed: index + 1,
                          glyph: Icons.album_outlined,
                          glyphSize: 30,
                        ),
                      ),
                      const Positioned(
                        right: 10,
                        top: 10,
                        child: Icon(
                          Icons.favorite,
                          size: 18,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kMuted, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

const List<(String, String, double)> _books = [
  ('The Glass Atlas', 'Rowan Ellis', 0.62),
  ('Salt and Signal', 'M. Okonkwo', 0.28),
  ('Notes on Fog', 'Ines Brandt', 0.85),
  ('The Quiet Machine', 'Dara Finch', 0.14),
];

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pagePadding(context),
      children: [
        const SectionHeader(title: 'Continue reading'),
        for (var index = 0; index < _books.length; index++)
          _BookRow(
            seed: index + 3,
            title: _books[index].$1,
            author: _books[index].$2,
            progress: _books[index].$3,
          ),
      ],
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.seed,
    required this.title,
    required this.author,
    required this.progress,
  });

  final int seed;
  final String title;
  final String author;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Artwork(
            seed: seed,
            width: 62,
            height: 86,
            radius: 12,
            glyph: Icons.menu_book_rounded,
            glyphSize: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  author,
                  style: const TextStyle(color: kMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: const Color(0x1FFFFFFF),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF6C5CE7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(color: kMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<(String, String, String)> _playlist = [
  ('Static Bloom', 'Wren Adler', '3:18'),
  ('Harbour Lights', 'Sofia Rem', '4:44'),
  ('Long Way Down', 'Otis Fane', '3:02'),
  ('Winter Signal', 'Kite Society', '5:10'),
  ('Cobalt', 'Aria Vale', '2:47'),
  ('Paper Trail', 'Emmet Hale', '3:55'),
  ('Slow Exit', 'Juno Park', '4:12'),
  ('Northbound', 'Ilse Byrne', '3:37'),
];

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pagePadding(context),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Artwork(
                seed: 2,
                width: 118,
                height: 118,
                radius: 20,
                glyph: Icons.queue_music_rounded,
                glyphSize: 34,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Late Night Coding',
                      style: TextStyle(
                        color: kText,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '48 tracks · 3 hr 12 min',
                      style: TextStyle(color: kMuted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        _PillButton(
                          label: 'Play',
                          icon: Icons.play_arrow_rounded,
                          filled: true,
                        ),
                        SizedBox(width: 10),
                        _PillButton(
                          label: 'Shuffle',
                          icon: Icons.shuffle_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Tracks'),
        for (var index = 0; index < _playlist.length; index++)
          _TrackRow(
            seed: index + 4,
            leadingNumber: index + 1,
            title: _playlist[index].$1,
            subtitle: _playlist[index].$2,
            trailing: _playlist[index].$3,
          ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: filled ? Colors.white : kSurface,
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: filled ? const Color(0xFF17121F) : kText),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: filled ? const Color(0xFF17121F) : kText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
