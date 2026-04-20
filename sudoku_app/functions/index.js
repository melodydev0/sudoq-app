const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { google } = require("googleapis");
const crypto = require("crypto");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

const MATCHMAKING_TTL_MS = 2 * 60 * 1000;
const PLAY_PACKAGE_NAME = process.env.PLAY_PACKAGE_NAME || "com.sudoq.puzzle";
const APPLE_SHARED_SECRET = process.env.APPLE_SHARED_SECRET || "";
const APPLE_VERIFY_RECEIPT_PROD = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_VERIFY_RECEIPT_SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt";
const SUPPORTED_SUBSCRIPTIONS = new Set([
  "sudoq_premium",
  "sudoq_premium_weekly",
  "sudoq_premium_monthly",
  "sudoq_premium_yearly",
]);

function purchaseTokenHash(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function toMillisOrZero(isoTime) {
  if (!isoTime || typeof isoTime !== "string") return 0;
  const ms = Date.parse(isoTime);
  return Number.isFinite(ms) ? ms : 0;
}

async function verifyGooglePlaySubscription(purchaseToken) {
  const auth = new google.auth.GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const authClient = await auth.getClient();
  const androidpublisher = google.androidpublisher({
    version: "v3",
    auth: authClient,
  });

  const response = await androidpublisher.purchases.subscriptionsv2.get({
    packageName: PLAY_PACKAGE_NAME,
    token: purchaseToken,
  });

  const data = response.data || {};
  const lineItems = Array.isArray(data.lineItems) ? data.lineItems : [];

  // Log the raw response so we can diagnose pricing issues from Cloud Logs.
  logger.info("[verifyGooglePlaySubscription] raw lineItems", {
    lineItemsCount: lineItems.length,
    lineItems: JSON.stringify(lineItems),
    subscriptionState: data.subscriptionState,
  });

  let productId = null;
  let expiresAtMs = 0;
  let autoRenewing = false;
  let basePlanId = null;
  let priceCurrencyCode = null;
  let priceAmountMicros = null;

  for (const item of lineItems) {
    if (!productId && item.productId) productId = item.productId;
    const itemExpiry = toMillisOrZero(item.expiryTime);
    if (itemExpiry > expiresAtMs) expiresAtMs = itemExpiry;
    if (item.autoRenewingPlan?.autoRenewEnabled === true) {
      autoRenewing = true;
    }
  }

  // Parse ISO 8601 duration (e.g. "P1W", "P7D", "P1Y", "P1M") into days.
  // Used to identify which line item represents the shortest (= active purchase) plan.
  function billingPeriodToDays(period) {
    if (!period || typeof period !== "string") return Number.MAX_SAFE_INTEGER;
    const m = period.match(/^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$/);
    if (!m) return Number.MAX_SAFE_INTEGER;
    const years = parseInt(m[1] || "0", 10);
    const months = parseInt(m[2] || "0", 10);
    const weeks = parseInt(m[3] || "0", 10);
    const days = parseInt(m[4] || "0", 10);
    return years * 365 + months * 30 + weeks * 7 + days;
  }

  // Return the billingPeriod of the item's recurring (base) phase.
  function itemBillingPeriod(item) {
    const phases = item.offerDetails?.pricingPhases || [];
    for (const phase of phases) {
      if (phase.recurrenceMode === "INFINITE_RECURRING" && phase.billingPeriod) {
        return phase.billingPeriod;
      }
    }
    const last = phases[phases.length - 1];
    return last?.billingPeriod || null;
  }

  // Find the ACTIVE line item.  Google Play may return multiple line items
  // (e.g. stale entries from previous purchases, or concurrent subscriptions).
  // Strategy, in order of reliability:
  //   1. Among line items with a future expiryTime, pick the one with the
  //      SHORTEST billingPeriod — this is what the user just bought (weekly
  //      is shorter than yearly).  Ties broken by nearest future expiry.
  //   2. Fallback: nearest future expiryTime.
  //   3. Fallback: highest expiryTime overall.
  const nowMs = Date.now();
  const activeItems = lineItems.filter(
    (item) => toMillisOrZero(item.expiryTime) > nowMs
  );

  let activeItem = null;
  if (activeItems.length > 0) {
    activeItem = activeItems.reduce((best, item) => {
      const bestDays = billingPeriodToDays(itemBillingPeriod(best));
      const itemDays = billingPeriodToDays(itemBillingPeriod(item));
      if (itemDays < bestDays) return item;
      if (itemDays > bestDays) return best;
      return toMillisOrZero(item.expiryTime) < toMillisOrZero(best.expiryTime)
        ? item
        : best;
    });
  } else if (lineItems.length > 0) {
    activeItem = lineItems.reduce(
      (best, item) =>
        toMillisOrZero(item.expiryTime) > toMillisOrZero(best.expiryTime)
          ? item
          : best,
      lineItems[0]
    );
  }

  // Convert Google's Money format (units + nanos) into micros.
  // Money:   units = whole currency units (e.g. 99)
  //          nanos = nano units (1e-9) — e.g. 990000000 means +0.99
  // Example: units=99, nanos=990000000  →  99.99
  //          → micros = 99 * 1_000_000 + 990000000 / 1000 = 99_990_000
  function moneyToMicros(money) {
    if (!money) return null;
    const units = Number(money.units || 0);
    const nanos = Number(money.nanos || 0);
    return units * 1_000_000 + Math.round(nanos / 1000);
  }

  // Extract basePlanId and recurring price from the active item.
  // The Play Subscriptions v2 API exposes the price at
  // `autoRenewingPlan.recurringPrice` (Money format). Older docs reference
  // `offerDetails.pricingPhases`, but that field is not returned for normal
  // recurring subscriptions — it's reserved for pre-paid / offer phases.
  if (activeItem) {
    if (activeItem.offerDetails?.basePlanId) {
      basePlanId = activeItem.offerDetails.basePlanId;
    }

    // Detect whether the user is currently in an intro / promotional phase.
    // In Subscriptions v2, `offerPhase` carries either `basePrice` (normal
    // recurring phase) or promotional markers like `prorationPeriod` /
    // `introductoryPhase`. When `offerDetails.offerId` is present the user
    // is on an offer, and `autoRenewingPlan.recurringPrice` reflects the
    // BASE PLAN renewal price — NOT what the user paid this period.
    const hasOfferId = !!activeItem.offerDetails?.offerId;
    const offerPhaseKeys = Object.keys(activeItem.offerPhase || {});
    const isBasePriceOnly =
      offerPhaseKeys.length === 1 && offerPhaseKeys[0] === "basePrice";
    const isIntroPhase = hasOfferId || (offerPhaseKeys.length > 0 && !isBasePriceOnly);

    const recurring = activeItem.autoRenewingPlan?.recurringPrice;
    const prepaid = activeItem.prepaidPlan?.basePrice;
    const moneyField = !isIntroPhase ? (recurring || prepaid) : null;

    if (moneyField) {
      priceCurrencyCode = moneyField.currencyCode || null;
      priceAmountMicros = moneyToMicros(moneyField);
    } else if (isIntroPhase) {
      // Leave priceAmountMicros null so the admin panel falls back to the
      // client-provided price (which reflects the actual intro amount paid).
      priceAmountMicros = null;
      priceCurrencyCode = null;
      logger.info(
        "[verifyGooglePlaySubscription] intro/promotional phase — " +
          "deferring to client price",
        {
          offerId: activeItem.offerDetails?.offerId || null,
          offerPhaseKeys,
        }
      );
    } else {
      // Legacy fallback: some older responses include pricingPhases.
      const phases = activeItem.offerDetails?.pricingPhases || [];
      const chosenPhase =
        phases.find((p) => p.recurrenceMode === "INFINITE_RECURRING") ||
        phases[phases.length - 1];
      if (chosenPhase) {
        priceCurrencyCode = chosenPhase.currencyCode || null;
        priceAmountMicros = chosenPhase.priceAmountMicros
          ? Number(chosenPhase.priceAmountMicros)
          : null;
      }
    }

    logger.info("[verifyGooglePlaySubscription] selected plan", {
      basePlanId,
      billingPeriod: itemBillingPeriod(activeItem),
      priceAmountMicros,
      priceCurrencyCode,
      priceSource: isIntroPhase
        ? "intro (client)"
        : recurring
          ? "recurring"
          : prepaid
            ? "prepaid"
            : "pricingPhases",
      isIntroPhase,
      offerId: activeItem.offerDetails?.offerId || null,
    });
  }

  const state = data.subscriptionState || "SUBSCRIPTION_STATE_UNSPECIFIED";
  const activeStates = new Set([
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
    "SUBSCRIPTION_STATE_ON_HOLD",
  ]);
  const premium = activeStates.has(state) && expiresAtMs > Date.now();

  const orderId = data.latestOrderId || null;
  const startTime = data.startTime || null;
  const regionCode = data.regionCode || null;
  const acknowledgementState = data.acknowledgementState || null;

  return {
    premium,
    state,
    productId,
    basePlanId,
    autoRenewing,
    source: "google_play",
    expiresAt: expiresAtMs > 0 ? Timestamp.fromMillis(expiresAtMs) : null,
    proof: purchaseToken,
    orderId,
    startTime,
    regionCode,
    acknowledgementState,
    priceCurrencyCode,
    priceAmountMicros,
  };
}

async function postAppleVerifyReceipt(url, receiptData) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receiptData,
      password: APPLE_SHARED_SECRET,
      "exclude-old-transactions": true,
    }),
  });
  if (!response.ok) {
    throw new Error(`apple_verify_http_${response.status}`);
  }
  return response.json();
}

