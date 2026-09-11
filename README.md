# my_app --- Architecture & Structure Guide

This README explains how to use the project structure in a simple and
practical way.

The main idea is:

> **Start simple. Add structure only when you really need it.**

------------------------------------------------------------------------

## 1. Project Structure in Simple Words

``` text
lib/
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── dependencies.dart
│
├── core/
│   ├── network/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── home/
│   └── profile/
│
└── main.dart
```

### `app/`

Contains the global application setup.

Examples:

-   App initialization
-   Routing
-   Dependency injection setup
-   Global configuration

### `core/`

Contains shared infrastructure used by more than one feature.

Examples:

-   Network
-   Storage
-   Firebase
-   Location
-   Localization
-   Theme
-   Shared widgets

### `features/`

Contains the actual application features.

Each feature owns its own:

-   Pages
-   Cubits
-   States
-   Models
-   Repositories
-   Feature-specific services

### The Main Rule

> **If something belongs to one feature, keep it inside that feature.\
> If it is really shared by multiple features, move it to `core/`.**

------------------------------------------------------------------------

# 2. Adding a New Feature

Let's say we want to add an `orders` feature.

## Level 1 --- Start Simple

Create:

``` text
features/
└── orders/
    ├── orders_page.dart
    ├── orders_cubit.dart
    └── orders_state.dart
```

This is the default starting point.

You do not need a Model, Repository, or UseCase just because other
projects use them.

### Example Cubit

``` dart
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._apiClient) : super(OrdersInitial());

  final OrdersApiClient _apiClient;

  Future<void> fetchOrders() async {
    emit(OrdersLoading());

    try {
      final response = await _apiClient.getOrders();
      emit(OrdersLoaded(response));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }
}
```

For a simple feature, the flow can be:

``` text
UI → Cubit → ApiClient
```

------------------------------------------------------------------------

# 3. Add a Model Only When You Need One

If the API response becomes complex, has nested objects, or needs
serialization/type safety, add a model.

``` text
features/
└── orders/
    ├── orders_page.dart
    ├── orders_cubit.dart
    ├── orders_state.dart
    └── order_model.dart
```

Example:

``` dart
class OrderModel {
  final int id;
  final double total;
  final String status;

  OrderModel({
    required this.id,
    required this.total,
    required this.status,
  });
}
```

### When should you create a Model?

Create one when you need:

-   JSON serialization
-   Nested objects
-   Type safety
-   Easier data handling
-   Clear domain/data structure

If the response is very simple and using a `Map` is enough, you do not
have to create a Model.

------------------------------------------------------------------------

# 4. Add a Repository When Data Access Needs It

Do not create a Repository for every API call.

Add one when the feature starts handling more complex data access.

For example:

-   API + local cache
-   Multiple data sources
-   Data transformation
-   Complex fetching logic
-   The Cubit becomes too dependent on the API layer

Structure:

``` text
features/
└── orders/
    ├── orders_page.dart
    ├── orders_cubit.dart
    ├── orders_state.dart
    ├── order_model.dart
    └── orders_repository.dart
```

Example:

``` dart
class OrdersRepository {
  OrdersRepository(
    this._apiClient,
    this._localStorage,
  );

  final OrdersApiClient _apiClient;
  final LocalStorageService _localStorage;

  Future<List<OrderModel>> getOrders() async {
    // API / cache / data handling
  }
}
```

Now the flow becomes:

``` text
UI → Cubit → Repository → ApiClient
```

The Cubit should not contain complicated data-access logic.

------------------------------------------------------------------------

# 5. Add an Action for Complex Operations

Sometimes one operation becomes large or contains complicated business
logic.

Instead of making the Cubit very large, move that operation into an
Action.

Example:

``` text
features/
└── orders/
    ├── orders_page.dart
    ├── orders_cubit.dart
    ├── orders_state.dart
    ├── order_model.dart
    ├── orders_repository.dart
    └── actions/
        └── calculate_order_summary_action.dart
```

The flow can become:

``` text
UI → Cubit → Action → Repository → ApiClient
```

Use an Action when the operation is:

-   Complex
-   Reusable
-   Better tested separately
-   Large enough to make the Cubit difficult to read

Do not create an Action for every small function.

------------------------------------------------------------------------

# 6. How to Use `core/`

## `core/network`

Put shared network infrastructure here.

Example:

``` text
core/
└── network/
    ├── api_client.dart
    ├── api_exception.dart
    └── api_response.dart
```

The feature can create its own API client using the shared Dio instance.

Example:

