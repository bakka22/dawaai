# Dawaai - Medication Discovery & Delivery App

## Project Overview

**Dawaai** is a robust Flutter mobile application designed for the Sudanese market. It solves the challenge of medication scarcity and fragmented inventory by allowing users to scan prescriptions, receive real-time availability quotes from pharmacies, and have medications delivered to their doorstep.

### Extended Vision (Habit Utility Layer)
Dawaai evolves from a transactional medical app into a **habit utility platform** by introducing a **Cosmetics & Personal Care ecosystem**.  
This layer increases engagement frequency by addressing emotional triggers such as:
- Feeling down
- Desire to improve appearance
- Curiosity about health and beauty

The platform combines:
- **High-frequency engagement (cosmetics & content)**
- **High-value transactions (medication & prescriptions)**

---

### Target Market
- **Country**: Sudan (East Africa)
- **Languages**: Arabic (RTL) + English
- **Model**: Delivery-Only (Pharmacy contact info is hidden to maintain platform integrity).

---

## Core Features & Workflows

### 1. Advanced Prescription Processing
- **OCR with Verification:** Users scan prescriptions via camera. The app processes the image through a backend-relayed Google Vision API.
- **Manual Correction:** Users must verify and edit the extracted medication list side-by-side with the original image to correct handwriting misinterpretations.
- **Security:** Image-based reuse limitations to prevent multiple fills of the same prescription.

---

### 2. Intelligent Search & Quoting
- **Master Drug List:** Backend maps brand names to active ingredients and synonyms.
- **Alternative Brands:** App suggests "Alternative Companies" (شركات أخرى) if the specific requested brand is unavailable.
- **Mandatory Quote Flow:** Instead of direct ordering, users send a "Quote Request." Pharmacists must confirm current availability and price before the user can finalize the order.
- **Search Priority:** Results are ranked by **Completeness** (pharmacies with all items first), then by **Distance**.

---

### 3. Pharmacist Inventory Management
- **Scan-to-Update:** Pharmacists can update stock by scanning barcodes or using OCR to read a list of medication names.
- **Auto-Sync:** Marking an item as "Out of Stock" during a quote automatically updates the pharmacy's public inventory.
- **Integration:** API hooks for connecting existing pharmacy management software to the Dawaai backend.

---

### 4. Multi-Pharmacy Logistics
- **Smart Splitting:** If no single pharmacy has the full prescription, an algorithm calculates the optimal delivery route across multiple pharmacies.
- **Unified Invoice:** Users see one total (Meds + Delivery + Service Fee). The backend handles the complex splitting of payments to different vendors.
- **Flexible Payments:** Support for local Sudanese payment gateways (via verification codes) and Cash on Delivery (COD).

---

### 5. Safety & Physical Verification
- **Tiered Medication Flags:** High-risk medications are flagged in the database.
- **Driver Verification:** 
    - **Standard:** Driver verifies the physical prescription upon delivery.
    - **High-Risk:** Driver may be required to take a photo of the prescription, stamp it, or collect the physical paper before handing over medications.

---

### 6. Cosmetics & Personal Care (Habit Layer)

#### Purpose
Increase user engagement frequency by providing a **personalized beauty discovery and shopping experience**.

#### Core Capabilities
- **Cosmetics Search & Comparison:** Users can search, compare prices, and check availability across pharmacies.
- **Personalized Recommendations:** Products recommended based on user profile and behavior.
- **Content & Blog:** Health and beauty educational content to drive engagement.
- **Price Awareness:** Highlight best prices and availability nearby.

---

## Personalization & Recommendation System

### 1. User Profile (MVP)
Basic profile used for personalization:

- Skin type (oily, dry, combination, sensitive)
- Skin concerns (acne, dryness, dark spots, etc.)
- Budget range
- Sensitivities (e.g., fragrance)
- Preferred product types
- Location

---

### 2. Product Intelligence Model
Each product is structured with:

- Category
- Supported skin types
- Targeted concerns
- Key ingredients
- Sensitivity flags (e.g., fragrance)
- Price
- Availability by pharmacy

---

