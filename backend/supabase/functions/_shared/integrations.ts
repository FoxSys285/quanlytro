const encoder = new TextEncoder();
const FIREBASE_JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const PRIVATE_MEDIA_CATEGORIES = new Set([
  "verification-proofs",
  "lease-member-identity",
  "payment-proofs",
]);

export type IntegrationEnv = {
  FIREBASE_PROJECT_ID: string;
  SEPAY_WEBHOOK_API_KEY: string;
  CLOUDINARY_CLOUD_NAME: string;
  CLOUDINARY_API_KEY: string;
  CLOUDINARY_API_SECRET: string;
};

export class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

class FirestoreError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

type FirestoreDocument = {
  name: string;
  updateTime: string;
  data: Record<string, unknown>;
};

let firebaseJwks: JsonWebKey[] | null = null;
let firebaseJwksExpiresAt = 0;
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey",
  "Access-Control-Max-Age": "86400",
};

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...corsHeaders,
    },
  });
}

export function failure(error: unknown): Response {
  if (error instanceof HttpError) {
    return jsonResponse({ error: error.message }, error.status);
  }
  if (error instanceof FirestoreError) {
    console.error("Firestore integration request failed:", error.message);
    return jsonResponse({ error: "Firestore request failed" }, 503);
  }
  console.error(
    "Integration request failed:",
    error instanceof Error ? error.message : "unknown error",
  );
  return jsonResponse({ error: "Integration endpoint failed" }, 500);
}

export function integrationEnv(): IntegrationEnv {
  return {
    FIREBASE_PROJECT_ID: Deno.env.get("FIREBASE_PROJECT_ID") ?? "",
    SEPAY_WEBHOOK_API_KEY: Deno.env.get("SEPAY_WEBHOOK_API_KEY") ?? "",
    CLOUDINARY_CLOUD_NAME: Deno.env.get("CLOUDINARY_CLOUD_NAME") ?? "",
    CLOUDINARY_API_KEY: Deno.env.get("CLOUDINARY_API_KEY") ?? "",
    CLOUDINARY_API_SECRET: Deno.env.get("CLOUDINARY_API_SECRET") ?? "",
  };
}

