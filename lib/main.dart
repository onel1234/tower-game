import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart';
import 'package:tower_dash_game/ui/game_over_screen.dart';
import 'package:tower_dash_game/ui/pause_button.dart';
import 'package:tower_dash_game/ui/start_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final game = TowerDashGame();

  runApp(
    GameWidget<TowerDashGame>(
      game: game,
      overlayBuilderMap: {
        'StartScreen': (BuildContext context, TowerDashGame game) {
          return StartScreen(game: game);
        },
        'GameOverScreen': (BuildContext context, TowerDashGame game) {
          return GameOverScreen(game: game);
        },
        'PauseButton': (BuildContext context, TowerDashGame game) {
          return PauseButton(game: game);
        },
        'PauseMenu': (BuildContext context, TowerDashGame game) {
          return PauseMenu(game: game);
        },
      },
      // Initial overlay shown when the game starts
      initialActiveOverlays: const ['StartScreen'],
    ),
  );
}
