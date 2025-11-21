# Service Definition Language (SDL)

Version: 0.1  
Scope: declarative service contracts with types and actions. Pipelines/flows are intentionally out.

## 1. Minimal layout

Two files to illustrate packages and imports:

```kotlin
// commons.sdl
package commons

type Money = Decimal @min(0)
type Email = String @pattern(".+@.+")
```

```kotlin
// checkout.sdl
package checkout

import commons.*

type OrderId = UUID

type Order = {
    id: OrderId
    email: Email
    total: Money
}

type Receipt = { id: UUID; orderId: OrderId; total: Money }

// Events (any type referenced after -> in actions)
type OrderCreated = { orderId: OrderId; total: Money }
type OrderCompleted = { orderId: OrderId; receiptId: UUID }

// Errors (names ending with Error)
type CheckoutError = { code: String; message: String }

service CheckoutService {
    processOrder(order: Order): Receipt | CheckoutError -> [OrderCreated, OrderCompleted]
}
```

Doc comments use `///` and attach to the next declaration.

## 2. Reserved words

`package`, `import`, `type`, `enum`, `service`, `true`, `false`, `null`, `Unit`, `consumes`, `produces`.

## 3. Types and conventions

- **Primitives:** `String`, `Boolean`, `Int`, `Long`, `Double`, `Decimal`, `Bytes`, `UUID`, `Timestamp`, `Unit`.
- **Nullability:** `T?` marks optional; `null` only allowed on optional types.
- **Collections:** `T[]` or `List<T>`, plus `Set<T>`, `Map<K,V>`. Modifiers can chain: `String[]?` means optional array of strings.
- **Generics:** supported on `type` declarations and references: `type Page<T> = { items: T[]; total: Int }`.
- **Unions (XOR):** `A | B` means exactly one branch. Example: `Receipt | CheckoutError`.
- **Errors:** any `type` whose name ends with `Error`. Use them as error branches in unions.
- **Events:** any declared `type` referenced after `->` in an action signature.
- **Enums:** `enum { Pending; Approved; Failed(reason: String) }` supports simple and data variants.
- **Type bodies:** multi-line or single-line; stay consistent within a type family.
- **Imports:** `import commons.*` pulls all types from that package; `import commons.Money` imports a single type.
- **Annotations:** `@foo(bar)` are attached to type aliases or fields; semantics are implementation-defined.

## 4. Services and actions

### 4.0 Grammar (EBNF)

```
file         := package_decl imports? decl*
package_decl := "package" ident
imports      := import_decl*
import_decl  := "import" (ident ".*" | ident "." ident)
decl         := type_decl | service_decl

type_decl    := "type" ident generic_params? "=" type_body
type_body    := type_alias | object_type | enum_type
type_alias   := type_ref annotations?
object_type  := "{" field_decl (field_sep field_decl)* "}"
enum_type    := "enum" "{" enum_variant (field_sep enum_variant)* "}"
field_decl   := ident ":" type_ref
enum_variant := ident enum_fields?
enum_fields  := "(" enum_field ("," enum_field)* ")"
enum_field   := ident ":" type_ref
field_sep    := ";" | linebreak

service_decl := "service" ident "{" action_decl+ "}"
action_decl  := action_head ":" return_type ("->" event_list)?
action_head  := ident ("(" params? ")")?
params       := param ("," param)*
param        := ident ":" type_ref

return_type  := success_type ("|" error_type)*
success_type := type_ref                            # must be non-error type
error_type   := type_ref                            # conventionally ends with "Error"
event_list   := type_ref | "[" type_ref ("," type_ref)* "]"

type_ref     := base_type modifier*
base_type    := ident generic_args?
modifier     := "[]" | "?"

generic_params := "<" ident ("," ident)* ">"
generic_args   := "<" type_ref ("," type_ref)* ">"

ident        := /[A-Za-z_][A-Za-z0-9_]*/
annotations  := annotation*
annotation   := "@" ident ("(" annotation_args ")")? | "@" ident
annotation_args := /.*/
```

Notes:
- Modifiers can be chained: `String[]?` = optional array of strings.
- Return types must include at least one `success_type` (non-Error).
- Error types are distinguished by suffix `Error` (convention).
- Actions without parameters can omit parentheses.
- `onXyz` is a naming convention for consumers; `on` is not a keyword.
- Field separators can be semicolons or line breaks.
- Enums allow plain variants and variants with associated data.
- Inline event shapes after `->` are not allowed; events must be declared `type`s.

