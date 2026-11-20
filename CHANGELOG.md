# Changelog

## 2026.11.20.02-beta — 2026-11-20

This beta adds an installable addon ZIP to GitHub Releases.

- Sync prices into Auctionator after a full AHDB faction auction-house scan, without running a second scan.
- Update Auctionator's saved prices while preserving its daily price history.
- Leave neutral auction-house scan data in AHDB.
- Import stored AHDB prices with `/ahsync import`, with a configurable age limit.
- Use `/ahsync` commands to check sync status, toggle automatic imports, or change the import age limit.
