import 'package:flutter/material.dart';
import 'package:tower_dash_game/game/tower_dash_game.dart';

class GameOverScreen extends StatelessWidget {
  final TowerDashGame game;

  const GameOverScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Game Over',
              style: TextStyle(
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                 shadows: [
                  Shadow(blurRadius: 5.0, color: Colors.black54, offset: Offset(2,2)),
                ]
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Your Score: ${game.currentScore}',
              style: TextStyle(fontSize: 28.0, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'High Score: ${game.highScore}',
              style: TextStyle(fontSize: 22.0, color: Colors.white70),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              onPressed: () {
                game.restartGame(); // This method already exists
              },
              child: Text('Restart', style: TextStyle(color: Colors.black87)),
            ),
            SizedBox(height: 15),
            if (game.canOfferRewardedRetry()) // Only show if retry hasn't been used
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 18, color: Colors.white),
                ),
                onPressed: () {
                  game.watchRewardedAdForRetry(); // Method to be added
                },
                child: Text('Watch Ad to Retry', style: TextStyle(color: Colors.white)),
              ),
            SizedBox(height: 15),
            // Optional: "Main Menu" button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                game.returnToMainMenu(); // Method to be added
              },
              child: Text('Main Menu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
