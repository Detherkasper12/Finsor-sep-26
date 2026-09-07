import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const GENERAL_SYSTEM_PROMPT = `You are a neutral analytical assistant. You do NOT have access to any financial transaction data.

Rules:
- Discuss financial concepts, planning, education, or general decision-making.
- If the user asks for analysis of their spending, transactions, or financial data: respond with: "For transaction-based analysis, please use Finance mode and select a period or category."
- Never invent or assume financial data.
- Be neutral, structured, analytical. No moralizing. No motivational language. No "you should" or "you must."
- When discussing purchases (car, phone, trip): use cost breakdown, long-term impact, cash flow implications, risk factors, alternatives. Present trade-offs, not definitive advice.`;

const FINANCE_SYSTEM_PROMPT = `You are a neutral financial analyst. You ONLY use the provided dataset. Never invent numbers or conclusions.

Rules:
- Structure every response: TL;DR (max 3 bullets), Key numbers, Observed changes or patterns, Notable outliers (if any), Forecast (if applicable), Optional neutral recommendations (max 3, mathematical or scenario-based, not moral).
- Base conclusions ONLY on provided numbers. If data is insufficient, say: "Insufficient data for accurate analysis."
- No moralizing. No judgment. No emotional commentary.
- Never access data outside the provided context.`;

const MAX_TRANSACTIONS_CAP = 50;
const LARGE_TIER_TX_THRESHOLD = 500;

type DatasetTier = "small" | "medium" | "large";

interface FinanceContext {
  dateRange?: { start: string; end: string };
  categoryId?: string;
  accountIds?: string[];
}

function selectTier(
  message: string,
  opts: { deepToggle?: boolean; transactionCount?: number },
): DatasetTier {
  const lower = message.toLowerCase().trim();
  const { deepToggle = false, transactionCount = 0 } = opts;
  if (deepToggle) return "large";
  if (/\b(deep|detailed|full analysis)\b/.test(lower)) {
    if (transactionCount > LARGE_TIER_TX_THRESHOLD) return "medium";
    return "large";
  }
  const mediumKeywords = ["compare", "why", "trend", "pattern", "unusual", "outlier", "anomaly"];
  if (mediumKeywords.some((k) => lower.includes(k))) {
    return "medium";
  }
  return "small";
}

function getPreviousPeriod(ctx: FinanceContext): { start: string; end: string } | null {
  const dr = ctx.dateRange;
  if (!dr?.start || !dr?.end) return null;
  const start = new Date(dr.start);
  const end = new Date(dr.end);
  const days = Math.floor((end.getTime() - start.getTime()) / 86400000) + 1;
  if (days <= 10) {
    const prevEnd = new Date(start);
    prevEnd.setDate(prevEnd.getDate() - 1);
    const prevStart = new Date(prevEnd);
    prevStart.setDate(prevStart.getDate() - days + 1);
    return { start: prevStart.toISOString().slice(0, 10), end: prevEnd.toISOString().slice(0, 10) };
  }
  if (start.getDate() === 1 && end.getDate() >= 28 && start.getMonth() === end.getMonth()) {
    const prevMonth = new Date(start.getFullYear(), start.getMonth() - 1, 1);
    const prevMonthEnd = new Date(start.getFullYear(), start.getMonth(), 0);
    return { start: prevMonth.toISOString().slice(0, 10), end: prevMonthEnd.toISOString().slice(0, 10) };
  }
  const prevEnd = new Date(start);
  prevEnd.setDate(prevEnd.getDate() - 1);
  const prevStart = new Date(prevEnd);
  prevStart.setDate(prevStart.getDate() - days + 1);
  return { start: prevStart.toISOString().slice(0, 10), end: prevEnd.toISOString().slice(0, 10) };
}

function normalizeMerchant(raw: string | undefined | null): string {
  if (!raw || !raw.trim()) return "General";
  const s = raw.replace(/[0-9]/g, "").replace(/[^\w\s-]/g, " ").trim();
  return s.length > 32 ? s.slice(0, 32) : s || "General";
}

