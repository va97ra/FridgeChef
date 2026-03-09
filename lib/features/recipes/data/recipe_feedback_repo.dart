import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/taste_profile.dart';

final recipeFeedbackRepoProvider = Provider<RecipeFeedbackRepo>((ref) {
  return const RecipeFeedbackRepo();
});

class RecipeFeedbackRepo {
  static const storageKey = 'recipe_feedback_votes_v1';

  const RecipeFeedbackRepo();

  Future<Map<String, RecipeFeedbackVote>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final votes = <String, RecipeFeedbackVote>{};
    for (final entry in decoded.entries) {
      final vote = RecipeFeedbackVoteX.fromStorage(entry.value as String?);
      if (vote != null) {
        votes[entry.key] = vote;
      }
    }
    return votes;
  }

  Future<void> setVote(String recipeId, RecipeFeedbackVote? vote) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadAll();
    if (vote == null) {
      current.remove(recipeId);
    } else {
      current[recipeId] = vote;
    }
    final payload = {
      for (final entry in current.entries) entry.key: entry.value.storageValue,
    };
    await prefs.setString(storageKey, jsonEncode(payload));
  }

  Future<void> replaceAll(Map<String, RecipeFeedbackVote> votes) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      for (final entry in votes.entries) entry.key: entry.value.storageValue,
    };
    await prefs.setString(storageKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
