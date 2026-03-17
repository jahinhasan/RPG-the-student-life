import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/attendance_entry_screen.dart';
import 'screens/marks_entry_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/avatar_customization_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/ai_mentor_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/world_map_screen.dart';
import 'screens/battle_arena_screen.dart';
import 'screens/mini_games_screen.dart';
import 'screens/world_scene_screen.dart';
import 'screens/games/game_mode_screens.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/student_onboarding_screen.dart';
import 'screens/survival_arena_screen.dart';
import 'screens/unity_bridge_screen.dart';

class AppRoutes {
  static const String initial = '/role-selection';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String studentHome = '/studentHome';
  static const String teacherDashboard = '/teacherDashboard';
  static const String adminPanel = '/admin';
  static const String studentOnboarding = '/student-onboarding';
  
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherMarks = '/teacher/marks';
  
  static const String notifications = '/notifications';
  static const String leaderboard = '/leaderboard';
  static const String missions = '/missions';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String avatarCustomization = '/avatar-customization';
  static const String editProfile = '/edit-profile';
  static const String aiMentor = '/ai-mentor';
  static const String worldMap = '/world-map';
  static const String worldScene = '/world-scene';
  static const String battleArena = '/battleArena';
  static const String miniGames = '/mini-games';
  static const String quizBattleGame = '/mini-games/quiz-battle';
  static const String speedMathGame = '/mini-games/speed-math';
  static const String wordScrambleGame = '/mini-games/word-scramble';
  static const String memoryMatchGame = '/mini-games/memory-match';
  static const String ticTacTriviaGame = '/mini-games/tic-tac-trivia';
  static const String teamRaidGame = '/mini-games/team-raid';
  static const String survivalArena = '/survival-arena';
  static const String unityBridge = '/unity-bridge';

  static Map<String, WidgetBuilder> get routes => {
      initial: (context) => const RoleSelectionScreen(),
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        studentHome: (context) => const StudentHomeScreen(),
        teacherDashboard: (context) => const TeacherDashboardScreen(),
        adminPanel: (context) => const AdminPanelScreen(),
        studentOnboarding: (context) => const StudentOnboardingScreen(),
        teacherAttendance: (context) => const AttendanceEntryScreen(),
        teacherMarks: (context) => const MarksEntryScreen(),
        notifications: (context) => const NotificationCenterScreen(),
        leaderboard: (context) => const LeaderboardScreen(),
        missions: (context) => const MissionsScreen(),
        profile: (context) => const ProfileScreen(),
        settings: (context) => const SettingsScreen(),
        avatarCustomization: (context) => const AvatarCustomizationScreen(),
        editProfile: (context) => const EditProfileScreen(),
        aiMentor: (context) => const AIMentorScreen(),
        worldMap: (context) => const WorldMapScreen(),
        worldScene: (context) => const WorldSceneScreen(),
        battleArena: (context) => const BattleArenaScreen(),
        miniGames: (context) => const MiniGamesScreen(),
        quizBattleGame: (context) => const QuizBattleGameScreen(),
        speedMathGame: (context) => const SpeedMathGameScreen(),
        wordScrambleGame: (context) => const WordScrambleGameScreen(),
        memoryMatchGame: (context) => const MemoryMatchGameScreen(),
        ticTacTriviaGame: (context) => const TicTacTriviaGameScreen(),
        teamRaidGame: (context) => const TeamRaidGameScreen(),
        survivalArena: (context) => const SurvivalArenaScreen(),
        unityBridge: (context) => const UnityBridgeScreen(),
      };
}
