# Flutter Development Guidelines

Guidelines for building beautiful, performant, and maintainable Flutter
applications in Dart, targeting mobile, web, and desktop.

## Interacting with the User

- **Assume programming fluency, explain Dart specifics.** Assume the user knows
  general programming concepts but may be new to Dart. When generating code,
  briefly explain Dart-specific features such as null safety, `Future`s, and
  `Stream`s.
- **Clarify ambiguity.** If a request is unclear, ask about the intended
  functionality and target platform (command-line, web, mobile, desktop) before
  writing code.
- **Justify dependencies.** When suggesting a new package from pub.dev, explain
  its benefits and why it is the most suitable, stable choice.

## Tooling & Commands

- **Format code:** Run `dart format` on every change to keep formatting
  consistent.
- **Analyze:** Run `dart analyze` against the configured `analysis_options.yaml`
  to catch common issues, and fix what it reports.
- **Auto-fix:** Run `dart fix --apply` to resolve many common lint and analysis
  issues mechanically.
- **Manage packages** with `flutter pub`:
  - Add a dependency: `flutter pub add <package>`
  - Add a dev dependency: `flutter pub add dev:<package>`
  - Add an override: `flutter pub add override:<package>:1.0.0`
  - Remove a dependency: `flutter pub remove <package>`
  - Search [pub.dev](https://pub.dev) to identify the most suitable package
    before adding it.
- **Run tests:** `flutter test`.
- **Code generation:** If the project uses code generation, keep `build_runner`
  as a dev dependency and, after editing files that require codegen, run:

  ```shell
  dart run build_runner build --delete-conflicting-outputs
  ```

## Project Structure

- **Standard structure:** Assume a standard Flutter project with
  `lib/main.dart` as the primary application entry point.
- **Separation of concerns:** Organize the app like MVC/MVVM, with defined
  Model, View, and ViewModel/Controller roles.
- **Logical layers:** Split the project into logical layers:
  - **Presentation** — widgets, screens
  - **Domain** — business-logic classes
  - **Data** — model classes, API clients
  - **Core** — shared classes, utilities, and extension types
- **Feature-based organization:** For larger projects, organize code by feature,
  where each feature has its own presentation, domain, and data subfolders. This
  improves navigability and scalability.

## Code Style

- **Apply SOLID** principles throughout the codebase.
- **Be concise and declarative.** Write modern, technical Dart. Prefer functional
  and declarative patterns, and write the shortest code that remains clear.
- **Prefer composition over inheritance** when building complex widgets and
  logic.
- **Favor immutability.** Use immutable data structures; widgets (especially
  `StatelessWidget`) are immutable.
- **Keep UI and business logic separate.**
- **Name things meaningfully.** Avoid abbreviations; use consistent, descriptive
  names for variables, functions, and classes.
- **Keep it simple.** Clever or obscure code is hard to maintain.
- **Anticipate errors.** Handle potential errors; never let code fail silently.
- **Styling:**
  - Line length: 80 characters or fewer.
  - `PascalCase` for classes; `camelCase` for members, variables, functions, and
    enums; `snake_case` for files.
- **Functions:** Keep them short and single-purpose — strive for fewer than 20
  lines.
- **Write for testability.** Use the `file`, `process`, and `platform` packages
  where appropriate so you can inject in-memory and fake versions of objects.

## Dart Best Practices

- **Follow Effective Dart** (https://dart.dev/effective-dart).
- **Class organization:** Define related classes within the same library file.
  For large libraries, export smaller, private libraries from a single top-level
  library.
- **Library organization:** Group related libraries in the same folder.
- **Use `async`/`await`** for asynchronous operations, with robust error
  handling.
  - Use `Future`s, `async`, and `await` for asynchronous operations.
  - Use `Stream`s for sequences of asynchronous events.
- **Be soundly null-safe.** Leverage Dart's null safety and avoid `!` unless the
  value is guaranteed non-null.
- **Use pattern matching** where it simplifies the code.
- **Use records** to return multiple values when defining a whole class would be
  cumbersome.
- **Prefer exhaustive `switch`** statements or expressions, which need no
  `break`.
- **Handle exceptions precisely.** Use `try`/`catch` with exception types
  appropriate to the case, and define custom exceptions for situations specific
  to your code.
- **Use arrow syntax** (`=>`) for simple one-line functions.

## Flutter Best Practices

- **Widgets are immutable.** When the UI needs to change, Flutter rebuilds the
  widget tree — do not mutate widgets in place.
- **Compose, don't extend.** Prefer composing smaller widgets over subclassing
  existing ones; this also avoids deep widget nesting.
- **Prefer private widget classes** over private helper methods that return a
  `Widget`.
- **Break up large `build()` methods** into smaller, reusable private widget
  classes.
- **Use `ListView.builder` or `SliverList`** for long lists to lazy-load items
  for performance.
- **Offload expensive work** with `compute()` to run it in a separate isolate
  (e.g. JSON parsing) and avoid blocking the UI thread.
- **Use `const` constructors** for widgets and inside `build()` whenever
  possible to reduce rebuilds.
- **Keep `build()` cheap.** Avoid expensive operations such as network calls or
  complex computations directly inside `build()`.

## State Management

- **Prefer built-in solutions.** Use Flutter's built-in state management; do not
  add a third-party package unless explicitly requested.
- **`Stream`s:** Use `Stream`s and `StreamBuilder` for a sequence of
  asynchronous events.
- **`Future`s:** Use `Future`s and `FutureBuilder` for a single asynchronous
  operation that completes in the future.
- **`ValueNotifier`:** Use `ValueNotifier` with `ValueListenableBuilder` for
  simple, local state involving a single value.

  ```dart
  // Define a ValueNotifier to hold the state.
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  // Use ValueListenableBuilder to listen and rebuild.
  ValueListenableBuilder<int>(
    valueListenable: _counter,
    builder: (context, value, child) {
      return Text('Count: $value');
    },
  );
  ```

- **`ChangeNotifier`:** For more complex state or state shared across multiple
  widgets.
- **`ListenableBuilder`:** Use to listen to a `ChangeNotifier` or other
  `Listenable`.
- **MVVM:** When a more robust structure is needed, use the
  Model-View-ViewModel pattern.
- **Dependency injection:** Use simple manual constructor injection to make a
  class's dependencies explicit in its API and to manage dependencies between
  layers.
- **`provider`:** Only if a DI solution beyond manual constructor injection is
  explicitly requested, `provider` can expose services, repositories, or complex
  state objects to the UI without tight coupling.

### Data Flow

- **Define data structures** (classes) to represent the data used in the app.
- **Abstract data sources** (API calls, database operations) behind
  Repositories/Services to promote testability.

## Navigation & Routing

- **Use `go_router`** for declarative navigation, deep linking, and web support.
  Add it with `flutter pub add go_router`, then configure it:

  ```dart
  // 1. Add the dependency
  // flutter pub add go_router

  // 2. Configure the router
  final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'details/:id', // Route with a path parameter
            builder: (context, state) {
              final String id = state.pathParameters['id']!;
              return DetailScreen(id: id);
            },
          ),
        ],
      ),
    ],
  );

  // 3. Use it in your MaterialApp
  MaterialApp.router(
    routerConfig: _router,
  );
  ```

- **Authentication redirects:** Configure `go_router`'s `redirect` property to
  handle auth flows — redirect unauthorized users to login, then back to their
  intended destination after login.
- **Use the built-in `Navigator`** for short-lived screens that do not need deep
  linking, such as dialogs or temporary views.

  ```dart
  // Push a new screen onto the stack
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const DetailsScreen()),
  );

  // Pop the current screen to go back
  Navigator.pop(context);
  ```

## Data Handling & Serialization

- **Use `json_serializable` and `json_annotation`** to parse and encode JSON.
- **Rename fields** with `fieldRename: FieldRename.snake` to convert Dart's
  camelCase fields to snake_case JSON keys.

  ```dart
  // In your model file
  import 'package:json_annotation/json_annotation.dart';

  part 'user.g.dart';

  @JsonSerializable(fieldRename: FieldRename.snake)
  class User {
    final String firstName;
    final String lastName;

    User({required this.firstName, required this.lastName});

    factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
    Map<String, dynamic> toJson() => _$UserToJson(this);
  }
  ```

## Logging

- **Never use `print`** for diagnostic output.
- **Use `dart:developer`'s `log()`** for structured logging that integrates with
  Dart DevTools.

  ```dart
  import 'dart:developer' as developer;

  // For simple messages
  developer.log('User logged in successfully.');

  // For structured error logging
  try {
    // ... code that might fail
  } catch (e, s) {
    developer.log(
      'Failed to fetch data',
      name: 'myapp.network',
      level: 1000, // SEVERE
      error: e,
      stackTrace: s,
    );
  }
  ```

- **Consider the `logging` package** when you need leveled, hierarchical logging
  across the whole application.

## API Design

When building reusable APIs (e.g. a library), follow these principles.

- **Design for the user.** Build APIs from the perspective of the person using
  them; they should be intuitive and easy to use correctly.
- **Documentation is essential.** Good docs are part of good API design — clear,
  concise, and include examples.

## Testing

- **Run tests** with `flutter test`.
- **Unit tests:** Use `package:test`.
- **Widget tests:** Use `package:flutter_test`.
- **Integration tests:** Use `package:integration_test` from the Flutter SDK; add
  it as a dev dependency with `sdk: flutter`.

### Testing Best Practices

- **Follow Arrange-Act-Assert** (or Given-When-Then).
- **Cover each layer:** unit tests for domain logic, the data layer, and state
  management; widget tests for UI components; integration tests for end-to-end
  user flows.
- **Prefer fakes and stubs over mocks.** If mocks are unavoidable, use `mockito`
  or `mocktail`. Avoid code generation for mocks even when using it elsewhere
  (e.g. `freezed`).
- **Prefer `package:checks`** for more expressive, readable assertions over the
  default matchers.
- **Aim for high test coverage.**

## Lint Rules

Include a linter in `analysis_options.yaml`. Start from this baseline and add
project-specific rules:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Add additional lint rules here:
    # avoid_print: false
    # prefer_single_quotes: true
```

## Visual Design & Theming

- **Build beautiful, intuitive UIs** that follow modern design guidelines.
- **Be responsive.** Ensure the app adapts to different screen sizes and works
  well on mobile and web.
- **Provide intuitive navigation** (bars or controls) when there are multiple
  pages.
- **Use typography hierarchy** to aid understanding — hero text, section
  headlines, list headlines, and emphasized keywords.
- **Add a subtle noise texture** to the main background for a premium, tactile
  feel.
- **Use multi-layered drop shadows** to create depth; cards should have a soft,
  deep shadow to look "lifted."
- **Enhance with icons** to improve understanding and logical navigation.
- **Give interactive elements a glow** — buttons, checkboxes, sliders, lists,
  charts, and graphs can use shadow with elegant color for a "glow" effect.

### Theming

- **Centralize `ThemeData`** for a consistent application-wide style.
- **Support light and dark themes** via `theme` and `darkTheme` on
  `MaterialApp`, ideal for a theme toggle (`ThemeMode.light`, `ThemeMode.dark`,
  `ThemeMode.system`).
- **Generate palettes from a seed color** with `ColorScheme.fromSeed`.

  ```dart
  final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    // ... other theme properties
  );
  ```

- **Include a wide range** of color concentrations and hues for a vibrant look.
- **Use component themes** (`appBarTheme`, `elevatedButtonTheme`, etc.) to
  customize individual Material components.
- **Custom fonts:** Use the `google_fonts` package and define a `TextTheme` to
  apply fonts consistently.

  ```dart
  // 1. Add the dependency
  // flutter pub add google_fonts

  // 2. Define a TextTheme with a custom font
  final TextTheme appTextTheme = TextTheme(
    displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
    titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
    bodyMedium: GoogleFonts.openSans(fontSize: 14),
  );
  ```

### Material Theming Best Practices

- **Embrace `ThemeData` and Material 3.**
  - Use `ColorScheme.fromSeed()` to generate a complete, harmonious palette for
    both light and dark modes from a single seed color.
  - Provide both `theme` and `darkTheme` to support system brightness.
  - Centralize component styles (`elevatedButtonTheme`, `cardTheme`,
    `appBarTheme`) within `ThemeData`.
  - Control `themeMode` dynamically (e.g. via a `ChangeNotifierProvider`) to
    toggle between light, dark, and system.

  ```dart
  // main.dart
  MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
      ),
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    ),
    home: const MyHomePage(),
  );
  ```

- **Implement design tokens with `ThemeExtension`** for custom styles not covered
  by standard `ThemeData`.
  - Define a class extending `ThemeExtension<T>` with your custom properties.
  - Implement `copyWith` and `lerp` (required for theme transitions).
  - Register it in `ThemeData.extensions`.
  - Access tokens with `Theme.of(context).extension<MyColors>()!`.

  ```dart
  // 1. Define the extension
  @immutable
  class MyColors extends ThemeExtension<MyColors> {
    const MyColors({required this.success, required this.danger});

    final Color? success;
    final Color? danger;

    @override
    ThemeExtension<MyColors> copyWith({Color? success, Color? danger}) {
      return MyColors(success: success ?? this.success, danger: danger ?? this.danger);
    }

    @override
    ThemeExtension<MyColors> lerp(ThemeExtension<MyColors>? other, double t) {
      if (other is! MyColors) return this;
      return MyColors(
        success: Color.lerp(success, other.success, t),
        danger: Color.lerp(danger, other.danger, t),
      );
    }
  }

  // 2. Register it in ThemeData
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      MyColors(success: Colors.green, danger: Colors.red),
    ],
  ),

  // 3. Use it in a widget
  Container(
    color: Theme.of(context).extension<MyColors>()!.success,
  )
  ```

- **Style with `WidgetStateProperty`.**
  - `WidgetStateProperty.resolveWith`: provide a function that receives a
    `Set<WidgetState>` and returns the value for the current state.
  - `WidgetStateProperty.all`: shorthand when the value is the same for all
    states.

  ```dart
  // Example: Creating a button style that changes color when pressed.
  final ButtonStyle myButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.green; // Color when pressed
        }
        return Colors.red; // Default color
      },
    ),
  );
  ```

## UI Styling Code

- **Responsiveness:** Use `LayoutBuilder` or `MediaQuery` for responsive UIs.
- **Text styles:** Use `Theme.of(context).textTheme`.
- **Text fields:** Configure `textCapitalization`, `keyboardType`, and
  placeholder.

## Layout Best Practices

### Flexible, Overflow-Safe Layouts

**Rows and Columns:**

- **`Expanded`:** Make a child fill the remaining space along the main axis.
- **`Flexible`:** Let a widget shrink to fit without necessarily growing. Do not
  combine `Flexible` and `Expanded` in the same `Row` or `Column`.
- **`Wrap`:** Move a series of widgets to the next line when they would overflow
  a `Row` or `Column`.

**General content:**

- **`SingleChildScrollView`:** Use when content is intrinsically larger than the
  viewport but is a fixed size.
- **`ListView` / `GridView`:** For long lists or grids, always use a builder
  constructor (`.builder`).
- **`FittedBox`:** Scale or fit a single child within its parent.
- **`LayoutBuilder`:** Build complex, responsive layouts that adapt to available
  space.

### Layering with `Stack`

- **`Positioned`:** Precisely place a child within a `Stack` by anchoring it to
  the edges.
- **`Align`:** Position a child within a `Stack` using alignments like
  `Alignment.center`.

### Overlays

- **`OverlayPortal`:** Show UI elements (custom dropdowns, tooltips) on top of
  everything else; it manages the `OverlayEntry` for you.

  ```dart
  class MyDropdown extends StatefulWidget {
    const MyDropdown({super.key});

    @override
    State<MyDropdown> createState() => _MyDropdownState();
  }

  class _MyDropdownState extends State<MyDropdown> {
    final _controller = OverlayPortalController();

    @override
    Widget build(BuildContext context) {
      return OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (BuildContext context) {
          return const Positioned(
            top: 50,
            left: 10,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('I am an overlay!'),
              ),
            ),
          );
        },
        child: ElevatedButton(
          onPressed: _controller.toggle,
          child: const Text('Toggle Overlay'),
        ),
      );
    }
  }
  ```

## Color Scheme Best Practices

### Contrast Ratios

- **Meet WCAG 2.1.**
- **Minimum contrast:**
  - **Normal text:** at least **4.5:1**.
  - **Large text** (18pt, or 14pt bold): at least **3:1**.

### Palette Selection

- **Define a clear hierarchy:** primary, secondary, and accent colors.
- **Follow the 60-30-10 rule** for a balanced scheme:
  - **60%** primary/neutral (dominant)
  - **30%** secondary
  - **10%** accent

### Complementary Colors

- **Use with caution** — overuse is visually jarring.
- **Best for accents** to make elements pop; poor for text/background pairings,
  which cause eye strain.

### Example Palette

- **Primary:** `#0D47A1` (dark blue)
- **Secondary:** `#1976D2` (medium blue)
- **Accent:** `#FFC107` (amber)
- **Neutral/Text:** `#212121` (almost black)
- **Background:** `#FEFEFE` (almost white)