function base64UrlBytes(value: string): Uint8Array {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function decodeBase64UrlText(value: string): string {
  return new TextDecoder().decode(base64UrlBytes(value));
}

function hex(bytes: ArrayBuffer): string {
  return Array.from(new Uint8Array(bytes), (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}


async function firebaseKeys(forceRefresh = false): Promise<JsonWebKey[]> {
  if (!forceRefresh && firebaseJwks && Date.now() < firebaseJwksExpiresAt) {
    return firebaseJwks;
  }
  const response = await fetch(FIREBASE_JWKS_URL);
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || !Array.isArray(payload.keys)) {
    throw new HttpError(503, "Could not verify Firebase token");
  }
  firebaseJwks = payload.keys as JsonWebKey[];
  firebaseJwksExpiresAt = Date.now() + 60 * 60 * 1000;
  return firebaseJwks;
}

async function verifyFirebaseIdToken(
  authorization: string | null,
  projectId: string,
): Promise<string> {
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) throw new HttpError(401, "Missing Firebase ID token");
  const parts = token.split(".");
  if (parts.length !== 3) throw new HttpError(401, "Invalid Firebase ID token");

  let header: Record<string, unknown>;
  let claims: Record<string, unknown>;
  try {
    header = JSON.parse(decodeBase64UrlText(parts[0]));
    claims = JSON.parse(decodeBase64UrlText(parts[1]));
  } catch (_) {
    throw new HttpError(401, "Invalid Firebase ID token");
  }
  if (header.alg !== "RS256" || typeof header.kid !== "string") {
    throw new HttpError(401, "Invalid Firebase ID token");
  }

  let key = (await firebaseKeys()).find((candidate) => candidate.kid === header.kid);
  if (!key) key = (await firebaseKeys(true)).find((candidate) => candidate.kid === header.kid);
  if (!key) throw new HttpError(401, "Invalid Firebase ID token");

  const publicKey = await crypto.subtle.importKey(
    "jwk",
    key,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const validSignature = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    base64UrlBytes(parts[2]),
    encoder.encode(`${parts[0]}.${parts[1]}`),
  );
  const now = Math.floor(Date.now() / 1000);
  const uid = claims.sub;
  if (
    !validSignature ||
    claims.aud !== projectId ||
    claims.iss !== `https://securetoken.google.com/${projectId}` ||
    typeof uid !== "string" ||
    uid.length === 0 ||
    uid.length > 128 ||
    typeof claims.exp !== "number" ||
    claims.exp <= now ||
    typeof claims.iat !== "number" ||
    claims.iat > now
  ) {
    throw new HttpError(401, "Invalid Firebase ID token");
  }
  return uid;
}

function firestoreBase(env: IntegrationEnv): string {
  const projectId = env.FIREBASE_PROJECT_ID.trim();
  if (!projectId || !/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(projectId)) {
    throw new HttpError(503, "Firebase project ID is not configured");
  }
  return `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents`;
}

function encodedDocumentPath(path: string): string {
  return path.split("/").map(encodeURIComponent).join("/");
}

function decodeValue(value: Record<string, unknown>): unknown {
  if ("stringValue" in value) return value.stringValue;
  if ("integerValue" in value) return Number(value.integerValue);
  if ("doubleValue" in value) return value.doubleValue;
  if ("booleanValue" in value) return value.booleanValue;
  if ("nullValue" in value) return null;
  if ("timestampValue" in value) return value.timestampValue;
  if ("arrayValue" in value) {
    const values = (value.arrayValue as { values?: Record<string, unknown>[] }).values ?? [];
    return values.map(decodeValue);
  }
  if ("mapValue" in value) {
    const fields = (value.mapValue as { fields?: Record<string, Record<string, unknown>> }).fields ?? {};
    return decodeFields(fields);
  }
  return null;
}

function decodeFields(fields: Record<string, Record<string, unknown>> = {}): Record<string, unknown> {
  return Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, decodeValue(value)]));
}

function decodeDocument(payload: Record<string, unknown>): FirestoreDocument {
  const name = typeof payload.name === "string" ? payload.name : "";
  const updateTime = typeof payload.updateTime === "string" ? payload.updateTime : "";
  const fields = (payload.fields ?? {}) as Record<string, Record<string, unknown>>;
  return { name, updateTime, data: decodeFields(fields) };
}

async function getFirestoreDocumentAsUser(
  env: IntegrationEnv,
  path: string,
  idToken: string,
): Promise<FirestoreDocument | null> {
  const response = await fetch(`${firestoreBase(env)}/${encodedDocumentPath(path)}`, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (response.status === 404 || response.status === 403) return null;
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new FirestoreError(response.status, payload?.error?.message ?? "Firestore request failed");
  }
  return decodeDocument(payload);
}

function safeSegments(assetPath: unknown): string[] | null {
  if (typeof assetPath !== "string" || assetPath.length > 500) return null;
  const parts = assetPath.split("/");
  if (
    parts.length < 5 ||
    parts.length > 10 ||
    parts.some((part) => part === "." || part === ".." || !/^[A-Za-z0-9_.-]{1,100}$/.test(part)) ||
    parts[0] !== "tropremium"
  ) return null;
  return parts;
}

