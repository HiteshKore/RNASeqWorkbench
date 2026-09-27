<center>

# RNAseqWorkbench

### An interactive interface for differential expression and gene set enrichment analysis/visualisation

</center>

---

## Overview

**RNAseqWorkbench** is a Shiny-based application that streamlines two core
steps of RNA-seq analysis:

- **Differential Expression (DE) analysis** — quantify and visualise
  transcript/gene-level expression changes between conditions using
  DESeq2 or edgeR.
- **Gene Set Enrichment Analysis (GSEA)** — identify enriched biological
  processes, molecular functions, cellular components, KEGG pathways, and
  MSigDb gene sets from your DE results.

The app is designed to take raw count data through to publication-ready
volcano plots and enrichment visualisations, without requiring users to
write R code.

## What you can do here

| Module | Description |
|---|---|
| **Differential expression** | Upload count data, sample metadata, and comparison definitions to run DE analysis and generate volcano plots. |
| **GSEA visualisation** | Upload DE results to run enrichment analysis and generate lollipop/bar plots across GO, KEGG, and MSigDb gene sets. |

## Getting started

1. Navigate to **Differential expression** in the sidebar.
2. Upload your Excel workbook (must contain `count_data`, `sample_information`, and `comparisons` sheets — see the format guide on that page).
3. Upload the corresponding GTF annotation file.
4. Configure your analysis options and click **Submit**.
5. Once complete, proceed to **GSEA visualisations** to explore enrichment results.

## Input requirements

Each module has strict input format requirements (exact sheet names,
column names, and data types). Please refer to the format guides
before uploading your files to avoid processing errors.

## Support & feedback

For questions, bug reports, or feature requests, please contact:

📧 [hitesh.kore22@gmail.com](mailto:hitesh.kore22@gmail.com)

---

<center>
<sub>Developed by Hitesh Kore · Parker Lab, The University of Melbourne</sub>
</center>