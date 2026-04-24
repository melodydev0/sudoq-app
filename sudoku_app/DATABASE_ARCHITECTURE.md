# Database Architecture - SudoQ Duel Mode

## Overview
This document describes the Firestore database structure optimized for **100,000+ monthly active users** with real-time duel functionality.

## Division System (ELO-based)
| Division | ELO Range | Emoji | Color |
|----------|-----------|-------|-------|
| Bronze | 0 - 499 | 🥉 | #CD7F32 |
| Silver | 500 - 799 | 🥈 | #C0C0C0 |
| Gold | 800 - 1099 | 🥇 | #FF8C00 |
| Platinum | 1100 - 1399 | 💎 | #00BFFF |
| Diamond | 1400 - 1699 | 💠 | #1E90FF |
| Master | 1700 - 1999 | 🏆 | #FFA500 |
| Grandmaster | 2000 - 2299 | 👑 | #9400D3 |
| Champion | 2300+ | 🔥 | #FF4500 |

## Collections Structure

### 1. `users/{userId}`
User profiles and game statistics.

```javascript
{
  uid: string,
  displayName: string,
  photoUrl: string | null,
  email: string | null,
  createdAt: timestamp,
  lastSeenAt: timestamp,
  
  duelStats: {
    wins: number,
    losses: number,
    elo: number,              // Starting: 450
    division: string,         // 'Bronze' | 'Silver' | ... | 'Champion'
    gamesPlayed: number,
    winStreak: number,
    bestWinStreak: number,
    totalPlayTime: number,    // in seconds
    avgCompletionTime: number,
    lastPlayedAt: timestamp,
  },
  
  achievements: string[],     // Achievement IDs
  
  settings: {
    notifications: boolean,
    soundEnabled: boolean,
  },

  // Market / entitlements (synced from PurchaseService + UserSyncService)
  isAdsFree: boolean,         // Premium: no ads (one-time or subscription)
}
```

**Subcollections:**
- `users/{userId}/duel_history/{matchId}` - Match history
- `users/{userId}/achievements/{achievementId}` - Detailed achievement data

### 2. `users/{userId}/duel_history/{matchId}`
Individual match records for history.

```javascript
{
  orderId: string,
  battleId: string,
  opponentId: string,
  opponentName: string,
  opponentPhotoUrl: string | null,
  opponentElo: number,
  won: boolean,
  eloChange: number,          // +25 or -20
  newElo: number,
  completionTimeSeconds: number,
  mistakes: number,
  difficulty: string,
  isTestBattle: boolean,
  playedAt: timestamp,
}
```

### 3. `leaderboard/{userId}` (root – Level/XP)
Level-based ranking (totalXp, level). Used by UserSyncService for general leaderboard.

```javascript
{
  uid: string,
  displayName: string,
  photoUrl: string | null,
  level: number,
  totalXp: number,
  updatedAt: timestamp,
}
```

**Indexes:** `totalXp DESC, updatedAt DESC`

### 4. `duel_leaderboard/{userId}`
Global duel leaderboard (ELO-based, sharded by division for performance).

```javascript
{
  orderId: string,
  displayName: string,
  photoUrl: string | null,
  elo: number,
  division: string,
  wins: number,
  updatedAt: timestamp,
}
```

**Indexes:**
- `elo DESC, updatedAt DESC` - Global ranking
- `division ASC, elo DESC` - Division-specific ranking

### 5. `battles/{battleId}`
Active and completed duel battles.

```javascript
{
  status: 'waiting' | 'countdown' | 'playing' | 'finished' | 'cancelled',
  difficulty: string,
  createdAt: timestamp,
  startedAt: timestamp | null,
  finishedAt: timestamp | null,
  
  player1: {
    orderId: string,
    displayName: string,
    photoUrl: string | null,
    elo: number,
    rank: string,
    progress: number,         // 0-100
    mistakes: number,
    correctCells: number,
    isFinished: boolean,
    finishedAt: timestamp | null,
    currentGrid: number[][] | null,
  },
  
  player2: { ... },           // Same structure as player1
  
  puzzle: number[][],         // 9x9 grid (0 = empty)
  solution: number[][],       // 9x9 grid (complete)
  totalCells: number,         // Empty cells to fill
  winnerId: string | null,
  isTestBattle: boolean,
}
```

**Indexes:**
- `player1.orderId ASC, status ASC`
- `player2.orderId ASC, status ASC`
- `status ASC, createdAt DESC`

