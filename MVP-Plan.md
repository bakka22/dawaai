# Dawaai MVP Implementation Plan (Complete 40-Phase Version)

# ROLE: Senior Full-Stack Architect & Project Lead
# TASK: Build the Dawaai MVP (Medication Discovery & Delivery System)
# CONTEXT: 
- **Tech Stack:** Flutter (Frontend), Node.js/Express (Backend), PostgreSQL (Database).
- **Environment:** Sudan (Low connectivity, RTL Arabic, IP blocking risks).
- **Core Workflow:** Scan -> Verify -> Broadcast Quote -> Live Bids -> Order -> Regulatory Delivery.

---

# PHASE-BY-PHASE IMPLEMENTATION

## PHASE 1: DB - Initial Setup & Fuzzy Search
- **Task 1:** Initialize a PostgreSQL database and run `CREATE EXTENSION pg_trgm;`.
- **Task 2:** Create the `users` table with `id`, `phone`, `role`, and `refresh_token_hash`.
- **Verification:** Confirm `pg_trgm` is active in the extensions list.

## PHASE 2: DB - Pharmacy & Inventory
- **Task 1:** Create `pharmacies` table with `id`, `owner_id`, `name`, `lat`, `lng`, `is_approved`, and `city`.
- **Task 2:** Create `pharmacy_inventory` with `id`, `pharmacy_id`, `medication_id`, `is_in_stock`, and `price`.
- **Verification:** Check FK constraints on `pharmacy_inventory`.

## PHASE 3: DB - Master Meds & Trigram Indexes
- **Task 1:** Create `medication_master` with `id`, `name`, `active_ingredient`, `synonyms` (JSONB), and `is_flagged`.
- **Task 2:** Create GIN Trigram indexes on `name` and `active_ingredient`.
- **Verification:** Confirm `EXPLAIN ANALYZE` shows index scans on text searches.

## PHASE 4: DB - Quotes & Response Tables
- **Task 1:** Create `quotes` table with `id`, `customer_id`, `status`, and `expires_at`.
- **Task 2:** Create `quote_responses` table linking `quote_id` and `pharmacy_id`.
- **Verification:** Confirm the unique constraint on `(quote_id, pharmacy_id)`.

## PHASE 5: Backend - Basic Express Skeleton
- **Task 1:** Initialize Node.js project with `express`, `pg`, `jsonwebtoken`, and `cors`.
- **Task 2:** Implement a `/health` check and a basic error handler middleware.
- **Verification:** `GET /health` returns 200 OK.

## PHASE 6: Backend - DB Pool & Multer Storage
- **Task 1:** Configure `pg.Pool` for connection management.
- **Task 2:** Setup `multer` storage to save prescription images to `backend/uploads`.
- **Verification:** Successfully upload a test image via Postman.

## PHASE 7: Backend - AWS Proxy Relay Skeleton
- **Task 1:** Create `/api/ocr/relay` endpoint.
- **Task 2:** Implement mock OCR logic that returns a static list of medications.
- **Verification:** Endpoint returns mock text when an image is posted.

## PHASE 8: Backend - JWT & Refresh Token Auth
- **Task 1:** Implement login/register with `accessToken` and `refreshToken` rotation.
- **Task 2:** Implement `POST /auth/refresh` to allow seamless re-auth on weak networks.
- **Verification:** Use a refresh token to obtain a new access token successfully.

## PHASE 9: Flutter - Project & RTL Setup
- **Task 1:** Init Flutter project with `flutter_riverpod`, `dio`, and `connectivity_plus`.
- **Task 2:** Force `TextDirection.rtl` and `Locale('ar')` in `MaterialApp`.
- **Verification:** "Back" button icon points to the right automatically.

## PHASE 10: Flutter - Connectivity & Dio Client
- **Task 1:** Implement a global `ConnectivityWatcher` UI banner.
- **Task 2:** Configure `Dio` with a 3-retry interceptor for connection timeouts.
- **Verification:** Disabling Wi-Fi shows a red "No Internet" bar immediately.

## PHASE 11: Flutter - Auth Screen & WhatsApp Fallback
- **Task 1:** Build the login UI with phone input.
- **Task 2:** Add a "Request via WhatsApp" button that appears on service failure.
- **Verification:** The WhatsApp button opens a deep link with a pre-filled message.