const PII_FIELDS = ["description", "notes", "address", "email", "phone", "accountNumber", "account_number"];

function validateAndSanitizeClientDataset(
  d: Record<string, unknown>,
): { valid: true; dataset: Record<string, unknown> } | { valid: false; error: string } {
  if (!d.aggregates || typeof d.aggregates !== "object") {
    return { valid: false, error: "Invalid dataset shape. Requires aggregates." };
  }
  if (!d.currency) {
    return { valid: false, error: "Invalid dataset shape. Requires currency." };
  }
  const ctx = d.context as Record<string, unknown> | undefined;
  const dr = ctx?.dateRange as { start?: string; end?: string } | undefined;
  const catId = ctx?.categoryId as string | undefined;
  const hasDateRange = dr?.start && dr?.end;
  const hasCategory = catId != null && String(catId).trim().length > 0;
  if (!hasDateRange && !hasCategory) {
    return { valid: false, error: "CONTEXT_REQUIRED" };
  }
  const dataset = { ...d } as Record<string, unknown>;
  const topTx = dataset.topTransactions as unknown[] | undefined;
  if (Array.isArray(topTx) && topTx.length > MAX_TRANSACTIONS_CAP) {
    dataset.topTransactions = topTx.slice(0, MAX_TRANSACTIONS_CAP);
  }
  const str = JSON.stringify(dataset);
  for (const field of PII_FIELDS) {
    const re = new RegExp(`"${field}"\\s*:`, "i");
    if (re.test(str)) {
      return { valid: false, error: `Dataset contains forbidden PII field: ${field}` };
    }
  }
  return { valid: true, dataset };
}

function getAuthToken(req: Request): string | null {
  const authHeader = req.headers.get("Authorization") ?? req.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;
  return authHeader.slice(7).trim();
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  };
}

function authErrorJson(code: string, message: string) {
  return Response.json(
    { code, message },
    { status: 401, headers: corsHeaders() },
  );
}

function buildDatasetSmall(
  rows: Record<string, unknown>[],
  categories: Record<string, unknown>[],
  context: FinanceContext,
): Record<string, unknown> {
  const catMap = new Map(categories.map((c) => [c.id, c.name]));
  const income = rows.filter((r) => r.type === "income");
  const expense = rows.filter((r) => r.type === "expense");
  const totalIncome = income.reduce((s, r) => s + (r.amount as number), 0);
  const totalExpense = expense.reduce((s, r) => s + (r.amount as number), 0);
  const amounts = rows.map((r) => r.amount as number).filter((a) => a !== 0);
  const sorted = [...amounts].sort((a, b) => Math.abs(b) - Math.abs(a));
  const avg = amounts.length ? amounts.reduce((a, b) => a + b, 0) / amounts.length : 0;
  const median =
    sorted.length > 0
      ? sorted.length % 2 === 0
        ? (sorted[sorted.length / 2 - 1]! + sorted[sorted.length / 2]!) / 2
        : sorted[Math.floor(sorted.length / 2)]!
      : 0;
  const expAmounts = expense.map((r) => r.amount as number);
  const avgExpense = expAmounts.length ? expAmounts.reduce((a, b) => a + b, 0) / expAmounts.length : 0;
  const medSorted = [...expAmounts].sort((a, b) => a - b);
  const medianExpense =
    medSorted.length > 0
      ? medSorted.length % 2 === 0
        ? (medSorted[medSorted.length / 2 - 1]! + medSorted[medSorted.length / 2]!) / 2
        : medSorted[Math.floor(medSorted.length / 2)]!
      : 0;

  const byCategory = new Map<string, { total: number; count: number }>();
  for (const r of rows) {
    if (r.type === "transfer") continue;
    const cid = r.category_id as string;
    const name = (catMap.get(cid) as string) ?? "Unknown";
    const key = `${cid}|${name}`;
    const cur = byCategory.get(key) ?? { total: 0, count: 0 };
    cur.total += r.amount as number;
    cur.count += 1;
    byCategory.set(key, cur);
  }
  const catList = Array.from(byCategory.entries())
    .map(([k, v]) => {
      const [id, name] = k.split("|");
      return { categoryId: id, name, total: v.total, count: v.count };
    })
    .sort((a, b) => Math.abs(b.total) - Math.abs(a.total));
  const topCats = catList.slice(0, 10);
  const other = catList.slice(10).reduce(
    (acc, x) => ({ total: acc.total + x.total, count: acc.count + x.count }),
    { total: 0, count: 0 },
  );
  if (other.total !== 0 || other.count !== 0) {
    topCats.push({ categoryId: "other", name: "Other", total: other.total, count: other.count });
  }

  const topTx = rows
    .filter((r) => r.type !== "transfer")
    .sort((a, b) => Math.abs((b.amount as number)) - Math.abs((a.amount as number)))
    .slice(0, 10)
    .map((r) => ({
      amount: r.amount,
      type: r.type,
      currency: "USD",
      categoryName: catMap.get(r.category_id as string) ?? "Unknown",
      merchant: normalizeMerchant(catMap.get(r.category_id as string) as string),
      date: (r.date as string ?? r.created_at as string)?.slice(0, 10),
    }));

  return {
    context,
    currency: "USD",
    tier: "small",
    aggregates: {
      totalIncome,
      totalExpense,
      transactionCount: rows.length,
      avgAmount: avg,
      medianAmount: median,
      avgExpense,
      medianExpense,
      byCategory: topCats,
    },
    topTransactions: topTx,
  };
}