## Font Best Practices

### Font Selection

- **Limit font families** to one or two for the whole application.
- **Prioritize legibility** across all screen sizes; sans-serif is generally
  preferred for UI body text.
- **Consider system fonts** (platform-native).
- **Use `google_fonts`** for a wide selection of open-source fonts.

### Hierarchy and Scale

- **Establish a scale** of font sizes for headlines, titles, body text, and
  captions.
- **Differentiate with font weight.**
- **De-emphasize with color and opacity.**

### Readability

- **Line height (leading):** typically **1.4× to 1.6×** the font size.
- **Line length:** **45–75 characters** for body text.
- **Avoid all caps** for long-form text.

### Example Typographic Scale

```dart
// In your ThemeData
textTheme: const TextTheme(
  displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
  titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
  bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
  bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
  labelSmall: TextStyle(fontSize: 11.0, color: Colors.grey),
),
```

## Assets & Images

- **Choose relevant, meaningful images** with appropriate size, layout, and
  licensing; provide placeholders when real images are unavailable.
- **Declare all asset paths** in `pubspec.yaml`:

  ```yaml
  flutter:
    uses-material-design: true
    assets:
      - assets/images/
  ```

- **Local images:** Use `Image.asset` for images from the asset bundle.

  ```dart
  Image.asset('assets/images/placeholder.png')
  ```

