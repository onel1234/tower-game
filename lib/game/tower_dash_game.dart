// Define GameState enum
enum GameState {
  initializing, // Initial loading state
  mainMenu,     // Start screen
  playing,      // Game is active
  paused,       // Game is paused by user
  gameOver,     // Game over screen shown
}

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tower_dash_game/game/components/player.dart';
// import 'package:tower_dash_game/game/components/rotating_spike.dart'; // Now handled by manager
// import 'package:tower_dash_game/game/components/moving_platform.dart'; // Now handled by manager
import 'package:tower_dash_game/game/managers/obstacle_manager.dart';
import 'package:flame_audio/flame_audio.dart';

class TowerDashGame extends FlameGame with TapCallbacks {
  late Player player;
  late ObstacleManager obstacleManager;
  late TextComponent _scoreText;
  late TextComponent _highScoreText; // Will be shown on game over or start screen

  int currentScore = 0;
  int highScore = 0;
  static const String highScoreKey = 'towerDashHighScore';

  // Game States
  GameState currentGameState = GameState.initializing;
  bool _rewardedRetryAvailable = true; // True if a retry can be offered for the current game over

  // TEMP: Placeholder for actual assets.
  // User needs to create these files in assets/images/
  // e.g., 1x1 white pngs
  final String placeholderIdle = 'placeholder_player_idle.png';
  final String placeholderDash = 'placeholder_player_dash.png';

  // List to hold components that should be checked for cleanup
  // For now, this will be manually populated. Later, an ObstacleManager might handle this.
  List<Component> collidableChildren = [];

  // Define a cleanup threshold. For example, components that are
  // one screen height below the bottom of the camera view.
  double get cleanupThreshold => camera.visibleWorldRect.bottom + size.y;


  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initial game state setup
    currentGameState = GameState.initializing;
    pauseEngine(); // Start paused, StartScreen will unpause or start game

    // Camera setup
    // The camera's world is centered on (0,0) by default.
    // The player starts at size.x / 2, size.y * 0.8.
    // The camera will follow the player.
    // It's important that the player's initial position makes sense in this world.
    // If player starts at y=positive_value, and moves towards y=negative_value (up),
    // the camera setup is fine.

    // Add player
    // Player's position is in world coordinates.
    // If world origin (0,0) is top-left, and player moves up (y decreases),
    // then player starts at a positive y and moves towards negative y.
    player = Player(position: Vector2(size.x / 2, size.y * 0.7)); // Start player a bit higher
    add(player);

    // Camera follows the player.
    // The camera's viewport, by default, tries to keep the followed object in the center.
    // `verticalOnly` ensures horizontal position isn't affected.
    // `maxSpeed` on follow can make it smoother if desired.
    camera.follow(player, verticalOnly: true);
    // To make the player appear at the bottom 1/3 of the screen:
    // camera.follow(player, verticalOnly: true, relativeOffset: Anchor(0.5, 0.66));


    // Add a simple background color for visibility
    // This component will also move with the camera if not set to PositionType.viewport
    // For an infinite scroller, a ParallaxComponent is better for backgrounds.
    // For now, a static color is fine.
    // add(RectangleComponent(
    //   size: size, // This will be screen size
    //   paint: Paint()..color = Colors.blueGrey.withOpacity(0.2),
    //   positionType: PositionType.viewport, // Make it stick to the camera view
    //   priority: -1,
    // ));

    await _loadHighScore();

    // Score Text (added to camera viewport to stay fixed)
    _scoreText = TextComponent(
        text: 'Score: 0',
        position: Vector2(10, 10), // Top-left
        textRenderer: TextPaint(style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        priority: 1, // UI layer
    );
    camera.viewport.add(_scoreText);

    // High score text (prepared, to be used in UI overlays)
    _highScoreText = TextComponent(
        text: 'High: $highScore',
        // Positioned by UI system
        textRenderer: TextPaint(style: TextStyle(fontSize: 20, color: Colors.white)),
        priority: 1,
    );
    // We won't add _highScoreText directly to the game or camera here.
    // It will be part of the StartScreen or GameOverScreen.


    // Initialize and add the ObstacleManager. It should only act when game is playing.
    obstacleManager = ObstacleManager();
    // add(obstacleManager); // Add it when game starts, not immediately.

    print("TowerDashGame loaded. Initializing UI.");
    // After essential loading, move to main menu state.
    // The StartScreen overlay is already active from main.dart
    currentGameState = GameState.mainMenu;
     // Ensure overlays are clean before adding StartScreen
    overlays.clear();
    overlays.add('StartScreen');


    // Preload audio assets
    // Errors will be logged by FlameAudio if files are not found.
    await FlameAudio.audioCache.loadAll([
      'background_music.mp3',
      'dash.wav',
      'hit.wav',
      'score_up.wav',
    ]);
    print("Audio assets preloaded (or attempted).");
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt(highScoreKey) ?? 0;
    print("Loaded high score: $highScore");
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(highScoreKey, highScore);
    print("Saved high score: $highScore");
  }


