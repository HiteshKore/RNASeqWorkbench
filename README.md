# Input Excel Workbook Format — Differential Expression Module

This document specifies the required sheet names, columns, and data types
for the workbook uploaded to the **"Differential expression"** tab of
RNAseqWorkbench (`de_excel` input, processed by `DE_analysis.Rmd`).

It's based on `count_data.xlsx`, an actual working example workbook, cross
-checked against the validation logic in `read_and_validate_de_excel()`
(`validate_count_data()`, `validate_sample_info()`, `validate_comparisons()`).
Concrete values from that example are used below to illustrate the format.

The workbook must contain **exactly three sheets**, spelled exactly as
shown (case-sensitive, no trailing spaces):

| Sheet name           | Purpose                                    | Rows in example |
|-----------------------|---------------------------------------------|-----------------:|
| `count_data`          | Raw gene-level count matrix                  | 24,806 genes     |
| `sample_information`  | Sample metadata                              | 12 samples       |
| `comparisons`          | Which groups to compare                      | 3 comparisons    |

---

## 1. `count_data` sheet

**Example structure:**

| Geneid | sample_1 | sample_2 | sample_3 | ... | sample_12 |
|---|---|---|---|---|---|
| ENSMUSG00000102693.2 | 0 | 0 | 0 | ... | 0 |
| ENSMUSG00000064842.3 | 0 | 0 | 0 | ... | 0 |
| ENSMUSG00000051951.6 | 0 | 0 | 0 | ... | 0 |
| ENSMUSG00000103377.2 | 0 | 0 | 0 | ... | 0 |

**Format requirements:**

| Requirement | Detail |
|---|---|
| First column name | Must be exactly `Geneid` |
| First column values | Character gene IDs (example uses versioned Ensembl IDs, e.g. `ENSMUSG00000102693.2`); must be **unique** |
| Sample columns | One column per sample; column names must exactly match `sample_information$sample` (example: `sample_1` … `sample_12`) |
| Count values | Numeric only, no missing (`NA`/blank) cells anywhere |
| Count values | Non-negative — this is a raw count matrix, not fold changes or normalized/log values |

**Strict requirements, enforced by `validate_count_data()`:**
- The first column must be named `Geneid` exactly — not `gene_id`, `GeneID`, or `Gene`.
- Duplicate gene IDs are rejected (the example has zero duplicates across its 24,806 rows).
- Every sample column must be entirely numeric — a single stray text value, footnote symbol, or blank auto-imported as `""` will flag that whole column as non-numeric.
- No missing values are permitted anywhere in the sheet.
- Negative values are rejected outright.

**Cross-check with `sample_information`:** every sample column name in
`count_data` must have a matching row in `sample_information$sample`, and
vice versa — no extra or missing samples on either side.

---

## 2. `sample_information` sheet

**Example content:**

| sample | condition | batch |
|---|---|---|
| sample_1 | Control | 4 |
| sample_2 | Control | 3 |
| sample_3 | Control | 4 |
| sample_4 | Treatment_1 | 3 |
| sample_5 | Treatment_1 | 3 |
| sample_6 | Treatment_1 | 4 |
| sample_7 | Treatment_2 | 1 |
| sample_8 | Treatment_2 | 2 |
| sample_9 | Treatment_2 | 3 |
| sample_10 | Treatment_3 | 1 |
| sample_11 | Treatment_3 | 2 |
| sample_12 | Treatment_3 | 3 |

**Format requirements:**

| Column | Type | Notes |
|---|---|---|
| `sample` | character | Unique; must exactly match a `count_data` column name |
| `condition` | character | Experimental group used in comparisons (example: `Control`, `Treatment_1/2/3`) |
| `batch` | numeric or character | Batch/replicate identifier (example uses integers 1–4). Only needs more than one unique value **within samples being compared** if batch correction is enabled |

