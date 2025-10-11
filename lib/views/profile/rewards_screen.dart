// lib/src/screens/rewards_screen.dart

import 'package:diuquestionbank/views/profile/rewards_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../theme/app_theme.dart'; // Assuming you have this for styling

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use a Consumer to get the latest data from the HomeViewModel
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final userLevel = RewardsHelper.getLevelForPoints(viewModel.userPoints);
        final levelProgress = RewardsHelper.getLevelProgress(viewModel.userPoints);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rewards & Levels'),
            backgroundColor: theme.colorScheme.surface,
            elevation: 1,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLevelCard(theme, viewModel, userLevel, levelProgress),
                const SizedBox(height: 24.0),
                Text(
                  'Available Rewards',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                _buildRewardsList(theme, viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelCard(
      ThemeData theme,
      HomeViewModel viewModel,
      Level userLevel,
      double levelProgress,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Your Current Level',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8.0),
            Icon(userLevel.icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 8.0),
            Text(
              userLevel.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              '${viewModel.userPoints} Points',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            LinearProgressIndicator(
              value: levelProgress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8.0),
            Text(
              '${(levelProgress * 100).toStringAsFixed(0)}% to next level',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsList(ThemeData theme, HomeViewModel viewModel) {
    final rewards = RewardsHelper.availableRewards;

    if (rewards.isEmpty) {
      return const Center(child: Text('No rewards available at the moment.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canClaim = viewModel.userPoints >= reward.pointsRequired;

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Icon(
              Icons.emoji_events,
              color: canClaim ? theme.colorScheme.secondary : Colors.grey,
            ),
            title: Text(reward.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${reward.description}\nRequires: ${reward.pointsRequired} points'),
            trailing: ElevatedButton(
              onPressed: canClaim ? () {
                // TODO: Implement claim logic
              } : null,
              child: const Text('Claim'),
            ),
          ),
        );
      },
    );
  }
}
