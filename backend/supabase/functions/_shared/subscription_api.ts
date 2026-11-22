import {
  failure,
  HttpError,
  integrationEnv,
  jsonResponse,
  parseJsonBody,
  requireAppUser,
} from "./integrations.ts";
import { subscriptionStore } from "./subscription_store.ts";

const PLAN_PRICES: Record<string, number> = {
  go: 39000,
  plus: 99000,
  ultra: 199000,
};

type DbOrder = Record<string, unknown>;

function accountSettings(row: Record<string, unknown> | null) {
  if (!row) return null;
  return {
    bankName: row.bank_name,
    bankBin: row.bank_bin,
    accountName: row.account_name,
    accountNumber: row.account_number,
    instructions: row.instructions,
    updatedBy: row.updated_by,
    updatedAt: row.updated_at,
  };
}

function orderView(row: DbOrder) {
  return {
    id: row.id,
    legacyId: row.legacy_id,
    landlordUid: row.landlord_uid,
    landlordName: row.landlord_name,
    landlordEmail: row.landlord_email,
    planId: row.plan_id,
    planName: row.plan_name,
    amount: row.amount,
    paymentReference: row.payment_reference,
    paymentBankName: row.payment_bank_name,
    paymentBankBin: row.payment_bank_bin,
    paymentAccountName: row.payment_account_name,
    paymentAccountNumber: row.payment_account_number,
    paymentInstructions: row.payment_instructions,
    status: row.status,
    paymentNote: row.payment_note,
    adminNote: row.admin_note,
    createdAt: row.created_at,
    submittedAt: row.submitted_at,
    reviewedAt: row.reviewed_at,
    reviewedBy: row.reviewed_by,
    startsAt: row.starts_at,
    expiresAt: row.expires_at,
  };
}

function unmatchedView(row: Record<string, unknown>) {
  return {
    id: row.transaction_hash,
    transactionId: row.transaction_id,
    accountNumber: row.account_number,
    transferAmount: row.transfer_amount,
    content: row.content,
    transferType: row.transfer_type,
    reason: row.reason,
    receivedAt: row.received_at,
  };
}

function requireAdmin(profile: Record<string, unknown>): void {
  if (profile.role !== "admin") throw new HttpError(403, "Chỉ admin được thực hiện thao tác này.");
}

function requireLandlord(profile: Record<string, unknown>): void {
  if (profile.role !== "landlord") throw new HttpError(403, "Chỉ chủ trọ được đăng ký gói dịch vụ.");
}

function databaseFailure(error: { code?: string; message?: string }, fallback: string): never {
  console.error("Subscription database request failed:", error.code ?? "unknown");
  if (error.code === "23505") {
    throw new HttpError(409, "Đang có yêu cầu gói chưa được xử lý hoặc mã giao dịch bị trùng.");
  }
  if (error.code === "P0002") {
    throw new HttpError(409, "Yêu cầu này đã được xử lý hoặc chưa gửi xác nhận.");
  }
  throw new HttpError(503, fallback);
}

