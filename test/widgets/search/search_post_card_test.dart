import 'package:app_icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/models/category.dart';
import 'package:fluxdo/models/search_result.dart';
import 'package:fluxdo/providers/discourse_providers.dart';
import 'package:fluxdo/providers/theme_provider.dart';
import 'package:fluxdo/widgets/search/search_post_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _titlePrefix = 'Scaled search';

SearchPost _post({String? headline}) => SearchPost(
  id: 1,
  username: 'user',
  avatarTemplate: '',
  createdAt: DateTime.utc(2026, 1, 1),
  likeCount: 0,
  blurb: '',
  postNumber: 1,
  topicTitleHeadline: headline,
  topic: SearchTopic(
    id: 10,
    title: '$_titlePrefix title',
    slug: 'scaled-search',
    categoryId: null,
    tags: const [],
    postsCount: 1,
    views: 1,
    closed: true,
    archived: false,
  ),
);

Future<void> _pumpCard(WidgetTester tester, SearchPost post) async {
  SharedPreferences.setMockInitialValues({'pref_topic_title_font_scale': 2.0});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        categoryMapProvider.overrideWithValue(
          const AsyncData<Map<int, Category>>({}),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          textTheme: const TextTheme(
            titleMedium: TextStyle(fontSize: 20),
            labelSmall: TextStyle(fontSize: 8),
          ),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 800, child: SearchPostCard(post: post)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Text _findTitleText(WidgetTester tester) {
  return tester.widgetList<Text>(find.byType(Text)).singleWhere(
    (widget) =>
        widget.textSpan?.toPlainText().contains(_titlePrefix) ?? false,
  );
}

void main() {
  testWidgets('SearchPostCard scales title text', (tester) async {
    await _pumpCard(tester, _post());

    final title = _findTitleText(tester);
    final lockIcon = tester.widget<Icon>(find.byIcon(Symbols.lock_rounded));

    expect(title.textSpan!.style?.fontSize, 40);
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(lockIcon.size, 16);
  });

  testWidgets('SearchPostCard scales highlighted title text', (tester) async {
    await _pumpCard(
      tester,
      _post(
        headline: '$_titlePrefix <span class="search-highlight">hit</span>',
      ),
    );

    final title = _findTitleText(tester);
    expect(title.textSpan!.style?.fontSize, 40);
  });
}
