import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'gen_localizations_ar.dart';
import 'gen_localizations_bn.dart';
import 'gen_localizations_en.dart';
import 'gen_localizations_es.dart';
import 'gen_localizations_fr.dart';
import 'gen_localizations_hi.dart';
import 'gen_localizations_ja.dart';
import 'gen_localizations_pt.dart';
import 'gen_localizations_ru.dart';
import 'gen_localizations_tr.dart';
import 'gen_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GenLocalizations
/// returned by `GenLocalizations.of(context)`.
///
/// Applications need to include `GenLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/gen_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GenLocalizations.localizationsDelegates,
///   supportedLocales: GenLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GenLocalizations.supportedLocales
/// property.
abstract class GenLocalizations {
  GenLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GenLocalizations of(BuildContext context) {
    return Localizations.of<GenLocalizations>(context, GenLocalizations)!;
  }

  static const LocalizationsDelegate<GenLocalizations> delegate =
      _GenLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sudoku Master'**
  String get appName;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello! 👋'**
  String get hello;

  /// No description provided for @readyToPlay.
  ///
  /// In en, this message translates to:
  /// **'Ready to Play Sudoku?'**
  String get readyToPlay;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyChallengeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new puzzle every day!'**
  String get dailyChallengeSubtitle;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @quickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStart;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play?'**
  String get howToPlay;

  /// No description provided for @howToPlaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn the rules of Sudoku'**
  String get howToPlaySubtitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @ranked.
  ///
  /// In en, this message translates to:
  /// **'Ranked'**
  String get ranked;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @autoRemoveNotes.
  ///
  /// In en, this message translates to:
  /// **'Auto Remove Notes'**
  String get autoRemoveNotes;

  /// No description provided for @autoRemoveNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove notes when number is placed'**
  String get autoRemoveNotesSubtitle;

  /// No description provided for @highlightSameNumbers.
  ///
  /// In en, this message translates to:
  /// **'Highlight Same Numbers'**
  String get highlightSameNumbers;

  /// No description provided for @highlightSameNumbersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Highlight matching numbers'**
  String get highlightSameNumbersSubtitle;

  /// No description provided for @showMistakes.
  ///
  /// In en, this message translates to:
  /// **'Show Mistakes'**
  String get showMistakes;

  /// No description provided for @showMistakesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show incorrect numbers'**
  String get showMistakesSubtitle;

  /// No description provided for @showTimer.
  ///
  /// In en, this message translates to:
  /// **'Show Timer'**
  String get showTimer;

  /// No description provided for @showTimerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display game timer'**
  String get showTimerSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select app language'**
  String get languageSubtitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @lightModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic bright theme'**
  String get lightModeDesc;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get darkModeDesc;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get darkModeSubtitle;

  /// No description provided for @premiumThemes.
  ///
  /// In en, this message translates to:
  /// **'Premium Themes'**
  String get premiumThemes;

  /// No description provided for @requiresMasterDivision.
  ///
  /// In en, this message translates to:
  /// **'Requires Master Division'**
  String get requiresMasterDivision;

  /// No description provided for @requiresChampionDivision.
  ///
  /// In en, this message translates to:
  /// **'Requires Champion Division'**
  String get requiresChampionDivision;

  /// No description provided for @soundHaptics.
  ///
  /// In en, this message translates to:
  /// **'Sound & Haptics'**
  String get soundHaptics;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @soundEffectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play sound effects'**
  String get soundEffectsSubtitle;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get vibrationSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Game updates and duel invites'**
  String get pushNotificationsSubtitle;

  /// No description provided for @quickSetup.
  ///
  /// In en, this message translates to:
  /// **'Quick Setup'**
  String get quickSetup;

  /// No description provided for @quickSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow the following for the best experience.\nYou can change these anytime in Settings.'**
  String get quickSetupSubtitle;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationPermission;

  /// No description provided for @locationPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match with nearby players & regional leaderboard'**
  String get locationPermissionSubtitle;

  /// No description provided for @allowContinue.
  ///
  /// In en, this message translates to:
  /// **'Allow & Continue'**
  String get allowContinue;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @goPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get goPremiumSubtitle;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @restorePurchaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore previous purchases'**
  String get restorePurchaseSubtitle;

  /// No description provided for @adsFree.
  ///
  /// In en, this message translates to:
  /// **'Ads-Free'**
  String get adsFree;

  /// No description provided for @adsFreeThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get adsFreeThankYou;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @rateUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your feedback'**
  String get rateUsSubtitle;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @shareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell your friends'**
  String get shareAppSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {v}'**
  String version(String v);

  /// No description provided for @rankedMode.
  ///
  /// In en, this message translates to:
  /// **'Ranked Mode'**
  String get rankedMode;

  /// No description provided for @raceAgainstTime.
  ///
  /// In en, this message translates to:
  /// **'Race Against Time!'**
  String get raceAgainstTime;

  /// No description provided for @rankedRules.
  ///
  /// In en, this message translates to:
  /// **'Ranked Rules'**
  String get rankedRules;

  /// No description provided for @selectDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Select Difficulty'**
  String get selectDifficulty;

  /// No description provided for @topPlayers.
  ///
  /// In en, this message translates to:
  /// **'Top Players'**
  String get topPlayers;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @perfectForWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Perfect for warming up'**
  String get perfectForWarmingUp;

  /// No description provided for @balancedChallenge.
  ///
  /// In en, this message translates to:
  /// **'A balanced challenge'**
  String get balancedChallenge;

  /// No description provided for @forExperiencedPlayers.
  ///
  /// In en, this message translates to:
  /// **'For experienced players'**
  String get forExperiencedPlayers;

  /// No description provided for @ultimateTestOfSkill.
  ///
  /// In en, this message translates to:
  /// **'Ultimate test of skill'**
  String get ultimateTestOfSkill;

  /// No description provided for @rankedRuleTime.
  ///
  /// In en, this message translates to:
  /// **'Race against time - Complete before countdown ends!'**
  String get rankedRuleTime;

  /// No description provided for @rankedRuleHints.
  ///
  /// In en, this message translates to:
  /// **'Max 3 hints per game (VIP: No ads needed)'**
  String get rankedRuleHints;

  /// No description provided for @rankedRuleFastNotes.
  ///
  /// In en, this message translates to:
  /// **'Fast Notes: Watch 1 ad to unlock (VIP: Free)'**
  String get rankedRuleFastNotes;

  /// No description provided for @rankedRuleScore.
  ///
  /// In en, this message translates to:
  /// **'Higher difficulty = Higher score rewards!'**
  String get rankedRuleScore;

  /// No description provided for @rankedRuleFairPlay.
  ///
  /// In en, this message translates to:
  /// **'Fair play: VIP only removes ads, no winning advantage'**
  String get rankedRuleFairPlay;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @youWin.
  ///
  /// In en, this message translates to:
  /// **'You Win!'**
  String get youWin;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @mistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get mistakes;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @hints.
  ///
  /// In en, this message translates to:
  /// **'Hints'**
  String get hints;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get erase;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @selectCellFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a cell first!'**
  String get selectCellFirst;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @dailyBonus.
  ///
  /// In en, this message translates to:
  /// **'Daily Bonus'**
  String get dailyBonus;

  /// No description provided for @watchAdEarnXp.
  ///
  /// In en, this message translates to:
  /// **'Watch ad, earn +50 XP!'**
  String get watchAdEarnXp;

  /// No description provided for @comeBackTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow!'**
  String get comeBackTomorrow;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// No description provided for @agreeAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree & Continue'**
  String get agreeAndContinue;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// No description provided for @eloBasedCompetition.
  ///
  /// In en, this message translates to:
  /// **'ELO-based competition'**
  String get eloBasedCompetition;

  /// No description provided for @guestPlayer.
  ///
  /// In en, this message translates to:
  /// **'Guest Player'**
  String get guestPlayer;

  /// No description provided for @localPlayer.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localPlayer;

  /// No description provided for @tapToEditNickname.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit nickname'**
  String get tapToEditNickname;

  /// No description provided for @editNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit Nickname'**
  String get editNickname;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get enterNickname;

  /// No description provided for @nicknameSaved.
  ///
  /// In en, this message translates to:
  /// **'Nickname saved!'**
  String get nicknameSaved;

  /// No description provided for @nicknameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be at least 3 characters'**
  String get nicknameMinLength;

  /// No description provided for @currentRank.
  ///
  /// In en, this message translates to:
  /// **'Current Rank'**
  String get currentRank;

  /// No description provided for @startDuel.
  ///
  /// In en, this message translates to:
  /// **'Start Duel'**
  String get startDuel;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// No description provided for @rankProgress.
  ///
  /// In en, this message translates to:
  /// **'Rank Progress'**
  String get rankProgress;

  /// No description provided for @eloToNextRank.
  ///
  /// In en, this message translates to:
  /// **'+{elo} ELO to next rank'**
  String eloToNextRank(int elo);

  /// No description provided for @playVsAi.
  ///
  /// In en, this message translates to:
  /// **'Play vs AI'**
  String get playVsAi;

  /// No description provided for @rookie.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get rookie;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get perfect;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @exploreComingSoon.
  ///
  /// In en, this message translates to:
  /// **'New content coming soon!'**
  String get exploreComingSoon;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @dailyChallengeHistory.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge History'**
  String get dailyChallengeHistory;

  /// No description provided for @dailyChallengeOncePerDay.
  ///
  /// In en, this message translates to:
  /// **'You can complete today\'s challenge only once. Complete past challenges to earn your monthly badge!'**
  String get dailyChallengeOncePerDay;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View Calendar'**
  String get viewCalendar;

  /// No description provided for @completeDailyToSee.
  ///
  /// In en, this message translates to:
  /// **'Complete daily challenges to see your history'**
  String get completeDailyToSee;

  /// No description provided for @eventHistory.
  ///
  /// In en, this message translates to:
  /// **'Event History'**
  String get eventHistory;

  /// No description provided for @participateInEvents.
  ///
  /// In en, this message translates to:
  /// **'Participate in events to see your history'**
  String get participateInEvents;

  /// No description provided for @rankedHistory.
  ///
  /// In en, this message translates to:
  /// **'Ranked History'**
  String get rankedHistory;

  /// No description provided for @playRankedToSee.
  ///
  /// In en, this message translates to:
  /// **'Play ranked games to see your history'**
  String get playRankedToSee;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @keepPlayingToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Keep playing to unlock more!'**
  String get keepPlayingToUnlock;

  /// No description provided for @checkYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Check your progress'**
  String get checkYourProgress;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @trophyRoom.
  ///
  /// In en, this message translates to:
  /// **'Badge Gallery'**
  String get trophyRoom;

  /// No description provided for @playersCompleted.
  ///
  /// In en, this message translates to:
  /// **'players have completed'**
  String get playersCompleted;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompleted;

  /// No description provided for @daysCompleted.
  ///
  /// In en, this message translates to:
  /// **'days completed'**
  String get daysCompleted;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @dailyStreak3.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get dailyStreak3;

  /// No description provided for @dailyStreak3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 daily challenges in a row'**
  String get dailyStreak3Desc;

  /// No description provided for @dailyStreak7.
  ///
  /// In en, this message translates to:
  /// **'Week Warrior'**
  String get dailyStreak7;

