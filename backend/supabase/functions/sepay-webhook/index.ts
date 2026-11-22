import { handleSePayWebhook } from "../_shared/sepay_webhook.ts";

Deno.serve(handleSePayWebhook);
