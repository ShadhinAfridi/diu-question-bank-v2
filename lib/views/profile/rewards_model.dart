import 'package:flutter/material.dart';


/// A class representing a single level in the rewards system.
class Level {
  final int level;
  final String title;
  final int pointsRequired;
  final IconData icon;

  const Level({
    required this.level,
    required this.title,
    required this.pointsRequired,
    required this.icon,
  });
}

/// A class representing a single reward that can be claimed.
class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final bool isClaimed;

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    this.isClaimed = false,
  });
}

/// A utility class to manage the rewards and leveling system.
class RewardsHelper {
  /// A predefined list of levels. You can expand this list as your app grows.
  static const List<Level> levels = [
    Level(level: 1, title: 'Newbie', pointsRequired: 0, icon: Icons.star_border),
    Level(level: 2, title: 'Contributor', pointsRequired: 100, icon: Icons.star_half),
    Level(level: 3, title: 'Scholar', pointsRequired: 250, icon: Icons.star),
    Level(level: 4, title: 'Expert', pointsRequired: 500, icon: Icons.school),
    Level(level: 5, title: 'Master', pointsRequired: 1000, icon: Icons.military_tech),
  ];

  /// A predefined list of rewards.
  static final List<Reward> availableRewards = [
    const Reward(
      id: 'reward_1',
      title: 'Bronze Contributor Badge',
      description: 'Awarded for reaching 100 points.',
      pointsRequired: 100,
    ),
    const Reward(
      id: 'reward_2',
      title: 'Silver Scholar Badge',
      description: 'Awarded for reaching 250 points.',
      pointsRequired: 250,
    ),
    const Reward(
      id: 'reward_3',
      title: 'Gold Expert Badge',
      description: 'Awarded for reaching 500 points.',
      pointsRequired: 500,
    ),
  ];

  /// Calculates the user's current level based on their total points.
  static Level getLevelForPoints(int points) {
    // Iterate backward to find the highest level achieved
    for (int i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].pointsRequired) {
        return levels[i];
      }
    }
    return levels.first; // Default to the first level
  }

  /// Calculates the progress towards the next level as a percentage (0.0 to 1.0).
  static double getLevelProgress(int points) {
    final currentLevel = getLevelForPoints(points);
    final nextLevelIndex = levels.indexWhere((l) => l.level == currentLevel.level + 1);

    // If the user is at the max level, progress is 100%
    if (nextLevelIndex == -1) {
      return 1.0;
    }

    final nextLevel = levels[nextLevelIndex];
    final pointsInCurrentLevel = points - currentLevel.pointsRequired;
    final pointsForNextLevel = nextLevel.pointsRequired - currentLevel.pointsRequired;

    if (pointsForNextLevel == 0) {
      return 1.0; // Avoid division by zero
    }

    return (pointsInCurrentLevel / pointsForNextLevel).clamp(0.0, 1.0);
  }
}