  /// No description provided for @dailyStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 7 daily challenges in a row'**
  String get dailyStreak7Desc;

  /// No description provided for @dailyStreak14.
  ///
  /// In en, this message translates to:
  /// **'Two Week Champion'**
  String get dailyStreak14;

  /// No description provided for @dailyStreak14Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 14 daily challenges in a row'**
  String get dailyStreak14Desc;

  /// No description provided for @dailyStreak30.
  ///
  /// In en, this message translates to:
  /// **'Month Master'**
  String get dailyStreak30;

  /// No description provided for @dailyStreak30Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 30 daily challenges in a row'**
  String get dailyStreak30Desc;

  /// No description provided for @dailyStreak60.
  ///
  /// In en, this message translates to:
  /// **'Dedication'**
  String get dailyStreak60;

  /// No description provided for @dailyStreak60Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 60 daily challenges in a row'**
  String get dailyStreak60Desc;

  /// No description provided for @dailyStreak100.
  ///
  /// In en, this message translates to:
  /// **'Daily Legend'**
  String get dailyStreak100;

  /// No description provided for @dailyStreak100Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 daily challenges in a row'**
  String get dailyStreak100Desc;

  /// No description provided for @dailyTotal10.
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get dailyTotal10;

  /// No description provided for @dailyTotal10Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 daily challenges total'**
  String get dailyTotal10Desc;

  /// No description provided for @dailyTotal30.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get dailyTotal30;

  /// No description provided for @dailyTotal30Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 30 daily challenges total'**
  String get dailyTotal30Desc;

  /// No description provided for @dailyTotal100.
  ///
  /// In en, this message translates to:
  /// **'Centurion'**
  String get dailyTotal100;

  /// No description provided for @dailyTotal100Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 daily challenges total'**
  String get dailyTotal100Desc;

  /// No description provided for @dailyTotal365.
  ///
  /// In en, this message translates to:
  /// **'Year Round'**
  String get dailyTotal365;

  /// No description provided for @dailyTotal365Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 365 daily challenges total'**
  String get dailyTotal365Desc;

  /// No description provided for @dailyBadges1.
  ///
  /// In en, this message translates to:
  /// **'First Badge'**
  String get dailyBadges1;

  /// No description provided for @dailyBadges1Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn your first monthly badge'**
  String get dailyBadges1Desc;

  /// No description provided for @dailyBadges3.
  ///
  /// In en, this message translates to:
  /// **'Badge Collector'**
  String get dailyBadges3;

  /// No description provided for @dailyBadges3Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 3 monthly badges'**
  String get dailyBadges3Desc;

  /// No description provided for @dailyBadges6.
  ///
  /// In en, this message translates to:
  /// **'Half Year Hero'**
  String get dailyBadges6;

  /// No description provided for @dailyBadges6Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 6 monthly badges'**
  String get dailyBadges6Desc;

  /// No description provided for @dailyBadges12.
  ///
  /// In en, this message translates to:
  /// **'Badge Master'**
  String get dailyBadges12;

  /// No description provided for @dailyBadges12Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 12 monthly badges'**
  String get dailyBadges12Desc;

  /// No description provided for @newYearChampion.
  ///
  /// In en, this message translates to:
  /// **'New Year Champion'**
  String get newYearChampion;

  /// No description provided for @summerWarrior.
  ///
  /// In en, this message translates to:
  /// **'Summer Warrior'**
  String get summerWarrior;

  /// No description provided for @winterLegend.
  ///
  /// In en, this message translates to:
  /// **'Winter Legend'**
  String get winterLegend;

  /// No description provided for @dailyLegend.
  ///
  /// In en, this message translates to:
  /// **'Daily Legend'**
  String get dailyLegend;

  /// No description provided for @yearRoundPlayer.
  ///
  /// In en, this message translates to:
  /// **'Year Round Player'**
  String get yearRoundPlayer;

  /// No description provided for @badgeMaster.
  ///
  /// In en, this message translates to:
  /// **'Badge Master'**
  String get badgeMaster;

  /// No description provided for @seedling.
  ///
  /// In en, this message translates to:
  /// **'Seedling'**
  String get seedling;

  /// No description provided for @rising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get rising;

  /// No description provided for @skilled.
  ///
  /// In en, this message translates to:
  /// **'Skilled'**
  String get skilled;

  /// No description provided for @elite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get elite;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @gameComplete.
  ///
  /// In en, this message translates to:
  /// **'Game Complete!'**
  String get gameComplete;

  /// No description provided for @gameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'You made too many mistakes'**
  String get gameOverMessage;

  /// No description provided for @congratsMessage.
  ///
  /// In en, this message translates to:
  /// **'Excellent work!'**
  String get congratsMessage;

  /// No description provided for @newBestTime.
  ///
  /// In en, this message translates to:
  /// **'New Best Time!'**
  String get newBestTime;

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'Final Score'**
  String get finalScore;

  /// No description provided for @timeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time Taken'**
  String get timeTaken;

  /// No description provided for @noMistakes.
  ///
  /// In en, this message translates to:
  /// **'No Mistakes'**
  String get noMistakes;

  /// No description provided for @perfectGame.
  ///
  /// In en, this message translates to:
  /// **'Perfect Game!'**
  String get perfectGame;

  /// No description provided for @watchAdForHint.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to get a hint'**
  String get watchAdForHint;

  /// No description provided for @watchAdForFastNotes.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to unlock Fast Notes'**
  String get watchAdForFastNotes;

  /// No description provided for @watchAdToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to unlock'**
  String get watchAdToUnlock;

  /// No description provided for @watchAdForSecondChance.
  ///
  /// In en, this message translates to:
  /// **'Watch 3 ads to get another chance'**
  String get watchAdForSecondChance;

  /// No description provided for @secondChanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Second Chance'**
  String get secondChanceTitle;

  /// No description provided for @secondChanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch ads to continue playing!'**
  String get secondChanceMessage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No Thanks'**
  String get noThanks;

  /// No description provided for @exitGame.
  ///
  /// In en, this message translates to:
  /// **'Exit Game'**
  String get exitGame;

  /// No description provided for @exitGameMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved'**
  String get exitGameMessage;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @adsFreeActivated.
  ///
  /// In en, this message translates to:
  /// **'Ads-Free activated!'**
  String get adsFreeActivated;

  /// No description provided for @alreadyPurchased.
  ///
  /// In en, this message translates to:
  /// **'Already purchased!'**
  String get alreadyPurchased;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get purchasePending;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase restored!'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailed;

  /// No description provided for @noPurchaseToRestore.
  ///
  /// In en, this message translates to:
  /// **'No purchase to restore'**
  String get noPurchaseToRestore;

  /// No description provided for @vipOnly.
  ///
  /// In en, this message translates to:
  /// **'VIP Only'**
  String get vipOnly;

  /// No description provided for @unlockWithVip.
  ///
  /// In en, this message translates to:
  /// **'Unlock with VIP'**
  String get unlockWithVip;

  /// No description provided for @freeWithVip.
  ///
  /// In en, this message translates to:
  /// **'Free with VIP'**
  String get freeWithVip;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAds;

  /// No description provided for @unlimitedHints.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Hints'**
  String get unlimitedHints;

  /// No description provided for @allFeatures.
  ///
  /// In en, this message translates to:
  /// **'All Features'**
  String get allFeatures;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievementUnlocked;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @easySolved.
  ///
  /// In en, this message translates to:
  /// **'easy Sudoku solved'**
  String get easySolved;

  /// No description provided for @mediumSolved.
  ///
  /// In en, this message translates to:
  /// **'medium Sudoku solved'**
  String get mediumSolved;

  /// No description provided for @hardSolved.
  ///
  /// In en, this message translates to:
  /// **'hard Sudoku solved'**
  String get hardSolved;

  /// No description provided for @expertSolved.
  ///
  /// In en, this message translates to:
  /// **'expert Sudoku solved'**
  String get expertSolved;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @puzzles.
  ///
  /// In en, this message translates to:
  /// **'puzzles'**
  String get puzzles;

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get timesUp;

  /// No description provided for @timesUpMessage.
  ///
  /// In en, this message translates to:
  /// **'You ran out of time. Better luck next time!'**
  String get timesUpMessage;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @backToRanked.
  ///
  /// In en, this message translates to:
  /// **'Back to Ranked'**
  String get backToRanked;

  /// No description provided for @preparingRanked.
  ///
  /// In en, this message translates to:
  /// **'Preparing ranked puzzle...'**
  String get preparingRanked;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victory;

  /// No description provided for @hintsUsed.
  ///
  /// In en, this message translates to:
  /// **'Hints Used'**
  String get hintsUsed;

  /// No description provided for @scoreEarned.
  ///
  /// In en, this message translates to:
  /// **'Score Earned'**
  String get scoreEarned;

  /// No description provided for @threeMistakesMessage.
  ///
  /// In en, this message translates to:
  /// **'You made 3 mistakes. In Ranked mode, precision is key!'**
  String get threeMistakesMessage;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @fastNotesApplied.
  ///
  /// In en, this message translates to:
  /// **'Fast Notes applied!'**
  String get fastNotesApplied;

  /// No description provided for @noHintsRemaining.
  ///
  /// In en, this message translates to:
  /// **'No hints remaining! Max 5 hints per game.'**
  String get noHintsRemaining;

  /// No description provided for @useHint.
  ///
  /// In en, this message translates to:
  /// **'Use Hint'**
  String get useHint;

  /// No description provided for @watchAdForHintQuestion.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to use a hint?'**
  String get watchAdForHintQuestion;

  /// No description provided for @hintsRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'Hints remaining: {count}'**
  String hintsRemainingCount(int count);

  /// No description provided for @watchAdForFastNotesRanked.
  ///
  /// In en, this message translates to:
  /// **'Watch 1 ad to unlock Fast Notes for this game.'**
  String get watchAdForFastNotesRanked;

  /// No description provided for @fastNotes.
  ///
  /// In en, this message translates to:
  /// **'Fast Notes'**
  String get fastNotes;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @cellCannotChange.
  ///
  /// In en, this message translates to:
  /// **'This cell cannot be changed!'**
  String get cellCannotChange;

  /// No description provided for @ranger.
  ///
  /// In en, this message translates to:
  /// **'Ranger'**
  String get ranger;

  /// No description provided for @ingenious.
  ///
  /// In en, this message translates to:
  /// **'Ingenious'**
  String get ingenious;

  /// No description provided for @sudokuKing.
  ///
  /// In en, this message translates to:
  /// **'Sudoku King'**
  String get sudokuKing;

  /// No description provided for @needAHint.
  ///
  /// In en, this message translates to:
  /// **'Need a Hint?'**
  String get needAHint;

  /// No description provided for @selectEmptyCellForHint.
  ///
  /// In en, this message translates to:
  /// **'Please select an empty cell for hint!'**
  String get selectEmptyCellForHint;

  /// No description provided for @noEmptyCellsLeft.
  ///
  /// In en, this message translates to:
  /// **'No empty cells left!'**
  String get noEmptyCellsLeft;

  /// No description provided for @getFreeHint.
  ///
  /// In en, this message translates to:
  /// **'Get 1 free hint'**
  String get getFreeHint;

  /// No description provided for @watchOneAd.
  ///
  /// In en, this message translates to:
  /// **'Watch 1 Ad'**
  String get watchOneAd;