async function verifyAppleSubscription(receiptData) {
  if (!APPLE_SHARED_SECRET) {
    throw new Error("missing_apple_shared_secret");
  }

  let payload = await postAppleVerifyReceipt(APPLE_VERIFY_RECEIPT_PROD, receiptData);
  if (payload.status === 21007) {
    payload = await postAppleVerifyReceipt(APPLE_VERIFY_RECEIPT_SANDBOX, receiptData);
  }
  if (payload.status !== 0) {
    throw new Error(`apple_receipt_invalid_${payload.status}`);
  }

  const latest = Array.isArray(payload.latest_receipt_info) ? payload.latest_receipt_info : [];
  const inApp = Array.isArray(payload.receipt?.in_app) ? payload.receipt.in_app : [];
  const candidates = [...latest, ...inApp].filter((item) =>
    SUPPORTED_SUBSCRIPTIONS.has(item.product_id)
  );

  if (candidates.length === 0) {
    return {
      premium: false,
      state: "NO_SUPPORTED_SUBSCRIPTION",
      productId: null,
      autoRenewing: false,
      source: "app_store",
      expiresAt: null,
      proof: receiptData,
    };
  }

  candidates.sort((a, b) => {
    const ams = Number(a.expires_date_ms || 0);
    const bms = Number(b.expires_date_ms || 0);
    return bms - ams;
  });
  const latestEntry = candidates[0];
  const expiresAtMs = Number(latestEntry.expires_date_ms || 0);

  const pendingRenewal = Array.isArray(payload.pending_renewal_info)
    ? payload.pending_renewal_info
    : [];
  const renewalInfo = pendingRenewal.find(
    (item) =>
      item.original_transaction_id === latestEntry.original_transaction_id ||
      item.auto_renew_product_id === latestEntry.product_id
  );
  const autoRenewing = renewalInfo?.auto_renew_status === "1";

  const nowMs = Date.now();
  const premium = expiresAtMs > nowMs;
  const state = premium ? "ACTIVE" : "EXPIRED";

  // Derive basePlanId from iOS product_id
  const iosProductId = latestEntry.product_id || "";
  let basePlanId = null;
  if (iosProductId.includes("weekly")) basePlanId = "weekly";
  else if (iosProductId.includes("monthly")) basePlanId = "monthly";
  else if (iosProductId.includes("yearly")) basePlanId = "yearly";

  const transactionId = latestEntry.transaction_id || null;
  const originalTransactionId = latestEntry.original_transaction_id || null;
  const purchaseDateMs = latestEntry.purchase_date_ms ? Number(latestEntry.purchase_date_ms) : null;
  const isTrialPeriod = latestEntry.is_trial_period === "true";
  const isInIntroOfferPeriod = latestEntry.is_in_intro_offer_period === "true";
  const webOrderLineItemId = latestEntry.web_order_line_item_id || null;

  return {
    premium,
    state,
    productId: latestEntry.product_id,
    basePlanId,
    autoRenewing,
    source: "app_store",
    expiresAt: expiresAtMs > 0 ? Timestamp.fromMillis(expiresAtMs) : null,
    proof: latestEntry.original_transaction_id || latestEntry.transaction_id || receiptData,
    orderId: originalTransactionId,
    transactionId,
    purchaseDateMs,
    isTrialPeriod,
    isInIntroOfferPeriod,
    webOrderLineItemId,
  };
}

function isExpired(entry, nowMs) {
  const expiresAt = entry?.expiresAt;
  if (!expiresAt || typeof expiresAt.toMillis !== "function") return false;
  return expiresAt.toMillis() <= nowMs;
}

function difficultyForElo(elo) {
  const pool =
    elo < 500
      ? ["Easy", "Medium", "Hard"]
      : elo < 1100
        ? ["Medium", "Hard", "Expert"]
        : ["Hard", "Expert"];
  return pool[Math.floor(Math.random() * pool.length)];
}

