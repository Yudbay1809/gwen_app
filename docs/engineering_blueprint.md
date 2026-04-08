# Gwen App Engineering Blueprint

## Objective
Upgrade the app to a cleaner, scalable architecture without removing existing features, while improving test stability and code maintainability.

## Guiding Principles
- Preserve current UX and all existing flows.
- Keep feature behavior backward-compatible.
- Separate concerns: `presentation` -> `domain` -> `data`.
- Prefer testable business logic and predictable state transitions.
- Stabilize CI by keeping analyzer and tests green.

## Baseline Snapshot
- `flutter analyze`: clean.
- Existing tests: one unstable widget test caused by pending splash timer.
- Major technical debt hotspots:
  - `lib/features/home/presentation/home_screen.dart`
  - `lib/features/profile/presentation/profile_screen.dart`
  - `lib/features/product/presentation/product_detail_screen.dart`
  - `lib/router/app_router.dart`
- Repository interfaces for `auth` and `product` existed but were empty.
- Storage wrappers existed but were placeholders.

## Delivery Plan

### Phase A - Stability First
1. Remove pending timer leak in splash flow.
2. Ensure widget tests can fully dispose tree without invariants error.

### Phase B - Data Layer Foundation
1. Implement `AuthRepository` contract and concrete persistence logic.
2. Route auth state provider through repository methods.
3. Implement `ProductRepository` contract (`getAll`, `getById`, `search`).
4. Add Riverpod provider bridge for product repository usage.

### Phase C - Core Utilities
1. Replace placeholder `LocalStorage` with typed read/write/remove API.
2. Replace placeholder `SecureStorage` with encoded persistence API and delete support.

### Phase D - Regression Safety
1. Add focused unit tests for auth repository behavior.
2. Add tests for storage utility behavior.
3. Add tests for product repository query behavior.
4. Run analyzer + full test suite.

## Implemented in This Pass
- Splash timer lifecycle fix completed.
- Auth repository contract + implementation completed.
- Auth provider migrated to repository-backed persistence completed.
- Product repository contract + implementation completed.
- Product repository Riverpod providers added completed.
- Router redirect policy extracted into testable route guard completed.
- LocalStorage implementation completed.
- SecureStorage implementation completed.
- Home filtering and ranking logic extracted into dedicated logic module completed.
- Home cache stale invalidation strategy (TTL + purge) completed.
- Product DTO + mapper layer foundation completed.
- New test coverage added for auth, storage, and product repositories completed.

## Additional Validation Added
- Route-guard redirect unit tests.
- Checkout promo rule tests (critical checkout policy).
- Home screen logic tests.
- Product DTO mapper tests.

## Next Refactor Waves (No Feature Removal)
1. Extract large screens into section widgets and controller classes.
2. Split `app_router.dart` into route groups per feature.
3. Add integration tests for auth redirects and checkout critical path.
4. Introduce API DTOs + mapper layer before backend rollout.
5. Add offline cache strategy and stale-data invalidation policy.