  /// No description provided for @getMoreHintsBy.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your free hints. Get more hints by:'**
  String get getMoreHintsBy;

  /// No description provided for @fastPencilUnlock.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill all possible numbers as notes. Unlock this feature:'**
  String get fastPencilUnlock;

  /// No description provided for @useFastPencilOnce.
  ///
  /// In en, this message translates to:
  /// **'Use Fast Pencil once'**
  String get useFastPencilOnce;

  /// No description provided for @unlockPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get unlockPremium;

  /// No description provided for @secondChances.
  ///
  /// In en, this message translates to:
  /// **'Second Chances'**
  String get secondChances;

  /// No description provided for @smartPencil.
  ///
  /// In en, this message translates to:
  /// **'Smart Pencil'**
  String get smartPencil;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @save70.
  ///
  /// In en, this message translates to:
  /// **'Save 70%'**
  String get save70;

  /// No description provided for @save35.
  ///
  /// In en, this message translates to:
  /// **'Save 35%'**
  String get save35;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get best;

  /// No description provided for @fillTheGrid.
  ///
  /// In en, this message translates to:
  /// **'Fill the Grid'**
  String get fillTheGrid;

  /// No description provided for @eachRowColumn.
  ///
  /// In en, this message translates to:
  /// **'Each row, column, and 3x3 box: numbers 1-9'**
  String get eachRowColumn;

  /// No description provided for @rows19.
  ///
  /// In en, this message translates to:
  /// **'Rows: 1-9'**
  String get rows19;

  /// No description provided for @columns19.
  ///
  /// In en, this message translates to:
  /// **'Columns: 1-9'**
  String get columns19;

  /// No description provided for @boxes19.
  ///
  /// In en, this message translates to:
  /// **'3x3 boxes: 1-9'**
  String get boxes19;

  /// No description provided for @tapToPlace.
  ///
  /// In en, this message translates to:
  /// **'Tap to Place'**
  String get tapToPlace;

  /// No description provided for @tapHighlightedCellThen7.
  ///
  /// In en, this message translates to:
  /// **'Tap highlighted cell, then tap number 7'**
  String get tapHighlightedCellThen7;

  /// No description provided for @pencilModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pencil Mode'**
  String get pencilModeTitle;

  /// No description provided for @tapPencilButton.
  ///
  /// In en, this message translates to:
  /// **'Tap Pencil button to enable notes'**
  String get tapPencilButton;

  /// No description provided for @tapTheHighlightedCell.
  ///
  /// In en, this message translates to:
  /// **'Tap the highlighted cell'**
  String get tapTheHighlightedCell;

  /// No description provided for @addNotes127.
  ///
  /// In en, this message translates to:
  /// **'Add notes: 1, 2, 7'**
  String get addNotes127;

  /// No description provided for @youveMasteredNotes.
  ///
  /// In en, this message translates to:
  /// **'You\'ve mastered notes!'**
  String get youveMasteredNotes;

  /// No description provided for @useHintsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Hints'**
  String get useHintsTitle;

  /// No description provided for @nowTapHintButton.
  ///
  /// In en, this message translates to:
  /// **'Now tap the Hint button'**
  String get nowTapHintButton;

  /// No description provided for @tutorialCompleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Tutorial complete! Enjoy playing!'**
  String get tutorialCompleteMsg;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get excellent;

  /// No description provided for @youreReady.
  ///
  /// In en, this message translates to:
  /// **'You\'re Ready!'**
  String get youreReady;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get greatJob;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @mayShort.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayShort;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @noAchievementsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No achievements in this category'**
  String get noAchievementsInCategory;

  /// No description provided for @achievement_first_win.
  ///
  /// In en, this message translates to:
  /// **'First Victory'**
  String get achievement_first_win;

  /// No description provided for @achievement_win_10.
  ///
  /// In en, this message translates to:
  /// **'Dedicated Player'**
  String get achievement_win_10;

  /// No description provided for @achievement_win_50.
  ///
  /// In en, this message translates to:
  /// **'Experienced Player'**
  String get achievement_win_50;

  /// No description provided for @achievement_win_100.
  ///
  /// In en, this message translates to:
  /// **'Veteran Player'**
  String get achievement_win_100;

  /// No description provided for @achievement_win_500.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster'**
  String get achievement_win_500;

  /// No description provided for @achievement_first_perfect.
  ///
  /// In en, this message translates to:
  /// **'Flawless'**
  String get achievement_first_perfect;

  /// No description provided for @achievement_perfect_10.
  ///
  /// In en, this message translates to:
  /// **'Perfectionist'**
  String get achievement_perfect_10;

  /// No description provided for @achievement_perfect_50.
  ///
  /// In en, this message translates to:
  /// **'Flawless Master'**
  String get achievement_perfect_50;

  /// No description provided for @achievement_perfect_100.
  ///
  /// In en, this message translates to:
  /// **'Perfection Incarnate'**
  String get achievement_perfect_100;

  /// No description provided for @achievement_streak_3.
  ///
  /// In en, this message translates to:
  /// **'Hot Streak'**
  String get achievement_streak_3;

  /// No description provided for @achievement_streak_7.
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get achievement_streak_7;

  /// No description provided for @achievement_streak_14.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get achievement_streak_14;

  /// No description provided for @achievement_streak_30.
  ///
  /// In en, this message translates to:
  /// **'Legendary Streak'**
  String get achievement_streak_30;

  /// No description provided for @achievement_speed_easy_3min.
  ///
  /// In en, this message translates to:
  /// **'Speed Demon'**
  String get achievement_speed_easy_3min;

  /// No description provided for @achievement_speed_medium_8min.
  ///
  /// In en, this message translates to:
  /// **'Quick Thinker'**
  String get achievement_speed_medium_8min;

  /// No description provided for @achievement_speed_hard_15min.
  ///
  /// In en, this message translates to:
  /// **'Speed Master'**
  String get achievement_speed_hard_15min;

  /// No description provided for @achievement_speed_expert_25min.
  ///
  /// In en, this message translates to:
  /// **'Lightning Expert'**
  String get achievement_speed_expert_25min;

  /// No description provided for @achievement_easy_master.
  ///
  /// In en, this message translates to:
  /// **'Easy Master'**
  String get achievement_easy_master;

  /// No description provided for @achievement_medium_master.
  ///
  /// In en, this message translates to:
  /// **'Medium Master'**
  String get achievement_medium_master;

  /// No description provided for @achievement_hard_master.
  ///
  /// In en, this message translates to:
  /// **'Hard Master'**
  String get achievement_hard_master;

  /// No description provided for @achievement_expert_master.
  ///
  /// In en, this message translates to:
  /// **'Expert Master'**
  String get achievement_expert_master;

  /// No description provided for @achievement_expert_perfect.
  ///
  /// In en, this message translates to:
  /// **'Expert Perfectionist'**
  String get achievement_expert_perfect;

  /// No description provided for @achievement_easy_5.
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get achievement_easy_5;

  /// No description provided for @achievement_easy_10.
  ///
  /// In en, this message translates to:
  /// **'Getting Warmed Up'**
  String get achievement_easy_10;

  /// No description provided for @achievement_easy_50.
  ///
  /// In en, this message translates to:
  /// **'Easy Breezy'**
  String get achievement_easy_50;

  /// No description provided for @achievement_easy_100.
  ///
  /// In en, this message translates to:
  /// **'Beginner Champion'**
  String get achievement_easy_100;

  /// No description provided for @achievement_medium_5.
  ///
  /// In en, this message translates to:
  /// **'Rising Star'**
  String get achievement_medium_5;

  /// No description provided for @achievement_medium_10.
  ///
  /// In en, this message translates to:
  /// **'Steady Progress'**
  String get achievement_medium_10;

  /// No description provided for @achievement_medium_50.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Enthusiast'**
  String get achievement_medium_50;

  /// No description provided for @achievement_hard_5.
  ///
  /// In en, this message translates to:
  /// **'Brave Heart'**
  String get achievement_hard_5;

  /// No description provided for @achievement_hard_20.
  ///
  /// In en, this message translates to:
  /// **'Fearless Solver'**
  String get achievement_hard_20;

  /// No description provided for @achievement_expert_10.
  ///
  /// In en, this message translates to:
  /// **'Mind Master'**
  String get achievement_expert_10;

  /// No description provided for @achievement_days_7.
  ///
  /// In en, this message translates to:
  /// **'Week Warrior'**
  String get achievement_days_7;

  /// No description provided for @achievement_days_30.
  ///
  /// In en, this message translates to:
  /// **'Monthly Master'**
  String get achievement_days_30;

  /// No description provided for @achievement_days_365.
  ///
  /// In en, this message translates to:
  /// **'Year-Round Legend'**
  String get achievement_days_365;

  /// No description provided for @achievement_daily_first.
  ///
  /// In en, this message translates to:
  /// **'First Challenge'**
  String get achievement_daily_first;

  /// No description provided for @achievement_daily_7.
  ///
  /// In en, this message translates to:
  /// **'Daily Devotee'**
  String get achievement_daily_7;

  /// No description provided for @achievement_daily_14.
  ///
  /// In en, this message translates to:
  /// **'Two Week Streak'**
  String get achievement_daily_14;

  /// No description provided for @achievement_daily_30.
  ///
  /// In en, this message translates to:
  /// **'Challenge Conqueror'**
  String get achievement_daily_30;

  /// No description provided for @achievement_hints_10.
  ///
  /// In en, this message translates to:
  /// **'Hint Seeker'**
  String get achievement_hints_10;

  /// No description provided for @achievement_hints_100.
  ///
  /// In en, this message translates to:
  /// **'Wisdom Gatherer'**
  String get achievement_hints_100;

  /// No description provided for @achievement_hints_500.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Hunter'**
  String get achievement_hints_500;

  /// No description provided for @achievement_hints_1000.
  ///
  /// In en, this message translates to:
  /// **'Enlightened One'**
  String get achievement_hints_1000;

  /// No description provided for @achievement_king_5.
  ///
  /// In en, this message translates to:
  /// **'Giant Slayer'**
  String get achievement_king_5;

  /// No description provided for @achievement_king_20.
  ///
  /// In en, this message translates to:
  /// **'Supreme Ruler'**
  String get achievement_king_20;

  /// No description provided for @achievementDesc_first_win.
  ///
  /// In en, this message translates to:
  /// **'Win your first game'**
  String get achievementDesc_first_win;

  /// No description provided for @achievementDesc_win_10.
  ///
  /// In en, this message translates to:
  /// **'Win 10 games'**
  String get achievementDesc_win_10;

  /// No description provided for @achievementDesc_win_50.
  ///
  /// In en, this message translates to:
  /// **'Win 50 games'**
  String get achievementDesc_win_50;

  /// No description provided for @achievementDesc_win_100.
  ///
  /// In en, this message translates to:
  /// **'Win 100 games'**
  String get achievementDesc_win_100;

  /// No description provided for @achievementDesc_win_500.
  ///
  /// In en, this message translates to:
  /// **'Win 500 games'**
  String get achievementDesc_win_500;

  /// No description provided for @achievementDesc_first_perfect.
  ///
  /// In en, this message translates to:
  /// **'Complete a game without mistakes'**
  String get achievementDesc_first_perfect;

  /// No description provided for @achievementDesc_perfect_10.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 games without mistakes'**
  String get achievementDesc_perfect_10;

