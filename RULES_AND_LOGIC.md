# KUTHAKA (കുത്തക) — Rules, Mechanics & System Logic

> **IMPORTANT MAINTENANCE NOTICE**:
> This document is the single source of truth for all gameplay rules, monetary valuations, turn lifecycle mechanics, and implementation logic of **Kuthaka**.
> **Any future modifications to gameplay, rule behavior, economics, tile pricing, or state machines MUST be documented and kept up-to-date in this file.**

---

## 1. Objective of the Game

The objective of **Kuthaka** is to become the wealthiest player across God's Own Country (Kerala) through buying, renting, upgrading, and trading prime real estate until all opponents are driven into bankruptcy.

---

## 2. Starting Setup & Bankroll

* **Starting Cash**: Every player begins the match with **₹1,000** in liquid cash.
* **Starting Position**: Space `0` (**NAATTILE THUDAKKAM** / GO).
* **Player Tokens**: Traditional Kerala tokens including Thenga (Coconut), Chundan Vallam (Houseboat), Aana (Elephant), Chaya Glass, Minnal Bus, Palm Tree, and Nilavilakku.
* **Roster**: 2 to 4 players (Local Pass & Play, AI Bots with distinct personalities, or Online Multiplayer).

---

## 3. Turn Sequence & Dice Mechanics

1. **Roll Dice**: The active player rolls two 6-sided dice (`d1` and `d2`).
2. **Stepwise Movement**: The player token hops clockwise around the 40-space perimeter by the sum (`d1 + d2`) with a smooth, readable jump pacing (2.8 steps/sec).
3. **Space Action**: Upon landing on a tile, the specific space action is triggered (Buy/Auction, Pay Rent, Draw Card, Pay Tax, etc.).
4. **30-Second Turn Timer**:
   * Each player is allocated a strict **30-second countdown timer** to complete their turn actions (roll, buy/auction, trade, mortgage).
   * **Timeout / Pass Turn**: If the timer hits `0s`, the turn is forcibly concluded and passed immediately to the next player.
   * **3-Consecutive Timeout Elimination**: If a specific player fails to play for **3 consecutive times** (accumulating 3 consecutive strikes), that player is **eliminated from the game**.
   * **Property Forfeiture**: All properties, transports, and utilities owned by the eliminated player are immediately **forfeited and reset to unowned status** (`ownerId = null`, cottages/resorts removed, mortgages cleared), making them available for any player to purchase or auction upon landing on them.
5. **Doubles Rule**:
   * If a player rolls identical numbers on both dice (`d1 == d2`), they roll **Doubles**.
   * The player moves as normal, completes the tile's action, and **receives an immediate extra roll**.
   * **Three Consecutive Doubles Penalty**: If a player rolls doubles 3 times in succession within the same turn, their turn ends immediately and they are sent directly to **Police Lockup (Jail)** without completing their 3rd movement.
6. **Turn End**: If doubles were not rolled (or if doubles bonus was used), turn passes to the next non-bankrupt player and the 30-second timer resets.

---

## 4. Board Spaces & Tile Actions

### 4.1 Naattile Thudakkam (GO — Space 0)
* Each time a player's token lands on or passes over **Naattile Thudakkam**, the Bank pays that player a **₹200 salary**.
* If a card directs a player to "Advance to Start", they collect the ₹200 salary upon arrival.

---

### 4.2 Unpurchased Properties & The Auction System

When a player lands on an unowned property, railroad, or utility, they have **two options**:
1. **BUY**: Purchase the Title Deed from the Bank at the printed face value.
2. **AUCTION**: Put the property up for public auction to the highest bidder.

#### Auction Rules:
* **First Bidder**: Per official rules, **the landing player bids first**.
* **Order of Bidding**: Clockwise turn order starting from the landing player.
* **Bidding Actions**:
  * **Bid**: Place an opening bid or increase the current highest bid (minimum increment of ₹10 or quick `+₹20`).
  * **Pass**: Drop out of the auction for this property. Once a player passes, they cannot bid again in this auction.
* **Winning the Auction & Auto-Close**:
  * When all other bidders have passed, the highest bidder pays the Bank their winning bid amount in cash and receives the Title Deed.
  * If all players (including the initiator) pass without placing a single bid, the property remains unowned.
  * **Auto-Close Modal**: Once the winning bid is finalized or all players pass, the auction overlay window automatically closes for all players after a 2.5-second countdown, smoothly resuming gameplay without requiring manual clicks.
