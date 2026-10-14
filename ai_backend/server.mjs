import http from "node:http";
import { execFile } from "node:child_process";
import { pathToFileURL } from "node:url";
import { promisify } from "node:util";

const port = Number.parseInt(process.env.PORT ?? "7071", 10);
const endpoint = (process.env.AZURE_OPENAI_ENDPOINT ?? "").replace(/\/$/, "");
const useAzureIdentity = process.env.AZURE_OPENAI_USE_IDENTITY === "true";
const apiKey = useAzureIdentity
  ? ""
  : (process.env.AZURE_OPENAI_API_KEY ?? "");
const deployment = process.env.AZURE_OPENAI_DEPLOYMENT ?? "";
const runFile = promisify(execFile);
const maximumBodyBytes = 12 * 1024 * 1024;
const allowedTypes = new Set(["image/jpeg", "image/png", "image/webp"]);

const responseSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "is_road_scene",
    "has_road_damage",
    "damage_type",
    "confidence_percent",
    "severity_score",
    "summary",
    "rejection_reason",
  ],
  properties: {
    is_road_scene: { type: "boolean" },
    has_road_damage: { type: "boolean" },
    damage_type: {
      type: "string",
      enum: [
        "pothole",
        "longitudinal_crack",
        "transverse_crack",
        "alligator_crack",
        "none",
      ],
    },
    confidence_percent: { type: "integer", minimum: 0, maximum: 100 },
    severity_score: { type: "integer", minimum: 0, maximum: 100 },
    summary: { type: "string", maxLength: 240 },
    rejection_reason: { type: "string", maxLength: 180 },
  },
};

export function finalizeAnalysis(raw) {
  const confidence = clampInteger(raw.confidence_percent);
  const severityScore = clampInteger(raw.severity_score);
  const supportedDamage = raw.damage_type !== "none";
  const accepted =
    raw.is_road_scene === true &&
    raw.has_road_damage === true &&
    supportedDamage &&
    confidence >= 65;
  const priorityScore = accepted
    ? clampInteger(severityScore * 0.7 + confidence * 0.3)
    : 0;
  const severity =
    severityScore >= 85
      ? "critical"
      : severityScore >= 65
        ? "high"
        : severityScore >= 40
          ? "medium"
          : "low";

  return {
    accepted,
    isRoadScene: raw.is_road_scene === true,
    hasRoadDamage: raw.has_road_damage === true,
    damageType: supportedDamage ? raw.damage_type : null,
    confidence: confidence / 100,
    severity,
    severityScore,
    priorityScore,
    healthScore: Math.max(0, 100 - severityScore),
    summary: String(raw.summary ?? "").trim(),
    rejectionReason: accepted
      ? ""
      : rejectionMessage(raw, confidence, supportedDamage),
    provider: "Azure AI Foundry",
    model: "gpt-4.1-mini",
  };
}

function rejectionMessage(raw, confidence, supportedDamage) {
  const supplied = String(raw.rejection_reason ?? "").trim();
  if (supplied) return supplied;
  if (raw.is_road_scene !== true) return "Upload a clear photo of a road surface.";
  if (raw.has_road_damage !== true || !supportedDamage) {
    return "No supported road damage is clearly visible in this photo.";
  }
  if (confidence < 65) {
    return "The image is unclear. Retake it in good light with more road surface visible.";
  }
  return "This image could not be accepted as road-damage evidence.";
}

function clampInteger(value) {
  return Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
}

export async function analyzeImage(imageBase64, mimeType) {
  if (!endpoint || !deployment) {
    throw new PublicError(503, "The AI service is not configured on the server.");
  }

  const url = endpoint.includes("/openai/v1")
    ? `${endpoint}/chat/completions`
    : `${endpoint}/openai/v1/chat/completions`;
  const prompt = [
    "Inspect only the supplied image as municipal road-damage evidence.",
    "Reject selfies, people, animals, documents, screenshots, indoor scenes, vehicles without visible road damage, and unrelated objects.",
    "Accept only when a road surface and one supported damage type are clearly visible.",
    "Confidence is your confidence that both the scene and classified damage are correct, not image quality alone.",
    "Severity score: 0-39 minor, 40-64 moderate, 65-84 major, 85-100 critical safety risk.",
    "Use 'none' when uncertain or unrelated. Keep the summary factual and short.",
  ].join(" ");

  const aiResponse = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(await azureAuthenticationHeaders()),
    },
    body: JSON.stringify({
      model: deployment,
      temperature: 0,
      max_tokens: 450,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "road_damage_analysis",
          strict: true,
          schema: responseSchema,
        },
      },
      messages: [
        { role: "system", content: prompt },
        {
          role: "user",
          content: [
            { type: "text", text: "Validate and classify this evidence image." },
            {
              type: "image_url",
              image_url: {
                url: `data:${mimeType};base64,${imageBase64}`,
                detail: "high",
              },
            },
          ],
        },
      ],
    }),
    signal: AbortSignal.timeout(45_000),
  });

  if (!aiResponse.ok) {
    const requestId = aiResponse.headers.get("x-request-id");
    const failure = await aiResponse.text();
    console.error(
      "Azure AI request failed",
      aiResponse.status,
      requestId ?? "",
      failure.slice(0, 500),
    );
    throw new PublicError(502, "Image analysis is temporarily unavailable.");
  }
  const payload = await aiResponse.json();
  const content = payload?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.length === 0) {
    throw new PublicError(502, "The AI service returned an incomplete result.");
  }
  return finalizeAnalysis(JSON.parse(content));
}

