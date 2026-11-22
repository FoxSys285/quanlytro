import {
  failure,
  HttpError,
  integrationEnv,
  jsonResponse,
  parseJsonBody,
} from "./integrations.ts";
import { subscriptionStore } from "./subscription_store.ts";

const encoder = new TextEncoder();

function constantTimeSecretMatch(left: string, right: string): boolean {
  const a = encoder.encode(left);
  const b = encoder.encode(right);
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let index = 0; index < a.length; index++) difference |= a[index] ^ b[index];
  return difference === 0;
}

function transactionId(transaction: Record<string, unknown>): string {
  return String(
    transaction.id ?? transaction.transactionId ?? transaction.referenceCode ??
      `${transaction.accountNumber ?? ""}:${transaction.transactionDate ?? ""}:${transaction.transferAmount ?? ""}:${transaction.content ?? ""}`,
  );
}

function paymentReference(transaction: Record<string, unknown>): string | null {
  const content = `${transaction.code ?? ""} ${transaction.content ?? ""} ${transaction.description ?? ""}`
    .toUpperCase();
  return content.match(/\bTP[A-Z0-9]{8,20}\b/)?.[0] ?? null;
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function handleSePayWebhook(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") return new Response(null, { status: 204 });
  if (request.method !== "POST") return jsonResponse({ success: false }, 405);
  try {
    const configuredKey = integrationEnv().SEPAY_WEBHOOK_API_KEY.trim();
    if (!configuredKey) throw new HttpError(503, "SePay chưa được cấu hình.");
    const match = request.headers.get("authorization")?.match(/^Apikey\s+(.+)$/i);
    if (!match || !constantTimeSecretMatch(match[1], configuredKey)) {
      return jsonResponse({ success: false }, 401);
    }

    const transaction = await parseJsonBody(request);
    const id = transactionId(transaction);
    if (!id.trim()) throw new HttpError(400, "Thiếu mã giao dịch SePay.");
    const transferAmount = Number(transaction.transferAmount);
    const amount = Number.isSafeInteger(transferAmount) && transferAmount > 0
      ? transferAmount
      : 0;
    const content = String(transaction.content ?? transaction.description ?? "").slice(0, 2000);
    const { data, error } = await subscriptionStore().rpc(
      "process_sepay_subscription_transaction",
      {
        p_transaction_hash: await sha256Hex(id),
        p_transaction_id: id.slice(0, 500),
        p_account_number: String(transaction.accountNumber ?? "").slice(0, 100),
        p_transfer_amount: amount,
        p_transfer_type: String(transaction.transferType ?? "").toLowerCase().slice(0, 20),
        p_payment_reference: paymentReference(transaction),
        p_content: content,
      },
    );
    if (error) {
      console.error("SePay subscription transaction failed:", error.code ?? "unknown");
      throw new HttpError(503, "Không ghi nhận được giao dịch SePay, webhook sẽ được thử lại.");
    }
    return jsonResponse({ success: true, ...(data as Record<string, unknown>) });
  } catch (error) {
    return failure(error);
  }
}
