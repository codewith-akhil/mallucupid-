# STORAGE_SETUP.md — Mallu cupid (DostiPak)

Owner-facing guide to Firebase Storage for this app. Everything below reflects
what the code **actually does** (verified against `lib/`). No fluff.

---

## 1. What Firebase Storage is used for in THIS app

The app uses **one bucket** (created in the Firebase console) for all
user-generated media. Files are uploaded with `FirebaseStorage.instance`, the
download URL is fetched with `ref.getDownloadURL()` **at upload time**, and
that URL is saved into Firestore.

| Feature | Storage path (exactly what the app writes) | Code |
|---|---|---|
| Profile photo (sign-up + edit profile) | `uploads/users/profiles/{uid}/{uid}{timestamp}` | `lib/models/user_model.dart` → `signUp()`, `updateProfileImage()` via `uploadFile()` |
| Profile gallery photos | `uploads/users/gallery/{uid}/{uid}{timestamp}` | `lib/models/user_model.dart` → `updateProfileImage()` |
| Chat photos | `uploads/messages/{uid}/{uid}{timestamp}` | `lib/screens/chat_screen.dart` → `_sendMessage('image')` |
| Voice notes | `uploads/messages/{uid}/audio{timestamp}.m4a` | `lib/screens/chat_screen.dart` → `uploadAudio()` |
| GIFs (in-chat) | `uploads/messages/{uid}/gif{timestamp}.gif` | `lib/widgets/git_source_sheet.dart` |
| Stickers (in-chat) | `uploads/messages/{uid}/sticker{timestamp}.{png\|jpeg\|svg}` | `lib/widgets/sticker_source_sheet.dart` |

`{uid}` = the signed-in Firebase user's UID. `delete flows` (`delete account`,
`clear chat`, `change photo`) delete files with `refFromURL(url).delete()`
using the URL stored in Firestore — never a pasted constant.

> **File name history note:** voice notes / gifs / stickers were previously
> written straight under `uploads/messages/` with a stray `}` in the name
> (e.g. `audio1699...}.m4a`). Task 15-c moved them under
> `uploads/messages/{uid}/` and fixed the name. Old files (if any exist in a
> test bucket) still download fine — URLs live in Firestore, not in paths.

---

## 2. Console setup — step by step (5 minutes)

1. Open <https://console.firebase.google.com> → select your project.
2. Left menu: **Build → Storage → Get started**.
   If you see "Security rules" wizard: choose **Start in production mode**
   (never test mode — test mode is public-writable for 30 days).
3. **Location:** pick **asia-south1 (Mumbai)** — lowest latency for your
   Kerala / India audience.
   ⚠️ This is set **once** and **cannot be changed later** without migrating
   every file by hand.
4. Click **Done**. The bucket is created as
   `<your-project-id>.firebasestorage.app`
   (older projects: `<your-project-id>.appspot.com`).
5. Copy the rules from **section 4** below into the **Rules** tab → **Publish**.
6. Nothing else. No app code change is needed — see section 5.

---

## 3. Why the app needs no hardcoded values

The Android package reads its **entire Firebase config from
`android/app/google-services.json`**, which already contains the
`storageBucket` value. The Flutter plugin picks it up automatically at
`Firebase.initializeApp()` — no URL, bucket string or API key exists anywhere
in `lib/` (verified with `grep -rni "firebasestorage|appspot|storageBucket|bucket" lib/`
→ only dynamic `FirebaseStorage.instance` calls).

Relevant snippet from **this** app (`lib/models/user_model.dart`):

```dart
final _storageRef = FirebaseStorage.instance;          // bucket comes from google-services.json

Future<String> uploadFile({
  required File file,
  required String path,
  required String userId,
}) async {
  // Image name
  String imageName = userId + DateTime.now().millisecondsSinceEpoch.toString();
  // Upload file
  final UploadTask uploadTask = _storageRef
      .ref()                                            // -> root of the configured bucket
      .child(path + '/' + userId + '/' + imageName)     // e.g. uploads/users/profiles/{uid}/...
      .putFile(file);
  final TaskSnapshot snapshot = await uploadTask;
  String url = await snapshot.ref.getDownloadURL();     // URL captured at upload time
  return url;                                           // caller stores it in Firestore
}
```

So if you ever change projects/buckets: replace `google-services.json` and
rebuild — zero code edits.

---

## 4. Security rules (paste into Storage → Rules → Publish)

### Option A — simple (recommended while launching)

Signed-in users can read + write the app's media. Good enough because every
read in the app already requires an authenticated user.

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Option B — stricter per-path (owner-based writes)

