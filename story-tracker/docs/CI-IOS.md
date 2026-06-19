# CI iOS — moved to monorepo root

Personal OS iOS lives at **`../ios/`** (repo root). GitHub Actions: **`../.github/workflows/ios-*.yml`**.

See **[../docs/CI-IOS.md](../docs/CI-IOS.md)** for secrets, provisioning profiles, and TestFlight.

Extension build remains in this package:

```bash
npm run build:safari && npm run sync:safari-ios
npm run build:ios-bridge && npm run sync:ios-bridge
```