function makeSudoku(difficulty) {
  const side = 9;
  const base = 3;

  const pattern = (r, c) => (base * (r % base) + Math.floor(r / base) + c) % side;
  const shuffle = (arr) => {
    const copy = [...arr];
    for (let i = copy.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
  };

  const rBase = Array.from({ length: base }, (_, i) => i);
  const rows = shuffle(rBase).flatMap((g) => shuffle(rBase).map((r) => g * base + r));
  const cols = shuffle(rBase).flatMap((g) => shuffle(rBase).map((c) => g * base + c));
  const nums = shuffle(Array.from({ length: side }, (_, i) => i + 1));

  const solution = rows.map((r) => cols.map((c) => nums[pattern(r, c)]));
  const puzzle = solution.map((row) => [...row]);

  let removals = 45;
  if (difficulty === "Easy") removals = 38;
  if (difficulty === "Hard") removals = 52;
  if (difficulty === "Expert") removals = 56;

  const positions = shuffle(Array.from({ length: side * side }, (_, i) => i));
  for (let i = 0; i < removals; i++) {
    const p = positions[i];
    const r = Math.floor(p / side);
    const c = p % side;
    puzzle[r][c] = 0;
  }

  return { puzzle, solution, totalCells: removals };
}

exports.matchmakeOnQueueJoin = onDocumentWritten(
  "matchmaking/{oderId}",
  async (event) => {
    const myId = event.params.oderId;
    const myRef = db.collection("matchmaking").doc(myId);

    // Use the new document state.
    const myData = event.data?.after?.data();
    const prevData = event.data?.before?.data();

    // Only run matchmaking when the document becomes 'searching'.
    // Skip heartbeat updates (prevData was already 'searching') and deletes.
    if (!myData || myData.status !== "searching") return;
    if (prevData?.status === "searching") return;

    const nowMs = Date.now();
    if (isExpired(myData, nowMs)) return;

    const candidatesSnap = await db
      .collection("matchmaking")
      .where("status", "==", "searching")
      .orderBy("joinedAt")
      .limit(40)
      .get();

    const myElo = myData.elo || 450;
    const candidates = candidatesSnap.docs
      .filter((d) => d.id !== myId)
      .map((d) => ({ id: d.id, data: d.data() }))
      .filter((c) => !isExpired(c.data, nowMs))
      .sort((a, b) => {
        const da = Math.abs((a.data.elo || 450) - myElo);
        const dbv = Math.abs((b.data.elo || 450) - myElo);
        return da - dbv;
      });

    if (candidates.length === 0) return;
    const opponent = candidates[0];
    const oppRef = db.collection("matchmaking").doc(opponent.id);

    await db.runTransaction(async (tx) => {
      const [myFresh, oppFresh] = await Promise.all([tx.get(myRef), tx.get(oppRef)]);
      if (!myFresh.exists || !oppFresh.exists) return;

      const me = myFresh.data();
      const opp = oppFresh.data();
      if (!me || !opp) return;
      if (me.status !== "searching" || opp.status !== "searching") return;
      if (isExpired(me, Date.now()) || isExpired(opp, Date.now())) return;

      const avgElo = Math.round(((me.elo || 450) + (opp.elo || 450)) / 2);
      const difficulty = difficultyForElo(avgElo);
      const generated = makeSudoku(difficulty);

      const battleRef = db.collection("battles").doc();
      const battleDoc = {
        status: "countdown",
        difficulty,
        createdAt: FieldValue.serverTimestamp(),
        startedAt: null,
        finishedAt: null,
        winnerId: null,
        totalCells: generated.totalCells,
        isTestBattle: false,
        puzzle: JSON.stringify(generated.puzzle),
        solution: JSON.stringify(generated.solution),
        player1: {
          oderId: myId,
          displayName: me.displayName || "Player",
          photoUrl: me.photoUrl || null,
          elo: me.elo || 450,
          rank: me.rank || me.division || "Rookie",
          countryCode: me.countryCode || null,
          progress: 0,
          mistakes: 0,
          correctCells: 0,
          isFinished: false,
          finishedAt: null,
          currentGrid: null,
        },
        player2: {
          oderId: opponent.id,
          displayName: opp.displayName || "Player",
          photoUrl: opp.photoUrl || null,
          elo: opp.elo || 450,
          rank: opp.rank || opp.division || "Rookie",
          countryCode: opp.countryCode || null,
          progress: 0,
          mistakes: 0,
          correctCells: 0,
          isFinished: false,
          finishedAt: null,
          currentGrid: null,
        },
      };

      tx.set(battleRef, battleDoc);
      tx.update(myRef, {
        status: "matched",
        battleId: battleRef.id,
        matchedAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + 30 * 1000),
      });
      tx.update(oppRef, {
        status: "matched",
        battleId: battleRef.id,
        matchedAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + 30 * 1000),
      });
    });
  }
);

exports.cleanupStaleMatchmaking = onSchedule("every 1 minutes", async () => {
  const now = Timestamp.now();
  const stale = await db
    .collection("matchmaking")
    .where("expiresAt", "<=", now)
    .limit(500)
    .get();

  if (stale.empty) return;

  const batch = db.batch();
  stale.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  logger.info(`Cleaned stale matchmaking entries: ${stale.size}`);
});

