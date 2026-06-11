# Wallet Flow

This document describes the current Firestore-driven wallet base before Stripe is connected.

## Collections used

### `usuarios/{adminId}`
- `tipo`: identifies the profile role.
- `perfil.categoria`: admin profile category.
- `sucursales`: list of branch names assigned to the admin.
- `licencia_estado`: current admin license status.
- `licencia_plan`: current license plan.

### `usuarios/{adminId}/tarifas`
Stores monthly fee definitions created by the admin.

Required fields:
- `admin_id`
- `branch_id`
- `group_id` optional
- `name`
- `amount_cents`
- `currency`
- `period_type`
- `period_count`
- `description`
- `is_active`
- `stripe_product_id` optional for later Stripe sync
- `stripe_price_id` optional for later Stripe sync

### `usuarios/{adminId}/cobros`
Stores the billing history for the admin.

Required fields:
- `admin_id`
- `student_id`
- `student_name`
- `tariff_id`
- `tariff_name`
- `branch_id`
- `branch_name`
- `group_id`
- `group_name`
- `amount_cents`
- `discount_amount_cents`
- `total_amount_cents`
- `provider`
- `status`
- `period_start`
- `period_end`
- `checkout_session_id` optional
- `checkout_url` optional
- `payment_intent_id` optional
- `invoice_id` optional
- `paid_at` optional

### `usuarios/{adminId}/descuentos`
Stores one-time or limited-use discount codes.

Required fields:
- `admin_id`
- `code`
- `kind`
- `value`
- `branch_id` optional
- `group_id` optional
- `tariff_id` optional
- `max_uses`
- `uses_count`
- `is_active`
- `expires_at` optional
- `used_by_student_id` optional
- `used_by_charge_id` optional

### `cash_payment_requests`
Stores cash payment requests created from real students.

Required fields:
- `admin_id`
- `student_id`
- `student_name`
- `branch_id`
- `branch_name`
- `group_id`
- `group_name`
- `amount_cents`
- `status`
- `note` optional
- `reviewed_at` optional
- `reviewed_by` optional

## Current UI behavior

- `wallet_screen.dart` reads real branches from Firestore and shows real branch totals.
- `wallet_fees.dart` reads and writes tariff documents for the current admin.
- `cash_payment_requests.dart` lists real pending cash requests and lets the admin approve or reject them.
- `wallet_student_status.dart` derives student payment state from real billing records and filters by branch/group.

## Stripe boundary

Stripe is intentionally not wired yet.
When it is added, it should only populate:
- `checkout_session_id`
- `checkout_url`
- `payment_intent_id`
- `invoice_id`

The wallet UI should keep reading Firestore as the source of truth.