  /// No description provided for @achievementDesc_perfect_50.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 games without mistakes'**
  String get achievementDesc_perfect_50;

  /// No description provided for @achievementDesc_perfect_100.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 games without mistakes'**
  String get achievementDesc_perfect_100;

  /// No description provided for @achievementDesc_streak_3.
  ///
  /// In en, this message translates to:
  /// **'Win 3 games in a row'**
  String get achievementDesc_streak_3;

  /// No description provided for @achievementDesc_streak_7.
  ///
  /// In en, this message translates to:
  /// **'Win 7 games in a row'**
  String get achievementDesc_streak_7;

  /// No description provided for @achievementDesc_streak_14.
  ///
  /// In en, this message translates to:
  /// **'Win 14 games in a row'**
  String get achievementDesc_streak_14;

  /// No description provided for @achievementDesc_streak_30.
  ///
  /// In en, this message translates to:
  /// **'Win 30 games in a row'**
  String get achievementDesc_streak_30;

  /// No description provided for @achievementDesc_speed_easy_3min.
  ///
  /// In en, this message translates to:
  /// **'Complete easy puzzle under 3 minutes'**
  String get achievementDesc_speed_easy_3min;

  /// No description provided for @achievementDesc_speed_medium_8min.
  ///
  /// In en, this message translates to:
  /// **'Complete medium puzzle under 8 minutes'**
  String get achievementDesc_speed_medium_8min;

  /// No description provided for @achievementDesc_speed_hard_15min.
  ///
  /// In en, this message translates to:
  /// **'Complete hard puzzle under 15 minutes'**
  String get achievementDesc_speed_hard_15min;

  /// No description provided for @achievementDesc_speed_expert_25min.
  ///
  /// In en, this message translates to:
  /// **'Complete expert puzzle under 25 minutes'**
  String get achievementDesc_speed_expert_25min;

  /// No description provided for @achievementDesc_easy_master.
  ///
  /// In en, this message translates to:
  /// **'Complete 200 easy puzzles'**
  String get achievementDesc_easy_master;

  /// No description provided for @achievementDesc_medium_master.
  ///
  /// In en, this message translates to:
  /// **'Complete 200 medium puzzles'**
  String get achievementDesc_medium_master;

  /// No description provided for @achievementDesc_hard_master.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 hard puzzles'**
  String get achievementDesc_hard_master;

  /// No description provided for @achievementDesc_expert_master.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 expert puzzles'**
  String get achievementDesc_expert_master;

  /// No description provided for @achievementDesc_expert_perfect.
  ///
  /// In en, this message translates to:
  /// **'Complete expert puzzle without mistakes'**
  String get achievementDesc_expert_perfect;

  /// No description provided for @achievementDesc_easy_5.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 easy puzzles'**
  String get achievementDesc_easy_5;

  /// No description provided for @achievementDesc_easy_10.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 easy puzzles'**
  String get achievementDesc_easy_10;

  /// No description provided for @achievementDesc_easy_50.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 easy puzzles'**
  String get achievementDesc_easy_50;

  /// No description provided for @achievementDesc_easy_100.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 easy puzzles'**
  String get achievementDesc_easy_100;

  /// No description provided for @achievementDesc_medium_5.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 medium puzzles'**
  String get achievementDesc_medium_5;

  /// No description provided for @achievementDesc_medium_10.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 medium puzzles'**
  String get achievementDesc_medium_10;

  /// No description provided for @achievementDesc_medium_50.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 medium puzzles'**
  String get achievementDesc_medium_50;

  /// No description provided for @achievementDesc_hard_5.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 hard puzzles'**
  String get achievementDesc_hard_5;

  /// No description provided for @achievementDesc_hard_20.
  ///
  /// In en, this message translates to:
  /// **'Complete 20 hard puzzles'**
  String get achievementDesc_hard_20;

  /// No description provided for @achievementDesc_expert_10.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 expert puzzles'**
  String get achievementDesc_expert_10;

  /// No description provided for @achievementDesc_days_7.
  ///
  /// In en, this message translates to:
  /// **'Play for 7 consecutive days'**
  String get achievementDesc_days_7;

  /// No description provided for @achievementDesc_days_30.
  ///
  /// In en, this message translates to:
  /// **'Play for 30 consecutive days'**
  String get achievementDesc_days_30;

  /// No description provided for @achievementDesc_days_365.
  ///
  /// In en, this message translates to:
  /// **'Play for a whole year'**
  String get achievementDesc_days_365;

  /// No description provided for @achievementDesc_daily_first.
  ///
  /// In en, this message translates to:
  /// **'Complete your first daily challenge'**
  String get achievementDesc_daily_first;

  /// No description provided for @achievementDesc_daily_7.
  ///
  /// In en, this message translates to:
  /// **'Complete 7 daily challenges'**
  String get achievementDesc_daily_7;

  /// No description provided for @achievementDesc_daily_14.
  ///
  /// In en, this message translates to:
  /// **'Complete 14 daily challenges'**
  String get achievementDesc_daily_14;

  /// No description provided for @achievementDesc_daily_30.
  ///
  /// In en, this message translates to:
  /// **'Complete 30 daily challenges'**
  String get achievementDesc_daily_30;

  /// No description provided for @achievementDesc_hints_10.
  ///
  /// In en, this message translates to:
  /// **'Use 10 hints total'**
  String get achievementDesc_hints_10;

  /// No description provided for @achievementDesc_hints_100.
  ///
  /// In en, this message translates to:
  /// **'Use 100 hints total'**
  String get achievementDesc_hints_100;

  /// No description provided for @achievementDesc_hints_500.
  ///
  /// In en, this message translates to:
  /// **'Use 500 hints total'**
  String get achievementDesc_hints_500;

  /// No description provided for @achievementDesc_hints_1000.
  ///
  /// In en, this message translates to:
  /// **'Use 1000 hints total'**
  String get achievementDesc_hints_1000;

  /// No description provided for @achievementDesc_king_5.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 16x16 puzzles'**
  String get achievementDesc_king_5;

  /// No description provided for @achievementDesc_king_20.
  ///
  /// In en, this message translates to:
  /// **'Complete 20 16x16 puzzles'**
  String get achievementDesc_king_20;

  /// No description provided for @achievement_ranked_first_win.
  ///
  /// In en, this message translates to:
  /// **'Ranked Rookie'**
  String get achievement_ranked_first_win;

  /// No description provided for @achievementDesc_ranked_first_win.
  ///
  /// In en, this message translates to:
  /// **'Win your first ranked game'**
  String get achievementDesc_ranked_first_win;

  /// No description provided for @achievement_ranked_win_10.
  ///
  /// In en, this message translates to:
  /// **'Ranked Fighter'**
  String get achievement_ranked_win_10;

  /// No description provided for @achievementDesc_ranked_win_10.
  ///
  /// In en, this message translates to:
  /// **'Win 10 ranked games'**
  String get achievementDesc_ranked_win_10;

  /// No description provided for @achievement_ranked_win_50.
  ///
  /// In en, this message translates to:
  /// **'Ranked Warrior'**
  String get achievement_ranked_win_50;

  /// No description provided for @achievementDesc_ranked_win_50.
  ///
  /// In en, this message translates to:
  /// **'Win 50 ranked games'**
  String get achievementDesc_ranked_win_50;

  /// No description provided for @achievement_ranked_win_100.
  ///
  /// In en, this message translates to:
  /// **'Ranked Veteran'**
  String get achievement_ranked_win_100;

  /// No description provided for @achievementDesc_ranked_win_100.
  ///
  /// In en, this message translates to:
  /// **'Win 100 ranked games'**
  String get achievementDesc_ranked_win_100;

  /// No description provided for @achievement_ranked_win_500.
  ///
  /// In en, this message translates to:
  /// **'Ranked Legend'**
  String get achievement_ranked_win_500;

  /// No description provided for @achievementDesc_ranked_win_500.
  ///
  /// In en, this message translates to:
  /// **'Win 500 ranked games'**
  String get achievementDesc_ranked_win_500;

  /// No description provided for @achievement_ranked_easy_5.
  ///
  /// In en, this message translates to:
  /// **'Easy Starter'**
  String get achievement_ranked_easy_5;

  /// No description provided for @achievementDesc_ranked_easy_5.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Easy ranked games'**
  String get achievementDesc_ranked_easy_5;

  /// No description provided for @achievement_ranked_easy_25.
  ///
  /// In en, this message translates to:
  /// **'Easy Expert'**
  String get achievement_ranked_easy_25;

  /// No description provided for @achievementDesc_ranked_easy_25.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Easy ranked games'**
  String get achievementDesc_ranked_easy_25;

  /// No description provided for @achievement_ranked_medium_5.
  ///
  /// In en, this message translates to:
  /// **'Medium Challenger'**
  String get achievement_ranked_medium_5;

  /// No description provided for @achievementDesc_ranked_medium_5.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Medium ranked games'**
  String get achievementDesc_ranked_medium_5;

  /// No description provided for @achievement_ranked_medium_25.
  ///
  /// In en, this message translates to:
  /// **'Medium Master'**
  String get achievement_ranked_medium_25;

  /// No description provided for @achievementDesc_ranked_medium_25.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Medium ranked games'**
  String get achievementDesc_ranked_medium_25;

  /// No description provided for @achievement_ranked_hard_5.
  ///
  /// In en, this message translates to:
  /// **'Hard Fighter'**
  String get achievement_ranked_hard_5;

  /// No description provided for @achievementDesc_ranked_hard_5.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Hard ranked games'**
  String get achievementDesc_ranked_hard_5;

  /// No description provided for @achievement_ranked_hard_25.
  ///
  /// In en, this message translates to:
  /// **'Hard Conqueror'**
  String get achievement_ranked_hard_25;

  /// No description provided for @achievementDesc_ranked_hard_25.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Hard ranked games'**
  String get achievementDesc_ranked_hard_25;

  /// No description provided for @achievement_ranked_expert_5.
  ///
  /// In en, this message translates to:
  /// **'Expert Warrior'**
  String get achievement_ranked_expert_5;

  /// No description provided for @achievementDesc_ranked_expert_5.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Expert ranked games'**
  String get achievementDesc_ranked_expert_5;

  /// No description provided for @achievement_ranked_expert_25.
  ///
  /// In en, this message translates to:
  /// **'Expert Legend'**
  String get achievement_ranked_expert_25;

  /// No description provided for @achievementDesc_ranked_expert_25.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Expert ranked games'**
  String get achievementDesc_ranked_expert_25;

  /// No description provided for @achievement_ranked_streak_3.
  ///
  /// In en, this message translates to:
  /// **'Hot Streak'**
  String get achievement_ranked_streak_3;

  /// No description provided for @achievementDesc_ranked_streak_3.
  ///
  /// In en, this message translates to:
  /// **'Win 3 ranked games in a row'**
  String get achievementDesc_ranked_streak_3;

  /// No description provided for @achievement_ranked_streak_5.
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get achievement_ranked_streak_5;

  /// No description provided for @achievementDesc_ranked_streak_5.
  ///
  /// In en, this message translates to:
  /// **'Win 5 ranked games in a row'**
  String get achievementDesc_ranked_streak_5;

  /// No description provided for @achievement_ranked_streak_10.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get achievement_ranked_streak_10;

