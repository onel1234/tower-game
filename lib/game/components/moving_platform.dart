import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart';

enum PlatformMoveDirection { horizontal, vertical }

class MovingPlatform extends SpriteComponent
    with HasGameReference<TowerDashGame>, CollisionCallbacks {

  final PlatformMoveDirection moveDirection;
  final double moveDistance; // Max distance to move from the starting point in one direction
  final double moveSpeed;    // Pixels per second

  late Vector2 _startPosition;
  int _moveSign = 1; // 1 for positive direction, -1 for negative

  MovingPlatform({
    required Vector2 position,
    required Vector2 size,
    this.moveDirection = PlatformMoveDirection.horizontal,
    this.moveDistance = 100.0,
    this.moveSpeed = 50.0,
    String? spritePath, // Optional: if you have a specific sprite
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        ) {
    _startPosition = position.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // TODO: Replace with actual platform asset
    // sprite = await game.loadSprite('placeholder_platform.png');
    // User needs to provide 'assets/images/placeholder_platform.png'
    try {
      sprite = await game.loadSprite('placeholder_platform.png');
    } catch (e) {
      print("Error loading platform sprite: $e. This component may not be visible.");
      // Consider adding a fallback colored shape if desired, similar to spike.
      // For now, relies on placeholder_platform.png existing.
    }

    add(RectangleHitbox(
      size: size * 0.95, // Slightly smaller hitbox to make landing feel fair
      anchor: Anchor.center,
      position: size / 2,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (moveDirection == PlatformMoveDirection.horizontal) {
      position.x += _moveSign * moveSpeed * dt;
      if ((position.x - _startPosition.x).abs() >= moveDistance) {
        // Snap to exact boundary to prevent overshooting due to dt variance
        position.x = _startPosition.x + _moveSign * moveDistance;
        _moveSign *= -1; // Reverse direction
      }
    } else { // Vertical movement
      position.y += _moveSign * moveSpeed * dt;
      if ((position.y - _startPosition.y).abs() >= moveDistance) {
        // Snap to exact boundary
        position.y = _startPosition.y + _moveSign * moveDistance;
        _moveSign *= -1; // Reverse direction
      }
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // Collision logic, especially sticking, will be handled by the Player.
    // For now, just a debug print.
    if (other is HasGameReference<TowerDashGame> && other.game.player == other) {
      print("Platform collided with Player!");
      // Player might check relative positions/velocities to "stick" or land.
    }
  }
}

// User needs to add 'assets/images/placeholder_platform.png'
// For example, a simple rectangle or a textured platform image.
// A 1x1 white png would suffice as a minimal placeholder to avoid load errors.
// (This is similar to the player and spike component's asset dependency)
