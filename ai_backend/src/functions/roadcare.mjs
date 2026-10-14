import { app } from "@azure/functions";
import { analyzeImage } from "../../server.mjs";
import {
  createIncident,
  getEvidence,
  listIncidents,
  updateIncident,
} from "../incident_store.mjs";

const allowedTypes = new Set(["image/jpeg", "image/png", "image/webp"]);

app.http("health", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "health",
  handler: async () => ({
    status: 200,
    jsonBody: {
      status: "ok",
      configured: Boolean(
        process.env.AZURE_OPENAI_ENDPOINT &&
          process.env.AZURE_OPENAI_DEPLOYMENT,
      ),
      model: "gpt-4.1-mini",
    },
  }),
});

app.http("analyze", {
  methods: ["POST", "OPTIONS"],
  authLevel: "anonymous",
  route: "analyze",
  handler: async (request) => {
    if (request.method === "OPTIONS") {
      return { status: 204, headers: corsHeaders };
    }
    try {
      const body = await request.json();
      const imageBase64 = body?.imageBase64;
      const mimeType = body?.mimeType;
      if (typeof imageBase64 !== "string" || imageBase64.length < 100) {
        return json(400, { error: "A valid image is required." });
      }
      if (!allowedTypes.has(mimeType)) {
        return json(415, { error: "Use a JPG, PNG, or WEBP image." });
      }
      const result = await analyzeImage(imageBase64, mimeType);
      return json(200, result);
    } catch (error) {
      console.error("RoadCare analysis failed", error?.message ?? error);
      return json(error?.status ?? 500, {
        error: error?.message ?? "Image analysis failed.",
      });
    }
  },
});

app.http("incidents", {
  methods: ["GET", "POST", "OPTIONS"],
  authLevel: "anonymous",
  route: "incidents",
  handler: async (request) => {
    if (request.method === "OPTIONS") return { status: 204, headers: corsHeaders };
    try {
      if (request.method === "GET") {
        const url = new URL(request.url);
        const incidents = await listIncidents({
          role: url.searchParams.get("role"),
          email: url.searchParams.get("email"),
          team: url.searchParams.get("team"),
        });
        return json(200, { incidents });
      }
      const body = await request.json();
      const origin = new URL(request.url).origin;
      const incident = await createIncident(
        body.incident,
        body.imageBase64
          ? { base64: body.imageBase64, mimeType: body.mimeType }
          : null,
        origin,
      );
      return json(201, { incident });
    } catch (error) {
      console.error("RoadCare incident request failed", error?.message ?? error);
      return json(400, { error: error?.message ?? "Incident request failed." });
    }
  },
});

app.http("incidentUpdate", {
  methods: ["PATCH", "OPTIONS"],
  authLevel: "anonymous",
  route: "incidents/{id}",
  handler: async (request) => {
    if (request.method === "OPTIONS") return { status: 204, headers: corsHeaders };
    try {
      const body = await request.json();
      const incident = await updateIncident(
        request.params.id,
        body.incident,
        body.repairImageBase64
          ? { base64: body.repairImageBase64, mimeType: body.mimeType }
          : null,
        new URL(request.url).origin,
      );
      return incident
        ? json(200, { incident })
        : json(404, { error: "Incident not found." });
    } catch (error) {
      console.error("RoadCare incident update failed", error?.message ?? error);
      return json(400, { error: error?.message ?? "Incident update failed." });
    }
  },
});

app.http("evidence", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "evidence/{name}",
  handler: async (request) => {
    const evidence = await getEvidence(request.params.name);
    if (!evidence) return json(404, { error: "Evidence not found." });
    return {
      status: 200,
      body: evidence.bytes,
      headers: {
        "Content-Type": evidence.contentType,
        "Cache-Control": "public, max-age=3600",
      },
    };
  },
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  "Cache-Control": "no-store",
};

function json(status, jsonBody) {
  return { status, jsonBody, headers: corsHeaders };
}
