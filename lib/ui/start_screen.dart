import 'package:flutter/material.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart'; // To access game states or methods

class StartScreen extends StatelessWidget {
  final TowerDashGame game; // Reference to the game instance

  const StartScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7), // Semi-transparent background
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Tower Dash',
              style: TextStyle(
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 5.0, color: Colors.blue.shade700, offset: Offset(2,2)),
                ]
              ),
            ),
            SizedBox(height: 20),
            Text(
              'High Score: ${game.highScore}', // Display high score
              style: TextStyle(fontSize: 24.0, color: Colors.white70),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              onPressed: () {
                game.startGame(); // Method to be added in TowerDashGame
              },
              child: Text('Play', style: TextStyle(color: Colors.black87)),
            ),
            SizedBox(height: 20),
            // Potentially add other buttons like "Settings", "Skins" later
          ],
        ),
      ),
    );
  }
}