## PHASE 12: Backend - Fuzzy Medication Search
- **Task 1:** Implement `GET /api/meds/search` using `similarity(name, $1)`.
- **Task 2:** Ensure the query checks both the primary name and the `synonyms` JSONB array.
- **Verification:** Searching "بندول" returns "بانادول" (Panadol).

## PHASE 13: Flutter - Scan & OCR Verification UI
- **Task 1:** Camera UI -> Upload to Relay -> Receive Text.
- **Task 2:** Build the Editable List screen where users fix names before searching.
- **Verification:** User can delete an incorrectly scanned item before clicking "Search."

## PHASE 14: Backend - Pharmacy Discovery Ranking
- **Task 1:** Implement `POST /api/search/pharmacies` to find top 5 matches.
- **Task 2:** Sort by `match_count` (DESC) then `distance` (ASC).
- **Verification:** A pharmacy with 3/3 matches is ranked above a 2/3 pharmacy.

## PHASE 15: Backend - Broadcast Quote Workflow
- **Task 1:** `POST /api/quotes/broadcast` creates a quote and notifies matching pharmacies.
- **Task 2:** Set the `expires_at` timestamp to 20 minutes from creation.
- **Verification:** DB shows the quote in 'BROADCASTING' status.

## PHASE 16: Pharmacist - Response UI & Stock Sync
- **Task 1:** UI for pharmacist to input price and availability for a quote.
- **Task 2:** Logic: If an item is marked "Out of Stock," auto-update `pharmacy_inventory`.
- **Verification:** Pharmacist's bid appears in the `quote_responses` table.

## PHASE 17: Flutter - Live Bidding Window
- **Task 1:** Build a live-updating list for the user to see incoming pharmacy bids.
- **Task 2:** Add a "Accept Offer" button that converts the quote to an order.
- **Verification:** Clicking "Accept" triggers the `POST /api/orders/create` flow.

## PHASE 18: Pharmacist - Order Acknowledgment (Bagging)
- **Task 1:** UI for pharmacist to see "Order Won" and click "Prepare Order."
- **Task 2:** Update order status to 'READY_FOR_PICKUP'.
- **Verification:** Order is not visible to drivers until the pharmacist acknowledges.

## PHASE 19: Backend - Multi-Pharmacy Order Splitting
- **Task 1:** Logic: If an order has multiple segments, calculate split payments.
- **Task 2:** Create a unified invoice with total delivery and service fees.
- **Verification:** Invoice breakdown shows sub-totals for each pharmacy.

## PHASE 20: Backend - Logistics: Regulatory Trip Engine
- **Task 1:** If `medication_master.is_flagged` is true, force a "Triple-Leg" sequence.
- **Task 2:** Waypoint generator: [1] Customer (Collect), [2] Pharmacy, [3] Customer (Deliver).
- **Verification:** Regulated orders show a different waypoint map than standard orders.

## PHASE 21: DB - Cosmetics & Personalization
- **Task 1:** Create `cosmetic_products` table and add `skin_type`/`concerns` to `user_profiles`.
- **Task 2:** Insert 10 sample cosmetic products with metadata.
- **Verification:** Query products by `target_skin_type`.

## PHASE 22: Flutter - Onboarding Skin Quiz
- **Task 1:** Build the 4-step quiz UI (Skin type, Allergies, Concerns, Budget).
- **Task 2:** Persist quiz results to the backend user profile.
- **Verification:** Completing the quiz updates the user record in PostgreSQL.

## PHASE 23: Backend - Rule-Based Recommender
- **Task 1:** Implement `GET /api/cosmetics/recommendations`.
- **Task 2:** Logic: Sort products by (SkinMatch * 2) + (ConcernMatch * 1).
- **Verification:** Dry-skin users see moisturizing products at the top of the feed.

## PHASE 24: Flutter - "For You" Feed UI
- **Task 1:** Build the habit-layer home screen with a compact card grid.
- **Task 2:** Add "Recommended" badges with brief explanations (e.g., "Good for Acne").
- **Verification:** Grid displays different products for different user profiles.

## PHASE 25: Pharmacist - Barcode/Bulk Inventory Update
- **Task 1:** Integrate `google_ml_kit` barcode scanning in the pharmacist app.
- **Task 2:** Logic: Batch scan a box to toggle `is_in_stock` in the DB instantly.
- **Verification:** Scanning a barcode updates the DB in under 500ms.

