import 'package:escape_puzzle/oss_licenses.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Entry point for the puzzle application
void main() => runApp(const PuzzleApp());

// Main app widget, sets up the MaterialApp with theme and home screen
class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        bottomSheetTheme: const BottomSheetThemeData(
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.blueGrey[300],
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
      home: const PuzzleScreen(),
    );
  }
}

// Represents a puzzle piece with position, size, and color
class PuzzlePiece {
  final int id;
  int row, col;
  final int width, height;
  final Color color;

  PuzzlePiece(this.id, this.row, this.col, this.width, this.height, this.color);
}

// Main screen widget for the puzzle game
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

// License screen widget
class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Source Licenses'),
        backgroundColor: Colors.blueGrey[300],
      ),
      backgroundColor: Colors.blueGrey[300],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600
              ? 600.0
              : constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(
              height: screenHeight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open Source Licenses',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.7,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allDependencies.length,
                        itemBuilder: (context, index) {
                          final package = allDependencies[index];
                          return ExpansionTile(
                            title: Text(
                              package.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              package.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  package.license ?? 'No license provided',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Constants for board and piece styling
const double pieceSpacing = 4.0;
const double borderPadding = 4.0;
const double strokeWidth = 4.0;
const double padding = 40;
const double radius = 8.0;
double cellSize = 0;

final colorA = Color(0xFF418EAE);
final colorB = Color(0xFF1C8866);
final colorC = Color(0xFF0B4B34);
final colorD = Color(0xFFCC995B);
final colorE = Color(0xFF9A5A49);
final colorF = Color(0xFFA88070);

// State for the puzzle screen, managing game logic and UI
class _PuzzleScreenState extends State<PuzzleScreen>
    with SingleTickerProviderStateMixin {
  List<PuzzlePiece>? pieces;
  late List<List<int>> board;
  double dragDx = 0.0, dragDy = 0.0;
  PuzzlePiece? draggingPiece;
  int moveCount = 0;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late ConfettiController _confettiController;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _initPrefsAndPuzzle();
  }

  Future<void> _initPrefsAndPuzzle() async {
    _prefs = await SharedPreferences.getInstance();
    _initPuzzle();
    await _loadProgress();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _initPuzzle() {
    pieces = [
      PuzzlePiece(0, 0, 1, 2, 2, colorA),
      PuzzlePiece(1, 0, 0, 1, 2, colorB),
      PuzzlePiece(2, 0, 3, 1, 2, colorB),
      PuzzlePiece(3, 2, 1, 2, 1, colorC),
      PuzzlePiece(4, 3, 1, 1, 1, colorD),
      PuzzlePiece(5, 3, 2, 1, 1, colorD),
      PuzzlePiece(6, 4, 1, 1, 1, colorE),
      PuzzlePiece(7, 4, 2, 1, 1, colorE),
      PuzzlePiece(8, 2, 0, 1, 2, colorF),
      PuzzlePiece(9, 2, 3, 1, 2, colorF),
    ];

    board = List.generate(5, (_) => List.filled(4, -1));
    moveCount = 0;
    _animationController.reset();
    _confettiController.stop();
    _updateBoard();
  }

  Future<void> _saveProgress() async {
    if (_prefs == null || pieces == null) return;
    await _prefs!.setInt('moveCount', moveCount);
    for (var piece in pieces!) {
      await _prefs!.setInt('piece_${piece.id}_row', piece.row);
      await _prefs!.setInt('piece_${piece.id}_col', piece.col);
    }
  }

  Future<void> _loadProgress() async {
    if (_prefs == null || pieces == null) return;
    final savedMoveCount = _prefs!.getInt('moveCount');
    if (savedMoveCount != null) {
      setState(() {
        moveCount = savedMoveCount;
        for (var piece in pieces!) {
          final savedRow = _prefs!.getInt('piece_${piece.id}_row');
          final savedCol = _prefs!.getInt('piece_${piece.id}_col');
          if (savedRow != null && savedCol != null) {
            piece.row = savedRow;
            piece.col = savedCol;
          }
        }
        _updateBoard();
      });
    }
  }

  void _updateBoard() {
    if (pieces == null) return;
    board = List.generate(5, (_) => List.filled(4, -1));
    for (var piece in pieces!) {
      for (var r = 0; r < piece.height; r++) {
        final row = piece.row + r;
        if (row >= 0 && row < 5) {
          for (var c = 0; c < piece.width; c++) {
            board[row][piece.col + c] = piece.id;
          }
        }
      }
    }
  }

  bool _canMove(PuzzlePiece piece, int dr, int dc) {
    final newRow = piece.row + dr;
    final newCol = piece.col + dc;

    if (newRow < 0 || newCol < 0 || newCol + piece.width > 4) return false;
    final isEscape = piece.id == 0 && newRow == 4 && newCol == 1;
    if (newRow + piece.height > 5 && !isEscape) return false;
    final height = newRow + piece.height > 5 ? 5 - newRow : piece.height;

    for (var r = 0; r < piece.height; r++) {
      final row = piece.row + r;
      if (row >= 0 && row < 5) {
        for (var c = 0; c < piece.width; c++) {
          board[row][piece.col + c] = -1;
        }
      }
    }

    for (var r = 0; r < height; r++) {
      for (var c = 0; c < piece.width; c++) {
        if (newRow + r >= 5) continue;
        final targetId = board[newRow + r][newCol + c];
        if (targetId != -1 &&
            pieces!.firstWhere((p) => p.id == targetId).id != piece.id) {
          _updateBoard();
          return false;
        }
      }
    }
    _updateBoard();
    return true;
  }

  void _movePiece(PuzzlePiece piece, int dr, int dc) async {
    if (!_canMove(piece, dr, dc)) return;
    piece.row += dr;
    piece.col += dc;
    moveCount++;
    await _saveProgress();
    _updateBoard();
    setState(() {});

    if (piece.id == 0 && piece.row == 4 && piece.col == 1) {
      _animationController.forward();
      _confettiController.play();
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You solved the puzzle in $moveCount moves!'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDefaultAction: true,
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        setState(() {
          _animationController.reset();
          _confettiController.stop();
          _initPuzzle();
        });
        await _prefs?.clear();
      }
    }
  }

  void _onDragStart(PuzzlePiece piece, DragStartDetails details) {
    setState(() {
      dragDx = 0.0;
      dragDy = 0.0;
      draggingPiece = piece;
    });
  }

  void _onDragUpdate(PuzzlePiece piece, DragUpdateDetails details) {
    if (draggingPiece != piece) return;
    dragDx += details.delta.dx;
    dragDy += details.delta.dy;
    final isHorizontal = dragDx.abs() > dragDy.abs();
    final accum = isHorizontal ? dragDx : dragDy;

    if (accum.abs() > cellSize * 0.5) {
      final delta = accum.sign.toInt();
      _movePiece(piece, isHorizontal ? 0 : delta, isHorizontal ? delta : 0);
      setState(() {
        if (isHorizontal) {
          dragDx = 0.0;
        } else {
          dragDy = 0.0;
        }
      });
    }
  }

  void _onDragEnd(PuzzlePiece piece, DragEndDetails details) {
    setState(() {
      if (draggingPiece == piece) draggingPiece = null;
    });
  }

  void _resetPuzzle() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Reset Puzzle'),
        content: const Text('Are you sure you want to reset the puzzle?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDefaultAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        draggingPiece = null;
        _initPuzzle();
      });
      await _prefs?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || pieces == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      bottomSheet: Container(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: const _AboutCreatorButton(),
      ),
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top,
            right: 10.0,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LicenseScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.help_outline_outlined,
                size: 24.0,
                color: Colors.yellow[500],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: padding,
              vertical: 32.0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardWidth = constraints.maxWidth > 600
                    ? 600.0
                    : constraints.maxWidth;
                cellSize =
                    (boardWidth -
                        (2 * padding) -
                        (2 * strokeWidth) -
                        (2 * borderPadding) -
                        (2 * pieceSpacing)) /
                    3;
                final boardHeight = boardWidth + cellSize + pieceSpacing;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      const SizedBox(height: 10.0),
                      Text(
                        'Moves: $moveCount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Escape the Dusty Blue square',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomPaint(
                        painter: BoardPainter(),
                        child: SizedBox(
                          width: boardWidth,
                          height: boardHeight,
                          child: Stack(
                            children: pieces!.map((piece) {
                              return Positioned(
                                left:
                                    borderPadding +
                                    strokeWidth +
                                    piece.col * (cellSize + pieceSpacing),
                                top:
                                    borderPadding +
                                    strokeWidth +
                                    piece.row * (cellSize + pieceSpacing),
                                child: IgnorePointer(
                                  ignoring:
                                      draggingPiece != null &&
                                      piece != draggingPiece,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (details) =>
                                        _onDragStart(piece, details),
                                    onPanUpdate: (details) =>
                                        _onDragUpdate(piece, details),
                                    onPanEnd: (details) =>
                                        _onDragEnd(piece, details),
                                    child: AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        final heightFactor = piece.id == 0
                                            ? _heightAnimation.value
                                            : 1.0;
                                        final fullHeight =
                                            piece.height * cellSize +
                                            (piece.height - 1) * pieceSpacing;
                                        return Container(
                                          margin: EdgeInsets.all(
                                            pieceSpacing / 2,
                                          ),
                                          width:
                                              piece.width * cellSize +
                                              (piece.width - 1) * pieceSpacing,
                                          height: fullHeight * heightFactor,
                                          decoration: BoxDecoration(
                                            color: piece.color,
                                            border: Border.all(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              width: 3,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              radius,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                spreadRadius: 1,
                                                blurRadius: 4,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 40),
                            backgroundColor: Colors.yellow[500],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _resetPuzzle,
                          child: const Text(
                            'Reset Game',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: [colorA, colorB, colorC, colorD, colorE, colorF],
            ),
          ),
        ],
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height + cellSize));
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path();
    final gapStartX =
        strokeWidth + borderPadding + 3 * (cellSize + pieceSpacing);
    final gapEndX = strokeWidth + borderPadding + cellSize;
    final bottomY = size.height - strokeWidth;

    path
      ..moveTo(strokeWidth + radius, strokeWidth)
      ..lineTo(size.width - strokeWidth - radius, strokeWidth)
      ..arcToPoint(
        Offset(size.width - strokeWidth, strokeWidth + radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(size.width - strokeWidth, bottomY - radius)
      ..arcToPoint(
        Offset(size.width - strokeWidth - radius, bottomY),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(gapStartX, bottomY)
      ..moveTo(gapEndX, bottomY)
      ..lineTo(strokeWidth + radius, bottomY)
      ..arcToPoint(
        Offset(strokeWidth, bottomY - radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(strokeWidth, strokeWidth + radius)
      ..arcToPoint(
        Offset(strokeWidth + radius, strokeWidth),
        radius: Radius.circular(radius),
        clockwise: true,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AboutCreatorButton extends StatelessWidget {
  const _AboutCreatorButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: () =>
            _launchURL('https://latefinal.github.io/about_creator/'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 40),
          backgroundColor: Colors.blue[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          '🥷🏼About Creator',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'MonoLisa',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
