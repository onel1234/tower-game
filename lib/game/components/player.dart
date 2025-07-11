import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart';

enum PlayerState { idle, dashing }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<TowerDashGame>, KeyboardHandler, CollisionCallbacks {
  Player({super.position})
      : super(
          size: Vector2(75, 100), // Example size, adjust as needed
          anchor: Anchor.center,
        );

  // Physics and movement constants
  final double _gravity = 1200.0; // Pixels per second^2, for falling off platforms
  final double _dashSpeed = -450.0; // Negative for upward movement (pixels/sec)
  final double _autoMoveSpeed = 120.0; // Base speed for automatic upward movement (pixels/sec)
  final double _platformStickTime = 0.3; // Seconds to stick to a platform/wall before auto-moving up

  Vector2 _velocity = Vector2.zero();
  bool _isDashing = false;
  double _dashTime = 0.0;
  final double _maxDashTime = 0.15; // How long a dash impulse lasts

  bool _isOnPlatform = false;
  double _timeSinceLastPlatformContact = 0.0;
  MovingPlatform? _currentPlatform; // To move with the platform

  // Game Over state
  bool _isGameOver = false;

  late Vector2 initialPosition; // To store starting position for score calculation

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    initialPosition = position.clone();

    // Load animations (using placeholders for now)
    // TODO: Replace with actual sprite sheets
    final idleAnimation = await game.loadSpriteAnimation(
      'placeholder_player_idle.png', // Replace with actual asset path
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 0.1,
        textureSize: Vector2(32, 32), // Example texture size
      ),
    );

    final dashAnimation = await game.loadSpriteAnimation(
      'placeholder_player_dash.png', // Replace with actual asset path
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 0.1,
        textureSize: Vector2(32, 32), // Example texture size
      ),
    );

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.dashing: dashAnimation,
    };
    current = PlayerState.idle;

    // Add hitbox
    add(RectangleHitbox(
      size: size * 0.8, // Smaller hitbox than visual
      anchor: Anchor.center,
      position: size / 2,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isGameOver) {
      // If game is over, player might fall or have specific animation
      // For now, just stop processing movement.
      // Consider adding a falling velocity if desired.
      _velocity.y += _gravity * dt; // Fall down
      position += _velocity * dt;
      // Check if completely off screen at bottom, then maybe remove or notify game
      if (position.y > game.camera.visibleWorldRect.bottom + size.y) {
          removeFromParent(); // Example: remove player if fallen way off
      }
      return;
    }

    // Base vertical velocity: automatic upward movement
    _velocity.y = -_autoMoveSpeed;

    if (_isOnPlatform) {
      _timeSinceLastPlatformContact += dt;
      if (_timeSinceLastPlatformContact > _platformStickTime && !_isDashing) {
        // Player "unsticks" and continues auto upward movement
        // No specific velocity change needed here as _autoMoveSpeed is the default
      } else if (!_isDashing) {
        // While stuck and not dashing, player has no independent vertical velocity
        // (or moves with platform if platform is vertical)
        _velocity.y = 0;
        if (_currentPlatform != null && _currentPlatform?.moveDirection == PlatformMoveDirection.vertical) {
          // Match platform's vertical speed. This needs platform to expose its current velocity.
          // For simplicity, if platform moves vertically, player might just detach sooner or
          // this needs more complex relative movement.
          // For now, sticking primarily means horizontal stability and brief pause.
        }
      }
    } else {
      // Not on platform - potentially apply gravity if a "fall" state is desired
      // For now, auto-move is king unless dashing.
      // If we want player to fall if they *miss* a dash to a platform, we'd add gravity here.
      // This makes the game harder. Let's assume for now player always moves up or dashes.
    }

    // Apply dash
    if (_isDashing) {
      _velocity.y = _dashSpeed;
      _dashTime += dt;
      if (_dashTime >= _maxDashTime) {
        _isDashing = false;
        _dashTime = 0.0;
        current = PlayerState.idle;
        // After dash, if not on a platform, resume auto-upward movement
      }
    }

    // Horizontal movement with platform
    if (_isOnPlatform && _currentPlatform != null && _currentPlatform?.moveDirection == PlatformMoveDirection.horizontal) {
        // This part is tricky. The player should move with the horizontal platform.
        // One way is to add platform's deltaX to player's position.
        // This requires platform to expose its dx or velocity.
        // Simpler: player's X is not directly controlled, they stick and dash.
        // The "sticking" is more about a brief pause before auto-scroll continues.
        // Let's assume player doesn't move horizontally with platforms unless explicitly coded.
    }


    position += _velocity * dt;

    // Check for falling off bottom of screen
    // Player's top edge (position.y - size.y / 2 for center anchor)
    // is below camera's bottom edge (game.camera.visibleWorldRect.bottom)
    if (position.y - size.y / 2 > game.camera.visibleWorldRect.bottom) {
      print("Player fell off screen!");
      _handleGameOver();
    }
  }

  // Basic tap-to-dash (will be replaced/augmented by Game's TapDetector)
  // This is more for keyboard testing if needed.
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (_isGameOver) return false;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.arrowUp) {
        dash();
        return true;
      }
    }
    return false;
  }

  void dash() {
    if (_isGameOver || _isDashing) return;

    _isDashing = true;
    _dashTime = 0.0;
    current = PlayerState.dashing;
    _isOnPlatform = false; // Dashing means no longer on a platform
    _currentPlatform = null;
    _timeSinceLastPlatformContact = 0.0; // Reset stick timer
    game.playDashSound();
  }

  void _handleGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    current = PlayerState.idle; // Or a specific 'hit' animation
    _velocity = Vector2.zero(); // Stop movement or apply falling
    print("Player: Game Over sequence started.");
    game.playHitSound();
    game.gameOver(); // Notify the main game class
  }

  // Collision Callbacks
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_isGameOver) return;

    if (other is RotatingSpike) {
      print("Player hit a spike!");
      _handleGameOver();
    } else if (other is MovingPlatform) {
      // Check relative position to determine if player landed on top
      // A common check: player's bottom is near platform's top, and player is moving downwards or was dashing.
      // For simplicity, any collision with a platform makes the player "stick" if they are not dashing upwards through it.

      // Player's bottom y: position.y + size.y / 2
      // Platform's top y: other.position.y - other.size.y / 2
      final playerBottom = absoluteCenter.y + size.y / 2;
      final platformTop = other.absoluteCenter.y - other.size.y / 2;

      // Ensure player is somewhat above or at the platform's top and not dashing through it.
      // A small tolerance for landing.
      bool landedOnTop = playerBottom <= platformTop + 10 && (_velocity.y >= 0 || _isDashing);


      if (landedOnTop) {
        print("Player landed on a platform.");
        _isOnPlatform = true;
        _currentPlatform = other;
        _timeSinceLastPlatformContact = 0.0;
        _velocity.y = 0; // Stop vertical movement momentarily
        position.y = platformTop - size.y / 2; // Snap to top of platform
        current = PlayerState.idle; // Change to idle animation when landed
      } else {
        // Hit platform from side or bottom - could be a glancing blow or hitting head.
        // For this game, dashing through narrow openings is key.
        // If dashing, we might ignore this collision or handle it as a "pass through".
        // If not dashing and hit side/bottom, could be game over or a "bounce".
        // For now, let's assume only landing on top matters for sticking.
        // Hitting sides could be a "wall" stick if we implement that, or just a pass-through.
        // If it's a narrow opening, this collision might not even occur if hitboxes are precise.
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other == _currentPlatform) {
      _isOnPlatform = false;
      _currentPlatform = null;
      _timeSinceLastPlatformContact = 0.0; // Reset timer when leaving platform
      // If not dashing, player will resume auto-upward movement in next update()
    }
  }

  void reset() {
    _isGameOver = false;
    position = initialPosition.clone(); // Reset to the initial loaded position
    _velocity = Vector2.zero();
    current = PlayerState.idle;
    _isOnPlatform = false;
    _currentPlatform = null;
    _timeSinceLastPlatformContact = 0.0;
    _isDashing = false;
    _dashTime = 0.0;
  }
}

// Placeholder asset creation - In a real scenario, these files must exist in assets/images/
// For the purpose of this tool, I will assume these are created or provided by the user.
// If I had image generation capabilities, I'd create simple 32x32 colored squares.
// Since I don't, these will cause errors if not present.
// User will need to add:
// assets/images/placeholder_player_idle.png
// assets/images/placeholder_player_dash.png
//
import 'package:tower_dash_game/game/components/moving_platform.dart';
import 'package:tower_dash_game/game/components/rotating_spike.dart';
