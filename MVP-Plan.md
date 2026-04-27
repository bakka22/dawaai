# Dawaai MVP Implementation Plan (Final Hardened Version)

# ROLE: Senior Full-Stack Architect & Project Lead
# TASK: Build the Dawaai MVP (Medication Discovery & Delivery System)
# CONTEXT: 
- **Tech Stack:** Flutter (Frontend), Node.js/Express (Backend), PostgreSQL (Database).
- **Environment:** Sudan (Low connectivity, RTL Arabic, IP blocking risks).
- **Core Workflow:** Scan -> Verify -> Broadcast Quote -> Live Bids -> Order -> Regulatory Delivery.

---

# PHASE-BY-PHASE IMPLEMENTATION

## PHASE 1: DB - Initial Setup & Fuzzy Search
- **Goal:** Initialize DB with advanced search capabilities.
- **Task 1:** Initialize a PostgreSQL database named `dawaai_db` and run `CREATE EXTENSION pg_trgm;`.
- **Task 2:** Create the `users` table with `id`, `phone`, `role`, and `refresh_token_hash`.
- **Verification:** Run `SELECT * FROM pg_extension WHERE extname = 'pg_trgm';` to confirm search extension.

## PHASE 2: DB - Pharmacy & Inventory
- **Goal:** Structure pharmacy profiles and their stock.
- **Task 1:** Create `pharmacies` table with `id`, `owner_id`, `name`, `lat`, `lng`, `is_approved`, and `city`.
- **Task 2:** Create `pharmacy_inventory` with `id`, `pharmacy_id`, `medication_id`, `is_in_stock`, and `price`.
- **Verification:** Confirm foreign key between `pharmacies` and `users`.

## PHASE 3: DB - Master Meds & Trigram Indexes
- **Goal:** High-performance medication search.
- **Task 1:** Create `medication_master` with `id`, `name`, `active_ingredient`, `synonyms` (JSONB), and `is_flagged`.
- **Task 2:** Create GIN Trigram indexes on `name` and `active_ingredient` for fuzzy matching.
- **Verification:** Run `EXPLAIN ANALYZE` on a `LIKE` query to confirm index usage.

## PHASE 4: DB - Quotes (Broadcast Ready)
- **Goal:** Support multiple pharmacy responses.
- **Task 1:** Create `quotes` table with `id`, `customer_id`, `status`, and `expires_at` (20-min TTL).
- **Task 2:** Create `quote_responses` table (links `quote_id` to `pharmacy_id`) to store individual pharmacy bids.
- **Verification:** Confirm `expires_at` is structured to handle auto-expiry logic.

## PHASE 5: Backend - Basic Express Skeleton
- **Goal:** Initialize the Node.js environment.
- **Task 1:** Run `npm init` and install `express`, `pg`, `jsonwebtoken`, `bcryptjs`, and `cors`.
- **Task 2:** Create `src/index.js` with a basic health check endpoint `GET /health`.
- **Verification:** `GET /health` returns `{"status": "ok"}`.

## PHASE 6: Backend - DB Pool & S3/Local Storage
- **Goal:** Handle data and file persistence.
- **Task 1:** Create `src/db/config.js` with `pg.Pool`.
- **Task 2:** Setup `multer` and a storage service (Local for MVP, S3-ready) to save prescription images.
- **Verification:** Server logs "Storage Service Ready" on startup.

## PHASE 7: Backend - AWS Proxy Relay Skeleton
- **Goal:** Bypass Sudan's IP blocks for Google APIs.
- **Task 1:** Create `src/routes/relay.js`.
- **Task 2:** Implement a dummy `POST /api/ocr/relay` that accepts a file and returns mock text.
- **Verification:** Test upload via Postman; confirm server returns 200 and mock data.

## PHASE 8: Backend - JWT & Refresh Token Auth
- **Goal:** Robust sessions for weak networks.
- **Task 1:** Implement `POST /auth/login` that returns both an `accessToken` (15 min) and a `refreshToken` (30 days).
- **Task 2:** Create `POST /auth/refresh` to rotate tokens without re-logging via SMS.
- **Verification:** Verify that an expired Access Token can be refreshed using a valid Refresh Token.

## PHASE 9: Flutter - Project & State Management
- **Goal:** Setup mobile architecture with Riverpod.
- **Task 1:** Create Flutter project and add `flutter_riverpod`, `dio`, and `connectivity_plus`.
- **Task 2:** Configure `MaterialApp` with `Locale('ar')` and `TextDirection.rtl`.
- **Verification:** App runs and can print "Riverpod Ready" to console.

## PHASE 10: Flutter - Connectivity & Retry Logic
- **Goal:** Resilience against 3G/4G drops.
- **Task 1:** Implement a `ConnectivityWatcher` that shows a global "No Internet" bar at the top of the UI.
- **Task 2:** Wrap `Dio` in a custom client that auto-retries failed requests 3 times.
- **Verification:** Toggle Wi-Fi; confirm the "No Internet" bar appears/disappears instantly.