  /// No description provided for @achievementDesc_ranked_streak_10.
  ///
  /// In en, this message translates to:
  /// **'Win 10 ranked games in a row'**
  String get achievementDesc_ranked_streak_10;

  /// No description provided for @achievement_ranked_silver.
  ///
  /// In en, this message translates to:
  /// **'Silver Rank'**
  String get achievement_ranked_silver;

  /// No description provided for @achievementDesc_ranked_silver.
  ///
  /// In en, this message translates to:
  /// **'Reach Silver division'**
  String get achievementDesc_ranked_silver;

  /// No description provided for @achievement_ranked_gold.
  ///
  /// In en, this message translates to:
  /// **'Gold Rank'**
  String get achievement_ranked_gold;

  /// No description provided for @achievementDesc_ranked_gold.
  ///
  /// In en, this message translates to:
  /// **'Reach Gold division'**
  String get achievementDesc_ranked_gold;

  /// No description provided for @achievement_ranked_platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum Rank'**
  String get achievement_ranked_platinum;

  /// No description provided for @achievementDesc_ranked_platinum.
  ///
  /// In en, this message translates to:
  /// **'Reach Platinum division'**
  String get achievementDesc_ranked_platinum;

  /// No description provided for @achievement_ranked_diamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond Rank'**
  String get achievement_ranked_diamond;

  /// No description provided for @achievementDesc_ranked_diamond.
  ///
  /// In en, this message translates to:
  /// **'Reach Diamond division'**
  String get achievementDesc_ranked_diamond;

  /// No description provided for @achievement_ranked_master.
  ///
  /// In en, this message translates to:
  /// **'Master Rank'**
  String get achievement_ranked_master;

  /// No description provided for @achievementDesc_ranked_master.
  ///
  /// In en, this message translates to:
  /// **'Reach Master division'**
  String get achievementDesc_ranked_master;

  /// No description provided for @achievement_ranked_grandmaster.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster'**
  String get achievement_ranked_grandmaster;

  /// No description provided for @achievementDesc_ranked_grandmaster.
  ///
  /// In en, this message translates to:
  /// **'Reach Grandmaster division'**
  String get achievementDesc_ranked_grandmaster;

  /// No description provided for @achievement_ranked_champion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get achievement_ranked_champion;

  /// No description provided for @achievementDesc_ranked_champion.
  ///
  /// In en, this message translates to:
  /// **'Reach Champion division'**
  String get achievementDesc_ranked_champion;

  /// No description provided for @achievement_ranked_perfect_expert_1.
  ///
  /// In en, this message translates to:
  /// **'Expert Perfection'**
  String get achievement_ranked_perfect_expert_1;

  /// No description provided for @achievementDesc_ranked_perfect_expert_1.
  ///
  /// In en, this message translates to:
  /// **'Win Expert ranked without mistakes'**
  String get achievementDesc_ranked_perfect_expert_1;

  /// No description provided for @achievement_ranked_perfect_expert_5.
  ///
  /// In en, this message translates to:
  /// **'Expert Master'**
  String get achievement_ranked_perfect_expert_5;

  /// No description provided for @achievementDesc_ranked_perfect_expert_5.
  ///
  /// In en, this message translates to:
  /// **'Win 5 perfect Expert ranked games'**
  String get achievementDesc_ranked_perfect_expert_5;

  /// No description provided for @achievement_ranked_perfect_expert_10.
  ///
  /// In en, this message translates to:
  /// **'Expert God'**
  String get achievement_ranked_perfect_expert_10;

  /// No description provided for @achievementDesc_ranked_perfect_expert_10.
  ///
  /// In en, this message translates to:
  /// **'Win 10 perfect Expert ranked games'**
  String get achievementDesc_ranked_perfect_expert_10;

  /// No description provided for @achievement_duel_first_win.
  ///
  /// In en, this message translates to:
  /// **'Duel Rookie'**
  String get achievement_duel_first_win;

  /// No description provided for @achievementDesc_duel_first_win.
  ///
  /// In en, this message translates to:
  /// **'Win your first duel'**
  String get achievementDesc_duel_first_win;

  /// No description provided for @achievement_duel_win_10.
  ///
  /// In en, this message translates to:
  /// **'Duel Fighter'**
  String get achievement_duel_win_10;

  /// No description provided for @achievementDesc_duel_win_10.
  ///
  /// In en, this message translates to:
  /// **'Win 10 duels'**
  String get achievementDesc_duel_win_10;

  /// No description provided for @achievement_duel_win_50.
  ///
  /// In en, this message translates to:
  /// **'Duel Warrior'**
  String get achievement_duel_win_50;

  /// No description provided for @achievementDesc_duel_win_50.
  ///
  /// In en, this message translates to:
  /// **'Win 50 duels'**
  String get achievementDesc_duel_win_50;

  /// No description provided for @achievement_duel_win_100.
  ///
  /// In en, this message translates to:
  /// **'Duel Veteran'**
  String get achievement_duel_win_100;

  /// No description provided for @achievementDesc_duel_win_100.
  ///
  /// In en, this message translates to:
  /// **'Win 100 duels'**
  String get achievementDesc_duel_win_100;

  /// No description provided for @achievement_duel_win_500.
  ///
  /// In en, this message translates to:
  /// **'Duel Legend'**
  String get achievement_duel_win_500;

  /// No description provided for @achievementDesc_duel_win_500.
  ///
  /// In en, this message translates to:
  /// **'Win 500 duels'**
  String get achievementDesc_duel_win_500;

  /// No description provided for @achievement_duel_streak_3.
  ///
  /// In en, this message translates to:
  /// **'Duel Hot Streak'**
  String get achievement_duel_streak_3;

  /// No description provided for @achievementDesc_duel_streak_3.
  ///
  /// In en, this message translates to:
  /// **'Win 3 duels in a row'**
  String get achievementDesc_duel_streak_3;

  /// No description provided for @achievement_duel_streak_5.
  ///
  /// In en, this message translates to:
  /// **'Duel On Fire'**
  String get achievement_duel_streak_5;

  /// No description provided for @achievementDesc_duel_streak_5.
  ///
  /// In en, this message translates to:
  /// **'Win 5 duels in a row'**
  String get achievementDesc_duel_streak_5;

  /// No description provided for @achievement_duel_streak_10.
  ///
  /// In en, this message translates to:
  /// **'Duel Unstoppable'**
  String get achievement_duel_streak_10;

  /// No description provided for @achievementDesc_duel_streak_10.
  ///
  /// In en, this message translates to:
  /// **'Win 10 duels in a row'**
  String get achievementDesc_duel_streak_10;

  /// No description provided for @achievement_duel_silver.
  ///
  /// In en, this message translates to:
  /// **'Silver Division'**
  String get achievement_duel_silver;

  /// No description provided for @achievementDesc_duel_silver.
  ///
  /// In en, this message translates to:
  /// **'Reach Silver (500 ELO)'**
  String get achievementDesc_duel_silver;

  /// No description provided for @achievement_duel_gold.
  ///
  /// In en, this message translates to:
  /// **'Gold Division'**
  String get achievement_duel_gold;

  /// No description provided for @achievementDesc_duel_gold.
  ///
  /// In en, this message translates to:
  /// **'Reach Gold (800 ELO)'**
  String get achievementDesc_duel_gold;

  /// No description provided for @achievement_duel_platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum Division'**
  String get achievement_duel_platinum;

  /// No description provided for @achievementDesc_duel_platinum.
  ///
  /// In en, this message translates to:
  /// **'Reach Platinum (1100 ELO)'**
  String get achievementDesc_duel_platinum;

  /// No description provided for @achievement_duel_diamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond Division'**
  String get achievement_duel_diamond;

  /// No description provided for @achievementDesc_duel_diamond.
  ///
  /// In en, this message translates to:
  /// **'Reach Diamond (1400 ELO)'**
  String get achievementDesc_duel_diamond;

  /// No description provided for @achievement_duel_master.
  ///
  /// In en, this message translates to:
  /// **'Master Division'**
  String get achievement_duel_master;

  /// No description provided for @achievementDesc_duel_master.
  ///
  /// In en, this message translates to:
  /// **'Reach Master (1700 ELO)'**
  String get achievementDesc_duel_master;

  /// No description provided for @achievement_duel_grandmaster.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster Division'**
  String get achievement_duel_grandmaster;

  /// No description provided for @achievementDesc_duel_grandmaster.
  ///
  /// In en, this message translates to:
  /// **'Reach Grandmaster (2000 ELO)'**
  String get achievementDesc_duel_grandmaster;

  /// No description provided for @achievement_duel_champion.
  ///
  /// In en, this message translates to:
  /// **'Champion Division'**
  String get achievement_duel_champion;

  /// No description provided for @achievementDesc_duel_champion.
  ///
  /// In en, this message translates to:
  /// **'Reach Champion (2300 ELO)'**
  String get achievementDesc_duel_champion;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'XP Earned'**
  String get xpEarned;

  /// No description provided for @levelUp.
  ///
  /// In en, this message translates to:
  /// **'Level Up!'**
  String get levelUp;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @seasonLevel.
  ///
  /// In en, this message translates to:
  /// **'Season Level'**
  String get seasonLevel;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @streakBonus.
  ///
  /// In en, this message translates to:
  /// **'Streak Bonus'**
  String get streakBonus;

  /// No description provided for @timeBonus.
  ///
  /// In en, this message translates to:
  /// **'Time Bonus'**
  String get timeBonus;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'days remaining'**
  String get daysRemaining;

  /// No description provided for @toNextLevel.
  ///
  /// In en, this message translates to:
  /// **'to next level'**
  String get toNextLevel;

  /// No description provided for @novice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get novice;

  /// No description provided for @amateur.
  ///
  /// In en, this message translates to:
  /// **'Amateur'**
  String get amateur;

  /// No description provided for @talented.
  ///
  /// In en, this message translates to:
  /// **'Talented'**
  String get talented;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @newRewards.
  ///
  /// In en, this message translates to:
  /// **'New Rewards!'**
  String get newRewards;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// No description provided for @gridStyle.
  ///
  /// In en, this message translates to:
  /// **'Grid Style'**
  String get gridStyle;

  /// No description provided for @gridStyleClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get gridStyleClassic;

  /// No description provided for @gridStyleClassicDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean and simple default style'**
  String get gridStyleClassicDesc;

  /// No description provided for @gridStyleOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get gridStyleOcean;

  /// No description provided for @gridStyleOceanDesc.
  ///
  /// In en, this message translates to:
  /// **'Calm ocean-inspired design'**
  String get gridStyleOceanDesc;

  /// No description provided for @gridStyleForest.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get gridStyleForest;

  /// No description provided for @gridStyleForestDesc.
  ///
  /// In en, this message translates to:
  /// **'Nature-inspired green theme'**
  String get gridStyleForestDesc;

  /// No description provided for @gridStyleMystic.
  ///
  /// In en, this message translates to:
  /// **'Mystic Purple'**
  String get gridStyleMystic;

  /// No description provided for @gridStyleMysticDesc.
  ///
  /// In en, this message translates to:
  /// **'Elegant purple design'**
  String get gridStyleMysticDesc;

  /// No description provided for @gridStyleAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get gridStyleAurora;

  /// No description provided for @gridStyleAuroraDesc.
  ///
  /// In en, this message translates to:
  /// **'Northern lights inspired'**
  String get gridStyleAuroraDesc;

