# Firestore Index Fix Guide

## Problem
The Leaderboard query requires a composite index that doesn't exist:
```
Error: [cloud_firestore/failed-precondition] The query requires an index
```

## Root Cause
The `streamLeaderboard()` query in [xp_service.dart](lib/services/xp_service.dart#L273) requires:
```dart
.collection('users')
  .where('role', isEqualTo: 'student')
  .orderBy('xp', descending: true)
  .limit(10)
```

This needs a composite index on: `(role, -xp)`

---

## Solution: Create Firestore Composite Index

### Method 1: Firebase Console (Recommended - 2 minutes)
1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Navigate**: `rpgthestduentlife` → Firestore → Indexes
3. **Click "Create Index"** button
4. **Fill form**:
   - Collection: `users`
   - Field 1: `role` (Ascending) ↑
   - Field 2: `xp` (Descending) ↓
5. **Click "Create"**
6. **Wait 2-3 minutes** for index to build (you'll see "Enabled" status)
7. **Refresh the app** - leaderboard will work!

### Method 2: Firebase CLI Deployment (If CLI installed)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Deploy indexes
cd /home/jahin/student\ life\ the\ rpg/rpg_student_life
firebase deploy --only firestore:indexes
```

A `firestore.indexes.json` configuration file has been created in the project for this purpose.

---

## Verification

After the index is created, the app will automatically work. You'll see:
- ✅ Leaderboard loads without errors
- ✅ Console no longer shows Firestore index errors
- ✅ Rankings display correctly sorted by XP

---

## Why This Happens

Firestore composite indexes are required for queries with:
- Multiple filter fields (`where` clauses)
- Ordering by a non-first-field (`orderBy`)

Single-field queries and sorting don't need indexes, but complex queries do for performance optimization.

