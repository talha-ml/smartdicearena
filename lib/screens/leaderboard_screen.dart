import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "GLOBAL RANKING",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold, 
            color: Colors.amberAccent, 
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.black, Colors.blueGrey.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('players')
                .orderBy('wins', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No players yet. Be the first to play!", 
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                  ),
                );
              }

              var players = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  var data = players[index].data() as Map<String, dynamic>;
                  String username = data['name'] ?? 'Unknown Player';
                  int wins = data['wins'] ?? 0;
                  int played = data['gamesPlayed'] ?? 0;
                  double accuracy = (data['accuracy'] ?? 0.0).toDouble();

                  Color rankColor = Colors.white70;
                  double elevation = 0;
                  if (index == 0) {
                    rankColor = Colors.amber;
                    elevation = 10;
                  } else if (index == 1) {
                    rankColor = Colors.grey.shade300;
                  } else if (index == 2) {
                    rankColor = Colors.orange.shade400;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: 90,
                      borderRadius: 20,
                      blur: 10,
                      alignment: Alignment.center,
                      border: 1.5,
                      linearGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          rankColor.withOpacity(0.5),
                          Colors.purpleAccent.withOpacity(0.2),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rankColor.withOpacity(0.1),
                            border: Border.all(color: rankColor.withOpacity(0.5), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: GoogleFonts.orbitron(
                                color: rankColor, 
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          username.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        subtitle: Text(
                          "Accuracy: ${accuracy.toStringAsFixed(1)}% | Played: $played",
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "WINS", 
                              style: GoogleFonts.orbitron(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$wins",
                              style: GoogleFonts.orbitron(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}