  /// No description provided for @gridStyleGold.
  ///
  /// In en, this message translates to:
  /// **'Royal Gold'**
  String get gridStyleGold;

  /// No description provided for @gridStyleGoldDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium golden design'**
  String get gridStyleGoldDesc;

  /// No description provided for @gridStyleDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get gridStyleDiamond;

  /// No description provided for @gridStyleDiamondDesc.
  ///
  /// In en, this message translates to:
  /// **'Legendary diamond design'**
  String get gridStyleDiamondDesc;

  /// No description provided for @frames.
  ///
  /// In en, this message translates to:
  /// **'Frames'**
  String get frames;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effects;

  /// No description provided for @selectReward.
  ///
  /// In en, this message translates to:
  /// **'Select a reward'**
  String get selectReward;

  /// No description provided for @common.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get common;

  /// No description provided for @uncommon.
  ///
  /// In en, this message translates to:
  /// **'Uncommon'**
  String get uncommon;

  /// No description provided for @rare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rare;

  /// No description provided for @epic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get epic;

  /// No description provided for @legendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get legendary;

  /// No description provided for @themeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themeDefault;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get themeOcean;

  /// No description provided for @themeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get themeForest;

  /// No description provided for @themeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset Orange'**
  String get themeSunset;

  /// No description provided for @themeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight Dark'**
  String get themeMidnight;

  /// No description provided for @themeSakura.
  ///
  /// In en, this message translates to:
  /// **'Cherry Blossom'**
  String get themeSakura;

  /// No description provided for @themeRoyal.
  ///
  /// In en, this message translates to:
  /// **'Royal Purple'**
  String get themeRoyal;

  /// No description provided for @themeNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon Cyber'**
  String get themeNeon;

  /// No description provided for @themeGold.
  ///
  /// In en, this message translates to:
  /// **'Golden Luxury'**
  String get themeGold;

  /// No description provided for @themeDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond Elite'**
  String get themeDiamond;

  /// No description provided for @themeChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion\'s Glory'**
  String get themeChampion;

  /// No description provided for @themeChampionDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium warm gold theme for Masters'**
  String get themeChampionDesc;

  /// No description provided for @themeGrandmaster.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster Prestige'**
  String get themeGrandmaster;

  /// No description provided for @themeGrandmasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Ultra premium lavender theme for Champions'**
  String get themeGrandmasterDesc;

  /// No description provided for @frameBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get frameBasic;

  /// No description provided for @frameBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get frameBronze;

  /// No description provided for @frameSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get frameSilver;

  /// No description provided for @frameGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get frameGold;

  /// No description provided for @framePlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get framePlatinum;

  /// No description provided for @frameRainbow.
  ///
  /// In en, this message translates to:
  /// **'Rainbow'**
  String get frameRainbow;

  /// No description provided for @effectSparkle.
  ///
  /// In en, this message translates to:
  /// **'Sparkle'**
  String get effectSparkle;

  /// No description provided for @effectConfetti.
  ///
  /// In en, this message translates to:
  /// **'Confetti'**
  String get effectConfetti;

  /// No description provided for @effectStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get effectStars;

  /// No description provided for @effectFireworks.
  ///
  /// In en, this message translates to:
  /// **'Fireworks'**
  String get effectFireworks;

  /// No description provided for @effectAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get effectAurora;

  /// No description provided for @effectRoyal.
  ///
  /// In en, this message translates to:
  /// **'Royal Celebration'**
  String get effectRoyal;

  /// No description provided for @effectLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary Aura'**
  String get effectLegendary;

  /// No description provided for @themeDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'The classic Sudoku look'**
  String get themeDefaultDesc;

  /// No description provided for @themeOceanDesc.
  ///
  /// In en, this message translates to:
  /// **'Calm ocean vibes'**
  String get themeOceanDesc;

  /// No description provided for @themeForestDesc.
  ///
  /// In en, this message translates to:
  /// **'Peaceful forest colors'**
  String get themeForestDesc;

  /// No description provided for @themeSunsetDesc.
  ///
  /// In en, this message translates to:
  /// **'Warm sunset tones'**
  String get themeSunsetDesc;

  /// No description provided for @themeMidnightDesc.
  ///
  /// In en, this message translates to:
  /// **'Dark mode elegance'**
  String get themeMidnightDesc;

  /// No description provided for @themeSakuraDesc.
  ///
  /// In en, this message translates to:
  /// **'Beautiful cherry blossoms'**
  String get themeSakuraDesc;

  /// No description provided for @themeRoyalDesc.
  ///
  /// In en, this message translates to:
  /// **'Fit for royalty'**
  String get themeRoyalDesc;

  /// No description provided for @themeNeonDesc.
  ///
  /// In en, this message translates to:
  /// **'Cyberpunk aesthetic'**
  String get themeNeonDesc;

  /// No description provided for @themeGoldDesc.
  ///
  /// In en, this message translates to:
  /// **'Luxurious golden shine'**
  String get themeGoldDesc;

  /// No description provided for @themeDiamondDesc.
  ///
  /// In en, this message translates to:
  /// **'Ultimate prestige'**
  String get themeDiamondDesc;

  /// No description provided for @frameBasicDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple and clean'**
  String get frameBasicDesc;

  /// No description provided for @frameBronzeDesc.
  ///
  /// In en, this message translates to:
  /// **'Bronze medal frame'**
  String get frameBronzeDesc;

  /// No description provided for @frameSilverDesc.
  ///
  /// In en, this message translates to:
  /// **'Silver medal frame'**
  String get frameSilverDesc;

  /// No description provided for @frameGoldDesc.
  ///
  /// In en, this message translates to:
  /// **'Gold medal frame'**
  String get frameGoldDesc;

  /// No description provided for @framePlatinumDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium platinum frame'**
  String get framePlatinumDesc;

  /// No description provided for @frameRainbowDesc.
  ///
  /// In en, this message translates to:
  /// **'Legendary rainbow frame'**
  String get frameRainbowDesc;

  /// No description provided for @effectSparkleDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple sparkle effect'**
  String get effectSparkleDesc;

  /// No description provided for @effectConfettiDesc.
  ///
  /// In en, this message translates to:
  /// **'Colorful confetti celebration'**
  String get effectConfettiDesc;

  /// No description provided for @effectStarsDesc.
  ///
  /// In en, this message translates to:
  /// **'Falling stars effect'**
  String get effectStarsDesc;

  /// No description provided for @effectFireworksDesc.
  ///
  /// In en, this message translates to:
  /// **'Explosive fireworks'**
  String get effectFireworksDesc;

  /// No description provided for @effectAuroraDesc.
  ///
  /// In en, this message translates to:
  /// **'Northern lights effect'**
  String get effectAuroraDesc;

  /// No description provided for @effectRoyalDesc.
  ///
  /// In en, this message translates to:
  /// **'Royal celebration effect'**
  String get effectRoyalDesc;

  /// No description provided for @effectLegendaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Legendary aura effect'**
  String get effectLegendaryDesc;

  /// No description provided for @bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronze;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get platinum;

  /// No description provided for @diamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get diamond;

  /// No description provided for @grandmaster.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster'**
  String get grandmaster;

  /// No description provided for @champion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get champion;

  /// No description provided for @rankedDivisions.
  ///
  /// In en, this message translates to:
  /// **'Ranked Divisions'**
  String get rankedDivisions;

  /// No description provided for @climbTheRanks.
  ///
  /// In en, this message translates to:
  /// **'Climb the ranks and earn rewards!'**
  String get climbTheRanks;

  /// No description provided for @lossReward.
  ///
  /// In en, this message translates to:
  /// **'Loss Penalty'**
  String get lossReward;

  /// No description provided for @frame.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get frame;

  /// No description provided for @effect.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get effect;

  /// No description provided for @winXDuels.
  ///
  /// In en, this message translates to:
  /// **'Win {count} duels'**
  String winXDuels(int count);

  /// No description provided for @reachRankElo.
  ///
  /// In en, this message translates to:
  /// **'Reach {rank} ({elo} ELO)'**
  String reachRankElo(String rank, int elo);

  /// No description provided for @finishTopXInSeason.
  ///
  /// In en, this message translates to:
  /// **'Finish Top {position} in Season'**
  String finishTopXInSeason(int position);

  /// No description provided for @finishFirstInSeason.
  ///
  /// In en, this message translates to:
  /// **'Finish #1 in Season'**
  String get finishFirstInSeason;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play Now'**
  String get playNow;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRank;

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your Position'**
  String get yourPosition;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @gamesWon.
  ///
  /// In en, this message translates to:
  /// **'Games Won'**
  String get gamesWon;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @duelRewards.
  ///
  /// In en, this message translates to:
  /// **'Duel Rewards'**
  String get duelRewards;

  /// No description provided for @nextDivision.
  ///
  /// In en, this message translates to:
  /// **'Next Division'**
  String get nextDivision;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @division.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get division;

  /// No description provided for @equip.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get equip;

  /// No description provided for @equipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get equipped;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get defeat;

  /// No description provided for @promoted.
  ///
  /// In en, this message translates to:
  /// **'Promoted!'**
  String get promoted;

  /// No description provided for @demoted.
  ///
  /// In en, this message translates to:
  /// **'Demoted'**
  String get demoted;

  /// No description provided for @fastTime.
  ///
  /// In en, this message translates to:
  /// **'Fast time'**
  String get fastTime;

  /// No description provided for @winStreak.
  ///
  /// In en, this message translates to:
  /// **'Win Streak'**
  String get winStreak;

  /// No description provided for @keepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get keepItUp;

  /// No description provided for @newAchievements.
  ///
  /// In en, this message translates to:
  /// **'New Achievements'**
  String get newAchievements;

  /// No description provided for @firstBlood.
  ///
  /// In en, this message translates to:
  /// **'First Victory'**
  String get firstBlood;

  /// No description provided for @firstBloodDesc.
  ///
  /// In en, this message translates to:
  /// **'Win your first ranked game'**
  String get firstBloodDesc;

  /// No description provided for @warrior.
  ///
  /// In en, this message translates to:
  /// **'Warrior'**
  String get warrior;

  /// No description provided for @warriorDesc.
  ///
  /// In en, this message translates to:
  /// **'Win 10 ranked games'**
  String get warriorDesc;

  /// No description provided for @gladiator.
  ///
  /// In en, this message translates to:
  /// **'Gladiator'**
  String get gladiator;

  /// No description provided for @gladiatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Win 50 ranked games'**
  String get gladiatorDesc;

  /// No description provided for @lightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get lightning;

  /// No description provided for @lightningDesc.
  ///
  /// In en, this message translates to:
  /// **'Win 100 ranked games'**
  String get lightningDesc;

  /// No description provided for @inferno.
  ///
  /// In en, this message translates to:
  /// **'Inferno'**
  String get inferno;

  /// No description provided for @infernoDesc.
  ///
  /// In en, this message translates to:
  /// **'Win 250 ranked games'**
  String get infernoDesc;

  /// No description provided for @unstoppable.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get unstoppable;

  /// No description provided for @unstoppableDesc.
  ///
  /// In en, this message translates to:
  /// **'10 ranked wins in a row'**
  String get unstoppableDesc;

  /// No description provided for @perfectStorm.
  ///
  /// In en, this message translates to:
  /// **'Perfect Storm'**
  String get perfectStorm;