* **Doubles Continuity**:
  * If the landing player rolled doubles, they still retain their **extra roll** after the auction concludes!

---

### 4.3 Owned Properties & Inward Ownership Extensions

* **Inward Tile Extensions (Ownership Indicators)**:
  * Each purchased tile displays an ownership tab jutting **inwards toward the center of the board** from its inner border.
  * The inward extension is rendered in the owner's signature player color with a Kasavu gold accent border, drop shadow, and a circular badge displaying the owner's initial (or 'M' when mortgaged).
  * This ensures instant, high-contrast visibility of who owns every space on the board without obstructing space text or graphics.
* When landing on an opponent's property, rent is immediately deducted from the visitor and paid to the owner.
* **Monopoly (Color-Group Complete)**: Holding all Title Deeds in a color-group doubles the base rent on all unimproved properties in that group.
* **Mortgaged Properties**: If a property is mortgaged, **no rent can be collected** when opponents land on it, and the inward badge displays an orange 'M'.

---

### 4.4 Houses & Hotels (Cottages & Luxury Resorts)

* **Eligibility**: Players can only construct buildings when they own **all properties** in that color group (Monopoly).
* **Even Building Rule**: Construction must be even across the color group. A player cannot build a 2nd cottage on a property until every property in that group has at least 1 cottage, and so forth.
* **Building Limits**:
  * Up to **4 Cottages** (Houses) per property.
  * Upgrade from 4 Cottages to **1 Luxury Resort** (Hotel). The 4 cottages are returned to the Bank upon erecting the Resort.
  * Only 1 Resort may be built on any single property.
* **Demolition / Selling Back**: Buildings may be sold back to the Bank at any time for **half of their original upgrade cost**.

---

### 4.5 Transports (Railroads) & Utilities

* **Transports (4 Spaces)**:
  * KSRTC Stand, Kochi Metro, Ferry, Airport.
  * Price: **₹135** each.
  * Rent scales with total transports owned:
    * 1 Transport: **₹15**
    * 2 Transports: **₹35**
    * 3 Transports: **₹70**
    * 4 Transports: **₹135**
* **Utilities (2 Spaces)**:
  * KSEB (Electricity) & Water Authority.
  * Price: **₹100** each.
  * Rent depends on the dice roll:
    * 1 Utility owned: **4× dice total**
    * Both Utilities owned: **10× dice total**

---

### 4.6 Taxes

* **Property Tax (Space 4)**: Fixed fee of **₹70** paid to the Bank.
* **Panchayath Tax (Space 38)**: Fixed fee of **₹35** paid to the Bank.

---

### 4.7 Police Lockup (Hospital / Jail — Space 10)

#### A player is sent to Jail when:
1. Landing on **Police Station** (Space 30 — "Go to Jail").
2. Drawing a **"Go to Jail"** card from Monsoon or Festival decks.
3. Rolling **Doubles 3 times in succession**.

#### While in Jail:
* You cannot collect the ₹200 salary for passing Start on that move.
* Your turn ends immediately upon being sent to Jail.
* You **can still collect rent**, bid in auctions, trade, and mortgage/upgrade properties.

#### How to get out of Jail:
1. **Roll Doubles** on any of your next three turns. If successful, you move forward by the dice sum. (You do not get an extra roll after escaping on doubles).
2. **Use a "Get Out of Jail Free" Card** (acquired from Chance / Community Chest).
3. **Pay a fine of ₹100**:
   * Can be paid voluntarily before rolling on turn 1 or 2 in Lockup.
   * If doubles are not rolled by the 3rd turn, the player is **forced to pay the ₹100 fine** and moves forward according to the roll.

#### Just Visiting:
* If a player lands on Space 10 through normal dice movement, they are **"Just Visiting"** the Hospital/Lockup with no penalty.

---

### 4.8 Mortgages

* Any unimproved property may be mortgaged to the Bank at any time for **50% of its purchase price** (printed on the Deed).
* All buildings in a color group must be sold back to the Bank (at 50% price) before any property in that group can be mortgaged.
* **Unmortgaging**: To lift a mortgage and restore rent collection, the owner must pay the Bank the **mortgage value plus 10% interest**.

---

### 4.9 Bankruptcy & Cash Deficits

* A player is declared **bankrupt** if their total debts exceed their total liquid cash and potential mortgage/sale value.
* If indebted to another player: all cash and properties transfer to that creditor player.
* If indebted to the Bank: all properties revert to unowned status and are put up for auction.

---

## 5. Complete Board Spaces & Valuation Catalog

All values scaled proportionally for the **₹1,000 Starting Cash** baseline:

| Space Index | Name | Category | Group | Price | Base Rent | 1 Cottage | 2 Cottages | 3 Cottages | 4 Cottages | Resort | Upgrade Cost | Mortgage Value |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **0** | **NAATTILE THUDAKKAM** | Start (GO) | — | — | +₹200 salary | — | — | — | — | — | — | — |
| **1** | Vengeri | Property | Malabar (Brown) | ₹40 | ₹2 | ₹10 | ₹30 | ₹90 | ₹160 | ₹250 | ₹30 | ₹20 |
| **2** | Vishu Kaineettam | Community Chest | — | — | Card Draw | — | — | — | — | — | — | — |
| **3** | Beypore | Property | Malabar (Brown) | ₹40 | ₹2 | ₹12 | ₹40 | ₹120 | ₹200 | ₹300 | ₹30 | ₹20 |
| **4** | Property Tax | Tax | — | — | Pay ₹70 | — | — | — | — | — | — | — |
| **5** | KSRTC Stand | Transport | Transport | ₹135 | ₹15 | ₹35 (2) | ₹70 (3) | ₹135 (4) | — | — | — | ₹70 |
| **6** | Nilambur | Property | Malabar (Brown) | ₹50 | ₹3 | ₹15 | ₹45 | ₹130 | ₹220 | ₹320 | ₹30 | ₹25 |
| **7** | Monsoon Alert | Chance | — | — | Card Draw | — | — | — | — | — | — | — |
| **8** | Payyanur | Property | Kochi (Pink) | ₹70 | ₹4 | ₹20 | ₹60 | ₹180 | ₹270 | ₹370 | ₹35 | ₹35 |
| **9** | Fort Kochi | Property | Kochi (Pink) | ₹70 | ₹4 | ₹20 | ₹60 | ₹180 | ₹270 | ₹370 | ₹35 | ₹35 |
| **10** | Hospital (Lockup) | Jail | — | — | Visiting / Lockup | — | — | — | — | — | — | — |
| **11** | Marine Drive | Property | Kochi (Pink) | ₹80 | ₹5 | ₹25 | ₹70 | ₹200 | ₹300 | ₹400 | ₹35 | ₹40 |
| **12** | KSEB | Utility | Utility | ₹100 | 4× / 10× Dice | — | — | — | — | — | — | ₹50 |
| **13** | Mattancherry | Property | Thrissur (Light Blue) | ₹90 | ₹7 | ₹35 | ₹100 | ₹300 | ₹410 | ₹500 | ₹65 | ₹45 |
| **14** | Vyttila | Property | Thrissur (Light Blue) | ₹90 | ₹7 | ₹35 | ₹100 | ₹300 | ₹410 | ₹500 | ₹65 | ₹45 |
| **15** | Kochi Metro | Transport | Transport | ₹135 | ₹15 | ₹35 (2) | ₹70 (3) | ₹135 (4) | — | — | — | ₹70 |
| **16** | Swaraj Round | Property | Thrissur (Light Blue) | ₹110 | ₹8 | ₹40 | ₹120 | ₹330 | ₹470 | ₹600 | ₹65 | ₹55 |
| **17** | Onam Sadya | Community Chest | — | — | Card Draw | — | — | — | — | — | — | — |
| **18** | Vadakkunnathan | Property | Backwaters (Orange) | ₹120 | ₹9 | ₹45 | ₹130 | ₹370 | ₹500 | ₹630 | ₹70 | ₹60 |
| **19** | Athirappilly | Property | Backwaters (Orange) | ₹120 | ₹9 | ₹45 | ₹130 | ₹370 | ₹500 | ₹630 | ₹70 | ₹60 |
| **20** | Chaya Kada | Free Parking | — | — | Free Rest (No fee) | — | — | — | — | — | — | — |
| **21** | Guruvayur | Property | Backwaters (Orange) | ₹135 | ₹11 | ₹55 | ₹150 | ₹400 | ₹530 | ₹670 | ₹70 | ₹70 |
| **22** | Monsoon Alert | Chance | — | — | Card Draw | — | — | — | — | — | — | — |
| **23** | Alappuzha | Property | Highlands (Red) | ₹150 | ₹12 | ₹60 | ₹170 | ₹470 | ₹580 | ₹700 | ₹100 | ₹75 |
| **24** | Kumarakom | Property | Highlands (Red) | ₹150 | ₹12 | ₹60 | ₹170 | ₹470 | ₹580 | ₹700 | ₹100 | ₹75 |
| **25** | Ferry | Transport | Transport | ₹135 | ₹15 | ₹35 (2) | ₹70 (3) | ₹135 (4) | — | — | — | ₹70 |
| **26** | Kuttanad | Property | Highlands (Red) | ₹160 | ₹13 | ₹65 | ₹200 | ₹500 | ₹610 | ₹730 | ₹100 | ₹80 |
| **27** | Ashtamudi | Property | South Kerala (Yellow) | ₹175 | ₹15 | ₹75 | ₹220 | ₹530 | ₹650 | ₹770 | ₹100 | ₹90 |
| **28** | Water Authority | Utility | Utility | ₹100 | 4× / 10× Dice | — | — | — | — | — | — | ₹50 |
| **29** | Munnar | Property | South Kerala (Yellow) | ₹175 | ₹15 | ₹75 | ₹220 | ₹530 | ₹650 | ₹770 | ₹100 | ₹90 |
| **30** | Police Station | Go To Jail | — | — | Sent to Hospital Lockup | — | — | — | — | — | — | — |
| **31** | Wayanad | Property | South Kerala (Yellow) | ₹190 | ₹16 | ₹80 | ₹240 | ₹570 | ₹680 | ₹800 | ₹100 | ₹95 |
| **32** | Vagamon | Property | Premium (Green) | ₹200 | ₹17 | ₹85 | ₹260 | ₹600 | ₹730 | ₹850 | ₹135 | ₹100 |
| **33** | Vishu Kaineettam | Community Chest | — | — | Card Draw | — | — | — | — | — | — | — |
| **34** | Thekkady | Property | Premium (Green) | ₹200 | ₹17 | ₹85 | ₹260 | ₹600 | ₹730 | ₹850 | ₹135 | ₹100 |
| **35** | Airport | Transport | Transport | ₹135 | ₹15 | ₹35 (2) | ₹70 (3) | ₹135 (4) | — | — | — | ₹70 |
| **36** | Monsoon Alert | Chance | — | — | Card Draw | — | — | — | — | — | — | — |
| **37** | Bekal Fort | Property | Premium (Green) | ₹215 | ₹19 | ₹100 | ₹300 | ₹670 | ₹800 | ₹930 | ₹135 | ₹110 |
| **38** | Panchayath Tax | Tax | — | — | Pay ₹35 | — | — | — | — | — | — | — |
| **39** | Kovalam | Property | Luxury (Dark Blue) | ₹240 | ₹25 | ₹120 | ₹330 | ₹730 | ₹870 | ₹1000 | ₹135 | ₹120 |