exports.verifyPurchaseClaim = onDocumentCreated(
  {
    document: "purchase_claims/{claimId}",
    minInstances: 1,
  },
  async (event) => {
    const claimId = event.params.claimId;
    const claimRef = db.collection("purchase_claims").doc(claimId);
    const claim = event.data?.data();
    if (!claim) return;

    const uid = claim.uid;
    const platform = claim.platform;
    const productId = claim.productId;
    const purchaseToken = claim.purchaseToken;
    const receiptData = claim.receiptData;
    const isTestPurchase = claim.isTestPurchase === true;

    if (
      !uid ||
      (platform !== "android" && platform !== "ios") ||
      (platform === "android" && !purchaseToken) ||
      (platform === "ios" && !receiptData)
    ) {
      await claimRef.set(
        {
          status: "rejected",
          premium: false,
          error: "invalid_claim_payload",
          processedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return;
    }

    if (!SUPPORTED_SUBSCRIPTIONS.has(productId)) {
      await claimRef.set(
        {
          status: "rejected",
          premium: false,
          error: "unsupported_product",
          processedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return;
    }

    try {
      const verification =
        platform === "android"
          ? await verifyGooglePlaySubscription(purchaseToken)
          : await verifyAppleSubscription(receiptData);

      if (!verification.productId || !SUPPORTED_SUBSCRIPTIONS.has(verification.productId)) {
        await claimRef.set(
          {
            status: "rejected",
            premium: false,
            error: "product_verification_failed",
            processedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        return;
      }

      const tokenHash = purchaseTokenHash(`${platform}:${verification.proof}`);
      const tokenRef = db.collection("purchase_tokens").doc(tokenHash);
      const entitlementRef = db.collection("entitlements").doc(uid);

      await db.runTransaction(async (tx) => {
        const existingTokenSnap = await tx.get(tokenRef);
        const previousUid = existingTokenSnap.exists ? existingTokenSnap.data()?.uid : null;

        if (previousUid && previousUid !== uid) {
          const previousEntitlementRef = db.collection("entitlements").doc(previousUid);
          tx.set(
            previousEntitlementRef,
            {
              premium: false,
              revokedReason: "token_relinked",
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }

        tx.set(
          tokenRef,
          {
            uid,
            platform,
            productId: verification.productId,
            state: verification.state,
            autoRenewing: verification.autoRenewing,
            expiresAt: verification.expiresAt,
            proof: verification.proof,
            isTestPurchase,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        tx.set(
          entitlementRef,
          {
            premium: verification.premium,
            source: verification.source,
            productId: verification.productId,
            basePlanId: verification.basePlanId || null,
            tokenHash,
            state: verification.state,
            autoRenewing: verification.autoRenewing,
            expiresAt: verification.expiresAt,
            isTestPurchase,
            orderId: verification.orderId || null,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        tx.set(
          claimRef,
          {
            status: "verified",
            premium: verification.premium,
            resolvedUid: uid,
            verifiedProductId: verification.productId,
            basePlanId: verification.basePlanId || null,
            verificationState: verification.state,
            orderId: verification.orderId || null,
            autoRenewing: verification.autoRenewing,
            regionCode: verification.regionCode || null,
            priceCurrencyCode: verification.priceCurrencyCode || null,
            priceAmountMicros: verification.priceAmountMicros || null,
            isTrialPeriod: verification.isTrialPeriod || false,
            processedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });
    } catch (error) {
      logger.error("verifyPurchaseClaim failed", {
        claimId,
        uid,
        error: String(error),
      });
      await claimRef.set(
        {
          status: "error",
          premium: false,
          error: "verification_failed",
          processedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  }
);

// ============================================================
// LEADERBOARD CACHE
// Rebuilds /leaderboard_cache/top_players every 10 minutes
// with top 100 by totalXp and top 100 by duel ELO.
// ============================================================
exports.refreshLeaderboardCache = onSchedule("every 10 minutes", async () => {
  const [xpSnap, eloSnap] = await Promise.all([
    db.collection("leaderboard").orderBy("totalXp", "desc").limit(100).get(),
    db.collection("duel_leaderboard").orderBy("elo", "desc").limit(100).get(),
  ]);

  const xpPlayers = xpSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const eloPlayers = eloSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  const batch = db.batch();

  batch.set(db.collection("leaderboard_cache").doc("top_xp"), {
    players: xpPlayers,
    updatedAt: FieldValue.serverTimestamp(),
  });

  batch.set(db.collection("leaderboard_cache").doc("top_elo"), {
    players: eloPlayers,
    updatedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  logger.info("Leaderboard cache refreshed", {
    xpCount: xpPlayers.length,
    eloCount: eloPlayers.length,
  });
});

// ============================================================
// LEADERBOARD DIVISION CACHE
// Rebuilds per-division shards every 15 minutes for fast queries.
// Divisions: Bronze, Silver, Gold, Platinum, Diamond, Master, Grandmaster, Champion
// ============================================================
const ELO_DIVISIONS = [
  { name: "Bronze",      min: 0,    max: 499  },
  { name: "Silver",      min: 500,  max: 799  },
  { name: "Gold",        min: 800,  max: 1099 },
  { name: "Platinum",    min: 1100, max: 1399 },
  { name: "Diamond",     min: 1400, max: 1699 },
  { name: "Master",      min: 1700, max: 1999 },
  { name: "Grandmaster", min: 2000, max: 2299 },
  { name: "Champion",    min: 2300, max: 9999 },
];

exports.refreshDivisionLeaderboard = onSchedule("every 15 minutes", async () => {
  const batch = db.batch();

  for (const div of ELO_DIVISIONS) {
    const snap = await db
      .collection("duel_leaderboard")
      .where("elo", ">=", div.min)
      .where("elo", "<=", div.max)
      .orderBy("elo", "desc")
      .limit(50)
      .get();

    const players = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    batch.set(
      db.collection("leaderboard_cache").doc(`division_${div.name.toLowerCase()}`),
      {
        division: div.name,
        players,
        updatedAt: FieldValue.serverTimestamp(),
      }
    );
  }

  await batch.commit();
  logger.info("Division leaderboard cache refreshed");
});

// ============================================================
// DUEL MATCH NOTIFICATION (OneSignal)
// When a battle is created (status = countdown), notifies both
// players via OneSignal so they can join immediately.
// ============================================================
const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || "";
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || "";

exports.notifyDuelMatch = onDocumentCreated("battles/{battleId}", async (event) => {
  const battleId = event.params.battleId;
  const battle = event.data?.data();
  if (!battle || battle.status !== "countdown") return;

  const p1Id = battle.player1?.oderId;
  const p2Id = battle.player2?.oderId;
  if (!p1Id || !p2Id) return;

  const p1Name = battle.player1?.displayName || "Opponent";
  const p2Name = battle.player2?.displayName || "Opponent";

  const sendNotification = async (externalUserId, opponentName) => {
    if (!externalUserId || !ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) return;
    try {
      await fetch("https://api.onesignal.com/notifications", {
        method: "POST",
        headers: {
          "Authorization": `Key ${ONESIGNAL_REST_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          app_id: ONESIGNAL_APP_ID,
          include_aliases: { external_id: [externalUserId] },
          target_channel: "push",
          headings: {
            en: "Duel Found!",
            tr: "Düello Bulundu!",
            zh: "决斗已找到！",
            hi: "द्वंद्व मिला!",
            es: "¡Duelo encontrado!",
            fr: "Duel trouvé !",
            ar: "تم العثور على مبارزة!",
            bn: "দ্বৈরথ পাওয়া গেছে!",
            pt: "Duelo encontrado!",
            ru: "Дуэль найдена!",
            ja: "デュエル発見！",
          },
          contents: {
            en: `Matched against ${opponentName}. Get ready!`,
            tr: `${opponentName} ile eşleştin. Hazırlan!`,
            zh: `与${opponentName}匹配。准备好！`,
            hi: `${opponentName} के खिलाफ मैच हुआ। तैयार हो जाओ!`,
            es: `Emparejado contra ${opponentName}. ¡Prepárate!`,
            fr: `Opposé à ${opponentName}. Préparez-vous !`,
            ar: `تمت مطابقتك مع ${opponentName}. استعد!`,
            bn: `${opponentName}-এর বিরুদ্ধে ম্যাচ হয়েছে। প্রস্তুত হও!`,
            pt: `Pareado contra ${opponentName}. Prepare-se!`,
            ru: `Матч против ${opponentName}. Приготовься!`,
            ja: `${opponentName}と対戦！準備して！`,
          },
          data: { type: "duel_match", battleId },
          priority: 10,
        }),
      });
    } catch (err) {
      logger.warn("OneSignal send failed", { externalUserId, error: String(err) });
    }
  };

  await Promise.all([
    sendNotification(p1Id, p2Name),
    sendNotification(p2Id, p1Name),
  ]);

  logger.info("Duel match notifications sent via OneSignal", { battleId, p1Id, p2Id });
});

// ============================================================
// HELPER: Send OneSignal notification
// ============================================================
async function sendOneSignalNotification(payload) {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    logger.warn("OneSignal credentials missing, skipping notification");
    return null;
  }
  const res = await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      "Authorization": `Key ${ONESIGNAL_REST_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ app_id: ONESIGNAL_APP_ID, ...payload }),
  });
  if (!res.ok) {
    const errorText = await res.text().catch(() => "unknown");
    logger.warn("OneSignal HTTP error", { status: res.status, body: errorText });
    return null;
  }
  const data = await res.json();
  if (data.errors) logger.warn("OneSignal errors", data.errors);
  return data;
}

// ============================================================
// 1. DAILY CHALLENGE REMINDER
// Runs every day at 10:00 UTC. Sends to all subscribed users
// in their local timezone language.
// ============================================================
exports.sendDailyChallengeReminder = onSchedule("every day 10:00", async () => {
  const result = await sendOneSignalNotification({
    included_segments: ["Subscribed Users"],
    target_channel: "push",
    headings: {
      en: "Daily Challenge Awaits!",
      tr: "Günlük Meydan Okuma Seni Bekliyor!",
      zh: "每日挑战等你来！",
      hi: "दैनिक चुनौती आपका इंतज़ार कर रही है!",
      es: "¡El desafío diario te espera!",
      fr: "Le défi quotidien vous attend !",
      ar: "التحدي اليومي في انتظارك!",
      bn: "দৈনিক চ্যালেঞ্জ আপনার জন্য অপেক্ষা করছে!",
      pt: "O desafio diário te espera!",
      ru: "Ежедневное испытание ждёт!",
      ja: "デイリーチャレンジが待っています！",
    },
    contents: {
      en: "A fresh puzzle is ready. Can you keep your streak going? 🧩",
      tr: "Yeni bulmaca hazır. Serini sürdürebilecek misin? 🧩",
      zh: "新谜题已准备好。你能保持连胜吗？🧩",
      hi: "एक नई पहेली तैयार है। क्या आप अपनी लय बनाए रख सकते हैं? 🧩",
      es: "Un nuevo puzzle está listo. ¿Puedes mantener tu racha? 🧩",
      fr: "Un nouveau puzzle est prêt. Pouvez-vous maintenir votre série ? 🧩",
      ar: "لغز جديد جاهز. هل يمكنك الحفاظ على سلسلتك؟ 🧩",
      bn: "একটি নতুন ধাঁধা প্রস্তুত। আপনি কি আপনার ধারা চালিয়ে যেতে পারবেন? 🧩",
      pt: "Um novo puzzle está pronto. Consegue manter sua sequência? 🧩",
      ru: "Новая головоломка готова. Сможешь сохранить серию? 🧩",
      ja: "新しいパズルの準備ができました。連続記録を維持できますか？🧩",
    },
    data: { type: "daily_challenge" },
    delayed_option: "timezone",
  });
  logger.info("Daily challenge reminder sent", { recipients: result?.recipients });
});

// ============================================================
// 2. RE-ENGAGEMENT NOTIFICATION
// Runs daily, targets users inactive for 72+ hours.
// ============================================================
exports.sendReengagementNotification = onSchedule("every day 18:00", async () => {
  const result = await sendOneSignalNotification({
    included_segments: ["Inactive Users"],
    target_channel: "push",
    headings: {
      en: "We miss you! 👋",
      tr: "Seni özledik! 👋",
      zh: "我们想你了！👋",
      hi: "हम आपको याद कर रहे हैं! 👋",
      es: "¡Te extrañamos! 👋",
      fr: "Vous nous manquez ! 👋",
      ar: "نحن نفتقدك! 👋",
      bn: "আমরা আপনাকে মিস করছি! 👋",
      pt: "Sentimos sua falta! 👋",
      ru: "Мы скучаем! 👋",
      ja: "お待ちしています！👋",
    },
    contents: {
      en: "Your brain needs a workout! Come back and solve today's puzzle. 🧠",
      tr: "Beynin egzersiz istiyor! Gel bugünkü bulmacayı çöz. 🧠",
      zh: "你的大脑需要锻炼！回来解今天的谜题吧。🧠",
      hi: "आपके दिमाग को व्यायाम की जरूरत है! आज की पहेली हल करें। 🧠",
      es: "¡Tu cerebro necesita ejercicio! Vuelve y resuelve el puzzle de hoy. 🧠",
      fr: "Votre cerveau a besoin d'exercice ! Revenez résoudre le puzzle du jour. 🧠",
      ar: "عقلك يحتاج للتمرين! عد وحل لغز اليوم. 🧠",
      bn: "আপনার মস্তিষ্কের ব্যায়াম দরকার! এসে আজকের ধাঁধা সমাধান করুন। 🧠",
      pt: "Seu cérebro precisa de exercício! Volte e resolva o puzzle de hoje. 🧠",
      ru: "Мозг требует тренировки! Вернись и реши сегодняшнюю головоломку. 🧠",
      ja: "脳にはトレーニングが必要です！今日のパズルを解きましょう。🧠",
    },
    data: { type: "reengagement" },
    delayed_option: "timezone",
  });
  logger.info("Re-engagement notification sent", { recipients: result?.recipients });
});

// ============================================================
// 3. WELCOME SERIES
// Triggered when a new user document is created.
// Sends 3 tips over 3 days via delayed notifications.
// ============================================================
const WELCOME_MESSAGES = [
  {
    delay: 0,
    headings: {
      en: "Welcome to SudoQ! 🎉",
      tr: "SudoQ'ya Hoş Geldin! 🎉",
      zh: "欢迎来到SudoQ！🎉",
      hi: "SudoQ में आपका स्वागत है! 🎉",
      es: "¡Bienvenido a SudoQ! 🎉",
      fr: "Bienvenue sur SudoQ ! 🎉",
      ar: "مرحباً بك في SudoQ! 🎉",
      bn: "SudoQ-তে স্বাগতম! 🎉",
      pt: "Bem-vindo ao SudoQ! 🎉",
      ru: "Добро пожаловать в SudoQ! 🎉",
      ja: "SudoQへようこそ！🎉",
    },
    contents: {
      en: "Start with Easy mode to warm up. Tap a cell, pick a number, and enjoy! 😊",
      tr: "Isınmak için Kolay modla başla. Hücreye dokun, sayı seç ve keyfini çıkar! 😊",
      zh: "从简单模式开始热身。点击格子，选择数字，享受吧！😊",
      hi: "वार्म अप के लिए आसान मोड से शुरू करें। सेल पर टैप करें, नंबर चुनें! 😊",
      es: "Empieza con el modo Fácil. ¡Toca una celda, elige un número y disfruta! 😊",
      fr: "Commencez par le mode Facile. Touchez une case, choisissez un nombre ! 😊",
      ar: "ابدأ بالوضع السهل. انقر على خلية، اختر رقمًا واستمتع! 😊",
      bn: "সহজ মোড দিয়ে শুরু করুন। একটি ঘরে ট্যাপ করুন, সংখ্যা বাছুন! 😊",
      pt: "Comece pelo modo Fácil. Toque numa célula, escolha um número! 😊",
      ru: "Начни с лёгкого режима. Нажми на ячейку, выбери число! 😊",
      ja: "イージーモードから始めましょう。セルをタップして数字を選ぼう！😊",
    },
  },
  {
    delay: 86400,
    headings: {
      en: "Tip: Use Notes Mode ✏️",
      tr: "İpucu: Not Modunu Kullan ✏️",
      zh: "提示：使用笔记模式 ✏️",
      hi: "सुझाव: नोट्स मोड का उपयोग करें ✏️",
      es: "Consejo: Usa el modo Notas ✏️",
      fr: "Astuce : Utilisez le mode Notes ✏️",
      ar: "نصيحة: استخدم وضع الملاحظات ✏️",
      bn: "টিপ: নোট মোড ব্যবহার করুন ✏️",
      pt: "Dica: Use o modo Notas ✏️",
      ru: "Совет: используй режим заметок ✏️",
      ja: "ヒント：メモモードを使おう ✏️",
    },
    contents: {
      en: "Toggle notes mode to pencil in possible numbers. It's the key to solving harder puzzles!",
      tr: "Olası sayıları not etmek için not modunu aç. Zor bulmacaların anahtarı!",
      zh: "切换笔记模式来标记可能的数字。这是解决难题的关键！",
      hi: "संभावित संख्याएँ लिखने के लिए नोट्स मोड चालू करें। कठिन पहेलियों की कुंजी!",
      es: "Activa el modo notas para anotar números posibles. ¡La clave para puzzles difíciles!",
      fr: "Activez le mode notes pour noter les nombres possibles. La clé des puzzles difficiles !",
      ar: "فعّل وضع الملاحظات لتدوين الأرقام المحتملة. مفتاح حل الألغاز الصعبة!",
      bn: "সম্ভাব্য সংখ্যা লিখতে নোট মোড চালু করুন। কঠিন ধাঁধার চাবিকাঠি!",
      pt: "Ative o modo notas para anotar números possíveis. A chave para puzzles difíceis!",
      ru: "Включи режим заметок, чтобы отмечать возможные числа. Ключ к сложным головоломкам!",
      ja: "メモモードで候補数字を書き込もう。難しいパズルの鍵です！",
    },
  },
  {
    delay: 172800,
    headings: {
      en: "Try a Duel! ⚔️",
      tr: "Düello Dene! ⚔️",
      zh: "来一场决斗吧！⚔️",
      hi: "एक द्वंद्व खेलें! ⚔️",
      es: "¡Prueba un Duelo! ⚔️",
      fr: "Essayez un Duel ! ⚔️",
      ar: "جرّب المبارزة! ⚔️",
      bn: "একটি দ্বৈরথ খেলুন! ⚔️",
      pt: "Experimente um Duelo! ⚔️",
      ru: "Попробуй дуэль! ⚔️",
      ja: "デュエルに挑戦！⚔️",
    },
    contents: {
      en: "Challenge a real player and race to solve the puzzle first. Climb the ranks! 🏆",
      tr: "Gerçek bir oyuncuya meydan oku ve bulmacayı ilk sen çöz. Sıralamada yüksel! 🏆",
      zh: "挑战真人玩家，比赛谁先解开谜题。攀登排名！🏆",
      hi: "किसी असली खिलाड़ी को चुनौती दें और पहले पहेली हल करें। रैंकिंग में आगे बढ़ें! 🏆",
      es: "Desafía a un jugador real y resuelve el puzzle primero. ¡Sube en el ranking! 🏆",
      fr: "Défiez un vrai joueur et résolvez le puzzle en premier. Grimpez au classement ! 🏆",
      ar: "تحدَّ لاعبًا حقيقيًا وسابقه في حل اللغز. ارتقِ في التصنيف! 🏆",
      bn: "একজন আসল খেলোয়াড়কে চ্যালেঞ্জ করুন এবং প্রথমে ধাঁধা সমাধান করুন। র‍্যাঙ্কে উঠুন! 🏆",
      pt: "Desafie um jogador real e resolva o puzzle primeiro. Suba no ranking! 🏆",
      ru: "Бросай вызов реальному игроку и реши головоломку первым. Поднимись в рейтинге! 🏆",
      ja: "リアルプレイヤーに挑戦してパズルを先に解こう。ランキングを上げよう！🏆",
    },
  },
];

exports.sendWelcomeSeries = onDocumentCreated("users/{userId}", async (event) => {
  const userId = event.params.userId;
  const userData = event.data?.data();
  if (!userData) return;

  const welcomeRef = db.collection("welcome_sent").doc(userId);
  const welcomeSnap = await welcomeRef.get();
  if (welcomeSnap.exists) {
    logger.info("Welcome series already sent, skipping", { userId });
    return;
  }

  await welcomeRef.set({ sentAt: FieldValue.serverTimestamp() });

  for (const msg of WELCOME_MESSAGES) {
    const payload = {
      include_aliases: { external_id: [userId] },
      target_channel: "push",
      headings: msg.headings,
      contents: msg.contents,
      data: { type: "welcome_tip" },
    };

    if (msg.delay > 0) {
      const sendAt = new Date(Date.now() + msg.delay * 1000);
      payload.send_after = sendAt.toISOString();
    }

    try {
      await sendOneSignalNotification(payload);
    } catch (err) {
      logger.warn("Welcome series send failed", { userId, delay: msg.delay, error: String(err) });
    }
  }

  logger.info("Welcome series scheduled", { userId, messages: WELCOME_MESSAGES.length });
});

// ============================================================
// SUBSCRIPTION EXPIRY CHECK
// Runs every hour. Finds entitlements where expiresAt has passed
// and premium is still true, then revokes them.
// Also re-verifies with Google Play to catch renewals.
// ============================================================
exports.checkExpiredSubscriptions = onSchedule("every 1 hours", async () => {
  const now = Timestamp.now();

  const expiredSnap = await db
    .collection("entitlements")
    .where("premium", "==", true)
    .where("expiresAt", "<=", now)
    .limit(200)
    .get();

  if (expiredSnap.empty) {
    logger.info("No expired subscriptions found");
    return;
  }

  let revoked = 0;
  let renewed = 0;

  for (const doc of expiredSnap.docs) {
    const data = doc.data();
    const tokenHash = data.tokenHash;

    if (tokenHash) {
      const tokenDoc = await db.collection("purchase_tokens").doc(tokenHash).get();
      const tokenData = tokenDoc.exists ? tokenDoc.data() : null;
      const purchaseToken = tokenData
        ? tokenData.proof || null
        : null;

      if (purchaseToken && data.source === "google_play") {
        try {
          const freshStatus = await verifyGooglePlaySubscription(purchaseToken);
          if (freshStatus.premium) {
            await doc.ref.set({
              premium: true,
              state: freshStatus.state,
              expiresAt: freshStatus.expiresAt,
              autoRenewing: freshStatus.autoRenewing,
              updatedAt: FieldValue.serverTimestamp(),
            }, { merge: true });
            renewed++;
            continue;
          }
        } catch (err) {
          logger.warn("Re-verify failed, revoking", { uid: doc.id, error: String(err) });
        }
      }
    }

    await doc.ref.set({
      premium: false,
      revokedReason: "expired",
      revokedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    revoked++;
  }

  logger.info("Subscription expiry check complete", { checked: expiredSnap.size, revoked, renewed });
});

// ============================================================
// GOOGLE PLAY RTDN (Real-Time Developer Notifications)
// Receives Pub/Sub messages from Google Play when subscription
// status changes: renewal, cancellation, refund, revoke, etc.
// Setup:
//   1. Google Cloud Console > Pub/Sub > Create topic "play-billing-notifications"
//   2. Google Play Console > Monetization > Monetization setup
//      > Real-time developer notifications
//      > Topic: projects/sudoq-online/topics/play-billing-notifications
// ============================================================
exports.playBillingRTDN = onMessagePublished("play-billing-notifications", async (event) => {
  try {
    const messageData = event.data?.message?.data;
    if (!messageData) {
      logger.warn("RTDN: No message data");
      return;
    }

    const decoded = typeof messageData === "string"
      ? JSON.parse(Buffer.from(messageData, "base64").toString("utf-8"))
      : messageData;
    const notification = decoded.subscriptionNotification;

    if (!notification) {
      logger.info("RTDN: Not a subscription notification, ignoring");
      return;
    }

    const { notificationType, purchaseToken, subscriptionId } = notification;
    logger.info("RTDN received", { notificationType, subscriptionId });

    // Notification types that mean subscription is no longer valid
    // 3 = SUBSCRIPTION_CANCELED
    // 5 = SUBSCRIPTION_ON_HOLD (payment failed)
    // 10 = SUBSCRIPTION_PAUSED
    // 12 = SUBSCRIPTION_REVOKED (refund)
    // 13 = SUBSCRIPTION_EXPIRED
    const revokeTypes = new Set([3, 5, 10, 12, 13]);

    // Notification types that mean subscription is active
    // 1 = SUBSCRIPTION_RECOVERED (came back from hold)
    // 2 = SUBSCRIPTION_RENEWED
    // 4 = SUBSCRIPTION_PURCHASED
    // 7 = SUBSCRIPTION_RESTARTED
    const activeTypes = new Set([1, 2, 4, 7]);

    if (!purchaseToken) {
      logger.warn("RTDN: No purchase token");
      return;
    }

    const tokenHash = purchaseTokenHash(`google_play:${purchaseToken}`);
    const tokenRef = db.collection("purchase_tokens").doc(tokenHash);
    const tokenSnap = await tokenRef.get();

    if (!tokenSnap.exists) {
      logger.info("RTDN: Token not found in our system, skipping", { tokenHash: tokenHash.slice(0, 12) });
      return;
    }

    const tokenData = tokenSnap.data();
    const uid = tokenData.uid;
    if (!uid) return;

    const entitlementRef = db.collection("entitlements").doc(uid);

    if (revokeTypes.has(notificationType)) {
      let revokedReason = "rtdn_unknown";
      if (notificationType === 3) revokedReason = "canceled";
      if (notificationType === 5) revokedReason = "on_hold";
      if (notificationType === 10) revokedReason = "paused";
      if (notificationType === 12) revokedReason = "refunded";
      if (notificationType === 13) revokedReason = "expired";

      await entitlementRef.set({
        premium: false,
        revokedReason,
        revokedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      await tokenRef.set({
        state: `RTDN_TYPE_${notificationType}`,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      logger.info("RTDN: Entitlement revoked", { uid, reason: revokedReason, notificationType });

    } else if (activeTypes.has(notificationType)) {
      try {
        const freshStatus = await verifyGooglePlaySubscription(purchaseToken);
        await entitlementRef.set({
          premium: freshStatus.premium,
          state: freshStatus.state,
          expiresAt: freshStatus.expiresAt,
          autoRenewing: freshStatus.autoRenewing,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        await tokenRef.set({
          state: freshStatus.state,
          expiresAt: freshStatus.expiresAt,
          autoRenewing: freshStatus.autoRenewing,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        logger.info("RTDN: Entitlement refreshed", { uid, state: freshStatus.state });
      } catch (err) {
        logger.error("RTDN: Re-verify failed", { uid, error: String(err) });
      }
    } else {
      logger.info("RTDN: Unhandled notification type", { notificationType, uid });
    }
  } catch (err) {
    logger.error("RTDN processing error", { error: String(err) });
  }
});

// ============================================================
// SYNC AUTH USERS TO FIRESTORE
// Admin-only callable function that creates missing Firestore
// user docs for Firebase Auth users
// ============================================================
const ADMIN_EMAILS = ["gobettingtipslive@gmail.com", "sudoqsupport@gmail.com"];

exports.syncAuthUsers = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth || !ADMIN_EMAILS.includes(request.auth.token.email || "")) {
    throw new HttpsError("permission-denied", "Admin only");
  }

  const auth = admin.auth();
  let nextPageToken;
  let synced = 0;
  let skipped = 0;
  let total = 0;

  do {
    const listResult = await auth.listUsers(1000, nextPageToken);
    total += listResult.users.length;

    for (const userRecord of listResult.users) {
      // Skip anonymous Auth users - they are tracked by the Flutter app directly
      if (!userRecord.email) {
        skipped++;
        continue;
      }

      const docRef = db.collection("users").doc(userRecord.uid);
      const docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          uid: userRecord.uid,
          displayName: userRecord.displayName || "",
          email: userRecord.email,
          photoUrl: userRecord.photoURL || "",
          isAnonymous: false,
          platform: "",
          createdAt: userRecord.metadata.creationTime
            ? Timestamp.fromDate(new Date(userRecord.metadata.creationTime))
            : FieldValue.serverTimestamp(),
          lastSeenAt: userRecord.metadata.lastSignInTime
            ? Timestamp.fromDate(new Date(userRecord.metadata.lastSignInTime))
            : FieldValue.serverTimestamp(),
        });
        synced++;
        logger.info(`Synced missing user: ${userRecord.uid} (${userRecord.email})`);
      } else {
        const existingData = docSnap.data();
        if (!existingData.email || existingData.email === "") {
          await docRef.update({
            email: userRecord.email,
            displayName: userRecord.displayName || existingData.displayName || "",
            photoUrl: userRecord.photoURL || existingData.photoUrl || "",
            isAnonymous: false,
          });
          synced++;
          logger.info(`Updated stale anonymous doc: ${userRecord.uid} -> ${userRecord.email}`);
        } else {
          skipped++;
        }
      }
    }

    nextPageToken = listResult.pageToken;
  } while (nextPageToken);

  logger.info(`Sync complete: ${synced} created, ${skipped} already existed, ${total} total auth users`);
  return { synced, skipped, total };
});

// Look up a specific user by email in Firebase Auth and sync to Firestore
exports.lookupUserByEmail = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth || !ADMIN_EMAILS.includes(request.auth.token.email || "")) {
    throw new HttpsError("permission-denied", "Admin only");
  }

  const email = (request.data.email || "").trim().toLowerCase();
  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required");
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);

    const docRef = db.collection("users").doc(userRecord.uid);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        uid: userRecord.uid,
        displayName: userRecord.displayName || "",
        email: userRecord.email || "",
        photoUrl: userRecord.photoURL || "",
        isAnonymous: false,
        platform: "",
        createdAt: userRecord.metadata.creationTime
          ? Timestamp.fromDate(new Date(userRecord.metadata.creationTime))
          : FieldValue.serverTimestamp(),
        lastSeenAt: userRecord.metadata.lastSignInTime
          ? Timestamp.fromDate(new Date(userRecord.metadata.lastSignInTime))
          : FieldValue.serverTimestamp(),
      });
      return { found: true, synced: true, uid: userRecord.uid, email: userRecord.email };
    }

    const existingData = docSnap.data();
    if (userRecord.email && (!existingData.email || existingData.email === "")) {
      await docRef.update({
        email: userRecord.email,
        displayName: userRecord.displayName || existingData.displayName || "",
        photoUrl: userRecord.photoURL || existingData.photoUrl || "",
        isAnonymous: false,
      });
      return { found: true, synced: true, uid: userRecord.uid, email: userRecord.email,
        message: "Updated stale anonymous doc" };
    }

    return { found: true, synced: false, uid: userRecord.uid, email: userRecord.email };
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      return { found: false, synced: false, message: "User not found in Firebase Auth" };
    }
    throw new HttpsError("internal", String(err));
  }
});

// Delete all anonymous users from Firestore (batch)
exports.deleteAnonymousUsers = onCall({ region: "us-central1", timeoutSeconds: 120 }, async (request) => {
  if (!request.auth || !ADMIN_EMAILS.includes(request.auth.token.email || "")) {
    throw new HttpsError("permission-denied", "Admin only");
  }

  const usersRef = db.collection("users");
  const allUsersSnap = await usersRef.get();
  let deleted = 0;
  let paymentsDeleted = 0;

  // Find all anonymous docs: email is empty, null, or missing
  const anonDocs = allUsersSnap.docs.filter((doc) => {
    const data = doc.data();
    return !data.email || data.email === "" || data.isAnonymous === true;
  });

  const anonUids = new Set(anonDocs.map((d) => d.id));

  const batchSize = 400;
  for (let i = 0; i < anonDocs.length; i += batchSize) {
    const batch = db.batch();
    const chunk = anonDocs.slice(i, i + batchSize);

    for (const doc of chunk) {
      batch.delete(doc.ref);
      batch.delete(db.collection("leaderboard").doc(doc.id));
      batch.delete(db.collection("duel_leaderboard").doc(doc.id));
      batch.delete(db.collection("entitlements").doc(doc.id));
    }

    await batch.commit();
    deleted += chunk.length;
  }

  // Delete purchase_claims from anonymous users
  const claimsSnap = await db.collection("purchase_claims").get();
  const anonClaims = claimsSnap.docs.filter((d) => anonUids.has(d.data().uid));

  for (let i = 0; i < anonClaims.length; i += batchSize) {
    const batch = db.batch();
    const chunk = anonClaims.slice(i, i + batchSize);
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    paymentsDeleted += chunk.length;
  }

  // Also delete anonymous users from Firebase Auth
  let authDeleted = 0;
  try {
    let nextPageToken;
    do {
      const listResult = await admin.auth().listUsers(1000, nextPageToken);
      const anonUsers = listResult.users.filter((u) => !u.email && u.providerData.length === 0);

      for (const u of anonUsers) {
        try {
          await admin.auth().deleteUser(u.uid);
          authDeleted++;
        } catch { /* skip */ }
      }

      nextPageToken = listResult.pageToken;
    } while (nextPageToken);
  } catch (err) {
    logger.error("Auth cleanup error:", String(err));
  }

  logger.info(`Deleted ${deleted} anonymous Firestore docs, ${paymentsDeleted} payments, ${authDeleted} anonymous Auth users`);
  return { deleted, paymentsDeleted, authDeleted };
});

// ============================================================
// DELETE USERS (Firestore + Firebase Auth + related data)
// Admin-only: deletes users by UID array from both Firestore and Auth
// ============================================================
exports.deleteUsers = onCall({ region: "us-central1", timeoutSeconds: 120 }, async (request) => {
  if (!request.auth || !ADMIN_EMAILS.includes(request.auth.token.email || "")) {
    throw new HttpsError("permission-denied", "Admin only");
  }

  const uids = request.data.uids;
  if (!Array.isArray(uids) || uids.length === 0) {
    throw new HttpsError("invalid-argument", "uids array is required");
  }

  let firestoreDeleted = 0;
  let authDeleted = 0;

  const batchSize = 400;
  for (let i = 0; i < uids.length; i += batchSize) {
    const chunk = uids.slice(i, i + batchSize);
    const batch = db.batch();

    for (const uid of chunk) {
      batch.delete(db.collection("users").doc(uid));
      batch.delete(db.collection("leaderboard").doc(uid));
      batch.delete(db.collection("duel_leaderboard").doc(uid));
      batch.delete(db.collection("entitlements").doc(uid));
    }

    await batch.commit();
    firestoreDeleted += chunk.length;
  }

  for (const uid of uids) {
    try {
      await admin.auth().deleteUser(uid);
      authDeleted++;
    } catch (err) {
      logger.warn(`Auth delete failed for ${uid}: ${String(err)}`);
    }
  }

  logger.info(`deleteUsers: ${firestoreDeleted} Firestore docs, ${authDeleted} Auth accounts deleted`);
  return { firestoreDeleted, authDeleted };
});

// Delete all purchase_claims (test data cleanup)
exports.deleteAllPayments = onCall({ region: "us-central1", timeoutSeconds: 120 }, async (request) => {
  if (!request.auth || !ADMIN_EMAILS.includes(request.auth.token.email || "")) {
    throw new HttpsError("permission-denied", "Admin only");
  }

  const claimsSnap = await db.collection("purchase_claims").get();
  let deleted = 0;
  const batchSize = 400;

  for (let i = 0; i < claimsSnap.docs.length; i += batchSize) {
    const batch = db.batch();
    const chunk = claimsSnap.docs.slice(i, i + batchSize);
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += chunk.length;
  }

  logger.info(`Deleted ${deleted} payment records`);
  return { deleted };
});