> ⚠️ **Discrepancy to be aware of:** `validate_sample_info()`'s code lists
> a **fourth required column, `group`**, in addition to `sample`,
> `condition`, and `batch`. The example workbook shown here does **not**
> include a `group` column, and the app currently accepts it anyway — this
> is because `validate_sample_info()` has a bug where it never actually
> raises an error even when required columns are missing (unlike
> `validate_count_data()` and `validate_comparisons()`, which do). Until
> that's fixed, `group` is *effectively optional* in practice, even though
> the code nominally requires it. If `group` is added in the future and
> the validation bug is fixed, this column will become strictly required —
> safest practice is to include a `group` column (it can duplicate
> `condition` if you don't need a separate grouping) to avoid surprises
> later.

- Sample names must be unique — no duplicate `sample` values.
- `condition` values here (`Control`, `Treatment_1`, `Treatment_2`,
  `Treatment_3`) must exactly match the `Control`/`Test` values used in
  the `comparisons` sheet (see below) — same spelling, same case.

---

## 3. `comparisons` sheet

**Example content:**

| Comparisons | Control | Test |
|---|---|---|
| Treatment_1vs_Control | Control | Treatment_1 |
| Treatment_2vs_Control | Control | Treatment_2 |
| Treatment_3vs_Control | Control | Treatment_3 |

**Format requirements:**

| Column | Type | Notes |
|---|---|---|
| `Comparisons` | character | Unique name per comparison; used as the output file/sheet name for that comparison's results |
| `Control` | character | Reference/baseline group — must match a value in `sample_information$condition` (or `$group`, if present) |
| `Test` | character | Group being compared against `Control`. Fold changes reported as Test vs. Control |

**Strict requirements, enforced by `validate_comparisons()`:**
- `Comparisons` names must be unique.
- Every `Control` and `Test` value must exist in `sample_information`'s
  `condition` (or `group`) column — a typo (e.g. `"treatment_1"` vs.
  `"Treatment_1"`) is caught and reported explicitly, listing exactly
  which value(s) didn't match.
- A comparison whose `Control`/`Test` values don't correspond to any
  samples is **skipped with a warning**, not a hard failure — other valid
  comparisons in the same sheet still run.

In the example, this produces three independent two-group comparisons —
each of `Treatment_1`, `Treatment_2`, `Treatment_3` vs. the shared
`Control` group — even though all three treatment groups and the control
group coexist in one `sample_information` sheet. Each row in `comparisons`
is run as its own separate DE analysis (a distinct DESeq2/edgeR model
subset to just those two groups' samples).

---

## Other inputs required alongside this workbook

| Input | Where set | Relevant to this example |
|---|---|---|
| GTF file | Separate file upload | Must match the genome build the Ensembl gene IDs (`ENSMUSG...`) came from — this example is **mouse** (`ENSMUSG` = *Mus musculus* Ensembl gene prefix), so a mouse GTF (e.g. GENCODE `vM*` or Ensembl mouse) is required, not a human one. |
| Smallest group size | Numeric input, DE tab | In this example, `Control` and each `Treatment_*` group each have exactly 3 samples — set "Smallest group size" to `3`. |
| Batch effect | Checkbox, DE tab | The example's `batch` column has multiple distinct values per condition (e.g. `Control` spans batches 3 and 4), so batch correction is *possible* to enable here, but note some comparisons (e.g. `Treatment_2` vs `Control`) mix batches 1–4 unevenly — check whether batch correction is statistically appropriate for your actual experimental design before enabling it. |

---

## Quick pre-flight checklist

- [ ] Workbook has exactly three sheets: `count_data`, `sample_information`, `comparisons`.
- [ ] `count_data`'s first column is `Geneid`, unique character gene IDs, matching your GTF's ID format/version.
- [ ] All other `count_data` columns are numeric, non-negative, with no missing values.
- [ ] `count_data` sample columns exactly match `sample_information$sample`.
- [ ] `sample_information` has `sample`, `condition`, `batch` columns (and ideally `group`, even if it duplicates `condition`, given the validation bug noted above).
- [ ] `comparisons` has `Comparisons`, `Control`, `Test` columns, with unique comparison names.
- [ ] Every `Control`/`Test` value in `comparisons` exactly matches a `condition` value in `sample_information`.
- [ ] The uploaded GTF matches the species/genome build of your gene IDs.
- [ ] "Smallest group size" matches your smallest comparison group's sample count.

# Input Excel Workbook Format

This document specifies the exact sheet names, column names, and data types
required by `DE_GSEA_plotting_report.Rmd`. The report validates most of this
automatically and will stop with a clear error message if something doesn't
match — but matching this spec exactly avoids those errors in the first
place.

The workbook is a single `.xlsx` file (path set via the `de_res_fn` param)
containing the following sheets (tabs):

| Sheet name       | Purpose                                          | Required |
|------------------|---------------------------------------------------|----------|
| `DE_genes`       | Differential expression results (volcano plot)     | Yes      |
| `BP`             | GO Biological Process enrichment (GSEA)            | Optional*|
| `MF`             | GO Molecular Function enrichment (GSEA)            | Optional*|
| `CC`             | GO Cellular Component enrichment (GSEA)            | Optional*|
| `KEGG`           | KEGG pathway enrichment (GSEA)                     | Optional*|
| `mSigDb_HM`      | MSigDb Hallmark gene set enrichment (GSEA)         | Optional*|
| `mSigDb_IS`      | MSigDb Immune Signature enrichment (GSEA)          | Optional*|
| `plot_instructions` | Controls which enrichment plots get built, and how | Yes (if any enrichment sheet is used) |

\* Any enrichment sheet is only read if it's listed as a `Tab` in
`plot_instructions`. Sheets not listed there are ignored.

**Sheet names are case-sensitive and matched exactly** (including
underscores). `"bp"`, `"Bp"`, or `"BP "` (trailing space) will all fail to
match `"BP"`.

---

## 1. `DE_genes` sheet

One row per gene/feature. Required columns (exact names, case-sensitive):

| Column           | Type      | Notes |
|------------------|-----------|-------|
| `Gene`           | character | Gene/feature ID |
| `baseMean`       | numeric   | Mean normalized count (as from DESeq2) |
| `log2FoldChange` | numeric   | Used as the volcano plot's x-axis |
| `lfcSE`          | numeric   | Standard error of log2FoldChange |
| `pvalue`         | numeric   | Raw p-value |
| `padj`           | numeric   | Adjusted p-value — used as the volcano plot's y-axis (`-log10(padj)`) |
| `regulation`     | character | e.g. "up" / "down" / "none" (not currently used in plotting logic, but required to be present) |
| `gene_name`      | character | Display name used as the volcano plot's feature label |

**Additionally used, but not strictly validated:**

| Column      | Type      | Notes |
|-------------|-----------|-------|
| `highlight` | character | Genes to label on the volcano plot. Use `"None"` (exact string) for genes that should **not** be labeled; any other value is treated as "label this gene." |

**Strict requirements:**
- `padj` and `log2FoldChange` must be numeric — not text, not formatted as
  percentages, not containing footnote symbols (`*`, `†`, etc.).
- Rows with `NA` in `gene_name`, `padj`, or `log2FoldChange` are silently
  dropped (`na.omit()`) before plotting — if a gene you expect to see is
  missing from the plot, check for blank cells first.
- `highlight` must contain the literal string `"None"` (capital N) to mean
  "do not label" — any other placeholder (`"none"`, `"NA"`, blank) will be
  treated as a gene name to highlight and may produce unexpected labels.

---

## 2. GSEA/GO enrichment sheets (`BP`, `MF`, `CC`, `KEGG`, `mSigDb_HM`, `mSigDb_IS`)

These all share **the same required column structure** — the format
produced by `clusterProfiler`'s `gseGO()` / `gseKEGG()` / MSigDb GSEA
results, exported to Excel, with one additional column added manually.

| Column            | Type      | Notes |
|-------------------|-----------|-------|
| `ID`              | character | Term/pathway ID (e.g. GO ID, KEGG ID, Hallmark name) |
| `Description`     | character | Human-readable term name — used as the y-axis label |
| `setSize`         | numeric   | Number of genes in the gene set |
| `enrichmentScore` | numeric   | Raw GSEA enrichment score |
| `NES`             | numeric   | Normalized enrichment score — used as the plot's x-axis (Gene Ratio position) |
| `pvalue`          | numeric   | Raw p-value |
| `p.adjust`        | numeric   | Adjusted p-value — used to color points/bars |
| `qvalue`          | numeric   | Q-value (not currently plotted, but must be present) |
| `rank`            | numeric   | Rank at max enrichment |
| `leading_edge`    | character | e.g. `"tags=33%, list=5%, signal=32%"` (not plotted, informational) |
| `core_enrichment` | character | `/`-separated list of leading-edge genes, e.g. `"Pcare/Crb1/Cdhr1"` — used to derive the point size / bar label (gene **Count**) by counting `/`-separated entries |
| `include_in_plot` | logical (`TRUE`/`FALSE`) | **Only rows where this is exactly `TRUE` are plotted.** All other rows (including blank/`NA`) are excluded. |

**Strict requirements:**
- `include_in_plot` must contain actual boolean values (`TRUE`/`FALSE`),
  not the text strings `"TRUE"`/`"FALSE"` in a text-formatted column, and
  not `1`/`0`. If Excel has auto-formatted this column as text, values may
  not filter correctly — check the column type in Excel (should NOT be
  left-aligned, which usually indicates text).
- `NES` must be numeric. If it's blank or non-numeric for a row that has
  `include_in_plot == TRUE`, that row will be silently dropped when
  ordering/plotting.
- `core_enrichment` must use `/` as the gene separator with **no spaces**
  around the slash (e.g. `Gene1/Gene2/Gene3`, not `Gene1 / Gene2 / Gene3`)
  — spaces will be counted as part of the gene name and produce an
  incorrect Count.
- Do not rename `Description`, `NES`, `p.adjust`, or `core_enrichment`
  unless you also update the corresponding column-name parameters passed
  into the plotting functions (`term_col`, `ratio_col`, `pval_col`,
  `count_col`) — by default the report expects these exact names.

---

## 3. `plot_instructions` sheet

One row per enrichment sheet you want plotted. This sheet drives which
tabs get processed, in what style, with what title, and at what PDF
export size.

| Column        | Type      | Notes |
|---------------|-----------|-------|
| `Tab`         | character | Must **exactly** match the sheet name it refers to (e.g. `BP`, `KEGG`, `mSigDb_HM`) |
| `Plot_type`   | character | `lollipop` or `bar` (case-insensitive; automatically lowercased) |
| `Title`       | character | Plot title shown above the plot and in the HTML section heading |
| `Plot_width`  | numeric   | PDF export width, in inches |
| `Plot_height` | numeric   | PDF export height, in inches |

**Example:**

| Tab        | Plot_type | Title                          | Plot_width | Plot_height |
|------------|-----------|----------------------------------|-----------:|------------:|
| BP         | lollipop  | Enriched Biological Processes    | 5          | 6           |
| MF         | lollipop  | Enriched Molecular Functions     | 5          | 6           |
| CC         | lollipop  | Enriched Cellular Compartments   | 5          | 6           |
| KEGG       | lollipop  | Enriched KEGG Pathways           | 5          | 6           |
| mSigDb_HM  | bar       | Enriched Hallmarks               | 5          | 6           |
| mSigDb_IS  | bar       | Enriched Immune Signatures       | 15         | 7           |

**Strict requirements:**
- Every value in the `Tab` column **must** correspond to an existing sheet
  in the same workbook, spelled and cased identically. A typo here (e.g.
  `"Bp"` instead of `"BP"`) will cause that row to fail with a
  "sheet not found" error, listing the sheets that actually exist.
- `Plot_type` must be either `lollipop` or `bar` (anything else throws a
  `match.arg()` error naming the allowed options). Leading/trailing
  whitespace is trimmed automatically.
- `Plot_width` / `Plot_height` must be numeric and greater than 0. A blank
  cell will cause `ggsave()` to fail for that row.
- If a row's `Tab` sheet has **zero** rows with `include_in_plot == TRUE`,
  that plot will render with no data — check the enrichment sheet's
  `include_in_plot` column if a plot is unexpectedly blank.
- Column header spelling: use `Title` (not `Tittle`). If your workbook was
  built from an older template with the `Tittle` typo, the report will
  still find it via a fallback, but new workbooks should use `Title`.

---

## Quick pre-flight checklist before running the report

- [ ] Sheet names match exactly, case-sensitive, no trailing spaces.
- [ ] `DE_genes` has all 8 required columns, with `padj` and
      `log2FoldChange` stored as numbers, not text.
- [ ] `highlight` uses the literal string `"None"` for non-highlighted genes.
- [ ] Every GSEA sheet listed in `plot_instructions.Tab` exists and has
      `Description`, `NES`, `p.adjust`, `core_enrichment`, and
      `include_in_plot` columns.
- [ ] `include_in_plot` is a true logical column (`TRUE`/`FALSE`), not text.
- [ ] `core_enrichment` gene lists use `/` with no surrounding spaces.
- [ ] `plot_instructions.Plot_type` is exactly `lollipop` or `bar`.
- [ ] `plot_instructions.Plot_width` / `Plot_height` are filled in and numeric.
