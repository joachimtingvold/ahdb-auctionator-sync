# AHDB Auctionator Sync

**World of Warcraft: Forever | Interface 16001**

AHDB Auctionator Sync copies auction-house prices from completed **Auction House DataBase (AHDB)** full scans into **Auctionator's persistent pricing database**. Use AHDB for full scans and continue using Auctionator's pricing features and addons that read Auctionator prices, without running a second full scan.

The addon does not scan the auction house, post or buy auctions, send addon messages, or connect to external services.

## Requirements

- **WoW: Forever**, game version **1.60.1** (Interface **16001**).
- **Auction House DataBase (AHDB)**, version **2.7.1** or compatible; addon folder `AuctionDB`.
- **Auctionator**, Forever-compatible build; addon folder `Auctionator`.

Both addons must be enabled. For CurseForge installations, select the **Forever** game version when installing dependencies.

## Installation

1. Exit the game. Back up `WTF/Account/<account>/SavedVariables/Auctionator.lua` before first use.
2. Install this addon and the two required addons using CurseForge. For manual installation, place the `AHDBAuctionatorSync` folder directly inside `World of Warcraft/_forever_/Interface/AddOns/`.
3. Start the game and type `/ahsync status` to verify that its AHDB scan listener is active.
4. At a faction auction house, complete an AHDB full scan. A confirmation in chat reports how many item prices were imported into Auctionator.
5. Disable Auctionator's automatic full scan in its settings and use AHDB's scans as the source of prices.

**Already have AHDB history?** Type `/ahsync import` to import the latest available own-faction prices without scanning again. The default maximum age for these saved historical prices is 48 hours.

## Commands

| Command | Description |
| --- | --- |
| `/ahsync` or `/ahsync status` | Show listener status, settings and last successful import. |
| `/ahsync import` | Import stored own-faction AHDB prices without a scan. |
| `/ahsync age 72` | Accept historical prices up to 72 hours old for manual import. |
| `/ahsync age 0` | Disable the age limit for manual imports. |
| `/ahsync on` | Enable automatic imports from completed scans. |
| `/ahsync off` | Disable automatic imports; manual imports remain available. |
| `/ahsync help` | Show commands. |

## How prices are imported

When AHDB announces a completed scan, the addon collects the lowest **per-unit buyout** for each item and the total available quantity from its full-scan data. It passes these values to Auctionator's database via `Auctionator.Database:ProcessScan`, retaining Auctionator's own normal daily price history. Where supported by Auctionator's current database format, the addon also sets the latest price field to the price observed in that scan.

Only listings with a positive buyout contribute. Manual history imports use each item's most recent AHDB recorded price, subject to the configured age limit. All prices are in copper per individual item, not per stack.

## Market separation

Only scans of your **character's own faction** are imported automatically (Alliance to Alliance or Horde to Horde). AHDB's **neutral auction-house** prices remain in AHDB. Neutral scans are deliberately skipped: Auctionator's active character market should not be overwritten with Gadgetzan, Booty Bay or Everlook prices.

## Limitations

- **Prices, not listings:** The addon updates Auctionator's pricing database. It does not synthesize Auctionator's full-scan event or supply individual auction records to sniper addons. A tool that expects a complete listing snapshot may still need a separate integration.
- **Item variants:** AHDB identifies items using base item IDs. Random-enchantment suffixes and other item variants may lose distinctions compared with Auctionator's own link-based scans.
- **Unavailable items:** Prices for items absent from the new AHDB scan are not automatically deleted from Auctionator. An old entry may remain until Auctionator itself updates or invalidates it.
- **No cross-client merging:** This addon runs in the current client and does not synchronize saved files between computers or accounts.
- **Version compatibility:** The integration uses AHDB and Auctionator internals that may change between releases. Please report any regressions after upstream updates.

## Troubleshooting

- **Listener inactive:** Ensure AHDB and Auctionator are enabled and loaded. Run `/reload`, then `/ahsync status`.
- **No prices imported:** Ensure the scan completed at an Alliance or Horde auction house matching your character's faction. Neutral scans are intentionally skipped.
- **Price appears outdated:** Check that an AHDB scan actually completed. For previously scanned items, try `/ahsync import`; use `/ahsync age 72` if your stored prices are older than the 48-hour default.
- **Import failed:** Check chat and run `/console scriptErrors 1` before reproducing. Record the error and the versions of AHDB and Auctionator.
- **Unexpected prices:** Temporarily disable this addon, restore your Auctionator saved-variable backup if needed, and report the item ID and prices observed.

Saved variables are usually written to disk when the client logs out or reloads the UI.

## In-game verification

Manual `/ahsync import` and automatic synchronization after a completed AHDB scan were confirmed working in WoW: Forever on November 15, 2026. No additional AH full scan is requested by this addon. These checks do not imply compatibility with every future AHDB/Auctionator release.

## Source, issues and releases

Source: [joachimtingvold/ahdb-auctionator-sync](https://github.com/joachimtingvold/ahdb-auctionator-sync).
Report problems in [GitHub Issues](https://github.com/joachimtingvold/ahdb-auctionator-sync/issues). See [`docs/RELEASING.md`](docs/RELEASING.md) in the source repository for publishing instructions.

## License and credits

Licensed under the **MIT License** (see `LICENSE`). This is an independent integration, not affiliated with or endorsed by the AHDB or Auctionator maintainers. AHDB and Auctionator remain their respective authors' projects and carry their own licenses.
