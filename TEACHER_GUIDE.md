# Teacher Guide - Student Life RPG Project

This repository contains the Flutter app for Student Life RPG.

## What Is In This Repository

- Flutter application source code
- Firebase app integration files
- Feature-based clean architecture screen structure

## Main Folder Map (Inside This Repo)

- `lib/main.dart`: App entry point
- `lib/routes.dart`: Route names and route-to-screen mapping
- `lib/features/`: Feature-first structure
- `lib/features/auth/presentation/screens/`: Login, register, splash, role selection
- `lib/features/student/presentation/screens/`: Student screens
- `lib/features/teacher/presentation/screens/`: Teacher screens
- `lib/features/admin/presentation/screens/`: Admin screens
- `lib/services/`: Shared service layer (current implementation)
- `lib/constants/`: Constants and enums
- `firestore.rules`: Firebase security rules
- `firestore.indexes.json`: Firestore indexes

## Clean Architecture Note

Current structure follows feature-first organization:

- `presentation`: UI and widgets
- `domain`: reserved for use-cases/entities
- `data`: reserved for repositories/data sources

This keeps each role and feature grouped and easier to review.

## Important Related Folders In Local Workspace (Outside This Repo)

These folders exist on local machine but are not part of this Flutter repo by default:

- `../com.unity.multiplayer.samples.coop`: Unity game project
- `../RpgTheStudentLifeFigmaUI`: Figma UI web project
- `../firebase_unity_sdk`: Firebase Unity SDK package files

## How To Run Flutter App

1. Open the `rpg_student_life` folder in VS Code.
2. Run `flutter pub get`.
3. Start with `flutter run`.

## What Teacher Should Review First

1. `lib/ARCHITECTURE.md` for structure overview.
2. `lib/routes.dart` for complete screen navigation map.
3. `lib/features/student/presentation/screens/student_home_screen.dart` for student main flow.
4. `lib/features/teacher/presentation/screens/teacher_dashboard_screen.dart` for teacher flow.
5. `lib/features/admin/presentation/screens/admin_panel_screen.dart` for admin tools.

## Notes For Submission

- This GitHub repository is the Flutter app repository.
- Unity and Figma projects are separate projects and can be submitted as separate repositories if needed.
