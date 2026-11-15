# AHDB Auctionator Sync

Use **AHDB’s historical auction-house prices** alongside addons that depend on
**Auctionator’s pricing data**, with just one full scan.

Many price-aware addons integrate with Auctionator, while few integrate directly
with AHDB. Keeping both databases current normally requires separate scans—but
the **15-minute auction-house full-scan cooldown is shared**, preventing AHDB and
Auctionator from scanning in rapid succession.

AHDB Auctionator Sync automatically copies prices from completed AHDB scans into
Auctionator’s pricing database. **Scan once with AHDB, keep its price history,
and let Auctionator-dependent addons use prices from the same scan.**

## Features

- **Automatic synchronization:** Updates Auctionator’s prices when AHDB completes a faction auction-house full scan.
- **No second scan:** Reuses AHDB’s results without additional auction-house queries or waiting for another scan cooldown.
- **Persistent prices:** Updates Auctionator’s saved pricing database and preserves its normal daily price history.
- **Manual imports:** Imports existing AHDB price history without scanning again.
- **Market separation:** Keeps neutral auction-house prices out of your faction’s Auctionator database.
- **Simple controls:** Check synchronization status, toggle automatic imports, and set an age limit for historical imports.

## Requirements

Both **Auction House DataBase (AHDB)** and **Auctionator** must be installed and enabled.

## Getting started

1. Install this addon alongside AHDB and Auctionator.
2. Type `/ahsync status` to check that the scan listener is active.
3. Complete a full scan using AHDB. A chat message confirms the import into Auctionator.
4. Disable Auctionator’s automatic full scans if AHDB is your primary scanner.

Already have AHDB scan history? Use `/ahsync import` to import stored prices
immediately. By default, manual imports accept prices up to 48 hours old.

## Commands

| Command | Description |
|---|---|
| `/ahsync status` | Show listener status, settings, and the last successful import. |
| `/ahsync import` | Import stored AHDB prices without scanning. |
| `/ahsync on` | Enable automatic imports. |
| `/ahsync off` | Disable automatic imports; manual imports remain available. |
| `/ahsync age 72` | Accept historical prices up to 72 hours old. |
| `/ahsync age 0` | Remove the age limit for historical imports. |
| `/ahsync help` | Show available commands. |

## Limitations

- **Prices, not listings:** Updates Auctionator’s pricing database. Addons that require individual auction listings or Auctionator scan events may need a separate integration.
- **Item variants:** AHDB’s base item IDs may not distinguish random enchantments and other item variants.
- **Missing items:** Items absent from a new scan are not automatically removed from Auctionator’s database.
- **Faction markets only:** Neutral auction-house scans remain in AHDB and are not imported.

MIT licensed. An independent integration, not affiliated with the AHDB or Auctionator maintainers.