## PHASE 26: Offline - Hive Caching for Orders
- **Task 1:** Implement `Hive` storage to cache `OrderHistory`.
- **Task 2:** Logic: Always display cached data first, then update from network.
- **Verification:** App shows previous orders even in Airplane mode.

## PHASE 27: Driver - Multi-Stop UI & Navigation
- **Task 1:** Build the "Active Trip" screen showing the sequence of waypoints.
- **Task 2:** Add deep-links to external maps (Google/OSM) for each stop.
- **Verification:** Driver can navigate to each stop with one click.

## PHASE 28: Security - Image Reuse Limitation
- **Task 1:** Backend: Hash uploaded prescription images and store in `image_fingerprints`.
- **Task 2:** Logic: Prevent creating a new quote if the hash matches an active/recent quote.
- **Verification:** Uploading the same photo twice within 24 hours returns an error.

## PHASE 29: Admin - Pharmacy & Med Flagging Dashboard
- **Task 1:** Build a simple web dashboard for the ADMIN role.
- **Task 2:** Add UI to approve/block pharmacies and flag medications as "High-Risk."
- **Verification:** Flagging a med instantly updates its delivery requirements in the backend.

## PHASE 30: Backend - Automated Quote Expiry Job
- **Task 1:** Setup a cron job (using `node-cron` or `setInterval`) to check for expired quotes.
- **Task 2:** Logic: If `now > expires_at`, mark quote and its responses as 'EXPIRED'.
- **Verification:** A 20-minute old quote automatically becomes un-orderable.

## PHASE 31: Flutter - Push Notifications (Polling Fallback)
- **Task 1:** Implement a simple polling mechanism for "Order Status" updates.
- **Task 2:** Logic: If Firebase Messaging is blocked, check the server every 60s while the order is active.
- **Verification:** Changing order status in DB reflects in the app within 60s.

## PHASE 32: Driver - Prescription Handover Flow
- **Task 1:** UI for "Paper Prescription Received" checkbox.
- **Task 2:** Logic: Driver must check this box to see the "Pharmacy Pickup" address.
- **Verification:** Prevents driver from visiting the pharmacy without the physical paper.

## PHASE 33: Backend - Logistics: Pickup Window Verification
- **Task 1:** Add `opening_time` and `closing_time` to the `pharmacies` table.
- **Task 2:** Logic: Exclude pharmacies from search if they will close within 1 hour.
- **Verification:** A pharmacy closing at 9:00 PM is not shown in a 8:30 PM search.

## PHASE 34: Flutter - In-App "Help/Chat" via WhatsApp
- **Task 1:** Build a "Need Help?" floating button.
- **Task 2:** Link it to a WhatsApp support number with the `order_id` in the message.
- **Verification:** Clicking the button opens WhatsApp with "Order #123 Help Needed".

## PHASE 35: Backend - Financial Split-Payment Calculator
- **Task 1:** Logic: Create a `billing` summary for each order.
- **Task 2:** Calculate: [Subtotal A] + [Subtotal B] + [Delivery Fee] = [User Total].
- **Verification:** Confirm the DB `order_segments` totals equal the `order` total.

## PHASE 36: Security - JWT Revocation Logic
- **Task 1:** Implement a `token_blacklist` in Redis (or DB) for logged-out users.
- **Task 2:** Update the `authMiddleware` to check against this blacklist.
- **Verification:** A logged-out user cannot use their old Access Token.