Same behavior for reads; writes restricted to the file owner's own folder,
plus a 10 MB size cap. **One caveat, by design:** `uploads/messages/**`
allows write to *any signed-in user* because "clear chat for both" also
deletes media uploaded by the conversation partner
(`lib/api/messages_api.dart` → `deleteChat(isDoubleDel: true)`).

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function signedIn() {
      return request.auth != null;
    }
    function isOwner(uid) {
      return signedIn() && request.auth.uid == uid;
    }
    // Cap user uploads at 10 MB
    function validSize() {
      return request.resource.size < 10 * 1024 * 1024;
    }

    // Profile photos: uploads/users/profiles/{uid}/...
    match /uploads/users/profiles/{uid}/{fileName} {
      allow read: if signedIn();
      allow write: if isOwner(uid) && validSize();
    }

    // Gallery photos: uploads/users/gallery/{uid}/...
    match /uploads/users/gallery/{uid}/{fileName} {
      allow read: if signedIn();
      allow write: if isOwner(uid) && validSize();
    }

    // Chat media (photos, voice notes, gifs, stickers):
    // uploads/messages/{uid}/...
    // write = any signed-in user: a chat partner may delete files the
    // other user uploaded when clearing the conversation for both.
    match /uploads/messages/{uid}/{fileName} {
      allow read: if signedIn();
      allow write: if signedIn() && validSize();
    }
  }
}
```

> If you also use **App Check** (this project registers Play Integrity), you
> can harden every rule further by appending
> `&& request.app != null` — but do that only AFTER App Check is verified
> working in MONITOR mode, or all uploads will be rejected.

---

## 5. File limits & formats the app enforces

| Media | Source | Limit / format |
|---|---|---|
| Profile / gallery / chat photos | `image_picker` (`lib/widgets/image_source_sheet.dart`) | `imageQuality: 80` JPEG re-encode on pick (gallery AND camera) → typical upload well under 1 MB; no explicit maxWidth/maxHeight set |
| Voice notes | native recorder via MethodChannel (`MainActivity.kt`) | AAC-LC in an `.m4a` container, short chat-length clips |
| GIFs | bundled `assets/images/gif1-5.gif` | `.gif` only |
| Stickers | bundled `assets/stickers/*` | `.png`, `.jpeg`, `.svg` (extension taken from the asset name) |
| Everything | Storage rules (Option B) | `request.resource.size < 10 MB` |

The app never uploads video or arbitrary documents.

---

## 6. Errors & fixes

| Symptom / log | Cause | Fix |
|---|---|---|
| `403` / ` PERMISSION_DENIED` on upload or download | Rules not published, or published to a different project | Paste rules from section 4 into **this** project's Storage → Rules → **Publish** |
| `403 PERMISSION_DENIED` only on delete | Old rules missing delete permission, or strict option used on `uploads/messages` | Re-publish Option A/B; deletes need `allow write` (delete is a write) |
| `FirebaseException: [storage/bucket-not-found]` / `object-not-found` on first upload | Storage was never created for this project (Get started never run) | Do section 2 — the bucket must exist before the first upload |
| `storage/unauthorized` right after publishing rules | Client cached old token — or the user's UID doesn't own the path (strict rules) | Restart the app; if it persists, check the file path in section 1 matches the rule block |
| Upload spins forever on real device | Phone offline / weak mobile data | The app now shows "Couldn't upload…" and stops loading; retry when online |
| "The file is too large" / upload rejected by rules | File over the 10 MB rule cap (huge camera originals bypass quality re-encode is not possible — picker always re-encodes at 80) | Rare; lower `imageQuality` in `image_source_sheet.dart` or raise the cap in rules |
| Images suddenly broken after changing bucket | Files live in the OLD bucket; Firestore URLs still point there | Never change bucket after launch (section 8) — migrate instead |

---

## 7. Verify it works end-to-end (2 minutes)

1. Firebase console → **Storage → Files**: confirm the bucket is empty (or has
   only test files).
2. Install the app → **Sign up** a fresh account with a profile photo.
3. Console → **Storage → Files**: you should now see
   `uploads/users/profiles/<uid>/<uid><timestamp>`. Tap the file → its
   download URL opens the photo.
4. In the app: **Profile → edit → change photo** → new object appears under
   `uploads/users/profiles/<uid>/…`.
5. Open any chat → send a photo, a voice note and a sticker →
   `uploads/messages/<uid>/…` gains `image`, `audio….m4a` and `sticker…` files.
6. In Storage → **Rules** tab, temporarily set read to `if false` → publish →
   restart the app → profile images should fail to load (proves rules are
   active). Restore the rules.

---

## 8. What NOT to do

- **Never hardcode a storage URL / bucket string in `lib/`.** The bucket comes
  from `google-services.json`; URLs of uploaded files come from
  `getDownloadURL()` at upload time (or from the Firestore field they were
  saved to). Keep it that way — it's already verified clean.
- **Never publish test-mode rules** (`allow read, write: if true;`) or leave
  rules unsigned (`request.auth == null` allowed). This bucket holds every
  user's face and voice.
- **Never change the bucket / region after launch.** Files can't be renamed
  across buckets by rules; you'd have to re-upload and rewrite every Firestore
  URL by hand. Pick `asia-south1` once, keep it.
- **Never store media files inside Firestore** (base64 or otherwise) — that is
  what Storage is for; Firestore documents cap at 1 MB.
- **Never delete a user's storage folder from the console** without deleting
  their Firestore `Users/{uid}` doc first (the app's delete-account flow
  handles both in the right order).