### 4.1 Structure

```
service ServiceName {
    actionName(params): ReturnType -> EventType
    actionName(params): ReturnType -> [EventA, EventB]
    onSomething(event: SomeEvent): ReturnType -> EventType
    noParamsAction: ReturnType
}
```

- **Return type:** single type or union (commonly success | error).
- **Events:** declared with `-> Event` or `-> [EventA, EventB]`. Use brackets only when listing more than one event.
- **Consumers:** actions whose names start with `on` and take a single `event: Xxx` parameter are treated as event consumers (see inference).
- **Parameters:** `name: Type`, comma-separated. No defaults or modifiers on params beyond `?`/`[]` in the type.
- **No implementations here:** this slice is declarative; runtime bindings implement behavior elsewhere.

### 4.2 Inference rules (to remove ambiguity)

- **Consumes:** any action named `onXyz(event: Xyz)` infers `consumes { Xyz }`.
- **Produces:** union of all event types listed after `->` across actions. This is the service's outbound catalog.
- **Dual use types:** a type can be both consumed and produced; inference is purely from action signatures.
- **Explicit catalogs (optional):** you may add comments `// consumes { ... }` and `// produces { ... }` for readability, but inference is the source of truth.

### 4.3 Optional explicit catalogs

If you choose to declare catalogs explicitly, keep them aligned with inference:

```kotlin
service CheckoutService {
    // consumes { PaymentApproved }
    // produces { OrderCreated, OrderCompleted }
    processOrder(order: Order): Receipt | CheckoutError -> [OrderCreated, OrderCompleted]
}
```

Explicit catalogs must exactly match what is inferred from action signatures; they do not override inference.

### 4.4 Validation expectations

- All referenced types (parameters, returns, events) must be declared in scope (current package or imported).
- Event names after `->` must refer to declared `type`s, not primitives or inline objects.
- Error names must end with `Error` if used as error branches.
- Union return types must include at least one non-error branch.
- Generics must be well-formed: params declared, args arity must match.
- Enum variants must be unique within the enum; variant field names must be unique per variant.

## 5. Complete example

```kotlin
package checkout

import commons.Money

type Email = String @pattern(".+@.+")
type OrderId = UUID
type CartId = UUID

type Order = {
    id: OrderId
    email: Email
    total: Money
}

type Receipt = {
    id: UUID
    orderId: OrderId
    total: Money
}

enum OrderStatus {
    Pending
    Approved
    Failed(reason: String)
}

// Events
type OrderCreated = {
    orderId: OrderId
    total: Money
}
type OrderCompleted = { orderId: OrderId; receiptId: UUID }
type PaymentApproved = { paymentId: UUID; orderId: OrderId }
type OrderCancelled = { orderId: OrderId }
type EmailNotificationSent = { orderId: OrderId; email: Email }

// Errors (suffix Error)
type OrderCancellationError = { code: String; message: String }
type CheckoutError = { code: String; message: String }

service CheckoutService {
    onPaymentApproved(event: PaymentApproved): Unit -> EmailNotificationSent
    processOrder(order: Order): Receipt | CheckoutError -> [OrderCreated, OrderCompleted]
    cancelOrder(orderId: OrderId): Unit | OrderCancellationError -> OrderCancelled

    // Inference (explicit for clarity):
    // consumes { PaymentApproved }
    // produces { OrderCreated, OrderCompleted, OrderCancelled, EmailNotificationSent }
}
```

## 6. Compilation model (packages and files)

- **Unit of compilation:** every `.sdl` file under the current directory (recursively) is part of the build input, similar to Go's package discovery.
- **Package boundary:** each `.sdl` declares exactly one `package`. All files with the same `package` name across the tree form that package; they are compiled together.
- **Imports:** `import foo.*` pulls all exported declarations from package `foo`. `import foo.Bar` pulls only `Bar`. Imports must resolve to a discovered package name.
- **Name resolution:** unqualified references first check the current package, then imported packages. Fully-qualified names are not required if imported.
- **Uniqueness:** within a package, `type` and `service` names must be unique. Duplicate names across different packages are allowed and are referenced via imports.
- **Build steps:**
  1. Scan current and nested folders for `*.sdl`.
  2. Group files by `package` declaration.
  3. Resolve imports between packages; fail if a package is missing.
  4. Validate declarations (types, services, actions) per this spec.
  5. Emit package-level artifacts (e.g., schemas/stubs) per build tool.