export async function handleSubscriptionApi(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") return new Response(null, { status: 204 });
  if (request.method !== "POST") return jsonResponse({ error: "POST required" }, 405);

  try {
    const env = integrationEnv();
    const user = await requireAppUser(request, env);
    const body = await parseJsonBody(request, 1_048_576);
    const action = typeof body.action === "string" ? body.action : "";
    const store = subscriptionStore();

    if (action === "getPaymentSettings") {
      const { data, error } = await store
        .from("subscription_payment_settings")
        .select("*")
        .eq("id", true)
        .maybeSingle();
      if (error) databaseFailure(error, "Không tải được cấu hình thanh toán.");
      return jsonResponse({ settings: accountSettings(data) });
    }

    if (action === "listOrders") {
      if (user.profile.role !== "admin" && user.profile.role !== "landlord") {
        throw new HttpError(403, "Tài khoản không được xem đăng ký gói.");
      }
      let query = store.from("subscription_orders").select("*")
        .order("created_at", { ascending: false }).limit(1000);
      if (user.profile.role === "landlord") query = query.eq("landlord_uid", user.uid);
      const { data, error } = await query;
      if (error) databaseFailure(error, "Không tải được danh sách đăng ký gói.");
      return jsonResponse({ orders: (data ?? []).map(orderView) });
    }

    if (action === "listUnmatched") {
      requireAdmin(user.profile);
      const { data, error } = await store.from("sepay_unmatched_transactions")
        .select("*").order("received_at", { ascending: false }).limit(500);
      if (error) databaseFailure(error, "Không tải được giao dịch chưa khớp.");
      return jsonResponse({ transactions: (data ?? []).map(unmatchedView) });
    }

    if (action === "savePaymentSettings") {
      requireAdmin(user.profile);
      const settings = body.settings as Record<string, unknown> | null;
      const bankName = String(settings?.bankName ?? "").trim();
      const bankBin = String(settings?.bankBin ?? "").trim();
      const accountName = String(settings?.accountName ?? "").trim();
      const accountNumber = String(settings?.accountNumber ?? "").trim();
      const instructions = String(settings?.instructions ?? "").trim();
      if (!bankName || bankName.length > 100 || !/^\d{6}$/.test(bankBin) ||
        !accountName || accountName.length > 100 || !/^\d{6,19}$/.test(accountNumber) ||
        instructions.length > 300) {
        throw new HttpError(400, "Kiểm tra ngân hàng, BIN, số tài khoản và hướng dẫn chuyển tiền.");
      }
      const { data, error } = await store.from("subscription_payment_settings").upsert({
        id: true,
        bank_name: bankName,
        bank_bin: bankBin,
        account_name: accountName,
        account_number: accountNumber,
        instructions,
        updated_by: user.uid,
        updated_at: new Date().toISOString(),
      }, { onConflict: "id" }).select("*").single();
      if (error) databaseFailure(error, "Không lưu được cấu hình nhận thanh toán.");
      return jsonResponse({ settings: accountSettings(data) });
    }

    if (action === "createOrder") {
      requireLandlord(user.profile);
      const planId = String(body.planId ?? "");
      const amount = PLAN_PRICES[planId];
      if (!amount) throw new HttpError(400, "Gói dịch vụ không hợp lệ.");
      const { data: settingsRow, error: settingsError } = await store
        .from("subscription_payment_settings").select("*").eq("id", true).maybeSingle();
      if (settingsError) databaseFailure(settingsError, "Không tải được cấu hình thanh toán.");
      if (!settingsRow || !/^\d{6}$/.test(String(settingsRow.bank_bin)) ||
        !/^\d{6,19}$/.test(String(settingsRow.account_number))) {
        throw new HttpError(409, "Admin chưa cấu hình tài khoản nhận thanh toán.");
      }
      const paymentReference = `TP${crypto.randomUUID().replaceAll("-", "").slice(0, 10).toUpperCase()}`;
      const { data, error } = await store.from("subscription_orders").insert({
        landlord_uid: user.uid,
        landlord_name: String(user.profile.displayName ?? "").trim(),
        landlord_email: String(user.profile.email ?? "").trim(),
        plan_id: planId,
        plan_name: planId[0].toUpperCase() + planId.slice(1),
        amount,
        payment_reference: paymentReference,
        payment_bank_name: settingsRow.bank_name,
        payment_bank_bin: settingsRow.bank_bin,
        payment_account_name: settingsRow.account_name,
        payment_account_number: settingsRow.account_number,
        payment_instructions: settingsRow.instructions,
        status: "awaiting_payment",
      }).select("*").single();
      if (error) databaseFailure(error, "Không tạo được yêu cầu đăng ký gói.");
      return jsonResponse({ order: orderView(data) }, 201);
    }

    if (action === "simulatePayment") {
      requireLandlord(user.profile);
      const planId = String(body.planId ?? "").trim();
      const orderId = String(body.orderId ?? "").trim();
      if (Boolean(planId) === Boolean(orderId)) {
        throw new HttpError(400, "Chọn gói hoặc yêu cầu cần giả lập thanh toán.");
      }
      const { data, error } = await store.rpc("simulate_subscription_payment", {
        p_landlord_uid: user.uid,
        p_landlord_name: String(user.profile.displayName ?? "").trim(),
        p_landlord_email: String(user.profile.email ?? "").trim(),
        p_plan_id: planId || null,
        p_order_id: orderId || null,
      });
      if (error) databaseFailure(error, "Không hoàn tất được thanh toán giả lập.");
      if (!data || typeof data !== "object") {
        throw new HttpError(503, "Backend không trả về đơn giả lập hợp lệ.");
      }
      return jsonResponse({ order: orderView(data as DbOrder) });
    }

    if (action === "submitPayment") {
      requireLandlord(user.profile);
      const orderId = String(body.orderId ?? "");
      const paymentNote = String(body.paymentNote ?? "").trim();
      if (paymentNote.length < 4 || paymentNote.length > 300) {
        throw new HttpError(400, "Nhập mã giao dịch hoặc thông tin chuyển khoản hợp lệ.");
      }
      const { data: current, error: currentError } = await store.from("subscription_orders")
        .select("id,status").eq("id", orderId).eq("landlord_uid", user.uid).maybeSingle();
      if (currentError) databaseFailure(currentError, "Không tìm thấy yêu cầu đăng ký gói.");
      if (!current) throw new HttpError(404, "Không tìm thấy yêu cầu đăng ký gói.");
      if (["approved", "submitted"].includes(String(current.status))) {
        return jsonResponse({ success: true });
      }
      if (current.status !== "awaiting_payment") {
        throw new HttpError(409, "Yêu cầu này đã được xử lý hoặc đã bị hủy.");
      }
      const { data, error } = await store.from("subscription_orders").update({
        status: "submitted",
        payment_note: paymentNote,
        submitted_at: new Date().toISOString(),
      }).eq("id", orderId).eq("landlord_uid", user.uid)
        .eq("status", "awaiting_payment").select("id").maybeSingle();
      if (error) databaseFailure(error, "Không gửi được xác nhận thanh toán.");
      if (!data) {
        const { data: latest } = await store.from("subscription_orders")
          .select("status").eq("id", orderId).eq("landlord_uid", user.uid).maybeSingle();
        if (!["approved", "submitted"].includes(String(latest?.status))) {
          throw new HttpError(409, "Yêu cầu này vừa được xử lý hoặc đã bị hủy.");
        }
      }
      return jsonResponse({ success: true });
    }

    if (action === "cancelOrder") {
      requireLandlord(user.profile);
      const { data, error } = await store.from("subscription_orders").update({
        status: "cancelled",
      }).eq("id", String(body.orderId ?? "")).eq("landlord_uid", user.uid)
        .eq("status", "awaiting_payment").select("id").maybeSingle();
      if (error) databaseFailure(error, "Không hủy được yêu cầu đăng ký gói.");
      if (!data) throw new HttpError(409, "Chỉ có thể hủy yêu cầu chưa thanh toán.");
      return jsonResponse({ success: true });
    }

    if (action === "reviewOrder") {
      requireAdmin(user.profile);
      const result = await store.rpc("review_subscription_order", {
        p_order_id: String(body.orderId ?? ""),
        p_admin_uid: user.uid,
        p_approve: body.approve === true,
        p_note: String(body.note ?? "").trim(),
      });
      if (result.error) databaseFailure(result.error, "Không cập nhật được yêu cầu đăng ký gói.");
      return jsonResponse({ order: orderView(result.data as DbOrder) });
    }

    if (action === "legacyMigrationStatus") {
      requireAdmin(user.profile);
      const { data, error } = await store.from("subscription_legacy_migrations")
        .select("id").eq("id", "firestore-subscriptions-v1").maybeSingle();
      if (error) databaseFailure(error, "Không kiểm tra được dữ liệu đăng ký cũ.");
      return jsonResponse({ completed: data != null });
    }

    if (action === "migrateLegacy") {
      requireAdmin(user.profile);
      const settings = body.settings && typeof body.settings === "object"
        ? body.settings
        : null;
      const orders = Array.isArray(body.orders) ? body.orders : [];
      const unmatched = Array.isArray(body.unmatched) ? body.unmatched : [];
      if (orders.length > 100 || unmatched.length > 100) {
        throw new HttpError(413, "Lô dữ liệu cũ vượt quá giới hạn cho phép.");
      }
      const result = await store.rpc("import_legacy_subscription_batch", {
        p_settings: settings,
        p_orders: orders,
        p_unmatched: unmatched,
        p_final: body.finalBatch === true,
      });
      if (result.error) databaseFailure(result.error, "Không chuyển được dữ liệu đăng ký cũ.");
      return jsonResponse(result.data ?? { imported: false });
    }

    throw new HttpError(400, "Thao tác đăng ký gói không hợp lệ.");
  } catch (error) {
    return failure(error);
  }
}
