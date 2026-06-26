# INTERFACES.md -- Swarm Module Contracts

> [!IMPORTANT]
> Before modifying any shared API, interface, utility module, or database contract, the agent must check this document. If your proposed change alters a contract, stop and seek user/human confirmation.

## Module Boundaries

### Auth Module
- **Contracts**:
  - `verifyToken(token: string): Promise<{userId: string} | null>`
- **Rules**: Must never throw on invalid token, returns null instead.

### Database Layer
- **Contracts**:
  - `getUser(userId: string): Promise<User | null>`
- **Rules**: `userId` is always a UUID string.

### API Routes
- **Contracts**:
  - `GET /api/v1/user` -> returns `{ user: User }`
