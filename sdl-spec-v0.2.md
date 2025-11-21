# Service Definition Language (SDL)

Version: 0.2  
Scope: declarative service contracts with types and actions.

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

type OrderCreated = { orderId: OrderId; total: Money }
type OrderCompleted = { orderId: OrderId; receiptId: UUID }

type CheckoutError = { code: String; message: String }

type PaymentApproved = { paymentId: UUID; orderId: OrderId }

type PaymentError = { code: String; message: String }

service PaymentService {
    authorize(order: Order): PaymentApproved | PaymentError -> PaymentApproved
}

service CheckoutService {
    processOrder(order: Order): Receipt | CheckoutError
      // synchronous dependency
      calls [PaymentService.authorize]
      // side effects/events
      emits [OrderCreated, OrderCompleted]
}
```

## 2. Reserved words

`package`, `import`, `type`, `enum`, `service`, `true`, `false`, `null`, `Unit`, `consumes`, `produces`, `calls`, `emits`.

## 3. Types and conventions

- **Primitives:** `String`, `Boolean`, `Int`, `Long`, `Double`, `Decimal`, `Bytes`, `UUID`, `Timestamp`, `Unit`.
- **Nullability:** `T?` marks optional; `null` only allowed on optional types.
- **Collections:** `T[]` or `List<T>`, plus `Set<T>`, `Map<K,V>`. Modifiers can chain: `String[]?` means optional array of strings.
- **Generics:** supported on `type` declarations and references: `type Page<T> = { items: T[]; total: Int }`.
- **Unions (XOR):** `A | B` means exactly one branch. Example: `Receipt | CheckoutError`.
- **Errors:** any `type` whose name ends with `Error`. Use them as error branches in unions.
- **Events:** any declared `type` referenced after `->`/`emits` in an action signature.
- **Enums:** `enum { Pending; Approved; Failed(reason: String) }` supports simple and data variants.
- **Type bodies:** multi-line or single-line; stay consistent within a type family.
- **Imports:** `import commons.*` pulls all types/services from that package; `import commons.Money` imports a single type. Services are importable only via `pkg.*`.
- **Annotations/comments:** `@foo(bar)` attached to type aliases or fields (semantics implementation-defined). Comments: `//` (line), `///` (doc, attaches to next declaration), `/* ... */` (block, single or multi-line).

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
action_decl  := action_head ":" return_type calls_clause? event_clause?
action_head  := ident ("(" params? ")")?
params       := param ("," param)*
param        := ident ":" type_ref

calls_clause := "calls" call_ref | "calls" "[" call_ref ("," call_ref)* "]"
call_ref     := ident "." ident "." ident   # pkg.service.action
              | ident "." ident              # service.action in scope

event_clause := ("->" | "emits") event_list
event_list   := type_ref | "[" type_ref ("," type_ref)* "]"

return_type  := success_type ("|" error_type)*
success_type := type_ref                            # must be non-error type
error_type   := type_ref                            # conventionally ends with "Error"

type_ref     := base_type modifier*
base_type    := ident generic_args?
modifier     := "[]" | "?"

generic_params := "<" ident ("," ident)* ">"
generic_args   := "<" type_ref ("," type_ref)* ">"

ident        := /[A-Za-z_][A-Za-z0-9_]*/
annotations  := annotation*
annotation   := "@" ident ("(" annotation_args ")")? | "@" ident
annotation_args := /.+/
```

Notes:
- Modifiers can be chained: `String[]?` = optional array of strings.
- Return types must include at least one non-error branch.
- Error types are distinguished by suffix `Error` (convention).
- Actions without parameters can omit parentheses.
- Field separators can be semicolons or line breaks.
- Enums allow plain variants and variants with associated data.
- Inline event shapes after `->`/`emits` are not allowed; events must be declared `type`s.

### 4.1 Structure

```
service ServiceName {
    actionName(params): ReturnType
      calls ServiceA.action, ServiceB.action
      emits [EventA, EventB]
}
```

- **Return type:** single type or union (commonly success | error).
- **Calls:** optional list of synchronous dependencies; resolved to services in the same package, or imported via `import pkg.*` when using `pkg.Service.action`.
- **Events:** optional list via `->` or `emits`; use brackets when listing more than one.
- **Parameters:** `name: Type`, comma-separated. No defaults or modifiers on params beyond `?`/`[]` in the type.

### 4.2 Inference rules

- **Consumes:** any action named `onXyz(event: Xyz)` infers `consumes { Xyz }`.
- **Produces:** union of all event types listed after `->`/`emits` across actions.
- **Calls do not affect consumes/produces**, but indicate synchronous coupling.
- **Dual use types:** a type can be both consumed and produced; inference is purely from action signatures.

### 4.3 Validation expectations

- All referenced types (parameters, returns, events) must be declared in scope (current package or imported).
- Event names after `->`/`emits` must refer to declared `type`s, not primitives or inline objects.
- Error names must end with `Error` if used as error branches.
- Union return types must include at least one non-error branch.
- Generics must be well-formed: params declared, args arity must match.
- Enum variants must be unique within the enum; variant field names must be unique per variant.
- `calls` must resolve to an existing service/action; cross-package calls require `import pkg.*`.
- `->` and `emits` are aliases; do not mix both on the same action.

## 5. Complete example

```kotlin
package checkout

import commons.*

// Shared types
type Money = Decimal @min(0)
type Email = String @pattern(".+@.+")
type OrderId = UUID
type PaymentId = UUID
type CartId = UUID

type Order = {
    id: OrderId
    email: Email
    total: Money
}

type Receipt = { id: UUID; orderId: OrderId; total: Money }

// Events
type OrderCreated = { orderId: OrderId; total: Money }
type OrderCompleted = { orderId: OrderId; receiptId: UUID }
type PaymentApproved = { paymentId: PaymentId; orderId: OrderId }

type CheckoutError = { code: String; message: String }
type PaymentError = { code: String; message: String }

service PaymentService {
    authorizePayment(order: Order): PaymentApproved | PaymentError -> PaymentApproved
}

service CheckoutService {
    processOrder(order: Order): Receipt | CheckoutError
      calls [PaymentService.authorizePayment]
      emits [OrderCreated, OrderCompleted]
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
  5. Emit package-level artifacts (schemas/stubs) per build tool.