``` dart
@RestApi()
abstract class OrdersApiClient {
  factory OrdersApiClient(Dio dio) = _OrdersApiClient;

  @GET('/orders')
  Future<List<OrderModel>> getOrders();
}
```

The feature owns `OrdersApiClient`.

The shared Dio configuration stays in `core/network`.

### Important

Do not create a new `Dio()` inside every feature.

Use the shared network setup.

------------------------------------------------------------------------

# 7. `core/storage`

Shared local storage belongs here.

Examples:

``` dart
await secureStorageService.write(
  'access_token',
  token,
);

final token = await secureStorageService.read(
  'access_token',
);

await localStorageService.setBool(
  'onboarding_seen',
  true,
);
```

Examples of things that can live here:

-   Secure token storage
-   Preferences
-   Local settings
-   Shared cache helpers

------------------------------------------------------------------------

# 8. `core/firebase`

Firebase initialization should happen once during app startup.

Example:

``` text
core/
└── firebase/
    ├── firebase_init.dart
    └── crashlytics_service.dart
```

Initialize Firebase in `main.dart` or the application startup flow.

Features should use the shared Firebase services.

For example:

``` dart
crashlyticsService.recordError(
  error,
  stackTrace,
);
```

### Avoid

``` dart
FirebaseAuth.instance
```

or creating Firebase-related infrastructure directly inside every
feature.

The goal is to keep Firebase setup centralized.

------------------------------------------------------------------------

# 9. `core/location`

Shared location functionality belongs here.

Example:

``` dart
final position =
    await locationService.getCurrentPosition();

final placemarks =
    await locationService.getAddressFromCoordinates(
  position,
);
```

A feature should use the shared location service instead of creating a
new location implementation.

------------------------------------------------------------------------

# 10. `core/localization`

All shared localization setup belongs here.

Example:

``` dart
Text('orders.title'.tr());
```

Changing the language:

``` dart
await localeService.setLocale(
  context,
  const Locale('ar'),
);
```

The localization configuration stays in `core`.

Feature-specific translation keys can remain related to their feature.

------------------------------------------------------------------------

# 11. Dependency Injection

If the project uses `injectable` and `get_it`, keep the DI setup
centralized.

Example:

``` dart
@lazySingleton
class OrdersRepository {
  // ...
}
```

Then run:

``` bash
flutter pub run build_runner build --delete-conflicting-outputs
```

The generated configuration will register the dependencies.

### Simple Rule

The class should define how it is registered.

The generated DI file handles the final wiring.

------------------------------------------------------------------------

# 12. `core/widgets`

Shared UI components should live here.

Example:

``` text
core/
└── widgets/
    ├── app_button.dart
    ├── app_text_field.dart
    ├── app_loader.dart
    ├── app_error.dart
    ├── app_dialog.dart
    └── app_network_image.dart
```

Use shared widgets instead of calling third-party packages directly
everywhere.

Example:

``` dart
AppNetworkImage(
  url: order.imageUrl,
);
```

Instead of:

``` dart
CachedNetworkImage(
  imageUrl: order.imageUrl,
);
```

This gives the project one central place to change the implementation
later.

For example, if the image package changes, you can update
`AppNetworkImage` instead of changing every feature.

------------------------------------------------------------------------

# 13. Decision Rules

Before creating a new file, ask:

## Model

**Do I really need a Model?**

No:

``` text
Use a simple Map/response.
```

Yes:

``` text
Create a Model.
```

Good reasons:

-   Serialization
-   Nested data
-   Type safety
-   Complex data

------------------------------------------------------------------------

## Repository

**Does the Cubit really need a Repository?**

No:

``` text
Cubit → ApiClient
```

Yes:

``` text
Cubit → Repository → ApiClient
```

Good reasons:

-   Multiple data sources
-   Caching
-   Complex data handling
-   Data transformation
-   Better separation

------------------------------------------------------------------------

## Action

**Is the operation complex enough to separate?**

No:

``` text
Keep it in the Cubit.
```

Yes:

``` text
Move it to an Action.
```

Good reasons:

-   Complex business logic
-   Reusable operation
-   Independent testing
-   Large Cubit

------------------------------------------------------------------------

## Core Service

**Is this service really shared?**

No:

``` text
Keep it inside the feature.
```

Yes:

``` text
Move it to core.
```

A good rule:

> Move something to `core/` when multiple features genuinely need it.

Do not move something to `core/` just because it might be useful in the
future.

------------------------------------------------------------------------

# 14. Common Mistakes to Avoid

### ❌ Do not create Base classes just for the future

Avoid:

``` text
BaseCubit
BaseState
BaseRepository
BaseModel
BaseUseCase
BaseService
```

unless the project actually has a real reason for them.

