import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _diceAnimationController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _diceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _diceAnimationController.dispose();
    super.dispose();
  }

  void _handleRoll(GameProvider provider) async {
    _confettiController.stop();
    _diceAnimationController.repeat();
    await provider.rollDice();
    _diceAnimationController.stop();
    if (provider.isWin) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "SMART DICE ARENA",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
            tooltip: "Daily Bonus",
            onPressed: () => gameProvider.claimDailyBonus(context),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.amberAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.black, Colors.blueGrey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Result Display with Glassmorphism
                  GlassmorphicContainer(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 80,
                    borderRadius: 20,
                    blur: 15,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ]),
                    borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.amberAccent.withOpacity(0.5),
                          Colors.purpleAccent.withOpacity(0.5),
                        ]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        gameProvider.resultMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: gameProvider.isWin ? Colors.greenAccent : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Dice Display - Simplified to fix sync issue
                  AnimatedBuilder(
                    animation: _diceAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: gameProvider.isRolling ? _diceAnimationController.value * 6.28 : 0,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/images/dice${gameProvider.currentDice}.png',
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                      // Removed AnimatedSwitcher to ensure the image updates instantly with the text
                    ),
                  ),

                  // Prediction Selection
                  Column(
                    children: [
                      Text(
                        "PREDICT YOUR LUCK",
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: List.generate(6, (index) {
                          int number = index + 1;
                          bool isSelected = gameProvider.playerPrediction == number;

                          return GestureDetector(
                            onTap: () {
                              if (!gameProvider.isRolling) gameProvider.setPrediction(number);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.amberAccent : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: Colors.amberAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
                                    : [],
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.white24,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                "$number",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  // Roll Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!gameProvider.isRolling)
                            BoxShadow(
                              color: Colors.amberAccent.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: gameProvider.isRolling || gameProvider.playerPrediction == null
                            ? null
                            : () => _handleRoll(gameProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: gameProvider.isRolling
                            ? const SizedBox(
                                height: 30,
                                width: 30,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                              )
                            : Text(
                                "ROLL NOW",
                                style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confetti Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.yellow],
                numberOfParticles: 30,
                gravity: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}