  /// No description provided for @perfectStormDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete Expert without mistakes'**
  String get perfectStormDesc;

  /// No description provided for @frameWarrior.
  ///
  /// In en, this message translates to:
  /// **'Warrior Frame'**
  String get frameWarrior;

  /// No description provided for @frameWarriorDesc.
  ///
  /// In en, this message translates to:
  /// **'Awarded for 10 ranked wins'**
  String get frameWarriorDesc;

  /// No description provided for @frameGladiator.
  ///
  /// In en, this message translates to:
  /// **'Gladiator Frame'**
  String get frameGladiator;

  /// No description provided for @frameGladiatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Awarded for 50 ranked wins'**
  String get frameGladiatorDesc;

  /// No description provided for @framePlatinumRanked.
  ///
  /// In en, this message translates to:
  /// **'Platinum Division Frame'**
  String get framePlatinumRanked;

  /// No description provided for @framePlatinumRankedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Platinum division'**
  String get framePlatinumRankedDesc;

  /// No description provided for @frameDiamondRanked.
  ///
  /// In en, this message translates to:
  /// **'Diamond Division Frame'**
  String get frameDiamondRanked;

  /// No description provided for @frameDiamondRankedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Diamond division'**
  String get frameDiamondRankedDesc;

  /// No description provided for @frameMasterRanked.
  ///
  /// In en, this message translates to:
  /// **'Master Division Frame'**
  String get frameMasterRanked;

  /// No description provided for @frameMasterRankedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Master division'**
  String get frameMasterRankedDesc;

  /// No description provided for @frameGrandmasterRanked.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster Frame'**
  String get frameGrandmasterRanked;

  /// No description provided for @frameGrandmasterRankedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Grandmaster division'**
  String get frameGrandmasterRankedDesc;

  /// No description provided for @frameChampionRanked.
  ///
  /// In en, this message translates to:
  /// **'Champion Frame'**
  String get frameChampionRanked;

  /// No description provided for @frameChampionRankedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Champion division'**
  String get frameChampionRankedDesc;

  /// No description provided for @frameTop50.
  ///
  /// In en, this message translates to:
  /// **'Top 50 Frame'**
  String get frameTop50;

  /// No description provided for @frameTop50Desc.
  ///
  /// In en, this message translates to:
  /// **'Finish season in Top 50'**
  String get frameTop50Desc;

  /// No description provided for @framePro.
  ///
  /// In en, this message translates to:
  /// **'Pro Frame'**
  String get framePro;

  /// No description provided for @frameProDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish season in Top 10'**
  String get frameProDesc;

  /// No description provided for @frameElite.
  ///
  /// In en, this message translates to:
  /// **'Elite Frame'**
  String get frameElite;

  /// No description provided for @frameEliteDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish season in Top 3'**
  String get frameEliteDesc;

  /// No description provided for @frameLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend Frame'**
  String get frameLegend;

  /// No description provided for @frameLegendDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish season as #1'**
  String get frameLegendDesc;

  /// No description provided for @effectLightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning Effect'**
  String get effectLightning;

  /// No description provided for @effectLightningDesc.
  ///
  /// In en, this message translates to:
  /// **'Electric celebration effect'**
  String get effectLightningDesc;

  /// No description provided for @effectInferno.
  ///
  /// In en, this message translates to:
  /// **'Inferno Effect'**
  String get effectInferno;

  /// No description provided for @effectInfernoDesc.
  ///
  /// In en, this message translates to:
  /// **'Fiery celebration effect'**
  String get effectInfernoDesc;

  /// No description provided for @effectMasterAura.
  ///
  /// In en, this message translates to:
  /// **'Master Aura'**
  String get effectMasterAura;

  /// No description provided for @effectMasterAuraDesc.
  ///
  /// In en, this message translates to:
  /// **'Golden master aura'**
  String get effectMasterAuraDesc;

  /// No description provided for @effectGrandmasterAura.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster Aura'**
  String get effectGrandmasterAura;

  /// No description provided for @effectGrandmasterAuraDesc.
  ///
  /// In en, this message translates to:
  /// **'Mystical purple aura'**
  String get effectGrandmasterAuraDesc;

  /// No description provided for @effectChampionAura.
  ///
  /// In en, this message translates to:
  /// **'Champion Aura'**
  String get effectChampionAura;

  /// No description provided for @effectChampionAuraDesc.
  ///
  /// In en, this message translates to:
  /// **'Legendary champion aura'**
  String get effectChampionAuraDesc;

  /// No description provided for @effectLegendAura.
  ///
  /// In en, this message translates to:
  /// **'Legend Aura'**
  String get effectLegendAura;

  /// No description provided for @effectLegendAuraDesc.
  ///
  /// In en, this message translates to:
  /// **'Ultimate legendary aura'**
  String get effectLegendAuraDesc;

  /// No description provided for @achievementRankedFirstWin.
  ///
  /// In en, this message translates to:
  /// **'Ranked Rookie'**
  String get achievementRankedFirstWin;

  /// No description provided for @achievementRankedFirstWinDesc.
  ///
  /// In en, this message translates to:
  /// **'Win your first ranked game'**
  String get achievementRankedFirstWinDesc;

  /// No description provided for @achievementRankedWin10.
  ///
  /// In en, this message translates to:
  /// **'Ranked Fighter'**
  String get achievementRankedWin10;

  /// No description provided for @achievementRankedWin10Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 10 ranked games'**
  String get achievementRankedWin10Desc;

  /// No description provided for @achievementRankedWin50.
  ///
  /// In en, this message translates to:
  /// **'Ranked Warrior'**
  String get achievementRankedWin50;

  /// No description provided for @achievementRankedWin50Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 50 ranked games'**
  String get achievementRankedWin50Desc;

  /// No description provided for @achievementRankedWin100.
  ///
  /// In en, this message translates to:
  /// **'Ranked Veteran'**
  String get achievementRankedWin100;

  /// No description provided for @achievementRankedWin100Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 100 ranked games'**
  String get achievementRankedWin100Desc;

  /// No description provided for @achievementRankedWin500.
  ///
  /// In en, this message translates to:
  /// **'Ranked Legend'**
  String get achievementRankedWin500;

  /// No description provided for @achievementRankedWin500Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 500 ranked games'**
  String get achievementRankedWin500Desc;

  /// No description provided for @achievementRankedEasy5.
  ///
  /// In en, this message translates to:
  /// **'Easy Starter'**
  String get achievementRankedEasy5;

  /// No description provided for @achievementRankedEasy5Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Easy ranked games'**
  String get achievementRankedEasy5Desc;

  /// No description provided for @achievementRankedEasy25.
  ///
  /// In en, this message translates to:
  /// **'Easy Expert'**
  String get achievementRankedEasy25;

  /// No description provided for @achievementRankedEasy25Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Easy ranked games'**
  String get achievementRankedEasy25Desc;

  /// No description provided for @achievementRankedMedium5.
  ///
  /// In en, this message translates to:
  /// **'Medium Challenger'**
  String get achievementRankedMedium5;

  /// No description provided for @achievementRankedMedium5Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Medium ranked games'**
  String get achievementRankedMedium5Desc;

  /// No description provided for @achievementRankedMedium25.
  ///
  /// In en, this message translates to:
  /// **'Medium Master'**
  String get achievementRankedMedium25;

  /// No description provided for @achievementRankedMedium25Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Medium ranked games'**
  String get achievementRankedMedium25Desc;

  /// No description provided for @achievementRankedHard5.
  ///
  /// In en, this message translates to:
  /// **'Hard Fighter'**
  String get achievementRankedHard5;

  /// No description provided for @achievementRankedHard5Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Hard ranked games'**
  String get achievementRankedHard5Desc;

  /// No description provided for @achievementRankedHard25.
  ///
  /// In en, this message translates to:
  /// **'Hard Conqueror'**
  String get achievementRankedHard25;

  /// No description provided for @achievementRankedHard25Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Hard ranked games'**
  String get achievementRankedHard25Desc;

  /// No description provided for @achievementRankedExpert5.
  ///
  /// In en, this message translates to:
  /// **'Expert Warrior'**
  String get achievementRankedExpert5;

  /// No description provided for @achievementRankedExpert5Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 5 Expert ranked games'**
  String get achievementRankedExpert5Desc;

  /// No description provided for @achievementRankedExpert25.
  ///
  /// In en, this message translates to:
  /// **'Expert Legend'**
  String get achievementRankedExpert25;

  /// No description provided for @achievementRankedExpert25Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 25 Expert ranked games'**
  String get achievementRankedExpert25Desc;

  /// No description provided for @achievementRankedStreak3.
  ///
  /// In en, this message translates to:
  /// **'Hot Streak'**
  String get achievementRankedStreak3;

  /// No description provided for @achievementRankedStreak3Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 3 ranked games in a row'**
  String get achievementRankedStreak3Desc;

  /// No description provided for @achievementRankedStreak5.
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get achievementRankedStreak5;

  /// No description provided for @achievementRankedStreak5Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 5 ranked games in a row'**
  String get achievementRankedStreak5Desc;

  /// No description provided for @achievementRankedStreak10.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get achievementRankedStreak10;

  /// No description provided for @achievementRankedStreak10Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 10 ranked games in a row'**
  String get achievementRankedStreak10Desc;

  /// No description provided for @achievementRankedStreak20.
  ///
  /// In en, this message translates to:
  /// **'Dominator'**
  String get achievementRankedStreak20;

  /// No description provided for @achievementRankedStreak20Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 20 ranked games in a row'**
  String get achievementRankedStreak20Desc;

  /// No description provided for @achievementRankedSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver Rank'**
  String get achievementRankedSilver;

  /// No description provided for @achievementRankedSilverDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Silver division'**
  String get achievementRankedSilverDesc;

  /// No description provided for @achievementRankedGold.
  ///
  /// In en, this message translates to:
  /// **'Gold Rank'**
  String get achievementRankedGold;

  /// No description provided for @achievementRankedGoldDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Gold division'**
  String get achievementRankedGoldDesc;

  /// No description provided for @achievementRankedPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum Rank'**
  String get achievementRankedPlatinum;

  /// No description provided for @achievementRankedPlatinumDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Platinum division'**
  String get achievementRankedPlatinumDesc;

  /// No description provided for @achievementRankedDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond Rank'**
  String get achievementRankedDiamond;

  /// No description provided for @achievementRankedDiamondDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Diamond division'**
  String get achievementRankedDiamondDesc;

  /// No description provided for @achievementRankedMaster.
  ///
  /// In en, this message translates to:
  /// **'Master Rank'**
  String get achievementRankedMaster;

  /// No description provided for @achievementRankedMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Master division'**
  String get achievementRankedMasterDesc;

  /// No description provided for @achievementRankedGrandmaster.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster'**
  String get achievementRankedGrandmaster;

  /// No description provided for @achievementRankedGrandmasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Grandmaster division'**
  String get achievementRankedGrandmasterDesc;

  /// No description provided for @achievementRankedChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get achievementRankedChampion;

  /// No description provided for @achievementRankedChampionDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach Champion division'**
  String get achievementRankedChampionDesc;

  /// No description provided for @achievementRankedPerfectExpert1.
  ///
  /// In en, this message translates to:
  /// **'Expert Perfection'**
  String get achievementRankedPerfectExpert1;