### 6. `matchmaking/{userId}`
Active matchmaking queue entries.

```javascript
{
  displayName: string,
  photoUrl: string | null,
  elo: number,
  division: string,
  status: 'searching' | 'matched',
  joinedAt: timestamp,
}
```

**Indexes:**
- `elo ASC, joinedAt ASC` - ELO-based matching
- `division ASC, joinedAt ASC` - Division-based matching

### 7. `duel_seasons/{seasonId}`
Seasonal ranking data (managed by Cloud Functions).

```javascript
{
  name: string,
  startDate: timestamp,
  endDate: timestamp,
  status: 'upcoming' | 'active' | 'ended',
  rewards: {
    top1: { ... },
    top3: { ... },
    top10: { ... },
    top50: { ... },
  }
}
```

**Subcollection:** `duel_seasons/{seasonId}/leaderboard/{userId}`

### 8. `global_stats/{document}`
Aggregated statistics (updated by Cloud Functions).

```javascript
// Document: 'duel'
{
  totalMatches: number,
  totalPlayers: number,
  activePlayersToday: number,
  activePlayersWeek: number,
  avgMatchDuration: number,
  divisionDistribution: {
    Bronze: number,
    Silver: number,
    ...
  },
  updatedAt: timestamp,
}
```

### 9. `reports/{reportId}`
Abuse/cheating reports.

```javascript
{
  reporterId: string,
  reportedUserId: string,
  battleId: string | null,
  reason: string,
  description: string,
  status: 'pending' | 'reviewed' | 'resolved',
  createdAt: timestamp,
}
```

## Performance Optimizations

### 1. Sharding Strategy
- Leaderboards are sharded by division to limit query scope
- Each division can have up to ~12,500 players (100K / 8 divisions)
- Queries within a division are fast and predictable

### 2. Caching Strategy
- `leaderboard_cache` stores pre-computed top 100 for each division
- Updated every 5 minutes by Cloud Functions
- Reduces read operations by ~90% for common queries

### 3. Document Size Limits
- User documents kept under 1MB
- Match history uses subcollections (not arrays)
- Puzzle grids stored as nested arrays (efficient)

### 4. Query Optimization
- All queries use composite indexes
- No collection group queries on large collections
- Pagination with cursors, not offsets

### 5. Real-time Listener Strategy
- Battle updates: Single document listener per player
- Matchmaking: Single document listener (own entry)
- Leaderboard: Paginated snapshots, not real-time

## Scaling Considerations

### For 100K Monthly Users:
- **Estimated daily active:** ~10-20K
- **Concurrent matches:** ~500-2000
- **Reads/day:** ~5-10M
- **Writes/day:** ~500K-1M

### Cost Optimization:
1. Use cached leaderboards (reduce reads)
2. Batch match history writes
3. Limit real-time listeners
4. Use security rules to reject invalid writes early

### Future Scaling (1M+ users):
1. Consider sharding by region
2. Implement CDN for static assets
3. Use Cloud Functions for heavy aggregations
4. Consider read replicas for leaderboards

## Security Rules Summary
- Users can only read/write their own data
- Battle participants can only update their own progress
- Leaderboard entries validated for ELO bounds (0-5000)
- Reports are write-only (no user reads)
- Cached data is read-only (Cloud Functions write)

## Duel Achievements
All duel-related achievements are tracked locally and synced to cloud:

| Achievement | Requirement | XP Reward |
|-------------|-------------|-----------|
| Duel Rookie | Win 1 duel | 50 |
| Duel Fighter | Win 10 duels | 100 |
| Duel Warrior | Win 50 duels | 250 |
| Duel Veteran | Win 100 duels | 500 |
| Duel Legend | Win 500 duels | 1500 |
| Duel Hot Streak | 3 wins in a row | 60 |
| Duel On Fire | 5 wins in a row | 120 |
| Duel Unstoppable | 10 wins in a row | 300 |
| Silver Division | Reach 500 ELO | 100 |
| Gold Division | Reach 800 ELO | 150 |
| Platinum Division | Reach 1100 ELO | 250 |
| Diamond Division | Reach 1400 ELO | 400 |
| Master Division | Reach 1700 ELO | 600 |
| Grandmaster Division | Reach 2000 ELO | 1000 |
| Champion Division | Reach 2300 ELO | 2000 |
