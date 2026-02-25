# Delete User — Frontend Integration Guide

> **Endpoint:** `POST /functions/v1/delete-user`
> **Auth:** Required (user's own JWT)
> **Effect:** Permanently deletes the account and every piece of data tied to it — no soft delete, no recovery.

---

## What gets deleted

A single call removes the authenticated user from `auth.users`. The database cascades the deletion automatically to every related table:

| Table | Data removed |
|-------|-------------|
| `user_profiles` | Language preference, subscription tier, target exam level |
| `user_subscriptions` | All Stripe payment records |
| `study_progress` | All per-question attempt and confidence data |
| `quiz_sessions` | All quiz and flashcard session history |

No backend cleanup job is needed — the cascade handles everything atomically.

---

## Request

### Headers

| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer <access_token>` | Yes |
| `Content-Type` | `application/json` | No (no body) |

### Body

None. The user is identified exclusively from the JWT — never pass a user ID in the body.

### Methods accepted

`DELETE` (preferred) or `POST`.

---

## How to call it

### Option 1 — Supabase JS client (recommended)

```ts
const { error } = await supabase.functions.invoke('delete-user', {
  method: 'DELETE',
})

if (error) {
  // Show error to the user — account was NOT deleted
  console.error(error)
  return
}

// Account is gone. Sign out locally and redirect.
await supabase.auth.signOut()
router.push('/goodbye')
```

### Option 2 — Raw fetch

```ts
const session = await supabase.auth.getSession()
const token = session.data.session?.access_token

const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/delete-user`, {
  method: 'DELETE',
  headers: {
    Authorization: `Bearer ${token}`,
  },
})

if (!res.ok) {
  const body = await res.json()
  console.error(body.error)
  return
}

await supabase.auth.signOut()
router.push('/goodbye')
```

---

## Responses

### Success

```
HTTP 200
```
```json
{ "message": "Account deleted successfully" }
```

### Errors

| Status | Body | What it means |
|--------|------|---------------|
| `401` | `{ "error": "Unauthorized" }` | JWT is missing, expired, or invalid |
| `405` | `{ "error": "Method not allowed" }` | Wrong HTTP method used |
| `500` | `{ "error": "Failed to delete account" }` | Unexpected server error — account was NOT deleted, safe to retry |

---

## After a successful deletion

The JWT becomes immediately invalid server-side. You must:

1. Call `supabase.auth.signOut()` to clear the local session
2. Clear any user data cached in local state or storage
3. Redirect the user — any further authenticated request will return `401`

Skipping the local sign-out won't cause a security issue (the token is dead), but it will cause confusing UI state.

---

## UX recommendation

Account deletion is irreversible. Before calling the endpoint, show a confirmation dialog that:

- Explicitly lists what will be lost (progress, history, subscription)
- Requires the user to type a confirmation phrase or re-enter their password
- Disables the confirm button until the input is valid

This prevents accidental deletions and meets standard GDPR "clear affirmative action" requirements.
