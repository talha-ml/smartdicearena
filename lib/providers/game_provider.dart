import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class GameProvider extends ChangeNotifier {
  int _currentDice = 1;
  int? _playerPrediction;
  bool _isRolling = false;
  String _resultMessage = "Select a number and roll!";
  bool _isWin = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  int get currentDice => _currentDice;
  int? get playerPrediction => _playerPrediction;
  bool get isRolling => _isRolling;
  String get resultMessage => _resultMessage;
  bool get isWin => _isWin;

  void setPrediction(int number) {
    if (!_isRolling) {
      _playerPrediction = number;
      _resultMessage = "Ready to roll! Good luck 🍀";
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }

  Future<void> rollDice() async {
    if (_playerPrediction == null) {
      _resultMessage = "Please select a number first! ⚠️";
      notifyListeners();
      return;
    }

    _isRolling = true;
    _isWin = false;
    _resultMessage = "Rolling the dice... 🎲";
    notifyListeners();

    try {
      // 1. Start Roll Sound
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/roll.mp3'));

      // 2. Pre-determine the FINAL result
      final int finalResult = _random.nextInt(6) + 1;

      // 3. Animation Loop (Visual only)
      for (int i = 0; i < 15; i++) {
        _currentDice = _random.nextInt(6) + 1;
        notifyListeners();
        await Future.delayed(Duration(milliseconds: 60 + (i * 12)));
        HapticFeedback.selectionClick();
      }

      // 4. ATOMIC UPDATE: Set result and message in one go
      _currentDice = finalResult;
      _isRolling = false;

      if (_currentDice == _playerPrediction) {
        _isWin = true;
        _resultMessage = "🎉 JACKPOT! It's a $_currentDice!";
      } else {
        _isWin = false;
        int diff = (_currentDice - _playerPrediction!).abs();
        if (diff == 1) {
          _resultMessage = "💀 SO CLOSE! It was a $_currentDice.";
        } else {
          _resultMessage = "❌ Better luck next time! It was a $_currentDice.";
        }
      }

      // 5. NOTIFY IMMEDIATELY so UI reflects the final result instantly
      notifyListeners();

      // 6. Post-Roll Actions (Sounds & DB) - These won't block the UI sync anymore
      await _audioPlayer.stop();
      if (_isWin) {
        _audioPlayer.play(AssetSource('sounds/win.mp3'));
        HapticFeedback.vibrate();
      } else {
        HapticFeedback.mediumImpact();
      }
      
      _updateDatabase(_isWin).catchError((e) => debugPrint("Firestore Error: $e"));

    } catch (e) {
      debugPrint("Game Error: $e");
      _isRolling = false;
      _resultMessage = "Oops! Something went wrong.";
      notifyListeners();
    }
  }

  Future<void> _updateDatabase(bool isWin) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference playerRef = FirebaseFirestore.instance.collection('players').doc(user.uid);
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(playerRef);
        
        if (!snapshot.exists) {
          transaction.set(playerRef, {
            'wins': isWin ? 1 : 0,
            'losses': isWin ? 0 : 1,
            'gamesPlayed': 1,
            'accuracy': isWin ? 100.0 : 0.0,
            'name': user.displayName ?? 'Player',
            'lastPlayed': FieldValue.serverTimestamp(),
          });
        } else {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int wins = (data['wins'] ?? 0) + (isWin ? 1 : 0);
          int losses = (data['losses'] ?? 0) + (isWin ? 0 : 1);
          int gamesPlayed = (data['gamesPlayed'] ?? 0) + 1;
          double accuracy = (wins / gamesPlayed) * 100;

          transaction.update(playerRef, {
            'wins': wins,
            'losses': losses,
            'gamesPlayed': gamesPlayed,
            'accuracy': accuracy,
            'lastPlayed': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint("Transaction Error: $e");
    }
  }

  void resetGame() {
    _currentDice = 1;
    _playerPrediction = null;
    _isRolling = false;
    _resultMessage = "Select a number and roll!";
    _isWin = false;
    notifyListeners();
  }

  Future<void> claimDailyBonus(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      DocumentReference playerRef = FirebaseFirestore.instance.collection('players').doc(user.uid);
      DocumentSnapshot snapshot = await playerRef.get();
      if (!snapshot.exists) return;
      
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Timestamp? lastBonusTimestamp = data.containsKey('dailyBonusDate') ? data['dailyBonusDate'] : null;
      DateTime now = DateTime.now();
      
      bool canClaim = true;
      if (lastBonusTimestamp != null) {
        DateTime lastBonusDate = lastBonusTimestamp.toDate();
        if (lastBonusDate.year == now.year && lastBonusDate.month == now.month && lastBonusDate.day == now.day) {
          canClaim = false;
        }
      }

      if (canClaim) {
        await playerRef.update({
          'wins': FieldValue.increment(2),
          'gamesPlayed': FieldValue.increment(2),
          'dailyBonusDate': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎁 Daily Bonus Claimed!"), backgroundColor: Colors.green));
        }
      }
    } catch (e) { debugPrint(e.toString()); }
  }
}