  /// No description provided for @achievementRankedPerfectExpert1Desc.
  ///
  /// In en, this message translates to:
  /// **'Win Expert ranked without mistakes'**
  String get achievementRankedPerfectExpert1Desc;

  /// No description provided for @achievementRankedPerfectExpert5.
  ///
  /// In en, this message translates to:
  /// **'Expert Master'**
  String get achievementRankedPerfectExpert5;

  /// No description provided for @achievementRankedPerfectExpert5Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 5 perfect Expert ranked games'**
  String get achievementRankedPerfectExpert5Desc;

  /// No description provided for @achievementRankedPerfectExpert10.
  ///
  /// In en, this message translates to:
  /// **'Expert God'**
  String get achievementRankedPerfectExpert10;

  /// No description provided for @achievementRankedPerfectExpert10Desc.
  ///
  /// In en, this message translates to:
  /// **'Win 10 perfect Expert ranked games'**
  String get achievementRankedPerfectExpert10Desc;

  /// No description provided for @seasonTop50.
  ///
  /// In en, this message translates to:
  /// **'Top 50'**
  String get seasonTop50;

  /// No description provided for @seasonTop50Desc.
  ///
  /// In en, this message translates to:
  /// **'Finish in the Top 50 at season end'**
  String get seasonTop50Desc;

  /// No description provided for @seasonTop10.
  ///
  /// In en, this message translates to:
  /// **'Top 10'**
  String get seasonTop10;

  /// No description provided for @seasonTop10Desc.
  ///
  /// In en, this message translates to:
  /// **'Finish in the Top 10 at season end'**
  String get seasonTop10Desc;

  /// No description provided for @seasonTop3.
  ///
  /// In en, this message translates to:
  /// **'Podium'**
  String get seasonTop3;

  /// No description provided for @seasonTop3Desc.
  ///
  /// In en, this message translates to:
  /// **'Finish in the Top 3 at season end'**
  String get seasonTop3Desc;

  /// No description provided for @seasonChampion.
  ///
  /// In en, this message translates to:
  /// **'Season Champion'**
  String get seasonChampion;

  /// No description provided for @seasonChampionDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish #1 at season end'**
  String get seasonChampionDesc;

  /// No description provided for @seasonChampionTitle.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get seasonChampionTitle;

  /// No description provided for @seasonEndBadge.
  ///
  /// In en, this message translates to:
  /// **'Season End'**
  String get seasonEndBadge;

  /// No description provided for @awardedAtSeasonEnd.
  ///
  /// In en, this message translates to:
  /// **'Awarded at season end'**
  String get awardedAtSeasonEnd;

  /// No description provided for @noMoveToUndo.
  ///
  /// In en, this message translates to:
  /// **'No move to undo!'**
  String get noMoveToUndo;

  /// No description provided for @cannotErase.
  ///
  /// In en, this message translates to:
  /// **'This cell cannot be erased!'**
  String get cannotErase;

  /// No description provided for @loadingAd.
  ///
  /// In en, this message translates to:
  /// **'Loading ad...'**
  String get loadingAd;

  /// No description provided for @hintUsedThanks.
  ///
  /// In en, this message translates to:
  /// **'Hint used! Thanks for watching.'**
  String get hintUsedThanks;

  /// No description provided for @adNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Ad not completed. Please try again.'**
  String get adNotCompleted;

  /// No description provided for @fastPencilOn.
  ///
  /// In en, this message translates to:
  /// **'Fast Pencil ON'**
  String get fastPencilOn;

  /// No description provided for @fastPencilOff.
  ///
  /// In en, this message translates to:
  /// **'Fast Pencil OFF'**
  String get fastPencilOff;

  /// No description provided for @fastPencil.
  ///
  /// In en, this message translates to:
  /// **'Fast Pencil'**
  String get fastPencil;

  /// No description provided for @gameXp.
  ///
  /// In en, this message translates to:
  /// **'Game XP'**
  String get gameXp;

  /// No description provided for @achievementBonus.
  ///
  /// In en, this message translates to:
  /// **'Achievement Bonus'**
  String get achievementBonus;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @watchFullAdToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please watch the full ad to continue.'**
  String get watchFullAdToContinue;

  /// No description provided for @secondChanceGranted.
  ///
  /// In en, this message translates to:
  /// **'Second chance granted! 1 life remaining.'**
  String get secondChanceGranted;

  /// No description provided for @xpBoost.
  ///
  /// In en, this message translates to:
  /// **'2x XP Boost'**
  String get xpBoost;

  /// No description provided for @performanceBonus.
  ///
  /// In en, this message translates to:
  /// **'Performance bonus'**
  String get performanceBonus;

  /// No description provided for @autoComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get autoComplete;

  /// No description provided for @autoCompleteNow.
  ///
  /// In en, this message translates to:
  /// **'Complete now!'**
  String get autoCompleteNow;

  /// No description provided for @botWins.
  ///
  /// In en, this message translates to:
  /// **'Bot Wins!'**
  String get botWins;

  /// No description provided for @resignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Resign?'**
  String get resignConfirm;

  /// No description provided for @resignButton.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resignButton;

  /// No description provided for @resignDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to resign? Your opponent will win this match.'**
  String get resignDescription;

  /// No description provided for @preparingBattle.
  ///
  /// In en, this message translates to:
  /// **'Preparing battle...'**
  String get preparingBattle;

  /// No description provided for @failedToCreateBattle.
  ///
  /// In en, this message translates to:
  /// **'Failed to create AI battle'**
  String get failedToCreateBattle;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get noConnection;

  /// No description provided for @noConnectionDuel.
  ///
  /// In en, this message translates to:
  /// **'An internet connection is required for matchmaking. Please check your connection and try again.'**
  String get noConnectionDuel;

  /// No description provided for @syncedAs.
  ///
  /// In en, this message translates to:
  /// **'Synced as'**
  String get syncedAs;

  /// No description provided for @watchFullAdForBonus.
  ///
  /// In en, this message translates to:
  /// **'Please watch the full ad to claim your bonus.'**
  String get watchFullAdForBonus;

  /// No description provided for @adLoadingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Ad is still loading. Please try again in a few seconds.'**
  String get adLoadingTryAgain;

  /// No description provided for @noPreviousPurchases.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found'**
  String get noPreviousPurchases;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @duel.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get duel;

  /// No description provided for @duelDivisions.
  ///
  /// In en, this message translates to:
  /// **'Duel Divisions'**
  String get duelDivisions;

  /// No description provided for @duelRules.
  ///
  /// In en, this message translates to:
  /// **'Duel Rules'**
  String get duelRules;

  /// No description provided for @duelRuleCompete.
  ///
  /// In en, this message translates to:
  /// **'Compete against opponents in real-time'**
  String get duelRuleCompete;

  /// No description provided for @duelRuleNoHints.
  ///
  /// In en, this message translates to:
  /// **'No hints or fast pencil available'**
  String get duelRuleNoHints;

  /// No description provided for @duelRuleElo.
  ///
  /// In en, this message translates to:
  /// **'Win to gain ELO, lose to drop'**
  String get duelRuleElo;

  /// No description provided for @duelRuleMistakes.
  ///
  /// In en, this message translates to:
  /// **'3 mistakes and you lose the duel'**
  String get duelRuleMistakes;

  /// No description provided for @duelWin.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get duelWin;

  /// No description provided for @duelLoss.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get duelLoss;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @newRating.
  ///
  /// In en, this message translates to:
  /// **'New Rating'**
  String get newRating;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @elo.
  ///
  /// In en, this message translates to:
  /// **'ELO'**
  String get elo;

  /// No description provided for @findingOpponent.
  ///
  /// In en, this message translates to:
  /// **'Finding Opponent'**
  String get findingOpponent;

  /// No description provided for @searchingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Searching for opponent...'**
  String get searchingForOpponent;

  /// No description provided for @expandingSearchRange.
  ///
  /// In en, this message translates to:
  /// **'Expanding search range...'**
  String get expandingSearchRange;

  /// No description provided for @lookingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Looking for available players...'**
  String get lookingForPlayers;

  /// No description provided for @stillSearching.
  ///
  /// In en, this message translates to:
  /// **'Still searching...'**
  String get stillSearching;

  /// No description provided for @couldNotFindOpponent.
  ///
  /// In en, this message translates to:
  /// **'Could not find an opponent. Please try again.'**
  String get couldNotFindOpponent;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @outOfLives.
  ///
  /// In en, this message translates to:
  /// **'Out of Lives!'**
  String get outOfLives;

  /// No description provided for @doubleYourXp.
  ///
  /// In en, this message translates to:
  /// **'Double Your XP!'**
  String get doubleYourXp;

  /// No description provided for @preparingPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Preparing puzzle...'**
  String get preparingPuzzle;

  /// No description provided for @unlimitedFastPencil.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Fast Pencil'**
  String get unlimitedFastPencil;

  /// No description provided for @puzzleSolved.
  ///
  /// In en, this message translates to:
  /// **'You solved the puzzle!'**
  String get puzzleSolved;

  /// No description provided for @xpBonusClaimed.
  ///
  /// In en, this message translates to:
  /// **'+50 XP bonus claimed!'**
  String get xpBonusClaimed;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequired;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @welcomeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium!'**
  String get welcomeToPremium;

  /// No description provided for @startPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start Playing!'**
  String get startPlaying;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get Ready!'**
  String get getReady;

  /// No description provided for @frameEquipped.
  ///
  /// In en, this message translates to:
  /// **'Frame selected'**
  String get frameEquipped;

  /// No description provided for @themeApplied.
  ///
  /// In en, this message translates to:
  /// **'Theme applied'**
  String get themeApplied;

  /// No description provided for @currentScore.
  ///
  /// In en, this message translates to:
  /// **'Current Score'**
  String get currentScore;

  /// No description provided for @syncingData.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncingData;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your data including progress, achievements, and statistics. This action cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountFinalConfirm.
  ///
  /// In en, this message translates to:
  /// **'This is your last chance!'**
  String get deleteAccountFinalConfirm;

  /// No description provided for @deleteAccountFinalWarning.
  ///
  /// In en, this message translates to:
  /// **'All your progress, level, achievements, premium subscription, and game data will be permanently lost. Are you absolutely sure?'**
  String get deleteAccountFinalWarning;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;
}

class _GenLocalizationsDelegate
    extends LocalizationsDelegate<GenLocalizations> {
  const _GenLocalizationsDelegate();

  @override
  Future<GenLocalizations> load(Locale locale) {
    return SynchronousFuture<GenLocalizations>(lookupGenLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'en',
        'es',
        'fr',
        'hi',
        'ja',
        'pt',
        'ru',
        'tr',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_GenLocalizationsDelegate old) => false;
}

GenLocalizations lookupGenLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return GenLocalizationsAr();
    case 'bn':
      return GenLocalizationsBn();
    case 'en':
      return GenLocalizationsEn();
    case 'es':
      return GenLocalizationsEs();
    case 'fr':
      return GenLocalizationsFr();
    case 'hi':
      return GenLocalizationsHi();
    case 'ja':
      return GenLocalizationsJa();
    case 'pt':
      return GenLocalizationsPt();
    case 'ru':
      return GenLocalizationsRu();
    case 'tr':
      return GenLocalizationsTr();
    case 'zh':
      return GenLocalizationsZh();
  }

  throw FlutterError(
      'GenLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