function buildDatasetMedium(
  rows: Record<string, unknown>[],
  categories: Record<string, unknown>[],
  context: FinanceContext,
  prevRows?: Record<string, unknown>[],
): Record<string, unknown> {
  const small = buildDatasetSmall(rows, categories, context);
  const catMap = new Map(categories.map((c) => [c.id, c.name]));

  const byDay = new Map<string, { income: number; expense: number }>();
  for (const r of rows) {
    const d = (r.date as string ?? r.created_at as string)?.slice(0, 10) ?? "";
    if (!d) continue;
    const cur = byDay.get(d) ?? { income: 0, expense: 0 };
    if (r.type === "income") cur.income += r.amount as number;
    else if (r.type === "expense") cur.expense += r.amount as number;
    byDay.set(d, cur);
  }
  const byDayAgg = Array.from(byDay.entries())
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([date, v]) => ({ date, income: v.income, expense: v.expense }));

  const merchantCounts = new Map<string, number>();
  for (const r of rows) {
    if (r.type === "transfer") continue;
    const m = normalizeMerchant(catMap.get(r.category_id as string) as string);
    merchantCounts.set(m, (merchantCounts.get(m) ?? 0) + 1);
  }
  const topMerchants = Array.from(merchantCounts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([name, count]) => ({ name, count }));

  const amounts = rows
    .filter((r) => r.type !== "transfer")
    .map((r) => Math.abs(r.amount as number))
    .filter((a) => a > 0);
  const medSorted = [...amounts].sort((a, b) => a - b);
  const median =
    medSorted.length > 0
      ? medSorted.length % 2 === 0
        ? (medSorted[medSorted.length / 2 - 1]! + medSorted[medSorted.length / 2]!) / 2
        : medSorted[Math.floor(medSorted.length / 2)]!
      : 0;
  const p95Idx = Math.floor(amounts.length * 0.95);
  const p95 = amounts.length > 0 ? ([...amounts].sort((a, b) => a - b))[Math.min(p95Idx, amounts.length - 1)]! : 0;
  const threshold3x = median * 3;
  const threshold = Math.max(p95, threshold3x);
  const ruleUsed = p95 >= threshold3x ? "p95" : "3xMedian";
  const outliers = rows
    .filter((r) => r.type !== "transfer" && Math.abs(r.amount as number) >= threshold)
    .sort((a, b) => Math.abs(b.amount as number) - Math.abs(a.amount as number))
    .slice(0, 10)
    .map((r) => ({
      amount: r.amount,
      type: r.type,
      categoryName: catMap.get(r.category_id as string) ?? "Unknown",
      date: (r.date as string ?? r.created_at as string)?.slice(0, 10),
    }));

  const agg = small.aggregates as Record<string, unknown>;
  let prevDelta: Record<string, unknown> = {};
  if (prevRows && prevRows.length >= 0) {
    const prevIncome = prevRows.filter((r) => r.type === "income").reduce((s, r) => s + (r.amount as number), 0);
    const prevExpense = prevRows.filter((r) => r.type === "expense").reduce((s, r) => s + (r.amount as number), 0);
    const currIncome = agg.totalIncome as number;
    const currExpense = agg.totalExpense as number;
    const currByCat = new Map<string, number>();
    for (const c of (agg.byCategory as { categoryId?: string; name: string; total: number }[]) ?? []) {
      const name = c.name ?? "Unknown";
      currByCat.set(name, (currByCat.get(name) ?? 0) + c.total);
    }
    const prevByCat = new Map<string, number>();
    for (const r of prevRows) {
      if (r.type === "transfer") continue;
      const name = (catMap.get(r.category_id as string) as string) ?? "Unknown";
      prevByCat.set(name, (prevByCat.get(name) ?? 0) + (r.amount as number));
    }
    const allCats = new Set([...currByCat.keys(), ...prevByCat.keys()]);
    const catDeltas = Array.from(allCats)
      .map((name) => {
        const curr = currByCat.get(name) ?? 0;
        const prev = prevByCat.get(name) ?? 0;
        const delta = curr - prev;
        const pct = prev !== 0 ? (delta / prev) * 100 : 0;
        return { category: name, delta_abs: delta, delta_pct: pct };
      })
      .sort((a, b) => Math.abs(b.delta_abs) - Math.abs(a.delta_abs))
      .slice(0, 5);
    prevDelta = {
      previous_total_income: prevIncome,
      previous_total_expense: prevExpense,
      delta_income_abs: currIncome - prevIncome,
      delta_income_pct: prevIncome !== 0 ? ((currIncome - prevIncome) / prevIncome) * 100 : 0,
      delta_expense_abs: currExpense - prevExpense,
      delta_expense_pct: prevExpense !== 0 ? ((currExpense - prevExpense) / prevExpense) * 100 : 0,
      top_category_deltas: catDeltas,
    };
  }
  const outlierMeta = outliers.length > 0 ? { outlierRuleUsed: ruleUsed, outlierThreshold: threshold } : {};

  return {
    ...small,
    tier: "medium",
    aggregates: { ...agg, byDay: byDayAgg, ...prevDelta },
    topMerchants,
    outliers,
    ...outlierMeta,
  };
}

