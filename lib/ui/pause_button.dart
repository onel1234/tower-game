import 'package:flutter/material.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart';

class PauseButton extends StatelessWidget {
  final TowerDashGame game;

  const PauseButton({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show the pause button if the game is in the 'playing' state.
    if (game.currentGameState != GameState.playing) {
      return SizedBox.shrink(); // Return an empty widget if not playing
    }

    return Positioned(
      top: 20.0,
      right: 20.0,
      child: IconButton(
        icon: Icon(Icons.pause_circle_filled, color: Colors.white, size: 40.0),
        onPressed: () {
          game.togglePauseState(); // Method to be added in TowerDashGame
        },
      ),
    );
  }
}

class PauseMenu extends StatelessWidget {
  final TowerDashGame game;
  const PauseMenu({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Paused',
              style: TextStyle(
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              onPressed: () {
                game.togglePauseState(); // Resume game
              },
              child: Text('Resume', style: TextStyle(color: Colors.black87)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 20, color: Colors.black87),
              ),
              onPressed: () {
                game.restartGame(); // Restart from pause menu
              },
              child: Text('Restart', style: TextStyle(color: Colors.black87)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                game.returnToMainMenu(); // Go to Main Menu
              },
              child: Text('Main Menu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