  @override
  void update(double dt) {
    super.update(dt);

    if (!isGameOver) {
      // Score is based on the maximum negative Y position reached by the player.
      // Player's initial Y position is positive (e.g., size.y * 0.7).
      // As player moves "up", their Y coordinate becomes smaller (more negative).
      // A simple way: score = -(player.position.y - initialPlayerY)
      // Let initialPlayerY be effectively 0 for scoring calculation after first move, or base it on a fixed world origin.
      // If player starts at y = 500, and moves to y = 400, score related to 100.
      // If player moves to y = -100, score related to 600.
      // Let's use a simpler model: score is max(-player.y, 0) scaled.
      // This means positive score for upward movement from y=0.
      // Player's Y is in world coordinates. If player starts at positive Y and moves towards negative Y.
      // ( (initial Y position) - (current Y position) )
      // The player's initial Y is game.size.y * 0.7.
      // Score increases as player.position.y decreases (moves up).

      // Score calculation: for every 10 pixels moved up from the starting line, 1 point.
      // The starting line for score calculation can be player.initialPosition.y or a fixed y=0.
      // Let's use player's initial Y as the baseline.
      double distanceMovedUp = (player.initialPosition.y - player.position.y);
      if (distanceMovedUp < 0) distanceMovedUp = 0; // Don't score for moving down from start

      int newScore = (distanceMovedUp / 10).floor();

      if (newScore > currentScore) {
        currentScore = newScore;
        // TODO: Play score up sound effect for milestones
      }
      _scoreText.text = 'Score: $currentScore';
    }

    // Component cleanup logic
    // Iterate over a copy of the list to avoid modification issues during iteration.
    // We'll need to decide which components are subject to cleanup.
    // For now, let's assume children of a specific type or added to a specific list.

    final currentCleanupThreshold = cleanupThreshold;
    children.whereType<PositionComponent>().forEach((component) {
      // Don't remove the player or essential UI elements if they are world components
      if (component is Player) return;
      // Add other types to exclude if necessary e.g. if (component is ScoreDisplay) return;

      // Check if the component is an obstacle type (once created)
      // bool isObstacle = component is RotatingSpike || component is MovingPlatform;
      // if (isObstacle) { ... }

      // If the component's top edge is below the cleanup threshold, remove it.
      // Assumes component.anchor is TopLeft or component.position refers to top-left.
      // If anchor is Center, then use component.position.y - component.size.y / 2
      // For components anchored at center (like our Player currently):
      // double componentTopY = component.position.y - component.size.y / 2;
      // For now, using component.position.y, assuming it's generally indicative
      // and most obstacles will be fully below this.
      // A more robust check considers the component's bounding box.
      // The `PositionComponent.bottom` getter can be useful if available and accurate.
      // Let's use `component.y` (top y-coordinate of the bounding box).

      // The world moves upwards, so player.y becomes more negative.
      // The camera follows. camera.visibleWorldRect.bottom will also become more negative.
      // We want to remove components whose 'y' is *greater* (further down) than the threshold.
      // The `cleanupThreshold` as defined (camera.bottom + screenHeight) will be a positive value if camera is near origin,
      // or less negative if camera has moved far up.
      // We remove components whose `y` position (assuming it's their top) is *greater* than this.
      // Example: Camera top is -1000, bottom is -1000 + screenHeight.
      // Cleanup threshold is (-1000 + screenHeight) + screenHeight.
      // If a component's y is, say, -500 (which is above -1000), it should not be removed.
      // If a component's y is, say, 500 (far below the screen), it should be removed.

      // Let's refine the cleanup threshold logic.
      // Player moves from positive Y towards negative Y (upwards).
      // Camera follows. camera.visibleWorldRect.top is the "highest" visible point (most negative Y).
      // camera.visibleWorldRect.bottom is the "lowest" visible point (least negative Y / most positive Y).
      // We want to remove components that are significantly *below* the visible area.
      // So, if component.position.y (assuming it's the top of the component) is greater than
      // camera.visibleWorldRect.bottom + some_buffer_offset.

      final double removalLineY = camera.visibleWorldRect.bottom + size.y / 2; // Remove if component's top is half screen below viewport

      if (component.position.y > removalLineY) {
          // Make sure not to remove the player or other essential persistent components
          if (component != player && component.parent != null) { // Check parent != null before removing
            // print('Removing off-screen component: $component at y=${component.position.y}, threshold: $removalLineY');
            component.removeFromParent();
          }
      }
    });
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    player.dash();
  }

