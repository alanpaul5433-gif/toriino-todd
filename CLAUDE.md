# Toriino Todd — Project Instructions

## Project Overview
Toriino is a Flutter EdTech/mentorship platform connecting **Students**, **Teachers**, and **Mentors**. The app uses **GetX MVVM** architecture with an **AWS backend** (Cognito, API Gateway, Lambda, DynamoDB, S3, AppSync).

## Tech Stack
- **Framework:** Flutter (Dart SDK ^3.7.2)
- **State Management:** GetX (package `get: ^4.7.2`) — do NOT use Provider
- **Architecture:** MVVM — Model / View / ViewModel (GetxController) / Repository
- **Backend:** AWS (Cognito Auth, API Gateway REST, Lambda, DynamoDB, S3, AppSync)
- **Local Storage:** FlutterSecureStorage for tokens, SharedPreferences for non-sensitive prefs
- **UI:** Material Design 3, ScreenUtil (375x812 design size), Google Fonts, Flutter SVG
- **Package Name:** `com.craft.t` (Android), imports use `package:getxmvvm/`

## Project Structure
```
lib/
├── data/
│   ├── appURL/app_url.dart          # All API endpoint URLs
│   ├── network/
│   │   ├── base_api_services.dart   # Abstract HTTP contract
│   │   ├── network_api_services.dart # HTTP implementation (GET/POST/PUT/DELETE/PATCH)
│   │   └── auth_interceptor.dart    # Auth header injection (to create)
│   ├── response/
│   │   ├── api_response.dart        # Generic ApiResponse<T> wrapper (loading/success/error)
│   │   └── status.dart              # Status enum
│   └── app_exception.dart           # Exception hierarchy
├── model/                           # Data models with fromJson/toJson
│   └── login/User_model.dart        # Currently only model
├── repository/                      # Repos call NetworkApiServices
│   └── login_repo.dart              # Currently only repo
├── viewmodel/
│   ├── controller/                  # GetxControllers per feature
│   │   └── login/login_viewmodel.dart
│   └── services/splash_services.dart
├── view/
│   ├── auth/                        # Splash, Login, Signup, Role Selection
│   └── users/
│       ├── student_view/            # ~25 student screens
│       ├── teacher/                 # ~15 teacher screens
│       ├── mentor_view/             # ~15 mentor screens
│       └── common_view/            # Privacy policy, shared views
├── widgets/                         # Reusable UI components
├── resources/
│   ├── colors/app_colors.dart
│   ├── fonts/app_fonts.dart
│   ├── assets/assets_images.dart
│   ├── routes/routes.dart           # GetPage route definitions
│   ├── routes/routes_name.dart      # Route name constants
│   ├── getx_localization/language.dart # EN/UR translations
│   └── padding.dart
├── utils/
│   ├── utils.dart                   # Toast, snackbar, focus utilities
│   └── responsive.dart
└── getx_controllers/
    └── advanceddrawercontroller.dart # Drawer + bottom nav index
```

## Coding Conventions

### Naming
- Files: `snake_case.dart` (some legacy files use PascalCase — standardize when modifying)
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Route names: `static const String` in `RoutesName` class
- API URLs: `static const String` in `AppUrl` class

### State Management Pattern
```dart
// ViewModel pattern — every feature controller follows this:
class XxxViewmodel extends GetxController {
  final _repo = XxxRepo();
  final rxData = Rx<ApiResponse<XxxModel>>(ApiResponse.loading());

  void fetchData() {
    rxData.value = ApiResponse.loading();
    _repo.getData().then((value) {
      rxData.value = ApiResponse.success(value);
    }).onError((error, _) {
      rxData.value = ApiResponse.error(error.toString());
    });
  }
}
```

### View Binding Pattern
```dart
// Wrap dynamic data in Obx():
Obx(() {
  switch (controller.rxData.value.status) {
    case Status.loading: return ShimmerWidget();
    case Status.error: return ErrorStateWidget(onRetry: controller.fetchData);
    case Status.success: return ContentWidget(data: controller.rxData.value.data);
  }
})
```

### Navigation
- Use `Get.toNamed(RoutesName.xxx)` — never raw `Navigator.push`
- Define all routes in `lib/resources/routes/routes.dart`
- Add constants to `lib/resources/routes/routes_name.dart`

### API Calls
- All HTTP goes through `NetworkApiServices` — never call `http` directly from views
- Repos wrap network calls and parse JSON into models
- ViewModels call repos and expose `Rx<ApiResponse<T>>`
- Auth headers injected via `auth_interceptor.dart`
- S3 uploads use Lambda-generated presigned URLs — never embed AWS creds in Flutter

### Error Handling
- Network errors throw `AppException` subclasses (InternetException, RequestTimeOut, ServerException)
- Views show `GernernalException` widget on API errors, `InternetExcepetion` on connectivity issues
- All API responses wrapped in `ApiResponse<T>` for consistent loading/success/error states

## Known Bugs (to fix)
1. `lib/viewmodel/controller/login/login_viewmodel.dart:24` — password reads `emailController.value.text` instead of `passwordController`
2. `lib/repository/login_repo.dart:16` — orphan `Map<String,String>;` statement
3. `lib/view/auth/role_selector_view.dart:19` — default role is `"Fighter"` (stale)
4. `lib/view/auth/sign_up_view.dart:33-39` — `dispose()` commented out, leaks controllers
5. `pubspec.yaml:49` — `provider` package imported but unused (remove it)

## Current Status
- **Auth:** Login/Signup UI exists but API calls are commented out
- **Views:** All ~90 screens are static UI mockups with hardcoded data
- **Data Layer:** Only UserModel, LoginRepo, LoginViewmodel exist
- **Network:** GET/POST work; PUT/DELETE throw UnimplementedError
- **AI Tutor:** Placeholder UI only (deferred)
- **Payments:** Mock dialogs only (deferred)
- **Tests:** None beyond default scaffold

## Build & Run
```bash
cd toriino-splash
flutter pub get
flutter run
```

## Do NOT
- Use Provider — the app uses GetX exclusively
- Embed AWS credentials in Flutter code
- Use `Navigator.push` — use `Get.toNamed()`
- Add AI Tutor or Payment integration (deferred)
- Create new files for one-time operations — use existing patterns