------------------------------------------------------------------------

### ❌ Do not create a Repository for every API call

A simple API call does not automatically need a Repository.

Start with:

``` text
Cubit → ApiClient
```

Add a Repository when it provides real value.

------------------------------------------------------------------------

### ❌ Do not create a Model for every response

If the response is simple and does not need a type, a Model may be
unnecessary.

------------------------------------------------------------------------

### ❌ Do not create UseCases automatically

This project does not require a UseCase for every operation.

Use an Action or another small abstraction only when the logic becomes
complex enough to justify it.

------------------------------------------------------------------------

### ❌ Do not create global feature folders

Avoid this structure:

``` text
lib/
├── models/
├── cubits/
├── repositories/
├── screens/
└── services/
```

This makes large projects harder to understand.

Instead:

``` text
features/
├── auth/
├── orders/
├── profile/
└── home/
```

Each feature keeps its own code together.

------------------------------------------------------------------------

### ❌ Do not put feature-specific logic in `core/`

Bad:

``` text
core/
└── order_pricing_service.dart
```

if the service is only used by the orders feature.

Better:

``` text
features/
└── orders/
    └── order_pricing_service.dart
```

------------------------------------------------------------------------

### ❌ Do not use multiple packages for the same job

For example, avoid using two different toast packages unless there is a
real reason.

Choose one shared implementation and use it through your project
widgets/services.

------------------------------------------------------------------------

# 15. Practical Feature Checklist

When creating a new feature:

### Step 1

Create:

``` text
features/<feature_name>/
```

### Step 2

Start with only:

``` text
<feature>_page.dart
<feature>_cubit.dart
<feature>_state.dart
```

### Step 3

If the feature needs an API:

``` text
<feature>_api_client.dart
```

Use the shared Dio/network setup from `core`.

### Step 4

If the data becomes complex:

``` text
<feature>_model.dart
```

### Step 5

If data access becomes complex:

``` text
<feature>_repository.dart
```

### Step 6

If a business operation becomes complex:

``` text
actions/
```

### Step 7

If something is genuinely shared by multiple features:

Move it to the appropriate `core/` folder.

------------------------------------------------------------------------

# 16. The Architecture in One Picture

Simple feature:

``` text
┌──────────────┐
│     Page     │
└──────┬───────┘
       ↓
┌──────────────┐
│    Cubit     │
└──────┬───────┘
       ↓
┌──────────────┐
│  Api Client  │
└──────────────┘
```

More complex feature:

``` text
┌──────────────┐
│     Page     │
└──────┬───────┘
       ↓
┌──────────────┐
│    Cubit     │
└──────┬───────┘
       ↓
┌──────────────┐
│  Repository  │
└──────┬───────┘
       ↓
┌──────────────┐
│  Api Client  │
└──────────────┘
```

Complex operation:

``` text
┌──────────────┐
│     Page     │
└──────┬───────┘
       ↓
┌──────────────┐
│    Cubit     │
└──────┬───────┘
       ↓
┌──────────────┐
│    Action    │
└──────┬───────┘
       ↓
┌──────────────┐
│  Repository  │
└──────┬───────┘
       ↓
┌──────────────┐
│  Api Client  │
└──────────────┘
```

------------------------------------------------------------------------

# 17. The Main Philosophy

This architecture follows a simple idea:

> **Start Flat. Grow Only When Needed.**

The project should not become complicated just because the architecture
looks professional.

Good architecture is not about having many folders and classes.

Good architecture means:

-   Easy to understand
-   Easy to change
-   Easy to test
-   Easy to maintain
-   Clear ownership
-   Low unnecessary complexity

### Remember

``` text
Feature-specific → Feature

Shared infrastructure → Core

Simple → Keep it simple

Complex → Add structure

Do not build for problems you do not have yet.
```

------------------------------------------------------------------------

# 18. Quick Reference

  Situation                    What to do
  ---------------------------- -------------------------
  New feature                  `Page + Cubit + State`
  Simple API                   `Cubit → ApiClient`
  Complex data                 Add `Model`
  Complex data access          Add `Repository`
  Complex business operation   Add `Action`
  Used by multiple features    Move to `Core`
  Used by one feature          Keep inside the feature
  Future abstraction only      Do not add it yet
  Repeated UI                  Create shared widget
  Repeated infrastructure      Create shared service

------------------------------------------------------------------------

# 19. Final Rule

When you are not sure whether to create another class or folder, ask:

> **"Does this solve a real problem in the project right now?"**

If the answer is **yes**, add it.

If the answer is **no**, keep the code simple.

**Every file should have a reason to exist.**
