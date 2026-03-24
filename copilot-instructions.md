# Tiled Platform

Multi-project platform for creating and sharing interactive content. Each sub-project is an independent repo with its own toolchain — there is no root-level package.json or shared build system.

## Project Map

| Directory | Description | Stack |
|-----------|-------------|-------|
| `api/` | REST API backend | Express, Mongoose, Mocha, Node 22 |
| `hub/` | Web builder + viewer | React 18, Express, Webpack 5, Jest, Node 22 |
| `mosaic/` | Shared JS SDK (enums, API client, permissions) | Babel, Node 22 |
| `tiled-ui/` | Shared React component library | TypeScript, Rollup, Storybook |
| `admin/` | Internal admin dashboard | React 18, CRA, MUI |
| `figma-plugin/` | Figma integration | TypeScript, webpack |
| `xd-plugin/` | Adobe XD integration | React 16, Webpack 4, Jest |
| `native-clients/` | Mobile app (iOS + Android) | React Native 0.74, Expo 51, Redux, Realm, Node 18 |
| `pdf-extractor/` | PDF slide extraction microservice | Python 3.8, Flask, PyMuPDF, Gunicorn |
| `mortar/` | Real-time engine | socket.io |
| `custom-tile/` | Custom tile dev environment | webpack |

## Universal Conventions

### Formatting & Linting
- **Prettier**: `printWidth: 120`, `singleQuote: true` — consistent across all projects
- **ESLint**: Airbnb base + Prettier integration in every project. Run `npm run lint` before committing.
- **Indentation**: 2 spaces, LF line endings, UTF-8, trim trailing whitespace

### Package Management
- **npm** exclusively (no yarn/pnpm). Use `npm ci` for reproducible installs.
  - **Exception:** `xd-plugin` uses `yarn` internally in its build scripts — global yarn installation required.
- `patch-package` is used in hub, electron-client, and native-clients — run `npm run postinstall` after patching.

### Node Versions
- Most projects: **Node 22.16.0** (use nvm — `.nvmrc` files are present)
- `native-clients/`: **Node 18.19.0** (locked — do not upgrade)
- `pdf-extractor/`: **Python 3.8.10** (no Node — entirely Python)
- Always check `.nvmrc` or `engines` in `package.json` when switching projects.

### The `mosaic` Shared SDK (Critical)
All projects share enums, API client, and permissions through `mosaic`. Never redefine enums or constants locally.

```js
import api from 'mosaic';
import { TileType, UserRole } from 'mosaic/enums';
import { hasPermission } from 'mosaic/permissions';
```

- Installed as a private GitHub dependency (git+https URL with OAuth token)
- After modifying mosaic source, run `npm run build` in the mosaic directory — it compiles `src/` to the package root via Babel
- Other projects must `npm install` after mosaic is updated to pick up changes

### The `tiled-ui` Component Library
Shared React components consumed by hub, admin, figma-plugin.

```js
import { Box, Flex } from 'tiled-ui';
```

- TypeScript source, Rollup build (dual CJS + ESM)
- Storybook available: `npm run storybook` (port 6006)

### Testing
| Project | Framework | Command |
|---------|-----------|---------|
| api | Mocha + Chai | `npm test` |
| hub | Jest (UI + server) | `npm test` |
| tiled-ui | Jest + Testing Library | `npm test` |
| native-clients | Jest | `npm test` |
| xd-plugin | Jest + Testing Library | `npm test` |
| pdf-extractor | (none) | N/A — Python service, no test suite |

### CI/CD & Releases
- api + hub: AWS CodeDeploy, pm2, release via `./scripts/release.sh stage|master`
- Environment config via `.env` (copy from `.env.sample`)

## Sub-Project Notes

