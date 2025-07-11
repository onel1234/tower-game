import 'dart:math';
import 'package:flame/components.dart';
import 'package:tower_dash_game/game/components/moving_platform.dart';
import 'package:tower_dash_game/game/components/rotating_spike.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart';

class ObstacleManager extendsComponent with HasGameReference<TowerDashGame> {
  // Timer for spawning new obstacles
  late Timer _spawnTimer;
  Random _random = Random();

  // Configuration for obstacle spawning
  double _initialSpawnInterval = 2.0; // Seconds
  double _minSpawnInterval = 0.8;    // Minimum spawn interval for difficulty scaling
  double _spawnIntervalDecrement = 0.1; // How much to decrease interval
  double _intervalDecrementTime = 10.0; // Decrease interval every X seconds
  late Timer _difficultyTimer;

  // Y position for spawning new obstacles, relative to camera top
  // Obstacles should spawn above the visible screen area.
  // Player moves towards negative Y. So, obstacles spawn at a more negative Y.
  double _spawnYOffset = -200.0; // Spawn 200 pixels above camera's top edge

  ObstacleManager() {
    _spawnTimer = Timer(_initialSpawnInterval, onTick: _spawnObstacle, repeat: true);
    _difficultyTimer = Timer(_intervalDecrementTime, onTick: _increaseDifficulty, repeat: true);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Start timers when the manager is added to the game
    _spawnTimer.start();
    _difficultyTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spawnTimer.update(dt);
    _difficultyTimer.update(dt);
  }

  void _increaseDifficulty() {
    if (_spawnTimer.limit > _minSpawnInterval) {
      _spawnTimer.limit -= _spawnIntervalDecrement;
      if (_spawnTimer.limit < _minSpawnInterval) {
        _spawnTimer.limit = _minSpawnInterval;
      }
      print("Difficulty increased: spawn interval now ${_spawnTimer.limit}s");
    }
  }

  void _spawnObstacle() {
    // Determine spawn position relative to camera's current view
    // Camera's top-left in world coordinates
    final cameraPosition = game.camera.viewfinder.position;
    // The visible world rect's top is the most negative Y value currently visible.
    final spawnBaseY = game.camera.visibleWorldRect.top + _spawnYOffset;

    // Randomly choose an obstacle type
    bool spawnSpike = _random.nextBool();
    // Ensure at least one type of obstacle is chosen if توسيع this logic
    // For now, 50/50 chance, or spawn both, or alternate, etc.
    // Let's try to spawn one type per tick for now.

    if (spawnSpike) {
      _spawnRotatingSpike(spawnBaseY);
    } else {
      _spawnMovingPlatform(spawnBaseY);
    }
  }

  void _spawnRotatingSpike(double baseY) {
    final gameWidth = game.size.x;
    final spikeSize = Vector2(50 + _random.nextDouble() * 30, 50 + _random.nextDouble() * 30); // 50-80
    final spikeX = _random.nextDouble() * (gameWidth - spikeSize.x) + spikeSize.x / 2;

    // Add some vertical variation too
    final spikeY = baseY - _random.nextDouble() * 100; // Spawn slightly above/below base Y

    final spike = RotatingSpike(
      position: Vector2(spikeX, spikeY),
      size: spikeSize,
      rotationSpeed: (_random.nextDouble() * 1.5 + 0.5) * (_random.nextBool() ? 1 : -1), // 0.5-2.0 rad/s, random direction
      clockwise: _random.nextBool(),
    );
    game.add(spike);
    // print("Spawned Spike at ${spike.position}");
  }

  void _spawnMovingPlatform(double baseY) {
    final gameWidth = game.size.x;
    final platformWidth = 80 + _random.nextDouble() * 70; // 80-150
    final platformHeight = 20.0;
    final platformSize = Vector2(platformWidth, platformHeight);

    final platformX = _random.nextDouble() * (gameWidth - platformSize.x) + platformSize.x / 2;
    // Add some vertical variation
    final platformY = baseY - _random.nextDouble() * 100;

    final moveDir = _random.nextBool() ? PlatformMoveDirection.horizontal : PlatformMoveDirection.vertical;
    double maxMoveDist = (moveDir == PlatformMoveDirection.horizontal) ? gameWidth * 0.3 : game.size.y * 0.15;

    final platform = MovingPlatform(
      position: Vector2(platformX, platformY),
      size: platformSize,
      moveDirection: moveDir,
      moveDistance: _random.nextDouble() * maxMoveDist + 20, // Min 20px move distance
      moveSpeed: _random.nextDouble() * 80 + 40, // 40-120 speed
    );
    game.add(platform);
    // print("Spawned Platform at ${platform.position}");
  }

  // Call this when game restarts to reset difficulty
  void reset() {
    _spawnTimer.limit = _initialSpawnInterval;
    _spawnTimer.reset();
    _difficultyTimer.reset();
    _spawnTimer.start();
    _difficultyTimer.start();
  }

  @override
  void onRemove() {
    // Stop timers when the manager is removed
    _spawnTimer.stop();
    _difficultyTimer.stop();
    super.onRemove();
  }
}
