import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart';

class RotatingSpike extends SpriteComponent
    with HasGameReference<TowerDashGame>, CollisionCallbacks {

  final double rotationSpeed; // Radians per second
  bool clockwise; // Direction of rotation

  RotatingSpike({
    required Vector2 position,
    required Vector2 size,
    this.rotationSpeed = pi / 2, // 90 degrees per second
    this.clockwise = true,
    String? spritePath, // Optional: if you have a specific sprite
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center, // Important for rotation around the center
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // TODO: Replace with actual spike asset
    // For now, using a placeholder or a colored rectangle if no spritePath is given.
    // sprite = await game.loadSprite('placeholder_spike.png');
    // User needs to provide 'assets/images/placeholder_spike.png'
    // As a fallback, let's draw a simple shape if a sprite isn't loaded.
    // This requires changing from SpriteComponent or adding a child ShapeComponent.

    // For simplicity with SpriteComponent, we assume the user will provide the asset.
    // If spritePath is null, this will error. A default could be set.
    try {
      sprite = await game.loadSprite(spritePath ?? 'placeholder_spike.png');
    } catch (e) {
      print("Error loading spike sprite: $e. Using fallback color.");
      // Fallback: Add a colored rectangle as a child if sprite fails to load
      // This is more complex than desired for a SpriteComponent.
      // A better approach for placeholders is to have a 1x1 pixel actual placeholder asset.
      // For now, this will fail if 'placeholder_spike.png' is not found.
      // The plan assumes user provides assets or placeholders.
    }

    // Add hitbox
    // Using a circular hitbox as spikes are often somewhat radial or dangerous from angles.
    // A PolygonHitbox would be more accurate for specific spike shapes.
    add(CircleHitbox(
      radius: size.x / 2 * 0.8, // 80% of the half-width, assuming roughly circular danger
      anchor: Anchor.center,
      position: size / 2, // Relative to the SpriteComponent's size
    ));

    // Randomize initial angle
    angle = Random().nextDouble() * 2 * pi;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (clockwise) {
      angle += rotationSpeed * dt;
    } else {
      angle -= rotationSpeed * dt;
    }
    angle %= 2 * pi; // Keep angle within 0-2pi range
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // Collision logic will be primarily handled by the Player component
    // or the game state manager.
    // For now, just print a debug message.
    if (other is HasGameReference<TowerDashGame> && other.game.player == other) {
      print("Spike collided with Player!");
      // game.gameOver(); // This should be called from Player or Game
    }
  }
}

// User needs to add 'assets/images/placeholder_spike.png'
// For example, a simple image of a spike or a spiky ball.
// A 1x1 white png would suffice as a minimal placeholder to avoid load errors.
// I will assume this file will be provided by the user.
// The game will error if 'placeholder_spike.png' is not found and no spritePath is given.
// (This is similar to the player component's asset dependency)
