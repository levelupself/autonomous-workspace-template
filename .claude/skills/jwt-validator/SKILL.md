---
name: jwt-validator
description: >
  Validates JWT tokens signed with RS256 (asymmetric) without requiring
  external libraries beyond openssl. Handles base64url padding edge cases.
  Use when you need to verify a JWT signature in a script or test.
  Created by skill-writer to resolve auth-service capability gap.
allowed-tools: Bash
---

# JWT-Validator Skill

Validate a JWT RS256 token against a public key.

## Usage

```
/jwt-validator <jwt-token> <path-to-public-key.pem>
```

Or invoke the script directly:
```bash
.claude/skills/jwt-validator/scripts/validate.sh <token> <pubkey.pem>
```

## What this does

1. Splits the JWT into header.payload.signature
2. Decodes header and payload from base64url (handling padding)
3. Verifies the signature using openssl with the RS256 algorithm
4. Returns the decoded payload if valid, error if invalid

## Arguments

`$ARGUMENTS` — format: `<jwt-token> <public-key-path>`

## Script location

`.claude/skills/jwt-validator/scripts/validate.sh`

## Example

```bash
TOKEN="eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyMSJ9.signature"
.claude/skills/jwt-validator/scripts/validate.sh "$TOKEN" ./keys/public.pem
```

Output on success:
```json
{"sub":"user1","iat":1711900000,"exp":1711903600}
```

Output on failure:
```
ERROR: signature verification failed
```

## Edge cases

- Handles base64url padding (adds `=` as needed)
- Handles JWTs without padding in any segment
- Rejects expired tokens (checks `exp` claim)
- Rejects tokens with wrong algorithm in header

## Created

Created by skill-writer on resolution of auth-service blocker:
"JWT RS256 validation without external library".
