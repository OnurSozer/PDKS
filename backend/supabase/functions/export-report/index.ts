import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

/**
 * Generate an attendance report export (Excel/PDF).
 * Fetches summary data, formats it as CSV (for Excel) or simple text (for PDF),
 * uploads to Supabase Storage, and returns a signed download URL.
 *
 * NOTE: For a production system, you'd use a proper Excel/PDF library.
 * This implementation creates a CSV file that can be opened in Excel.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["operator"]);

    const { format, start_date, end_date, employee_id } = await req.json();

    if (!format || !start_date || !end_date) {
      throw new Error("format, start_date, and end_date are required");
    }

    if (!["excel", "pdf"].includes(format)) {
      throw new Error("format must be 'excel' or 'pdf'");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // Fetch report data
    let summaryQuery = supabaseAdmin
      .from("daily_summaries")
      .select("*, employee:profiles(first_name, last_name, email)")
      .eq("company_id", user.company_id!)
      .gte("summary_date", start_date)
      .lte("summary_date", end_date)
      .order("summary_date", { ascending: true });

    if (employee_id) {
      summaryQuery = summaryQuery.eq("employee_id", employee_id);
    }

    const { data: summaries, error: dataError } = await summaryQuery;
    if (dataError) throw new Error(`Failed to fetch report data: ${dataError.message}`);

    // Generate CSV content
    const headers = [
      "Date",
      "Employee",
      "Email",
      "Sessions",
      "Total Work (min)",
      "Regular (min)",
      "Overtime (min)",
      "Expected (min)",
      "Late",
      "Late (min)",
      "Status",
    ];

    const rows = (summaries || []).map((s: any) => [
      s.summary_date,
      `${s.employee?.first_name || ""} ${s.employee?.last_name || ""}`.trim(),
      s.employee?.email || "",
      s.total_sessions,
      s.total_work_minutes,
      s.total_regular_minutes,
      s.total_overtime_minutes,
      s.expected_work_minutes,
      s.is_late ? "Yes" : "No",
      s.late_minutes,
      s.status,
    ]);

    const csvContent = [
      headers.join(","),
      ...rows.map((row: any[]) =>
        row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(",")
      ),
    ].join("\n");

    // Upload to Supabase Storage
    const fileName = `reports/${user.company_id}/${start_date}_${end_date}_${Date.now()}.csv`;

    const { error: uploadError } = await supabaseAdmin.storage
      .from("exports")
      .upload(fileName, new Blob([csvContent], { type: "text/csv" }), {
        contentType: "text/csv",
        upsert: true,
      });

    if (uploadError) {
      // If the bucket doesn't exist, return the CSV directly
      if (uploadError.message.includes("not found") || uploadError.message.includes("Bucket")) {
        return new Response(csvContent, {
          headers: {
            ...corsHeaders,
            "Content-Type": "text/csv",
            "Content-Disposition": `attachment; filename="report_${start_date}_${end_date}.csv"`,
          },
          status: 200,
        });
      }
      throw new Error(`Failed to upload report: ${uploadError.message}`);
    }

    // Get a signed URL (valid for 1 hour)
    const { data: signedUrl, error: urlError } = await supabaseAdmin.storage
      .from("exports")
      .createSignedUrl(fileName, 3600);

    if (urlError) throw new Error(`Failed to create download URL: ${urlError.message}`);

    return new Response(
      JSON.stringify({ download_url: signedUrl.signedUrl }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    const msg = (error as Error).message;
    const status = msg === "Unauthorized" ? 401 : msg.startsWith("Forbidden") ? 403 : 400;
    return new Response(JSON.stringify({ error: msg }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status,
    });
  }
});
