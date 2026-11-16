# AHDB Auctionator Sync

This addon syncs prices from AHDB to Auctionator. Why would you need that?

Many price-aware addons integrate with Auctionator, while few integrate directly with AHDB. Keeping both databases current normally requires separate scans. However, the auction house has a shared 15-minute full-scan cooldown, so AHDB and Auctionator cannot scan in rapid succession. If AHDB scans first, you would have to wait another 15 minutes before scanning with Auctionator, or keep using older prices.

AHDB Auctionator Sync copies prices from completed AHDB scans into Auctionator's pricing database. Scan once with AHDB, keep its price history, and let Auctionator-dependent addons use prices from the same scan.

## Features

- Sync prices automatically when AHDB completes a faction auction-house full scan.
- Reuse the scan results without additional auction-house queries.
- Update Auctionator's saved prices and preserve its daily price history.
- Import existing AHDB prices without scanning again.
- Keep neutral auction-house prices separate from your faction's prices.
- Check sync status, turn automatic imports on or off, and set an age limit for historical imports.

## Requirements

Auction House DataBase (AHDB) and Auctionator must both be installed and enabled.

## Getting started

1. Install this addon alongside AHDB and Auctionator.
2. Type `/ahsync status` to check that the scan listener is active.
3. Complete a full scan using AHDB. A chat message confirms the import into Auctionator.
4. Disable Auctionator's automatic full scans if AHDB is your primary scanner.

Already have AHDB scan history? Use `/ahsync import` to import stored prices immediately. By default, manual imports accept prices up to 48 hours old.

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

- Only prices are synced. Addons that need individual auction listings or Auctionator scan events may need a separate integration.
- AHDB identifies items by their base item ID, so random enchantments and other item variants may share a price.
- Items missing from a new scan are not automatically removed from Auctionator's database.
- Neutral auction-house scans stay in AHDB and are not imported.

MIT licensed. An independent integration, not affiliated with the AHDB or Auctionator maintainers.

## Manual installation

Extract the addon ZIP and put the `AHDBAuctionatorSync` folder in your game's `Interface/AddOns` directory. Back up your Auctionator saved variables before first use.

## Troubleshooting

If the listener is inactive, check that both dependencies are enabled, run `/reload`, then try `/ahsync status` again.

If no prices are imported, check that the scan completed at your own faction's auction house. For older stored prices, try `/ahsync age 72` followed by `/ahsync import`.

For errors, enable `/console scriptErrors 1` and report the error with your AHDB and Auctionator versions in [GitHub Issues](https://github.com/joachimtingvold/ahdb-auctionator-sync/issues).