async function canAccessMedia(
  env: IntegrationEnv,
  uid: string,
  idToken: string,
  profile: Record<string, unknown>,
  segments: string[],
  write: boolean,
): Promise<boolean> {
  const category = segments[1];
  const propertyId = segments[2];
  if (!propertyId) return false;
  const propertyDocument = await getFirestoreDocumentAsUser(
    env,
    `rental_properties/${propertyId}`,
    idToken,
  );
  const property = propertyDocument?.data ?? {};
  const isAdmin = profile.role === "admin";
  const isOwner = profile.role === "landlord" && property.ownerUid === uid;
  if (category === "properties") {
    const newPropertyForOwner = !propertyDocument && profile.role === "landlord" && segments[3] === uid;
    return isAdmin || isOwner || newPropertyForOwner;
  }
  if (category === "verification-proofs") return isAdmin || isOwner;
  if (category === "payment-proofs") {
    if (isAdmin || isOwner) return true;
    if (profile.role !== "tenant" || segments.length < 6) return false;
    const invoice = await getFirestoreDocumentAsUser(
      env,
      `rental_records/${propertyId}:invoices:${segments[3]}`,
      idToken,
    );
    return ((invoice?.data.tenantIds ?? []) as string[]).includes(String(profile.tenantId ?? ""));
  }
  if (category === "lease-member-identity") {
    if (isAdmin || (!write && isOwner)) return true;
    if (profile.role !== "tenant" || segments.length < 6) return false;
    const tenantId = segments[3];
    const member = await getFirestoreDocumentAsUser(
      env,
      `rental_records/${propertyId}:members:${segments[4]}`,
      idToken,
    );
    const data = member?.data ?? {};
    const item = (data.data ?? {}) as Record<string, unknown>;
    return profile.tenantId === tenantId &&
      item.tenantId === tenantId &&
      item.status === "active" &&
      ((data.tenantIds ?? []) as string[]).includes(tenantId);
  }
  return false;
}

export async function requireAppUser(
  request: Request,
  env: IntegrationEnv,
): Promise<{ uid: string; idToken: string; profile: Record<string, unknown> }> {
  const authorization = request.headers.get("authorization");
  const idToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1] ?? "";
  const uid = await verifyFirebaseIdToken(authorization, env.FIREBASE_PROJECT_ID);
  const userDocument = await getFirestoreDocumentAsUser(
    env,
    `users/${uid}`,
    idToken,
  );
  const profile = userDocument?.data;
  if (!profile || profile.disabled !== false) throw new HttpError(403, "Account is disabled");
  return { uid, idToken, profile };
}

async function signedCloudinaryParams(
  params: Record<string, string | undefined>,
  apiSecret: string,
): Promise<string> {
  const body = Object.entries(params)
    .filter(([, value]) => value !== undefined && value !== "")
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, value]) => `${key}=${value}`)
    .join("&");
  return hex(await crypto.subtle.digest("SHA-1", encoder.encode(body + apiSecret)));
}

function cloudinaryCredentials(env: IntegrationEnv) {
  const cloudName = env.CLOUDINARY_CLOUD_NAME.trim();
  const apiKey = env.CLOUDINARY_API_KEY.trim();
  const apiSecret = env.CLOUDINARY_API_SECRET.trim();
  if (!cloudName || !apiKey || !apiSecret) {
    throw new HttpError(503, "Cloudinary is not configured");
  }
  return { cloudName, apiKey, apiSecret };
}

export async function parseJsonBody(
  request: Request,
  maxBytes = 65_536,
): Promise<Record<string, unknown>> {
  const contentLength = Number(request.headers.get("content-length") ?? 0);
  if (contentLength > maxBytes) throw new HttpError(413, "Request body is too large");
  const text = await request.text();
  if (text.length > maxBytes) throw new HttpError(413, "Request body is too large");
  try {
    return JSON.parse(text || "{}") as Record<string, unknown>;
  } catch (_) {
    throw new HttpError(400, "Invalid JSON body");
  }
}