## PHASE 11: Flutter - Auth Screen (Hybrid Flow)
- **Goal:** Phone login with WhatsApp fallback.
- **Task 1:** UI for phone input + OTP input.
- **Task 2:** Logic: If Firebase SMS fails (or service blocked), show the "Request via WhatsApp" deep-link button.
- **Verification:** Successful login stores tokens in `FlutterSecureStorage`.

## PHASE 12: Backend - Fuzzy Medication Search
- **Goal:** Handle Arabic typos and synonyms.
- **Task 1:** Implement `GET /api/meds/search`.
- **Task 2:** Use SQL `similarity(name, $1) > 0.3` to find matches even with spelling errors.
- **Verification:** Searching "بندول" returns "بانادول" successfully.

## PHASE 13: Flutter - Prescription Scan & Verification
- **Goal:** Capture and edit medication list.
- **Task 1:** Camera screen -> Upload to Relay -> Receive Text.
- **Task 2:** Build the Editable List screen where users fix names before searching.
- **Verification:** User can scan, edit a typo, and proceed to the search result screen.

## PHASE 14: Backend - Pharmacy Discovery & Ranking
- **Goal:** Find the best fulfillment options.
- **Task 1:** `POST /api/search/pharmacies` calculates match counts for top 5 nearby pharmacies.
- **Task 2:** Hide contact info; return only `pharmacy_id`, `name`, `match_count`, and `distance`.
- **Verification:** API returns a list sorted by most medications found.

## PHASE 15: Backend - Broadcast Quote Workflow
- **Goal:** Speed up quotes by asking multiple pharmacies.
- **Task 1:** `POST /api/quotes/broadcast` creates a `quote` and notifies the top 3 matching pharmacies simultaneously.
- **Task 2:** Implement an `expires_at` check that marks the quote as EXPIRED after 20 minutes.
- **Verification:** 3 notifications are sent; DB shows the quote as 'BROADCASTING'.

## PHASE 16: Pharmacist - Response UI & Live Bidding
- **Goal:** Pharmacists provide price and availability.
- **Task 1:** UI for pharmacists to respond to a broadcast. They enter price and mark availability for items.
- **Task 2:** Logic: Marking an item "Out of Stock" here updates the pharmacy's global inventory.
- **Verification:** Pharmacy response is recorded in `quote_responses`.

## PHASE 17: Flutter - Quote Review & Selection
- **Goal:** User picks the best offer from live bids.
- **Task 1:** Screen shows a live-updating list of responses from pharmacies (Bidding Window).
- **Task 2:** User clicks "Accept" on a specific response to finalize the deal.
- **Verification:** Accept triggers `POST /api/orders/create` for the chosen pharmacy.

## PHASE 17b: Pharmacist - Order Acknowledgment
- **Goal:** Pharmacist confirms they are bagging the items.
- **Task 1:** Pharmacist receives an "Order Won" notification.
- **Task 2:** Pharmacist must click "Prepare Order" to signal that the physical stock is secured.
- **Verification:** Order status moves to 'PREPARING', then 'READY_FOR_PICKUP'.

## PHASE 18: Backend - Order Segments & Unified Billing
- **Goal:** Handle split orders (Pharmacy A + Pharmacy B).
- **Task 1:** If the user creates a multi-pharmacy order, the system creates two `order_segments`.
- **Task 2:** Calculate a single total invoice for the user, including multi-stop delivery fees.
- **Verification:** User sees one invoice; DB shows split payments for each pharmacy.

## PHASE 19: Backend - Logistics: Regulatory Trip Engine
- **Goal:** Legal compliance for high-risk meds.
- **Task 1:** Logic: If meds are flagged, the trip is sequenced as: `Driver -> Customer (Collect Paper) -> Pharmacy (Exchange Paper for Meds) -> Customer (Deliver)`.
- **Task 2:** If not flagged: `Driver -> Pharmacy -> Customer`.
- **Verification:** Algorithm returns different waypoint sequences based on medication `is_flagged` status.

## PHASE 20: Driver - Verification & Delivery
- **Goal:** Final proof of handoff.
- **Task 1:** Driver app displays step-by-step instructions (e.g., "Collect Paper First").
- **Task 2:** Driver must upload a photo of the prescription at the door to unlock the "Complete Order" button.
- **Verification:** Order status only moves to 'COMPLETED' after photo upload is verified by the server.

---

# CONSTRAINTS & AUDIT RULES
- **Session Security:** Use JWT with Refresh Tokens to prevent disconnect-logouts.
- **Fuzzy Search:** Always use Trigram Similarity for medication names.
- **Regulatory Safety:** High-risk meds MUST trigger the "Triple-Leg" driver trip.
- **Pharmacist Protection:** No driver is dispatched until the pharmacist clicks "Prepare Order."