function buildDatasetLarge(
  rows: Record<string, unknown>[],
  categories: Record<string, unknown>[],
  context: FinanceContext,
  prevRows?: Record<string, unknown>[],
): Record<string, unknown> {
  const medium = buildDatasetMedium(rows, categories, context, prevRows);
  const catMap = new Map(categories.map((c) => [c.id, c.name]));

  const topTx = rows
    .filter((r) => r.type !== "transfer")
    .sort((a, b) => Math.abs((b.amount as number)) - Math.abs((a.amount as number)))
    .slice(0, MAX_TRANSACTIONS_CAP)
    .map((r) => ({
      amount: r.amount,
      type: r.type,
      currency: "USD",
      categoryName: catMap.get(r.category_id as string) ?? "Unknown",
      merchant: normalizeMerchant(catMap.get(r.category_id as string) as string),
      date: (r.date as string ?? r.created_at as string)?.slice(0, 10),
    }));

  const byCatDay = new Map<string, number>();
  for (const r of rows) {
    if (r.type === "transfer") continue;
    const cat = (catMap.get(r.category_id as string) as string) ?? "Unknown";
    const d = (r.date as string ?? r.created_at as string)?.slice(0, 10) ?? "";
    const key = `${cat}|${d}`;
    byCatDay.set(key, (byCatDay.get(key) ?? 0) + (r.amount as number));
  }
  const cats = new Set<string>();
  const days = new Set<string>();
  for (const k of byCatDay.keys()) {
    const [cat, day] = k.split("|");
    if (cat && day) {
      cats.add(cat);
      days.add(day);
    }
  }
  const dayList = Array.from(days).sort();
  const categoryByDay = Array.from(cats).map((cat) => {
    const row: Record<string, unknown> = { category: cat };
    for (const d of dayList) {
      row[d] = byCatDay.get(`${cat}|${d}`) ?? 0;
    }
    return row;
  });

  return {
    ...medium,
    tier: "large",
    topTransactions: topTx,
    categoryByDay,
  };
}

