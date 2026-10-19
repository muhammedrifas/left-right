import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/engine/game_engine.dart';
import '../../core/models/game_enums.dart';
import '../../core/services/save_manager.dart';
import '../arena/arena_grid.dart';
import '../effects/arcade_background.dart';
import '../hud/center_halo_hud.dart';

enum MenuState { root, playSubmenu, selectLevel, zenTraining, settings, tutorial }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameEngine _engine;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  MenuState _menuState = MenuState.root;
  int _selectedStartTurn = 1;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _ticker = createTicker((elapsed) {
      final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      if (dt > 0 && dt < 0.25) {
        _engine.onTick(dt);
      }
    });
    _ticker.start();
  }

  void _startGame(int startTurn, GameMode mode) {
    _selectedStartTurn = startTurn;
    _lastElapsed = Duration.zero;
    _changeMenuState(MenuState.root);
    _engine.startGame(startTurn: _selectedStartTurn, mode: mode);
  }

  void _changeMenuState(MenuState newState) {
    setState(() => _menuState = newState);
  }

  void _returnToMain() {
    _engine.resetToIdle();
    _changeMenuState(MenuState.root);
  }

  bool get _canPop {
    if (_engine.status != GameStatus.idle) return false;
    if (_menuState != MenuState.root) return false;
    return true;
  }

  void _handlePopInvoked(bool didPop) {
    if (didPop) return;

    if (_engine.status != GameStatus.idle) {
      _returnToMain(); 
    } else {
      if (_menuState == MenuState.selectLevel || _menuState == MenuState.zenTraining) {
        _changeMenuState(MenuState.playSubmenu);
      } else if (_menuState != MenuState.root) {
        _changeMenuState(MenuState.root);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvoked: _handlePopInvoked,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        body: ListenableBuilder(
          listenable: _engine,
          builder: (context, _) {
            final turn = _engine.currentTurn;
            final mirrorMode = turn?.mirrorMode ?? MirrorMode.none;

            return Stack(
              children: [
                ArcadeBackground(mirrorMode: mirrorMode),
                SafeArea(
                  child: Stack(
                    children: [
                      if (turn != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CenterHaloHud(
                              timeBankListenable: _engine.timeBank,
                              score: _engine.score,
                              blitzStreak: _engine.blitzStreak,
                              mirrorMode: mirrorMode,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ArenaGrid(
                                  turn: turn,
                                  onZoneTouched: _engine.handleZoneTouch,
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (_engine.isTransitioning)
                        _WaveTransitionBanner(message: _engine.transitionMessage),

                      if (_engine.status == GameStatus.playing &&
                          _engine.isWaitingForFirstTouch &&
                          !_engine.isTransitioning)
                        const Positioned(
                          bottom: 40,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: Text(
                                'TAP TO BEGIN WAVE',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (_engine.status != GameStatus.playing)
                        _MenuOverlay(
                          status: _engine.status,
                          currentMenuState: _menuState,
                          currentMode: _engine.currentMode,
                          feedback: _engine.gameOverFeedback,
                          score: _engine.score,
                          highScore: _engine.highScore,
                          lastTurnCount: _engine.turnCount, // <--- We now pass the exact turn the player died on
                          maxUnlockedTurn: _engine.maxUnlockedTurn,
                          onMenuStateChanged: _changeMenuState,
                          onReturnToMain: _returnToMain,
                          onPlayRequested: _startGame,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WaveTransitionBanner extends StatelessWidget {
  final String message;
  const _WaveTransitionBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0055).withValues(alpha: 0.85),
                border: const Border(
                  top: BorderSide(color: Colors.white, width: 2),
                  bottom: BorderSide(color: Colors.white, width: 2),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFFF0055), blurRadius: 20),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// MENU OVERLAY (STATELESS)
// ============================================================================

class _WavePreset {
  final String label;
  final int startTurn;
  const _WavePreset(this.label, this.startTurn);
}

class _MenuOverlay extends StatelessWidget {
  final GameStatus status;
  final MenuState currentMenuState;
  final GameMode currentMode;
  final String feedback;
  final int score;
  final int highScore;
  final int lastTurnCount;
  final int maxUnlockedTurn;
  final ValueChanged<MenuState> onMenuStateChanged;
  final VoidCallback onReturnToMain;
  final void Function(int startTurn, GameMode mode) onPlayRequested;

  static const List<_WavePreset> presets = [
    _WavePreset('1: The Warmup', 1),
    _WavePreset('2: Expansion', 11),
    _WavePreset('3: Full Compass', 21),
    _WavePreset('4: Color Clash', 33),
    _WavePreset('5: The Mirror', 46),
    _WavePreset('6: Shattered L/R', 58),
    _WavePreset('7: Shattered T/B', 68),
    _WavePreset('8: Total Inversion', 78),
  ];

  const _MenuOverlay({
    required this.status,
    required this.currentMenuState,
    required this.currentMode,
    required this.feedback,
    required this.score,
    required this.highScore,
    required this.lastTurnCount,
    required this.maxUnlockedTurn,
    required this.onMenuStateChanged,
    required this.onReturnToMain,
    required this.onPlayRequested,
  });

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://example.com/privacy-policy');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0F14).withValues(alpha: 0.88),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: SingleChildScrollView(
          key: ValueKey<MenuState>(currentMenuState),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentMenuState != MenuState.tutorial) _buildHeader(),
              if (currentMenuState != MenuState.tutorial) const SizedBox(height: 32),
              _buildActiveView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isGameOver = status == GameStatus.gameOver && currentMenuState == MenuState.root;
    
    return Column(
      children: [
        if (!isGameOver) ...[
          Image.asset(
            'assets/images/icon.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          isGameOver ? 'GAME OVER' : 'LEFT — RIGHT',
          style: TextStyle(
            color: isGameOver ? const Color(0xFFFF3366) : Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        if (!isGameOver) ...[
          const SizedBox(height: 6),
          const Text(
            'TUNE YOUR BRAIN',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 4.0,
            ),
          ),
        ],
        if (isGameOver) ...[
          const SizedBox(height: 12),
          Text(
            feedback,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          if (currentMode == GameMode.standard)
            Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
        const SizedBox(height: 16),
        if (currentMenuState == MenuState.root)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
            ),
            child: Text(
              'BEST: $highScore',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveView() {
    switch (currentMenuState) {
      case MenuState.root:
        return _buildRootMenu();
      case MenuState.playSubmenu:
        return _buildPlaySubmenu();
      case MenuState.selectLevel:
        return _buildLevelGrid(GameMode.standard);
      case MenuState.zenTraining:
        return _buildLevelGrid(GameMode.zen);
      case MenuState.settings:
        return _buildSettings();
      case MenuState.tutorial:
        return _buildTutorial();
    }
  }

  Widget _buildRootMenu() {
    return Column(
      children: [
        _MenuButton(
          label: status == GameStatus.gameOver ? 'RETRY' : 'PLAY',
          color: const Color(0xFF00E5FF),
          onTap: () {
            if (status == GameStatus.gameOver) {
              // Calculate the highest valid level/wave the player reached before dying
              int retryLevel = 1;
              for (var preset in presets) {
                if (preset.startTurn <= lastTurnCount) {
                  retryLevel = preset.startTurn;
                }
              }
              onPlayRequested(retryLevel, currentMode); 
            } else {
              onMenuStateChanged(MenuState.playSubmenu);
            }
          },
        ),
        if (status == GameStatus.gameOver) ...[
          const SizedBox(height: 16),
          _MenuButton(
            label: 'MAIN MENU',
            color: Colors.white24,
            onTap: onReturnToMain, 
          ),
        ],
        if (status != GameStatus.gameOver) ...[
          const SizedBox(height: 16),
          _MenuButton(
            label: 'HOW TO PLAY',
            color: Colors.white24,
            onTap: () => onMenuStateChanged(MenuState.tutorial),
          ),
          const SizedBox(height: 16),
          _MenuButton(
            label: 'SETTINGS',
            color: Colors.white24,
            onTap: () => onMenuStateChanged(MenuState.settings),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaySubmenu() {
    return Column(
      children: [
        _MenuButton(
          label: 'START OVERDRIVE (LVL 1)',
          color: const Color(0xFF00E5FF),
          onTap: () => onPlayRequested(1, GameMode.standard),
        ),
        const SizedBox(height: 16),
        _MenuButton(
          label: 'SELECT LEVEL',
          color: Colors.white24,
          onTap: () => onMenuStateChanged(MenuState.selectLevel),
        ),
        const SizedBox(height: 16),
        _MenuButton(
          label: 'ZEN TRAINING',
          color: const Color(0xFFFF00AA),
          onTap: () => onMenuStateChanged(MenuState.zenTraining),
        ),
        const SizedBox(height: 32),
        _BackButton(onTap: () => onMenuStateChanged(MenuState.root)),
      ],
    );
  }

  Widget _buildLevelGrid(GameMode mode) {
    return Column(
      children: [
        Text(
          mode == GameMode.zen ? 'CHOOSE ZEN STAGE' : 'JUMP TO LEVEL',
          style: TextStyle(
            color: mode == GameMode.zen ? const Color(0xFFFF00AA) : Colors.cyanAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: presets.map((preset) {
            final bool isLocked = preset.startTurn > maxUnlockedTurn;
            return GestureDetector(
              onTap: isLocked ? null : () => onPlayRequested(preset.startTurn, mode),
              child: Opacity(
                opacity: isLocked ? 0.3 : 1.0,
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocked ? Colors.white24 : (mode == GameMode.zen ? const Color(0xFFFF00AA) : Colors.cyanAccent),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (isLocked) const Icon(Icons.lock, size: 16, color: Colors.white54),
                      if (!isLocked)
                        Text(
                          'LVL ${(preset.startTurn / 10).ceil()}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        preset.label.split(': ').last,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _BackButton(onTap: () => onMenuStateChanged(MenuState.playSubmenu)),
      ],
    );
  }

  Widget _buildSettings() {
    final bool isSoundOn = SaveManager.instance.soundEnabled;
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Column(
          children: [
            GestureDetector(
              onTap: () async {
                await SaveManager.instance.toggleSound();
                setStateLocal(() {});
              },
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSoundOn ? Icons.volume_up : Icons.volume_off,
                      color: isSoundOn ? Colors.cyanAccent : Colors.white54,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isSoundOn ? 'SOUND: ON' : 'SOUND: OFF',
                      style: TextStyle(
                        color: isSoundOn ? Colors.cyanAccent : Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: 'PRIVACY POLICY',
              color: Colors.white24,
              onTap: _launchPrivacyPolicy,
            ),
            const SizedBox(height: 32),
            _BackButton(onTap: () => onMenuStateChanged(MenuState.root)),
          ],
        );
      }
    );
  }

  Widget _buildTutorial() {
    const TextStyle headerStyle = TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2);
    const TextStyle bodyStyle = TextStyle(color: Colors.white, fontSize: 13, height: 1.5);
    const TextStyle highlightStyle = TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🧠 OVERDRIVE SURVIVAL GUIDE',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFFF0055), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 24),
          
          const Text('1. THE BASICS', style: headerStyle),
          const SizedBox(height: 4),
          const Text(
            'Read the text on the screen and tap the corresponding button. If the text says LEFT, tap the Left button. If it says RIGHT, tap the Right button. If it says TOP, tap the Top button. If it says BOTTOM, tap the Bottom button. If it says CENTER, tap the Center button.',
            style: bodyStyle,
          ),
          const SizedBox(height: 20),

          const Text('2. COLOR INJECTION (WAVE 4+)', style: headerStyle),
          const SizedBox(height: 4),
          RichText(
            text: const TextSpan(
              style: bodyStyle,
              children: [
                TextSpan(text: 'When the prompt is a color word (like '),
                TextSpan(text: '"YELLOW"', style: highlightStyle),
                TextSpan(text: '), you must tap the button that is physically painted that color. There are five colors: RED, BLUE, GREEN, YELLOW, and PURPLE.'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('3. MIRROR TRAPS (WAVE 5+)', style: headerStyle),
          const SizedBox(height: 4),
          const Text('When the text itself physically flips, the arena rules flip with it:', style: bodyStyle),
          const SizedBox(height: 8),
          _buildTutorialBullet('Vertical Mirror (Backwards Text like TᖷƎ⅃)', 'Left and Right are swapped. If the text says "LEFT", you must tap the RIGHT button and vice versa. (Immunity: Top and Bottom buttons work normally).'),
          _buildTutorialBullet('Horizontal Mirror (Upside-Down Text)', 'Top and Bottom are swapped. If the text says "TOP", you must tap the BOTTOM button and vice versa. (Immunity: Left and Right buttons work normally).'),
          _buildTutorialBullet('Full Mirror (Fully Inverted Text)', 'All directions are swapped simultaneously! "LEFT" means Right, "RIGHT" means Left, "TOP" means Bottom, and "BOTTOM" means Top.'),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: bodyStyle,
              children: [
                TextSpan(text: 'Exception: ', style: TextStyle(color: Color(0xFFFF0055), fontWeight: FontWeight.bold)),
                TextSpan(text: 'Color rules are entirely immune to mirrors. If you see a flipped "YELLOW", just tap the physical Yellow button!'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('4. THE TIME BANK', style: headerStyle),
          const SizedBox(height: 4),
          const Text(
            'The timer never stops draining. Correct taps refill your time bank. Lightning-fast taps give you a "Blitz" bonus. Hesitation will short-circuit your brain and end the run.',
            style: bodyStyle,
          ),
          const SizedBox(height: 20),

          const Text('5. ZEN TRAINING', style: headerStyle),
          const SizedBox(height: 4),
          const Text(
            'Need to build muscle memory? Zen Training lets you practice any unlocked level infinitely. The time bank is frozen, the game never ends, and the wave never advances. It is the perfect zero-pressure environment to master the mirror traps.',
            style: bodyStyle,
          ),
          
          const SizedBox(height: 32),
          Center(child: _BackButton(onTap: () => onMenuStateChanged(MenuState.root))),
        ],
      ),
    );
  }

  Widget _buildTutorialBullet(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color == Colors.white24 ? Colors.white.withValues(alpha: 0.05) : color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color == Colors.white24 ? Colors.white30 : Colors.transparent),
          boxShadow: color != Colors.white24
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color == Colors.white24 ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios, size: 14, color: Colors.white54),
          SizedBox(width: 4),
          Text(
            'BACK',
            style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }
}