---

## 6. System Architecture & Code Implementation Mapping

| Module / System | Primary Source File(s) | Description |
| :--- | :--- | :--- |
| **Game State Model** | [`lib/providers/game_provider.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/providers/game_provider.dart) | Contains `GameState`, `GamePhase`, and immutable player/property mappings. |
| **Turn Lifecycle & Dice** | [`lib/providers/game_provider.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/providers/game_provider.dart) | Controls `rollDice`, stepwise player animation, doubles verification, and jail tracking. |
| **Auction Engine** | [`lib/models/auction_state.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/models/auction_state.dart), [`lib/providers/game_provider.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/providers/game_provider.dart) | Handles bid bidding order (landing player first), AI bot bidding personality, passing, and property transfer. |
| **Auction UI Overlay** | [`lib/ui/overlays/auction_overlay.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/ui/overlays/auction_overlay.dart) | Renders real-time bidding modal, quick bid buttons, custom bid inputs, and winner banner. |
| **Property Card Overlay** | [`lib/ui/overlays/property_card_overlay.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/ui/overlays/property_card_overlay.dart) | Presents title deed specs and the dual `BUY` / `AUCTION` actions when landed on unowned tiles. |
| **Board Canvas Component** | [`lib/game/components/board_component.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/game/components/board_component.dart) | Custom high-performance canvas painter for board spaces, dynamic price tags, and cottages/resorts. |
| **Catalog Data** | [`lib/data/game_data.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/data/game_data.dart) | Master definition of the 40 spaces, property prices, rents, upgrade costs, and event cards. |
| **User Profile & Custom Name** | [`lib/services/user_profile_service.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/services/user_profile_service.dart), [`lib/ui/screens/user_profile_screen.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/ui/screens/user_profile_screen.dart) | Manages player identity, custom name entry, character preset selection, token lore, signature colors, and local persistence. |
| **Turn Timer & Timeouts** | [`lib/providers/game_provider.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/providers/game_provider.dart), [`lib/models/player.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/models/player.dart) | 30s turn countdown, forced turn pass on timeout, 3-consecutive-timeout elimination, and property unowning/forfeiture. |
| **Inward Ownership Tabs** | [`lib/game/components/board_component.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/game/components/board_component.dart) | Draws 13px inward-jutting tabs toward the center of the board with player signature colors, gold trim, and owner initial badge. |
| **Token Hop Animation** | [`lib/game/components/player_token_component.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/game/components/player_token_component.dart) | Paced stepwise pawn hopping across spaces at 2.8 steps/sec. |
| **Kerala Names Pool** | [`lib/services/user_profile_service.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/services/user_profile_service.dart), [`lib/ui/screens/user_profile_screen.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/ui/screens/user_profile_screen.dart) | 70+ Kerala character pool and dynamic "Shuffle / Random Name" dice button generator. |
| **Rules Help Guides** | [`lib/ui/screens/home_screen.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/ui/screens/home_screen.dart), [`lib/ui/overlays/game_menu_dialog.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/lib/ui/overlays/game_menu_dialog.dart) | User-facing simple rules modal accessible from main menu and in-game pause dialog. |
| **Unit & Logic Tests** | [`test/rules_test.dart`](file:///c:/Users/ksyed/.gemini/antigravity/scratch/monopoly/test/rules_test.dart) | Test suite validating doubles extra rolls, auction mechanics, timeouts, forfeiture, tariffs, and Kerala names. |

---

## 7. Change Log & Maintenance History

* **v1.3.0**:
  * **30-Second Turn Timer**:
    * Each player has 30 seconds to make their move. Turn auto-passes on expiration.
  * **3-Consecutive Timeout Elimination Rule**:
    * If a player fails to play for 3 consecutive turns, they are removed from the game.
    * All properties, transports, and utilities owned by the player are immediately unowned (`ownerId = null`), cleared of improvements, and made available for purchase/auction.
  * **Inward Tile Ownership Extensions**:
    * Added clear inward-facing ownership tabs on all 4 board edges rendered in the owner's color with Kasavu gold border and owner initial/mortgage badges.
  * **Center Dice Removal**:
    * Removed center board die animation so the board center features the elegant Kerala Kuthaka seal, with dice results cleanly shown on HUD side trays.
  * **Auction Auto-Close**:
    * Once a bid is finalized or all bidders pass, the auction dialog displays a closing banner and automatically closes after 2.5 seconds.
  * **Reduced Jumping Animation Speed**:
    * Hop speed between tiles calibrated to a smooth, relaxed 2.8 steps/sec.
  * **Kerala Character Shuffle & Names Pool**:
    * Replaced static preset chips with a dedicated "Kerala Shuffle 🎲" random generator tapping into a 70+ iconic character pool (Dasan, Vijayan, Aadu Thoma, Mangalassery Neelakandan, Induchoodan, etc.).
  * **Transport & Utilities Tariffs & Descriptions**:
    * Verified and corrected deed card descriptions to match actual gameplay values (Transports ₹15–₹135; Utilities 4× and 10× dice total) scaled for the ₹1,000 baseline.
* **v1.2.0**:
  * Added **Custom Player Name Option** in Profile:
    * Implemented dual-mode selector in Profile: **Custom Name** vs **Kerala Character Presets**.
    * Provided a dedicated custom text input with single-tap Clear button, character counter, and quick gamer tags (Boss, Champion, Tycoon, etc.).
    * Added visual status badges: `CUSTOM PLAYER NAME` (emerald) vs `KERALA CHARACTER PRESET` (amber).
    * Enhanced home screen identity badge with custom name indicator and direct edit access.
    * Added persistence for custom naming status across app reboots via `SharedPreferences`.
* **v1.1.0**:
  * Implemented official **Doubles Rule**: Matching dice grant an immediate extra roll; 3 consecutive doubles send player to Lockup.
  * Implemented **Unpurchased Tile Options**: Landing on unowned property provides explicit `BUY` or `AUCTION` choices.
  * Implemented **Auction Turn Order**: Landing player bids first in all auctions.
  * Scaled all tile prices, rents, upgrade costs, and taxes for the **₹1,000 starting cash balance**.
  * Set voluntary and forced jail fine to **₹100**.
  * Made home screen **KUTHAKA** title dynamically responsive with single-line constraint across all screen sizes.
  * Added simplified rules guide to `HomeScreen` and `GameMenuDialog`.
  * Created `RULES_AND_LOGIC.md` as the unified system reference.