### 3. Recommendation Engine (Phase 1 - Rule-Based)

#### Scoring Logic
Products are ranked using a weighted score:

- Skin Match
- Concern Match
- Safety Match
- Budget Match
- Availability Boost

#### Contextual Ranking
Final ranking includes:

- Availability
- Distance
- Price
- Pharmacy reliability

---

### 4. Explainable Recommendations
Each product includes a “Why this product?” section:

- Matches your skin type
- Helps your concern
- Safe for your sensitivities
- Available nearby

---

### 5. Behavior Tracking (Initial Signals)

Track user actions:

- Viewed products
- Saved products
- Searches
- Purchases

Used to improve ranking and personalization over time.

---

### 6. Feedback Loop

Post-purchase feedback:

- Product effectiveness
- Irritation or issues

Used to refine future recommendations.

---

## User Experience Layer (Habit Design)

### Entry Experience
Hybrid approach:
- Initial lightweight profile (optional)
- Immediate access to personalized feed

---

### Home Screen (Primary Entry Point)

“For You” personalized feed including:

- Recommended products
- Solutions for user concerns
- Products for skin type
- Best prices nearby

---

### Engagement Drivers
- Personalized recommendations
- Content (blog/articles)
- Price drops / availability signals

---

## Technical Stack & Infrastructure

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Flutter (Dart) | Cross-platform mobile app (RTL Support) |
| **Backend** | Node.js (Express) | Business logic and logistics engine |
| **Database** | PostgreSQL | Relational data for inventory/orders |
| **Auth** | Firebase + WhatsApp | Hybrid Auth: Firebase primary, WhatsApp fallback |
| **OCR/AI** | Google Cloud Vision | Relayed via **AWS Proxy** to bypass regional blocking |
| **Maps** | OpenStreetMap (OSM) | Distance calculation and trip optimization |
| **Offline** | Local Caching | Order history visible without internet |

---

## Architecture & Data Flow

### AWS Relay Strategy
To ensure resilience against regional IP blocking in Sudan, the mobile app does not communicate with Google Cloud services directly. Instead:
`Mobile App -> AWS Proxy Server (Global) -> Google Cloud Vision / Firebase -> AWS Proxy -> Mobile App`

---

### Directory Structure
```
dawaai/
├── flutter_app/          # Mobile Frontend
│   ├── lib/
│   │   ├── core/         # Caching, Proxy Config, Themes (RTL)
│   │   ├── features/
│   │   │   ├── auth/     # Hybrid Auth Logic
│   │   │   ├── quote/    # Request/Response Flow
│   │   │   ├── search/   # Synonym/Master List Logic
│   │   │   └── delivery/ # Driver/Verification Tracking
│
└── backend/             # Node.js API
    ├── src/
    │   ├── services/
    │   │   ├── logistics.js  # Multi-stop trip optimizer
    │   │   ├── payment.js    # Split-payment logic
    │   │   └── inventory.js  # Master Drug List & Sync
    └── ...
```

---

## Database Schema (Key Enhancements)

- **medication_master:** Standardized list with `synonyms` and `active_ingredients`.
- **medication_flags:** Mapping of meds to `verification_level` (None, Photo, Collect Paper).
- **quotes:** Interim state between Search and Order.
- **order_segments:** Tracks different pharmacy pickups for a single customer order.

---

## MVP Scope (Phase 1)

1. **Hybrid Auth:** SMS via Firebase with a manual WhatsApp verification button.
2. **Verified OCR:** Basic scan + user edit screen.
3. **Single Pharmacy Flow:** Full Quote -> Order -> Delivery lifecycle.
4. **Basic Inventory:** Pharmacist "Scan-to-Update" feature.
5. **Driver App:** Simple "Verify Prescription" checklist.
6. **AWS Relay:** Setup to ensure all external services work reliably in Sudan.
### Added MVP Extensions
7. Basic Cosmetics Catalog
8. User Profile (Skin Type + Concerns)
9. Rule-Based Recommendation Engine
10. “For You” Feed (Simple Ranking)
11. Product Explanation (“Why this?”)
12. Basic Behavior Tracking