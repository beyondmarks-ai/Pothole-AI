import { app } from "@azure/functions";
import { analyzeImage } from "../../server.mjs";

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

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  "Cache-Control": "no-store",
};

function json(status, jsonBody) {
  return { status, jsonBody, headers: corsHeaders };
}