  bool isGameOver = false;

  // TODO: Game over logic
  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    print("TowerDashGame: Game Over sequence initiated.");

    // Pause the game engine's processing of components.
    // Note: This stops updates but not rendering by default.
    // Individual components might need to check this state.
    pauseEngine();

    // TODO: Show Game Over overlay/screen (next UI step)
    // For now, we can print to console and prepare for restart.
    // overlays.add('GameOverScreen'); // Example for later UI step

    // Stop obstacle generation
    obstacleManager.onRemove(); // Or a specific pause method if preferred

    // Update and save high score
    if (currentScore > highScore) {
      highScore = currentScore;
      _saveHighScore();
      _highScoreText.text = 'High: $highScore'; // Update display if visible
    }
  }

  void restartGame() {
    print("TowerDashGame: Restarting game...");
    isGameOver = false;
    currentScore = 0;
    _scoreText.text = 'Score: 0';

    // Reset player
    player.reset();

    // Remove all existing obstacles (they should be removed by cleanup, but good to be sure)
    // This requires obstacles to be identifiable, e.g. by type or adding to a list.
    // The current cleanup logic in update() handles this over time.
    // A more direct way:
    children.where((c) => c is RotatingSpike || c is MovingPlatform).forEach((c) => c.removeFromParent());

    // Reset and restart obstacle manager
    obstacleManager.reset(); // This should also call onAdd or start its timers again.
                             // Current ObstacleManager.reset() does this.
    if (!contains(obstacleManager)) { // If it was fully removed
        add(obstacleManager);
    }


    // Resume engine
    resumeEngine();

    // TODO: Remove Game Over overlay/screen
    // overlays.remove('GameOverScreen');
    overlays.remove('PauseMenu'); // Ensure pause menu is also gone
    currentGameState = GameState.playing;
    overlays.add('PauseButton'); // Show pause button
    if (!FlameAudio.bgm.isPlaying) { // Resume music if it was paused
      startBackgroundMusic();
    }
  }

  void startGame() {
    if (currentGameState == GameState.playing) return;

    print("TowerDashGame: Starting game...");
    // Reset scores and player state
    currentScore = 0;
    _scoreText.text = 'Score: 0';
    player.reset(); // Resets player's state and position

    // Ensure player is added to the game if not already (e.g. if removed on game over)
    if (!contains(player)) {
      add(player);
    }
    // Ensure obstacle manager is added and reset
    if (!contains(obstacleManager)) {
      add(obstacleManager);
    }
    obstacleManager.reset();


    currentGameState = GameState.playing;
    overlays.remove('StartScreen');
    overlays.remove('GameOverScreen');
    overlays.remove('PauseMenu');
    overlays.add('PauseButton');
    resumeEngine();
    startBackgroundMusic();
  }

  void returnToMainMenu() {
    currentGameState = GameState.mainMenu;
    stopBackgroundMusic();
    // player.removeFromParent(); // Optionally remove player from view
    // obstacleManager.removeFromParent(); // Optionally remove manager

    // Clear all game-specific components if desired, or just pause them
    // For now, just pausing the engine and showing main menu is enough.
    // If game components are removed, ensure they are re-added in startGame().
    // Current restartGame and startGame handle re-adding.

    pauseEngine(); // Pause game logic while in menu
    overlays.clear(); // Remove all overlays
    overlays.add('StartScreen'); // Show only start screen
  }

  void togglePauseState() {
    if (currentGameState == GameState.playing) {
      currentGameState = GameState.paused;
      pauseEngine();
      FlameAudio.bgm.pause(); // Pause music
      overlays.remove('PauseButton');
      overlays.add('PauseMenu');
    } else if (currentGameState == GameState.paused) {
      currentGameState = GameState.playing;
      resumeEngine();
      FlameAudio.bgm.resume(); // Resume music
      overlays.remove('PauseMenu');
      overlays.add('PauseButton');
    }
  }

  // Override onTapDown to only work when playing
  @override
  void onTapDown(TapDownEvent event) {
    if (currentGameState == GameState.playing) {
      player.dash();
    }
    super.onTapDown(event); // Important for other tap detectors if any
  }

  // Override update to control behavior based on state
  @override
  void update(double dt) {
    if (currentGameState == GameState.playing) {
      super.update(dt); // Normal update loop for game components

      // Score update logic moved from generic update to here
      double distanceMovedUp = (player.initialPosition.y - player.position.y);
      if (distanceMovedUp < 0) distanceMovedUp = 0;
      int newScore = (distanceMovedUp / 10).floor();
      if (newScore > currentScore) {
        currentScore = newScore;
      }
      _scoreText.text = 'Score: $currentScore';

    } else {
      // If not playing (e.g. paused, menu), don't run the main game update logic.
      // Individual components might still update if they don't check game state,
      // but pauseEngine() should stop most things.
      // We might still want to update certain UI elements or timers.
      // For now, relying on pauseEngine() and component's own logic.
    }

    // Component cleanup logic should always run if game components are present,
    // even if paused, to prevent memory leaks if game is quit from a paused state.
    // However, if pauseEngine() stops component updates, this won't run for them.
    // Let's keep it within the playing block or ensure it's safe.
    // For now, it's part of super.update(dt) which is conditional.
    // A better place for cleanup might be a separate manager or always active.
    // Moving cleanup logic outside the 'playing' state check:
    // This might be problematic if player/camera are not where expected in paused states.
    // Let's refine this: cleanup should occur if game world is active.
    // `pauseEngine` stops `Component.update` calls. So, this is fine inside the `if (currentGameState == GameState.playing)`
  }


  // Modify gameOver to set state and show overlay
  @override
  void gameOver() { // Removed bool isGameOver field, using currentGameState
    if (currentGameState == GameState.gameOver) return;

    currentGameState = GameState.gameOver;
    print("TowerDashGame: Game Over sequence initiated.");

    pauseEngine();

    if (currentScore > highScore) {
      highScore = currentScore;
      _saveHighScore();
      _highScoreText.text = 'High: $highScore';
    }
    // Update the game over screen's score displays before showing it
    // This is handled by the GameOverScreen widget itself by accessing game.currentScore etc.

    overlays.remove('PauseButton');
    overlays.add('GameOverScreen');

    // obstacleManager.onRemove(); // This might be too aggressive, it stops timers.
                               // Better to have obstacleManager respect game state.
                               // For now, pauseEngine() should suffice.
                               // If ObstacleManager has its own update loop not respecting pauseEngine,
                               // then it needs to check currentGameState.
                               // ObstacleManager's Timer components respect pauseEngine.
    _rewardedRetryAvailable = true; // Make retry available for the new game over screen
    overlays.notifyListeners(); // Notify GameOverScreen to rebuild if it depends on canOfferRewardedRetry
  }

  bool canOfferRewardedRetry() {
    return _rewardedRetryAvailable;
  }

  void watchRewardedAdForRetry() {
    if (!_rewardedRetryAvailable) return;

    // --- Simulate Ad Logic ---
    // In a real app, you would trigger the ad SDK here.
    // For now, we'll simulate a successful ad view.
    print("Simulating watching a rewarded ad...");
    // Disable the button immediately to prevent multiple clicks
    _rewardedRetryAvailable = false;
    overlays.notifyListeners(); // Update GameOverScreen to hide button

    // Simulate ad delay
    Future.delayed(Duration(seconds: 1), () {
      print("Rewarded ad 'watched' successfully!");
      _grantRetry();
    });
  }

  void _grantRetry() {
    // Essentially, a restart but without resetting score and keeping current progress for a "second chance"
    // This is a simplified retry. A true retry might involve more state preservation or rollback.
    // For this game, a simple restart from current score = 0 is fine as a "retry".
    // If we wanted to continue from the same score, player.reset() would need adjustment.

    print("TowerDashGame: Granting retry (restarting game)...");
    // isGameOver = false; // Done by restartGame
    // currentScore = 0; // Done by restartGame
    // _scoreText.text = 'Score: 0'; // Done by restartGame

    // Player is reset, obstacles cleared, manager reset by restartGame.
    // Crucially, high score is NOT updated from the score that led to this game over.

    restartGame(); // Uses existing restart logic.
    // _rewardedRetryAvailable = false; // Already set in watchRewardedAdForRetry
  }


  // When a completely new game starts (not a retry), ensure retry is available again.
  @override
  void startGame() {
    _rewardedRetryAvailable = true; // Reset for a fresh game session
    // ... (rest of existing startGame method) ...
    if (currentGameState == GameState.playing) return;

    print("TowerDashGame: Starting game...");
    // Reset scores and player state
    currentScore = 0;
    _scoreText.text = 'Score: 0';
    player.reset(); // Resets player's state and position

    // Ensure player is added to the game if not already (e.g. if removed on game over)
    if (!contains(player)) {
      add(player);
    }
    // Ensure obstacle manager is added and reset
    if (!contains(obstacleManager)) {
      add(obstacleManager);
    }
    obstacleManager.reset();


    currentGameState = GameState.playing;
    overlays.remove('StartScreen');
    overlays.remove('GameOverScreen');
    overlays.remove('PauseMenu');
    overlays.add('PauseButton');
    resumeEngine();
    startBackgroundMusic();
  }
}