- **Network images:** Use `Image.network`, and always include `loadingBuilder`
  and `errorBuilder`.

  ```dart
  // When using network images, always provide an errorBuilder.
  Image.network(
    'https://picsum.photos/200/300',
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return const Center(child: CircularProgressIndicator());
    },
    errorBuilder: (context, error, stackTrace) {
      return const Icon(Icons.error);
    },
  )
  ```

- **Cached images:** Use the `cached_network_image` package.
- **Custom icons:** Use `ImageIcon` to display an icon from an `ImageProvider`,
  useful for icons not in the `Icons` class.

## Accessibility (A11Y)

Implement accessibility for a wide variety of users — different physical and
mental abilities, age groups, education levels, and learning styles.

- **Color contrast:** At least **4.5:1** between text and its background.
- **Dynamic text scaling:** Test that the UI remains usable when the system font
  size increases.
- **Semantic labels:** Use the `Semantics` widget to provide clear, descriptive
  labels for UI elements.
- **Screen reader testing:** Regularly test with TalkBack (Android) and VoiceOver
  (iOS).

## Documentation

- **Write `dartdoc`-style comments** (`///`) for all public APIs — classes,
  constructors, methods, and top-level functions.

### Philosophy

- **Comment the *why*, not the *what*.** The code itself should be
  self-explanatory; comments explain decisions.
- **Document for the reader.** If you had a question and found the answer, add it
  where you first looked.
- **No useless docs.** If a comment only restates the obvious from a name, remove
  it; good docs provide context that isn't immediately apparent.
- **Be consistent** in terminology.

### Style

- **Use `///` for doc comments** so tools can pick them up.
- **Start with a single-sentence summary** — concise and user-centric, ending
  with a period.
- **Separate the summary** with a blank line so tools build better overviews.
- **Avoid redundancy** with what's obvious from the class name or signature.
- **Document only one of a getter/setter pair** — tools treat them as one field.
- **Be brief.** Avoid jargon and acronyms unless widely understood.
- **Use Markdown sparingly** — never use HTML; enclose code in backtick fences
  with a language.
- **Place doc comments before annotations.**

### What to Document

- **Public APIs** (always) and **private APIs** (recommended).
- **Library-level overviews** via a top-level doc comment.
- **Code samples** where they aid understanding.
- **Parameters, return values, and exceptions** in prose.
