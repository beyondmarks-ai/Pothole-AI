import { randomUUID } from "node:crypto";
import { TableClient } from "@azure/data-tables";
import { BlobServiceClient } from "@azure/storage-blob";

const tableName = "RoadCareIncidents";
const containerName = "roadcare-evidence";
let tableClient;
let containerClient;
let initialized;

async function clients() {
  if (!initialized) {
    initialized = (async () => {
      const connection = process.env.AzureWebJobsStorage;
      if (!connection) throw new Error("Azure storage is not configured.");
      tableClient = TableClient.fromConnectionString(connection, tableName);
      containerClient = BlobServiceClient.fromConnectionString(connection)
        .getContainerClient(containerName);
      await Promise.all([
        tableClient.createTable().catch(ignoreAlreadyExists),
        containerClient.createIfNotExists(),
      ]);
    })();
  }
  await initialized;
  return { tableClient, containerClient };
}

function ignoreAlreadyExists(error) {
  if (error?.statusCode !== 409) throw error;
}

export async function listIncidents({ role, email, team }) {
  const { tableClient: table } = await clients();
  const incidents = [];
  for await (const entity of table.listEntities({
    queryOptions: { filter: "PartitionKey eq 'incident'" },
  })) {
    const incident = JSON.parse(entity.payload);
    if (role === "citizen" && email && incident.reporterEmail !== email) continue;
    if (role === "maintenance" && team && incident.assignedTeam !== team) continue;
    incidents.push(incident);
  }
  return incidents.sort(
    (a, b) => Date.parse(b.reportedAt) - Date.parse(a.reportedAt),
  );
}

export async function createIncident(incident, image, origin) {
  validateIncident(incident);
  const stored = {
    ...incident,
    imagePath: null,
    repairImagePath: null,
  };
  if (image?.base64) {
    stored.imageUrl = await storeEvidence(image, origin, "original");
  }
  await insert(stored);
  return stored;
}

export async function updateIncident(id, incident, repairImage, origin) {
  const existing = await getIncident(id);
  if (!existing) return null;
  const stored = {
    ...existing,
    ...incident,
    id,
    imagePath: null,
    repairImagePath: null,
    imageUrl: incident.imageUrl ?? existing.imageUrl ?? null,
    repairImageUrl: incident.repairImageUrl ?? existing.repairImageUrl ?? null,
  };
  if (repairImage?.base64) {
    stored.repairImageUrl = await storeEvidence(
      repairImage,
      origin,
      "repair",
    );
  }
  validateIncident(stored);
  await save(stored);
  return stored;
}

export async function getEvidence(name) {
  if (!/^[a-zA-Z0-9_.-]+$/.test(name)) return null;
  const { containerClient: container } = await clients();
  const blob = container.getBlockBlobClient(name);
  if (!(await blob.exists())) return null;
  const properties = await blob.getProperties();
  return {
    bytes: await blob.downloadToBuffer(),
    contentType: properties.contentType ?? "image/jpeg",
  };
}

async function getIncident(id) {
  const { tableClient: table } = await clients();
  try {
    const entity = await table.getEntity("incident", id);
    return JSON.parse(entity.payload);
  } catch (error) {
    if (error?.statusCode === 404) return null;
    throw error;
  }
}

async function save(incident) {
  const { tableClient: table } = await clients();
  const payload = JSON.stringify(incident);
  if (Buffer.byteLength(payload, "utf8") > 60_000) {
    throw new Error("Incident data is too large.");
  }
  await table.upsertEntity(
    {
      partitionKey: "incident",
      rowKey: incident.id,
      payload,
      updatedAt: new Date().toISOString(),
    },
    "Replace",
  );
}

async function insert(incident) {
  const { tableClient: table } = await clients();
  const payload = JSON.stringify(incident);
  if (Buffer.byteLength(payload, "utf8") > 60_000) {
    throw new Error("Incident data is too large.");
  }
  try {
    await table.createEntity({
      partitionKey: "incident",
      rowKey: incident.id,
      payload,
      updatedAt: new Date().toISOString(),
    });
  } catch (error) {
    if (error?.statusCode === 409) {
      throw new Error("This complaint ID already exists. Please submit again.");
    }
    throw error;
  }
}

async function storeEvidence(image, origin, prefix) {
  if (!["image/jpeg", "image/png", "image/webp"].includes(image.mimeType)) {
    throw new Error("Unsupported evidence image type.");
  }
  const bytes = Buffer.from(image.base64, "base64");
  if (bytes.length === 0 || bytes.length > 8 * 1024 * 1024) {
    throw new Error("Evidence image must be smaller than 8 MB.");
  }
  const extension = image.mimeType === "image/png"
    ? "png"
    : image.mimeType === "image/webp"
      ? "webp"
      : "jpg";
  const name = `${prefix}-${randomUUID()}.${extension}`;
  const { containerClient: container } = await clients();
  await container.getBlockBlobClient(name).uploadData(bytes, {
    blobHTTPHeaders: { blobContentType: image.mimeType },
  });
  return `${origin}/api/evidence/${encodeURIComponent(name)}`;
}

function validateIncident(incident) {
  const required = [
    "id",
    "roadName",
    "area",
    "type",
    "severity",
    "status",
    "reportedAt",
    "reporterEmail",
  ];
  if (!incident || required.some((key) => !incident[key])) {
    throw new Error("Incident data is incomplete.");
  }
}