export async function handleCloudinaryUploadSignature(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ error: "POST required" }, 405);
  const config = integrationEnv();
  try {
    const { uid, idToken, profile } = await requireAppUser(request, config);
    const body = await parseJsonBody(request);
    const segments = safeSegments(body.assetPath);
    const resourceType = body.resourceType;
    const deliveryType = body.deliveryType;
    const format = typeof body.format === "string" ? body.format.toLowerCase() : "";
    const category = segments?.[1] ?? "";
    const privateCategory = PRIVATE_MEDIA_CATEGORIES.has(category);
    if (
      !segments ||
      !["image", "video", "raw"].includes(String(resourceType)) ||
      !/^[a-z0-9]{2,6}$/.test(format) ||
      !["upload", "authenticated"].includes(String(deliveryType)) ||
      (privateCategory && deliveryType !== "authenticated") ||
      (!privateCategory && deliveryType === "authenticated")
    ) throw new HttpError(400, "Invalid media upload parameters");
    if (!await canAccessMedia(config, uid, idToken, profile, segments, true)) {
      throw new HttpError(403, "No permission to upload this asset");
    }
    const { cloudName, apiKey, apiSecret } = cloudinaryCredentials(config);
    const publicId = `${segments.slice(0, -1).join("/")}/${segments.at(-1)}`;
    const timestamp = Math.floor(Date.now() / 1000);
    const signedParams = {
      public_id: publicId,
      timestamp: String(timestamp),
      type: String(deliveryType),
      overwrite: body.overwrite === true ? "true" : undefined,
    };
    return jsonResponse({
      cloudName,
      apiKey,
      resourceType,
      deliveryType,
      publicId,
      format,
      timestamp,
      signature: await signedCloudinaryParams(signedParams, apiSecret),
      overwrite: signedParams.overwrite === "true",
    });
  } catch (error) {
    return failure(error);
  }
}

export async function handleCloudinaryPrivateDownloadUrl(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ error: "POST required" }, 405);
  const config = integrationEnv();
  try {
    const { uid, idToken, profile } = await requireAppUser(request, config);
    const body = await parseJsonBody(request);
    if (typeof body.assetRef !== "string") throw new HttpError(400, "Invalid private asset reference");
    let assetRef: URL;
    try {
      assetRef = new URL(body.assetRef);
    } catch (_) {
      throw new HttpError(400, "Invalid private asset reference");
    }
    if (assetRef.protocol !== "cloudinary:" || assetRef.pathname.split("/")[1] !== "authenticated") {
      throw new HttpError(400, "Invalid private asset reference");
    }
    const resourceType = assetRef.hostname;
    let publicId: string;
    try {
      publicId = decodeBase64UrlText(assetRef.pathname.split("/")[2] ?? "");
    } catch (_) {
      throw new HttpError(400, "Invalid private asset reference");
    }
    const format = assetRef.searchParams.get("format") ?? "";
    const segments = safeSegments(publicId);
    if (
      !segments ||
      !["image", "video", "raw"].includes(resourceType) ||
      !/^[a-z0-9]{2,6}$/.test(format) ||
      !PRIVATE_MEDIA_CATEGORIES.has(segments[1])
    ) throw new HttpError(400, "Invalid private asset reference");
    if (!await canAccessMedia(config, uid, idToken, profile, segments, false)) {
      throw new HttpError(403, "No permission to read this asset");
    }
    const { cloudName, apiKey, apiSecret } = cloudinaryCredentials(config);
    const timestamp = Math.floor(Date.now() / 1000);
    const params = {
      expires_at: String(timestamp + 300),
      format,
      public_id: publicId,
      timestamp: String(timestamp),
      type: "authenticated",
    };
    const url = new URL(
      `https://api.cloudinary.com/v1_1/${encodeURIComponent(cloudName)}/${resourceType}/download`,
    );
    for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value);
    url.searchParams.set("api_key", apiKey);
    url.searchParams.set("signature", await signedCloudinaryParams(params, apiSecret));
    return jsonResponse({ url: url.toString() });
  } catch (error) {
    return failure(error);
  }
}

