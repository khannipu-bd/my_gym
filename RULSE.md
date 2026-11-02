# RULES
Project Gym Management App (Flutter, Android).

STACK
- State: flutter_riverpod (ConsumerWidget & ConsumerStatefulWidget). Use ref.watch inside build, ref.read inside callbacks. Do NOT use standard Provider, BLoC, or GetX.
- Architecture: Clean Architecture, feature-first. Structure: core/ (services, constants), features/<feature_name>/ (presentation, domain, data).
- Backend: Firebase (firebase_auth, cloud_firestore, firebase_core).
- In-App OTA Update: ota_update with package_info_plus. Config fetched dynamically via Firestore.
- Storage & Config: Firestore for dynamic app configurations, notices, diets, and user records.

LAYER RULES
- core/services: houses cross-cutting singleton logic like AppUpdateService. No UI layouts here.
- presentation/views: handles UI layouts, drawers, dialogues, and screens. 
- presentation/controllers: manages Riverpod state logic, user sessions, and business actions.
- data: handles Firestore snapshots, collections, queries, and direct database transforms.
- Keep widget files modular. Separate custom drawer logic, dialogs, and repetitive cards into reusable private widgets or components.

BUSINESS & OTA UPDATE RULES
- Firestore path for OTA config: `app_config/latest_version`.
- Document fields: `latestBuildNumber` (int), `apkUrl` (string), `isForceUpdate` (bool).
- APK Direct Links:
  - Dropbox: Always ensure URLs use `dl=1` (replace `dl=0`).
  - Google Drive: Extract File ID and map to `https://drive.google.com/uc?export=download&id={id}&confirm=t`.
- Never bypass the `FileProvider` authority: `${applicationId}.ota_update.provider` with class `sk.styk.martin.otaupdate.OtaUpdateFileProvider`.
- Check for updates using `WidgetsBinding.instance.addPostFrameCallback` inside `initState` on root dashboard screens (UserHomeView, AdminDashboardView).

STYLE & THEME RULES
- Dark aesthetic is mandatory across all screens and dialogues.
  - Scaffold background: `Color(0xFF12141C)`
  - Cards, Sheets & Dialogs: `Color(0xFF1A1D29)`
  - Accents: `Colors.blueAccent`, `Colors.purpleAccent`, `Colors.greenAccent`, `Colors.redAccent`
- Border radius: use consistent `BorderRadius.circular(16)` for dialogs, cards, and input fields.
- Typography: contrast text colors (`Colors.white`, `Colors.white70`, `Colors.grey`). No pure black text anywhere.
- Prevent layout overflows: wrap dynamic vertical screen bodies inside `SingleChildScrollView` with `BouncingScrollPhysics`.

SAFETY & WORKFLOW
- Always verify `if (context.mounted)` before navigating, displaying SnackBars, or opening Dialogs after async gaps.
- Safe Firestore casting: guard against null fields using fallback defaults (e.g., `int.tryParse(...) ?? 0`, `data['field'] ?? ''`).
- Do only the exact task requested.
- State which files were modified and detail any prerequisite setup. Then STOP.