async function azureAuthenticationHeaders() {
  if (apiKey) return { "api-key": apiKey };
  if (process.env.IDENTITY_ENDPOINT && process.env.IDENTITY_HEADER) {
    try {
      const identityUrl = new URL(process.env.IDENTITY_ENDPOINT);
      identityUrl.searchParams.set(
        "resource",
        "https://cognitiveservices.azure.com",
      );
      identityUrl.searchParams.set("api-version", "2019-08-01");
      const identityResponse = await fetch(identityUrl, {
        headers: { "X-IDENTITY-HEADER": process.env.IDENTITY_HEADER },
        signal: AbortSignal.timeout(10_000),
      });
      if (!identityResponse.ok) throw new Error("Managed identity was rejected.");
      const identity = await identityResponse.json();
      if (!identity.access_token) throw new Error("Managed identity token missing.");
      return { Authorization: `Bearer ${identity.access_token}` };
    } catch {
      throw new PublicError(
        503,
        "Azure managed identity is unavailable on the AI server.",
      );
    }
  }
  try {
    const azureArguments = [
      "account",
      "get-access-token",
      "--resource",
      "https://cognitiveservices.azure.com",
      "--query",
      "accessToken",
      "-o",
      "tsv",
    ];
    const { stdout } = process.platform === "win32"
      ? await runFile(
          "powershell.exe",
          [
            "-NoProfile",
            "-NonInteractive",
            "-Command",
            `az ${azureArguments.join(" ")}`,
          ],
          { windowsHide: true },
        )
      : await runFile("az", azureArguments, { windowsHide: true });
    const token = stdout.trim();
    if (!token) throw new Error("Azure CLI returned an empty token.");
    return { Authorization: `Bearer ${token}` };
  } catch {
    throw new PublicError(
      503,
      "Azure authentication is unavailable on the AI server.",
    );
  }
}

class PublicError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function sendJson(response, status, body) {
  response.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*",
  });
  response.end(JSON.stringify(body));
}

function readJson(request) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    request.on("data", (chunk) => {
      size += chunk.length;
      if (size > maximumBodyBytes) {
        reject(new PublicError(413, "The image is too large."));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on("end", () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString("utf8")));
      } catch {
        reject(new PublicError(400, "Invalid JSON request."));
      }
    });
    request.on("error", reject);
  });
}

export function createServer() {
  return http.createServer(async (request, response) => {
    if (request.method === "GET" && request.url === "/health") {
      sendJson(response, 200, {
        status: "ok",
        configured: Boolean(endpoint && deployment),
        model: "gpt-4.1-mini",
      });
      return;
    }
    if (request.method === "OPTIONS") {
      response.writeHead(204, {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
      });
      response.end();
      return;
    }
    if (request.method !== "POST" || request.url !== "/analyze") {
      sendJson(response, 404, { error: "Not found." });
      return;
    }

    try {
      const body = await readJson(request);
      const imageBase64 = body?.imageBase64;
      const mimeType = body?.mimeType;
      if (typeof imageBase64 !== "string" || imageBase64.length < 100) {
        throw new PublicError(400, "A valid image is required.");
      }
      if (!allowedTypes.has(mimeType)) {
        throw new PublicError(415, "Use a JPG, PNG, or WEBP image.");
      }
      const result = await analyzeImage(imageBase64, mimeType);
      sendJson(response, 200, result);
    } catch (error) {
      if (!(error instanceof PublicError)) console.error("Analysis error", error);
      sendJson(response, error.status ?? 500, {
        error: error instanceof PublicError ? error.message : "Image analysis failed.",
      });
    }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  createServer().listen(port, "0.0.0.0", () => {
    console.log(`RoadCare AI backend listening on port ${port}`);
  });
}
