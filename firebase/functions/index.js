const { onWrite, onCreate } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 1. aggregateExposure
 * Trigger: Firestore onWrite on user's exposure collection.
 * Purpose: Keeps the daily/weekly aggregates updated when new ticks arrive.
 */
exports.aggregateExposure = onWrite("users/{userId}/exposure/{date}/{entryId}", async (event) => {
  logger.info("Aggregating exposure for user", event.params.userId);
  // Implementation: Calculate running sum and update summary doc
});

/**
 * 2. generateForecast
 * Trigger: Hourly Cloud Scheduler cron.
 * Purpose: Runs Vertex AI model to predict 96h AQI based on weather + history.
 */
exports.generateForecast = onSchedule("0 * * * *", async (event) => {
  logger.info("Running hourly forecast generation");
  // Implementation: Call Vertex AI, cache results to /forecasts/{city}
});

/**
 * 3. generateRecoveryPlan
 * Trigger: HTTP Request (Callable).
 * Purpose: Generates Gemini 2.0 personalized coaching plan.
 */
exports.generateRecoveryPlan = onRequest(async (req, res) => {
  logger.info("Generating recovery plan");
  // Implementation: Vertex AI Gemini call -> construct plan JSON -> return
  res.json({ status: "success", plan: {} });
});

/**
 * 4. ingestVisionEvents
 * Trigger: Firestore onCreate for crowd-sourced camera detections.
 * Purpose: Aggregation and anomaly detection for community mapping.
 */
exports.ingestVisionEvents = onCreate("visionEvents/{geoHash}/{eventId}", async (event) => {
  logger.info("Processing vision event at", event.params.geoHash);
  // Implementation: Sanity check, aggregate to city level, prune old events
});
