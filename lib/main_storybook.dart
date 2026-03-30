import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'storybook/atoms_stories.dart';
import 'storybook/molecules_stories.dart';
import 'storybook/organisms_stories.dart';

void main() => runApp(const StorybookApp());

class StorybookApp extends StatelessWidget {
  const StorybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Planning - Storybook',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: Storybook(
        stories: [
          // Atoms レイヤー
          ..._buildSection('Atoms', atomsStories()),

          // Molecules レイヤー
          ..._buildSection('Molecules', moleculesStories()),

          // Organisms レイヤー
          ..._buildSection('Organisms', organismsStories()),
        ],
      ),
    );
  }

  /// セクション区切りのStory を作成する補助メソッド
  List<Story> _buildSection(String sectionName, List<Story> stories) {
    final divider = Story(
      name: '━━━━ $sectionName ━━━━',
      builder: (context) => Center(
        child: Text(
          sectionName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    return [divider, ...stories];
  }
}