Deno.serve(async (req: Request) => {
  const requestId = crypto.randomUUID?.() ?? `req-${Date.now()}`;

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders() });
  }

  const token = getAuthToken(req);
  if (!token) {
    console.log(`[${requestId}] 401 missing Authorization header`);
    return authErrorJson("UNAUTHORIZED", "Missing or invalid Authorization header");
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data: { user }, error: userError } = await supabase.auth.getUser(token);
  if (userError || !user?.id) {
    const msg = userError?.message ?? "no-user";
    console.log(`[${requestId}] 401 Invalid or expired token userError=${msg}`);
    const isExpired = /expired|invalid.*token|jwt/i.test(msg);
    return authErrorJson(
      isExpired ? "SESSION_EXPIRED" : "UNAUTHORIZED",
      isExpired ? "Session or token expired. Please sign in again." : "Invalid or missing auth.",
    );
  }

  const userId = user.id;
  console.log(`[${requestId}] user=${userId}`);

  let body: { mode?: string; message?: string; dataset?: unknown; useServerData?: boolean; context?: FinanceContext; tier?: string; deepToggle?: boolean };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return Response.json(
      { error: "Invalid JSON body" },
      { status: 400, headers: corsHeaders() },
    );
  }

  const { mode, message } = body;
  if (!mode || (mode !== "general" && mode !== "finance")) {
    return Response.json(
      { error: "Invalid mode. Use 'general' or 'finance'" },
      { status: 400, headers: corsHeaders() },
    );
  }
  if (!message || typeof message !== "string") {
    return Response.json(
      { error: "Missing or invalid message" },
      { status: 400, headers: corsHeaders() },
    );
  }

  if (mode === "general") {
    if (!OPENAI_API_KEY) {
      return Response.json(
        { error: "AI_CONFIG_ERROR", message: "AI service not configured" },
        { status: 503, headers: corsHeaders() },
      );
    }
    console.log(`[${requestId}] user=${userId} calling OpenAI (general)`);
    try {
      const res = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-3.5-turbo",
          messages: [
            { role: "system", content: GENERAL_SYSTEM_PROMPT },
            { role: "user", content: message },
          ],
          max_tokens: 800,
          temperature: 0.5,
        }),
      });
      if (!res.ok) {
        const err = await res.text();
        if (res.status === 401 || res.status === 403) {
          return Response.json(
            { error: "AI_CONFIG_ERROR", message: "Invalid or missing API key" },
            { status: 503, headers: corsHeaders() },
          );
        }
        if (res.status === 429) {
          return Response.json(
            { error: "AI_RATE_LIMIT", message: "Rate limit exceeded. Try again in a moment." },
            { status: 429, headers: corsHeaders() },
          );
        }
        console.error("OpenAI error:", res.status, err);
        return Response.json(
          { error: "AI_TEMPORARY_ERROR", message: "AI service error" },
          { status: 503, headers: corsHeaders() },
        );
      }
      const data = (await res.json()) as { choices?: { message?: { content?: string } }[] };
      const content = data?.choices?.[0]?.message?.content ?? "No response.";
      return Response.json(
        { content },
        { headers: { ...corsHeaders(), "Content-Type": "application/json" } },
      );
    } catch (e) {
      console.error("OpenAI request failed:", e);
      return Response.json(
        { error: "AI_TEMPORARY_ERROR", message: "Network or temporary error" },
        { status: 503, headers: corsHeaders() },
      );
    }
  }

  if (mode === "finance") {
    const ctx = body.context;
    const hasDateRange = ctx?.dateRange?.start && ctx?.dateRange?.end;
    const hasCategory = ctx?.categoryId && String(ctx.categoryId).trim().length > 0;
    const hasClientDataset = body.dataset && typeof body.dataset === "object" && body.dataset !== null;

    if (!hasClientDataset && (!hasDateRange && !hasCategory)) {
      return Response.json(
        {
          error: "CONTEXT_REQUIRED",
          message: "Please select a period or category to analyze.",
        },
        { status: 400, headers: corsHeaders() },
      );
    }

    let dataset: Record<string, unknown>;
    if (body.useServerData === true && ctx) {
      let query = supabase
        .from("transactions")
        .select("id, amount, type, category_id, wallet_id, date, created_at")
        .is("deleted_at", null);

      if (hasDateRange && ctx.dateRange) {
        query = query
          .gte("date", ctx.dateRange.start)
          .lte("date", ctx.dateRange.end);
      }
      if (hasCategory && ctx.categoryId) {
        query = query.eq("category_id", ctx.categoryId);
      }
      if (ctx.accountIds && ctx.accountIds.length > 0) {
        query = query.in("wallet_id", ctx.accountIds);
      }

      const { data: txRows, error: txErr } = await query;
      if (txErr) {
        console.error("Supabase transactions error:", txErr);
        return Response.json(
          { error: "Failed to load transactions" },
          { status: 502, headers: corsHeaders() },
        );
      }
      const rows = (txRows ?? []) as Record<string, unknown>[];

      let prevRows: Record<string, unknown>[] = [];
      const prevPeriod = getPreviousPeriod(ctx);
      if (prevPeriod && hasDateRange) {
        let prevQuery = supabase
          .from("transactions")
          .select("id, amount, type, category_id, wallet_id, date, created_at")
          .is("deleted_at", null)
          .gte("date", prevPeriod.start)
          .lte("date", prevPeriod.end);
        if (hasCategory && ctx!.categoryId) prevQuery = prevQuery.eq("category_id", ctx!.categoryId);
        if (ctx!.accountIds?.length) prevQuery = prevQuery.in("wallet_id", ctx!.accountIds);
        const { data: prevTx } = await prevQuery;
        prevRows = (prevTx ?? []) as Record<string, unknown>[];
      }

      const { data: catRows } = await supabase
        .from("categories")
        .select("id, name")
        .is("deleted_at", null);
      const categories = (catRows ?? []) as Record<string, unknown>[];

      const tierFromClient = body.tier as DatasetTier | undefined;
      const deepToggle = body.deepToggle === true;
      const txCount = rows.length;
      const resolvedTier =
        tierFromClient && ["small", "medium", "large"].includes(tierFromClient)
          ? tierFromClient
          : selectTier(message, { deepToggle, transactionCount: txCount });
      const effectiveTier =
        resolvedTier === "large" && txCount > LARGE_TIER_TX_THRESHOLD && !deepToggle
          ? "medium"
          : resolvedTier;

      if (effectiveTier === "small") {
        dataset = buildDatasetSmall(rows, categories, ctx);
      } else if (effectiveTier === "medium") {
        dataset = buildDatasetMedium(rows, categories, ctx, prevRows.length ? prevRows : undefined);
      } else {
        dataset = buildDatasetLarge(rows, categories, ctx, prevRows.length ? prevRows : undefined);
      }
    } else if (body.dataset && typeof body.dataset === "object" && body.dataset !== null) {
      const d = body.dataset as Record<string, unknown>;
      const validation = validateAndSanitizeClientDataset(d);
      if (!validation.valid) {
        return Response.json(
          {
            error: validation.error ?? "Invalid dataset",
            message: validation.error === "CONTEXT_REQUIRED"
              ? "Please select a period or category to analyze."
              : validation.error,
          },
          { status: 400, headers: corsHeaders() },
        );
      }
      dataset = validation.dataset;
    } else {
      return Response.json(
        {
          error: "CONTEXT_REQUIRED",
          message: "Provide dataset or useServerData with context.",
        },
        { status: 400, headers: corsHeaders() },
      );
    }

    if (!OPENAI_API_KEY) {
      return Response.json(
        { error: "AI_CONFIG_ERROR", message: "AI service not configured" },
        { status: 503, headers: corsHeaders() },
      );
    }

    let contextStr = "Selected period";
    if (hasDateRange && ctx?.dateRange) {
      contextStr = `${ctx.dateRange.start} to ${ctx.dateRange.end}`;
    } else if (hasCategory && ctx?.categoryId) {
      contextStr = `Category ${ctx?.categoryId}`;
    } else if (hasClientDataset && dataset?.context) {
      const dc = (dataset.context as Record<string, unknown>).dateRange as { start?: string; end?: string } | undefined;
      const dCat = (dataset.context as Record<string, unknown>).categoryId as string | undefined;
      if (dc?.start && dc?.end) contextStr = `${dc.start} to ${dc.end}`;
      else if (dCat) contextStr = `Category ${dCat}`;
    }

    console.log(`[${requestId}] user=${userId} calling OpenAI (finance)`);
    try {
      const res = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-3.5-turbo",
          messages: [
            { role: "system", content: FINANCE_SYSTEM_PROMPT },
            { role: "user", content: `Dataset:\n${JSON.stringify(dataset)}\n\nUser question: ${message}` },
          ],
          max_tokens: 1000,
          temperature: 0.3,
        }),
      });
      if (!res.ok) {
        const err = await res.text();
        if (res.status === 401 || res.status === 403) {
          return Response.json(
            { error: "AI_CONFIG_ERROR", message: "Invalid or missing API key" },
            { status: 503, headers: corsHeaders() },
          );
        }
        if (res.status === 429) {
          return Response.json(
            { error: "AI_RATE_LIMIT", message: "Rate limit exceeded. Try again in a moment." },
            { status: 429, headers: corsHeaders() },
          );
        }
        console.error("OpenAI finance error:", res.status, err);
        return Response.json(
          { error: "AI_TEMPORARY_ERROR", message: "AI service error" },
          { status: 503, headers: corsHeaders() },
        );
      }
      const data = (await res.json()) as { choices?: { message?: { content?: string } }[] };
      let content = data?.choices?.[0]?.message?.content ?? "Insufficient data for accurate analysis.";
      if (/^Analysis for:[\s\S]*/i.test(content)) {
        content = content.replace(/^Analysis for:[^\n]*\n?/, "").trim();
      }
      const header = `Analysis for: ${contextStr}`;
      const finalContent = content ? `${header}\n\n${content}` : header;
      return Response.json(
        { content: finalContent },
        { headers: { ...corsHeaders(), "Content-Type": "application/json" } },
      );
    } catch (e) {
      console.error("OpenAI finance request failed:", e);
      return Response.json(
        { error: "AI_TEMPORARY_ERROR", message: "Network or temporary error" },
        { status: 503, headers: corsHeaders() },
      );
    }
  }

  return Response.json(
    { error: "Invalid mode" },
    { status: 400, headers: corsHeaders() },
  );
});
