import assert from "node:assert/strict";
import test from "node:test";
import { finalizeAnalysis } from "../server.mjs";

test("accepts confident pothole evidence and combines severity with confidence", () => {
  const result = finalizeAnalysis({
    is_road_scene: true,
    has_road_damage: true,
    damage_type: "pothole",
    confidence_percent: 90,
    severity_score: 80,
    summary: "Large pothole in the traffic lane.",
    rejection_reason: "",
  });
  assert.equal(result.accepted, true);
  assert.equal(result.severity, "high");
  assert.equal(result.priorityScore, 83);
});

test("rejects unrelated images even when the model reports high confidence", () => {
  const result = finalizeAnalysis({
    is_road_scene: false,
    has_road_damage: false,
    damage_type: "none",
    confidence_percent: 96,
    severity_score: 0,
    summary: "A person indoors.",
    rejection_reason: "The image does not show a road surface.",
  });
  assert.equal(result.accepted, false);
  assert.equal(result.priorityScore, 0);
  assert.match(result.rejectionReason, /road surface/i);
});

test("requires at least 65 percent confidence", () => {
  const result = finalizeAnalysis({
    is_road_scene: true,
    has_road_damage: true,
    damage_type: "pothole",
    confidence_percent: 64,
    severity_score: 90,
    summary: "Possible pothole.",
    rejection_reason: "",
  });
  assert.equal(result.accepted, false);
  assert.equal(result.priorityScore, 0);
});