## PHASE 37: Deployment - AWS Relay Setup (Real)
- **Task 1:** Deploy the Node.js backend to an AWS EC2 instance outside Sudan.
- **Task 2:** Configure a static IP and SSL certificate (Let's Encrypt).
- **Verification:** Access the API via `https://api.dawaai.com/health` from a Sudanese IP.

## PHASE 38: Testing - Multi-Pharmacy Order Stress Test
- **Task 1:** Script 10 concurrent multi-pharmacy orders.
- **Task 2:** Verify that the "Trip Optimizer" and "Split Billing" handle the load without errors.
- **Verification:** Database consistency check passes after 100 simulated orders.

## PHASE 39: Final - Market Localization (Sudanese SDG)
- **Task 1:** Finalize all labels for "SDG" (Sudanese Pound) and Arabic number formatting.
- **Task 2:** Add "Sudanese Phone Format" masks to all inputs.
- **Verification:** User input "0912345678" is correctly stored as "+249912345678".

## PHASE 40: Launch - Beta Pilot Readiness Check
- **Task 1:** Run a full end-to-end "Regulatory" order from a Sudanese device.
- **Task 2:** Confirm the "No Internet" banner works and the JWT refresh is seamless.
- **Verification:** Successful delivery recorded in the production database.

---
# ADDITIONAL PHASES (Addressing Gaps & Enhancements)

## PHASE 41: Flutter & Backend - Pharmacist Registration & Onboarding
- Task 1: Build pharmacist registration UI with pharmacy details, license upload, and location picker.
- Task 2: Backend endpoint POST /auth/pharmacist/register creates a pending pharmacy record (is_approved = false).
- Task 3: Admin notification to review new registrations.
- Verification: A new pharmacy appears in the admin dashboard with 'PENDING' status.

## PHASE 42: Backend - Push Notification Service for Pharmacists
- Task 1: Integrate Firebase Cloud Messaging (FCM) or fallback to server-sent events.
- Task 2: When a broadcast quote is created (Phase 15), send a notification to the selected pharmacies with the quote ID.
- Task 3: Ensure the AWS relay is used if FCM is blocked in Sudan.
- Verification: Pharmacist device receives a "New Quote Request" notification within 5 seconds of broadcast.

## PHASE 43: Flutter & Backend - Payment Initiation & Gateway Integration
- Task 1: Design the payment method selection UI (COD, local gateway).
- Task 2: Backend endpoint POST /api/payments/initiate creates a payment intent and returns a redirect URL or cash confirmation code.
- Task 3: Integrate one Sudanese payment gateway (e.g., Aphia, MTN MoMo) in the Flutter app via WebView or deep link.
- Task 4: Update POST /api/payments/verify (Phase 28) to handle real gateway callbacks.
- Verification: A test payment can be initiated, completed (mock), and the order status changes to 'PAID'.

## PHASE 44: Backend - Driver Assignment & Basic Dispatch Logic
- Task 1: Create a drivers table with availability status and location.
- Task 2: When an order segment status becomes 'READY_FOR_PICKUP', implement a simple assignment algorithm (nearest available driver).
- Task 3: Driver UI shows assigned orders (already covered in Phase 27).
- Verification: After a pharmacist clicks "Prepare Order," a driver is assigned within 60 seconds and notified.

## PHASE 45: Backend - Behavior Tracking Event Logger
- Task 1: Create an events table (customer_id, event_type, product_id, timestamp).
- Task 2: Implement POST /api/events to log "viewed", "saved", "searched", "purchased".
- Task 3: Integrate logger into the cosmetics feed and search flows.
- Verification: After browsing the "For You" feed, the events table contains viewed product logs.

## PHASE 46: DB & Backend - Spatial Indexing for Distance Queries
- Task 1: Add PostGIS extension or a composite GiST index on pharmacies(lat, lng) if using PostgreSQL geometry.
- Task 2: Rewrite the pharmacy search query in Phase 14 to use an indexed distance calculation (ST_DWithin or a bounding box filter).
- Task 3: Ensure OpenStreetMap distance data can be used efficiently.
- Verification: EXPLAIN ANALYZE shows index scan instead of sequential scan for distance filtering.

## PHASE 47: Admin - Order Monitoring Dashboard
- Task 1: Extend the admin web panel (Phase 29) with an "Orders" tab.
- Task 2: Display all ongoing orders with filters: status, pharmacy, driver, flag status.
- Task 3: Allow admins to manually override status in rare edge cases (e.g., stuck order).
- Verification: Admin can view real-time order status and intervene if needed.

## PHASE 48: Security - Concurrency Control for Quote Responses
- Task 1: Wrap inventory updates during quote responses in a database transaction with SELECT ... FOR UPDATE on the inventory row.
- Task 2: Prevent double inventory deduction when two pharmacists respond simultaneously.
- Verification: Stress test with 5 concurrent responses for the same medication; no negative stock or lost updates.

-----
# CONSTRAINTS & AUDIT RULES
- **Regulatory Safety:** High-risk meds MUST trigger the "Triple-Leg" driver trip.
- **Pharmacist Protection:** No driver is dispatched until the pharmacist clicks "Prepare Order."
- **Privacy:** Hide pharmacy contact strings from customers.

