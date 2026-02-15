#!/bin/bash
# Bookdown to Quarto Conversion Script
# Usage: ./convert_bookdown_to_quarto.sh [directory]
#
# This script automates many conversion steps but manual review is still required.

set -e

DIR="${1:-.}"
cd "$DIR"

echo "=== Bookdown to Quarto Conversion ==="
echo "Working directory: $(pwd)"
echo ""

# Step 1: Rename files
echo "Step 1: Renaming .Rmd files to .qmd..."
for f in *.Rmd 2>/dev/null; do
  if [ -f "$f" ]; then
    newname="${f%.Rmd}.qmd"
    mv "$f" "$newname"
    echo "  Renamed: $f -> $newname"
  fi
done
echo ""

# Step 2: Convert cross-references
echo "Step 2: Converting cross-references..."
for file in *.qmd; do
  if [ -f "$file" ]; then
    # Convert \@ref(fig:name) to @fig-name
    sed -i '' 's/\\@ref(fig:\([^)]*\))/@fig-\1/g' "$file"

    # Convert \@ref(tab:name) to @tbl-name
    sed -i '' 's/\\@ref(tab:\([^)]*\))/@tbl-\1/g' "$file"

    # Convert \@ref(eq:name) to @eq-name
    sed -i '' 's/\\@ref(eq:\([^)]*\))/@eq-\1/g' "$file"

    # Convert remaining \@ref(name) to @sec-name
    sed -i '' 's/\\@ref(\([^)]*\))/@sec-\1/g' "$file"

    echo "  Processed: $file"
  fi
done
echo ""

# Step 3: Remove redundant cross-reference prefixes
echo "Step 3: Removing redundant cross-reference prefixes..."
for file in *.qmd; do
  if [ -f "$file" ]; then
    sed -i '' 's/Figure @fig-/@fig-/g' "$file"
    sed -i '' 's/Figure@fig-/@fig-/g' "$file"
    sed -i '' 's/Table @tbl-/@tbl-/g' "$file"
    sed -i '' 's/Table@tbl-/@tbl-/g' "$file"
    sed -i '' 's/Chapter @sec-/@sec-/g' "$file"
    sed -i '' 's/Chapter@sec-/@sec-/g' "$file"
    sed -i '' 's/Section @sec-/@sec-/g' "$file"
    sed -i '' 's/Section@sec-/@sec-/g' "$file"
  fi
done
echo "  Done"
echo ""

# Step 4: Convert custom blocks to callouts
echo "Step 4: Converting custom blocks to callouts..."
for file in *.qmd; do
  if [ -f "$file" ]; then
    sed -i '' 's/:::rmdnote/::: {.callout-note}/g' "$file"
    sed -i '' 's/:::rmdwarning/::: {.callout-warning}/g' "$file"
    sed -i '' 's/:::rmdtip/::: {.callout-tip}/g' "$file"
    sed -i '' 's/:::rstudio-tip/::: {.callout-tip}/g' "$file"
    sed -i '' 's/:::rmdcaution/::: {.callout-caution}/g' "$file"
    sed -i '' 's/:::rmdimportant/::: {.callout-important}/g' "$file"
  fi
done
echo "  Done"
echo ""

# Step 5: Fix common chunk option issues
echo "Step 5: Fixing common chunk option patterns..."
for file in *.qmd; do
  if [ -f "$file" ]; then
    # Fix results: 'as-is' -> results: asis
    sed -i '' "s/results: 'as-is'/results: asis/g" "$file"
    sed -i '' 's/results: "as-is"/results: asis/g' "$file"

    # Fix missing space after colon (common patterns)
    sed -i '' 's/#| echo:false/#| echo: false/g' "$file"
    sed -i '' 's/#| echo:true/#| echo: true/g' "$file"
    sed -i '' 's/#| eval:false/#| eval: false/g' "$file"
    sed -i '' 's/#| eval:true/#| eval: true/g' "$file"
    sed -i '' 's/#| include:false/#| include: false/g' "$file"
    sed -i '' 's/#| include:true/#| include: true/g' "$file"
    sed -i '' 's/#| message:false/#| message: false/g' "$file"
    sed -i '' 's/#| warning:false/#| warning: false/g' "$file"
  fi
done
echo "  Done"
echo ""

echo "=== Automated conversion complete ==="
echo ""
echo "Manual steps still required:"
echo "  1. Create _quarto.yml configuration file"
echo "  2. Convert chunk options from {r opts} to #| format"
echo "  3. Add fig- prefix to figure chunk labels"
echo "  4. Add tbl- prefix to table chunk labels"
echo "  5. Move kable() captions to #| tbl-cap:"
echo "  6. Convert footnotes to inline format"
echo "  7. Add section labels {#sec-*} to headers"
echo "  8. Add '## Chapter References {.unnumbered}' to chapters with citations"
echo "  9. Test render with: quarto render --to html"
echo ""
