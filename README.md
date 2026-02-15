# bookdown-to-quarto

These files are a starting point to convert [bookdown](https://bookdown.org/) projects to [Quarto](https://quarto.org/) books.

The files are: 

 - `CONVERSION_GUIDE.md`: the summary of the process used to convert two of my books. This is a good place to start with Claude in `/plan` mode. 
 - `convert_bookdown_to_quarto.sh`: bash file for the project. 
 - `convert_chunk_options.R`: R code to handle the old option format to use yaml arguments. 
 - `test_chunks.qmd`: an example file to test `convert_chunk_options.R` (see results below).
 
For example: 

```r
source("convert_chunk_options.R")
## 
## ── Analyzing chunk options ────────────────────────────────────────────────────────────────────────────────
## ℹ Scanning 1 '.qmd' files in '.'
## ℹ Found 6 total R chunks
## ! Found 4 chunks needing conversion
## ───────────────────────────────────────────────────────────────────────────────────────────────────────────
## 
## ── 'test_chunks.qmd' (line 5) ──
## 
## Original:
## ```{r setup, include=FALSE}
## Convert to:
## ```{r}
## #| label: setup
## #| include: false
## ───────────────────────────────────────────────────────────────────────────────────────────────────────────
## 
## ── 'test_chunks.qmd' (line 9) ──
## 
## Original:
## ```{r my-plot, fig.cap="A sample plot", fig.width=8, fig.height=6}
## Convert to:
## ```{r}
## #| label: fig-my-plot
## #| fig-cap: "A sample plot"
## #| fig-width: 8
## #| fig-height: 6
## ───────────────────────────────────────────────────────────────────────────────────────────────────────────
## 
## ── 'test_chunks.qmd' (line 13) ──
## 
## Original:
## ```{r data-table, echo=FALSE, results='asis'}
## Convert to:
## ```{r}
## #| label: data-table
## #| echo: false
## #| results: 'asis'
## ───────────────────────────────────────────────────────────────────────────────────────────────────────────
## 
## ── 'test_chunks.qmd' (line 17) ──
## 
## Original:
## ```{r another-figure, fig.cap="Another figure", fig.alt="Alt text here", warning=FALSE, message=FALSE}
## Convert to:
## ```{r}
## #| label: fig-another-figure
## #| fig-cap: "Another figure"
## #| fig-alt: "Alt text here"
## #| warning: false
## #| message: false
## 
## ── Summary ────────────────────────────────────────────────────────────────────────────────────────────────
## 1 file with chunks to convert:
## • 'test_chunks.qmd': 4 chunks
```
