# Minimal PlantUML Example per Diagram Type

One smallest-useful diagram per type. Copy, then replace the names with the domain's own.

## Class

```plantuml
@startuml
interface PaymentGateway {
  +charge(amount: Money): Receipt
}
class StripeGateway implements PaymentGateway
class Order {
  -items: List<Item>
  +total(): Money
}
Order *-- Item
Order --> PaymentGateway : pays through
@enduml
```

## Sequence

```plantuml
@startuml
actor Customer
participant Checkout
participant PaymentGateway
Customer -> Checkout : submit(cart)
Checkout -> PaymentGateway : charge(total)
PaymentGateway --> Checkout : receipt
Checkout --> Customer : confirmation
@enduml
```

## Activity

```plantuml
@startuml
start
:receive order;
if (in stock?) then (yes)
  :reserve items;
  :charge payment;
else (no)
  :queue backorder;
endif
:send confirmation;
stop
@enduml
```

## Swimlane Activity

```plantuml
@startuml
|Customer|
start
:place order;
|Warehouse|
:pick items;
:ship parcel;
|Customer|
:receive parcel;
stop
@enduml
```

## State Machine

```plantuml
@startuml
[*] --> Draft
Draft --> Submitted : submit
Submitted --> Approved : approve
Submitted --> Draft : request changes
Approved --> [*]
@enduml
```

## Component

```plantuml
@startuml
component "Web App" as web
component "Order Service" as orders
database "PostgreSQL" as db
interface "REST /orders" as api
web --> api
api - orders
orders --> db
@enduml
```

## Use Case

```plantuml
@startuml
left to right direction
actor Customer
actor "Support Agent" as agent
rectangle Shop {
  Customer -- (Place order)
  Customer -- (Track delivery)
  agent -- (Refund order)
}
@enduml
```

## Deployment

```plantuml
@startuml
node "Load Balancer" as lb
node "App Server" as app {
  artifact "shop.jar"
}
database "Primary DB" as db
lb --> app
app --> db
@enduml
```

## Object

```plantuml
@startuml
object "order-4417 : Order" as order {
  status = "paid"
  total = 129.90
}
object "item-1 : Item" as item {
  sku = "SKU-1"
}
order --> item
@enduml
```

## Package

```plantuml
@startuml
package "domain" {
  class Order
}
package "infrastructure" {
  class PostgresOrderRepository
}
infrastructure ..> domain : depends on
@enduml
```

## Communication

```plantuml
@startuml
object Checkout
object Inventory
object PaymentGateway
Checkout -> Inventory : 1: reserve(items)
Checkout -> PaymentGateway : 2: charge(total)
PaymentGateway -> Checkout : 2.1: receipt
@enduml
```

## Composite Structure

```plantuml
@startuml
component Checkout {
  port "cart in" as cart
  port "receipt out" as receipt
  component Pricing
  component Payment
  cart --> Pricing
  Pricing --> Payment
  Payment --> receipt
}
@enduml
```

## Interaction Overview

```plantuml
@startuml
start
:authenticate;
group Checkout
  ref over Checkout, PaymentGateway : charge sequence
end group
if (paid?) then (yes)
  :ship order;
else (no)
  :cancel order;
endif
stop
@enduml
```

## Profile

```plantuml
@startuml
class OrderService <<service>> {
  +place(order: Order)
}
class OrderTable <<entity>>
OrderService ..> OrderTable
note right of OrderService : <<service>> is a profile stereotype
@enduml
```