### api/
- CommonJS throughout. Express + Mongoose.
- Multi-environment: dev, test, hotfix, pp, prod, env01–env20 (K8S staging)
- **Dual server processes:** `index.js` runs the private API on port 3002 (`npm run dev`); `index-public.js` runs a separate public API on port 3003 (`npm run dev:public`)
- **Dual database:** MongoDB/Mongoose for app data (`DB_MONGO_URL`), PostgreSQL/Sequelize for analytics (`tiled_analytics`, `tiled_arbiter`). Separate migration commands for each.
- **Queue system:** Bull (Redis-backed) for async jobs — PDF conversion, microapp import/export, analytics export, HubSpot sync, user anonymization, trial bootstrap/downgrade. Redis is optional (`REDIS_DISABLED` env var skips queue creation). Config: `REDIS_HOST`, `REDIS_PORT`, `REDIS_AUTH_PASS`, `REDIS_TLS`
- **Feature flags:** Unleash (`unleash-client`) with custom activation strategies: `InternalUseOnly`, `DesignerAccountsOnly`, `CreativeAccountsOnly` (defined in `api/strategies/`). Config: `UNLEASH_KEY`
- **Auth/security:** Cookie-based JWTs (`JWT_SECRET`, `access_token`/`refresh_token` cookies), `express-rate-limit`, `helmet`, `cors`, `bcrypt`, `sanitize-html`. OAuth providers: Google. SAML SSO (`saml2-js`). SCIM provisioning (`/scim` directory).
- **Storage backends:** S3 (default), Azure Blob Storage, CloudFront (signed URLs). `STORAGE_SERVICE` env var selects S3 vs Azure.
- **On-prem mode:** `DEPLOY_TYPE=on-prem` changes auth flows, cookie names (`tiled_` prefix), storage config, and required env vars.
- **Observability:** Sentry (`SENTRY_DSN_API` / `SENTRY_DSN_PUBLIC`), New Relic (on-prem only), Winston logger + LogEntries
- **v2 routes:** All REST routes under `/v2`. Key domains: accounts, analytics, assets, auth, config-sets, custom-tiles, dashboard, document-sets, documents, feature-flags, fonts, groups, instances, libraries, microapp, roles, rooms, saml-providers, scim-config, sheets, tags, tds, tenants, users, short-urls
- **API docs:** JSDoc-generated (`npm run build:docs`) + OpenAPI/Redoc (`npm run build:redoc` from `public/docs/openapi.yaml`)
- `pre-commit` hook runs lintcheck + build:docs
- `express-http-context` for request-scoped context threading through middleware

### admin/
- Create React App with MUI. Internal tool.
- Consumes `mosaic` and `tiled-ui`

### hub/
- Express server (port 3001) serves templates that bootstrap React apps; the server serves interpolated HTML shells, not server-rendered React.
- **Four webpack app bundles:** `hub`, `viewer`, `analytics`, `join` — each a separate React entry point, plus a shared `components` bundle all apps `dependOn`.
- **Webpack import aliases** (for `import` statements): `api`, `actions`, `components`, `component-library`, `asset-library`, `common`, `colorpicker`, `hooks`, `styles`, `utl` (NOT `util`), `util-ts`, `images`, `audio`, `clientConfig`, `reducers`
- **Jest three separate projects:** `server` (Node env, matches `server/test/**/*-test.js`), `ui` (jsdom env, matches `src/**`), `eslint` (linting as a Jest project). Run server tests alone: `npm run test:server`
- **Dev server uses pm2** + `webpack-hot-middleware` (not a standalone webpack-dev-server). Hot reload injected as an entry point prefix.

### figma-plugin/
- Figma plugin - syncs screens, hotspots, and prototypes from XD into Tiled microapps
- webpack build, Figma API types in `figma.d.ts`
- Consumes `mosaic` and `tiled-ui`

### xd-plugin/
- Adobe XD plugin — syncs screens, hotspots, and prototypes from XD into Tiled microapps
- React 16 + Webpack 4, outputs a `.xdx` archive (main.js + manifest.json + images)
- Uses `yarn` in build scripts (exception to the npm-only rule)
- Environment-specific builds: `npm run build:dev`, `build:test`, `build:pp`, `build:prod`
- `mosaic` version is v1.x (much older than other projects) — be aware of enum/API differences

### native-clients/
- React Native 0.74 + Expo 51 mobile app for iOS and Android
- Node 18.19.0 locked — do not upgrade
- State: Redux 5 + redux-thunk. Offline data: Realm 12
- Navigation: `@react-navigation` (native-stack, drawer, bottom-tabs)
- CI/CD: Azure Pipelines, builds via EAS (Expo Application Services)
- `patch-package` used — run `npm run postinstall` after patching

### pdf-extractor/
- Python Flask microservice — no Node.js, no package.json
- Receives PDF via HTTP POST, extracts slides/media/layout using PyMuPDF, uploads results to S3
- Deploy: AWS CodeDeploy (`appspec.yml` + `ci-cd/` scripts), runs behind nginx + Gunicorn
- Install: `pip install -r requirements.txt`
- Endpoint: `POST /extract` with body `{"output_folder": "<account>/<app>", "key": "<s3-key>"}`
