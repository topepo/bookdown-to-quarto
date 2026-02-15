# Bookdown to Quarto Conversion Guide

Based on the [TMwR](https://www.tmwr.org/) and [FES](https://www.feat.engineering/) conversion experiences, this guide provides a systematic approach to converting bookdown books to Quarto format.

## Overview

The conversion process involves these major steps:
1. Create `_quarto.yml` configuration
2. Rename `.Rmd` files to `.qmd`
3. Convert cross-references
4. Convert chunk options to hashpipe format
5. Convert custom blocks to callouts
6. Convert footnotes to inline format
7. Fix table labels and captions
8. Add section labels for cross-references
9. Add chapter references sections
10. Handle common errors

---

## Step 1: Create `_quarto.yml`

Replace `_bookdown.yml` and `_output.yaml` with a single `_quarto.yml` file.

### Template

```yaml
project:
  type: book

book:
  title: "Book Title"
  author:
    - Author Name
  date: today
  repo-url: https://github.com/org/repo
  repo-actions: [edit]
  chapters:
    - index.qmd
    - part: "Part Name"
      chapters:
        - 01-chapter.qmd
        - 02-chapter.qmd
  appendices:
    - appendix.qmd
    - references.qmd

bibliography: references.bib

execute:
  freeze: auto

format:
  html:
    theme: cosmo
    css: [style.css]
    toc-depth: 2
```

### Key mappings from bookdown

| bookdown (`_bookdown.yml`) | Quarto (`_quarto.yml`) |
|---------------------------|------------------------|
| `book_filename` | `book: title` |
| `rmd_files` | `book: chapters` |
| `before_chapter_script` | Use `source()` in each chapter |
| `output_dir` | Defaults to `_book` |

---

## Step 2: Rename Files

```bash
# Rename all .Rmd files to .qmd
for f in *.Rmd; do
  mv "$f" "${f%.Rmd}.qmd"
done
```

---

## Step 3: Convert Cross-References

### Patterns to convert

| Bookdown | Quarto |
|----------|--------|
| `\@ref(fig:name)` | `@fig-name` |
| `\@ref(tab:name)` | `@tbl-name` |
| `\@ref(eq:name)` | `@eq-name` |
| `\@ref(section-id)` | `@sec-section-id` |

### Conversion script

```bash
# Run from book directory
for file in *.qmd; do
  # Convert figure references
  sed -i '' 's/\\@ref(fig:\([^)]*\))/@fig-\1/g' "$file"

  # Convert table references
  sed -i '' 's/\\@ref(tab:\([^)]*\))/@tbl-\1/g' "$file"

  # Convert equation references
  sed -i '' 's/\\@ref(eq:\([^)]*\))/@eq-\1/g' "$file"

  # Convert section references (add sec- prefix)
  sed -i '' 's/\\@ref(\([^)]*\))/@sec-\1/g' "$file"
done
```

### Remove redundant prefixes

After conversion, search for and fix redundant patterns:
- `Figure @fig-` → `@fig-`
- `Table @tbl-` → `@tbl-`
- `Chapter @sec-` → `@sec-`
- `Section @sec-` → `@sec-`

```bash
for file in *.qmd; do
  sed -i '' 's/Figure @fig-/@fig-/g' "$file"
  sed -i '' 's/Table @tbl-/@tbl-/g' "$file"
  sed -i '' 's/Chapter @sec-/@sec-/g' "$file"
  sed -i '' 's/Section @sec-/@sec-/g' "$file"
done
```

---

## Step 4: Convert Chunk Options

Convert from knitr-style to hashpipe format.

### Before (bookdown)
````
```{r chunk-name, fig.cap="Caption", echo=FALSE, fig.width=8}
code
```
````

### After (Quarto)
````
```{r}
#| label: fig-chunk-name
#| fig-cap: "Caption"
#| echo: false
#| fig-width: 8
code
```
````

### Key option conversions

| knitr | Quarto hashpipe |
|-------|-----------------|
| `fig.cap` | `fig-cap` |
| `fig.width` | `fig-width` |
| `fig.height` | `fig-height` |
| `out.width` | `out-width` |
| `results='asis'` | `results: asis` |
| `results='hide'` | `results: hide` |
| `message=FALSE` | `message: false` |
| `warning=FALSE` | `warning: false` |
| `echo=FALSE` | `echo: false` |
| `eval=FALSE` | `eval: false` |
| `include=FALSE` | `include: false` |
| `cache=TRUE` | `cache: true` |

### Important notes

1. **Use dashes, not dots**: `fig-cap` not `fig.cap`
2. **Lowercase booleans**: `false` not `FALSE`
3. **No quotes on booleans**: `echo: false` not `echo: "false"`
4. **Quotes on strings**: `fig-cap: "My caption"`
5. **No trailing commas**
6. **No blank lines** between hashpipe options

### Figure labels

Any chunk with `fig-cap` should have a label starting with `fig-`:

```r
#| label: fig-my-plot
#| fig-cap: "Description of the plot"
```

---

## Step 5: Convert Custom Blocks to Callouts

### Common conversions

| Bookdown | Quarto |
|----------|--------|
| `:::rmdnote` | `::: {.callout-note}` |
| `:::rmdwarning` | `::: {.callout-warning}` |
| `:::rmdtip` | `::: {.callout-tip}` |
| `:::rmdcaution` | `::: {.callout-caution}` |
| `:::rmdimportant` | `::: {.callout-important}` |

### Conversion script

```bash
for file in *.qmd; do
  sed -i '' 's/:::rmdnote/::: {.callout-note}/g' "$file"
  sed -i '' 's/:::rmdwarning/::: {.callout-warning}/g' "$file"
  sed -i '' 's/:::rmdtip/::: {.callout-tip}/g' "$file"
  sed -i '' 's/:::rstudio-tip/::: {.callout-tip}/g' "$file"
  sed -i '' 's/:::rmdcaution/::: {.callout-caution}/g' "$file"
  sed -i '' 's/:::rmdimportant/::: {.callout-important}/g' "$file"
done
```

---

## Step 6: Convert Footnotes

Convert traditional footnotes to inline format.

### Before
```markdown
Some text[^footnote-id]

[^footnote-id]: The footnote content here.
```

### After
```markdown
Some text^[The footnote content here.]
```

### Finding footnotes

```bash
# Find footnote definitions
grep -n '\[\^[a-zA-Z0-9_-]*\]:' *.qmd

# Find footnote references
grep -n '\[\^[a-zA-Z0-9_-]*\][^:]' *.qmd
```

This conversion must be done manually or with careful scripting since each footnote reference must be replaced with the actual content.

---

## Step 7: Fix Table Labels and Captions

Tables created with `kable()` need proper Quarto labeling.

### Before
```r
kable(data,
  caption = "Table caption",
  label = "my-table"
)
```

### After
```r
#| label: tbl-my-table
#| tbl-cap: "Table caption"

kable(data)
```

### Steps

1. Change chunk label to start with `tbl-`
2. Add `#| tbl-cap: "Caption text"`
3. Remove `caption` and `label` arguments from `kable()`

---

## Step 8: Add Section Labels

For section cross-references to work, headers need labels.

### Adding labels to headers

```markdown
## Section Title {#sec-section-title}

### Subsection Title {#sec-subsection-title}
```

### Finding missing labels

After rendering, check warnings for unresolved `@sec-*` references, then add the corresponding labels to section headers.

---

## Step 9: Add Chapter References

For chapters with citations, add at the end:

```markdown
## Chapter References {.unnumbered}
```

### Finding chapters with citations

```bash
grep -l '@[a-z]*[0-9]\{4\}' *.qmd
```

---

## Step 10: Common Errors and Fixes

### Error: `results: 'as-is'` invalid
**Fix**: Change to `results: asis` (no quotes, no hyphen)

### Error: Duplicate chunk labels
**Fix**: Ensure each chunk has a unique label

### Error: Missing space after colon in hashpipe
**Fix**: `#| echo:false` → `#| echo: false`

### Error: `ref-label` not supported
**Fix**: Quarto doesn't support `ref-label`. Duplicate the code from the referenced chunk.

### Error: Package not found
**Fix**: Ensure all required packages are installed. Check setup chunks.

---

## Conversion Checklist

- [ ] Create `_quarto.yml` from `_bookdown.yml` and `_output.yaml`
- [ ] Rename `.Rmd` → `.qmd`
- [ ] Convert `\@ref()` cross-references to `@` format
- [ ] Remove redundant cross-reference prefixes
- [ ] Convert chunk options to hashpipe format
- [ ] Add `fig-` prefix to figure chunk labels
- [ ] Add `tbl-` prefix to table chunk labels
- [ ] Convert custom blocks to callouts
- [ ] Convert footnotes to inline format
- [ ] Add section labels (`{#sec-*}`) to headers
- [ ] Move kable captions to `#| tbl-cap:`
- [ ] Add `## Chapter References {.unnumbered}` sections
- [ ] Update `.gitignore` (add `/.quarto/`, `/_book/`)
- [ ] Test render: `quarto render --to html`
- [ ] Fix any remaining warnings
- [ ] Delete old files: `_bookdown.yml`, `_output.yaml`

---

## Files to Keep Unchanged

- `_common.R` or similar setup scripts
- CSS files (may need minor updates for callouts)
- Bibliography files (`.bib`)
- Image files
- LaTeX preamble files
- Cached RData files (unless causing issues)
