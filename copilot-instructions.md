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
| `electron-client/` | Mobile + desktop app | React Native, Expo, Node 18 |
| `electron-hub/` | Electron desktop shell | TypeScript, Electron |
| `figma-plugin/` | Figma integration | TypeScript, webpack |
| `mortar/` | Real-time engine | socket.io |
| `custom-tile/` | Custom tile dev environment | webpack |

## Universal Conventions

### Formatting & Linting
- **Prettier**: `printWidth: 120`, `singleQuote: true` — consistent across all projects
- **ESLint**: Airbnb base + Prettier integration in every project. Run `npm run lint` before committing.
- **Indentation**: 2 spaces, LF line endings, UTF-8, trim trailing whitespace

### Package Management
- **npm** exclusively (no yarn/pnpm). Use `npm ci` for reproducible installs.
- `patch-package` is used in hub and electron-client — run `npm run postinstall` after patching.

### Node Versions
- Most projects: **Node 22.16.0** (use nvm — `.nvmrc` files are present)
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
| electron-client | Jest | `npm test` |

### CI/CD & Releases
- api + hub: AWS CodeDeploy, pm2, release via `./scripts/release.sh stage|master`
- electron-client: Azure Pipelines, Expo EAS
- mosaic: CircleCI
- Environment config via `.env` (copy from `.env.sample`)

## Sub-Project Notes

### api/
- CommonJS throughout. Express + Mongoose.
- Multi-environment: dev, test, hotfix, pp, prod, env01–env20 (K8S staging)
- `pre-commit` hook runs lintcheck + build:docs
- API docs generated from JSDoc

### admin/
- Create React App with MUI. Internal tool.
- Consumes `mosaic` and `tiled-ui`

### electron-client/
- React Native + Expo (iOS, Android, Electron)
- Node 18 only — do not upgrade without checking Expo compatibility
- `syncVersions.js` keeps version numbers aligned across platforms

### figma-plugin/
- TypeScript plugin for Figma
- webpack build, Figma API types in `figma.d.ts`
