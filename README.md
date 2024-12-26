---
title: "README"
format: html
editor: visual

---

<!-- README.md is generated from README.qmd. Please edit that file -->

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
```

# Provider Recognition Program

### Moffitt Cancer Center - Patient Experience Department

## Overview

This is an automated sort, filter and distribution process that takes positive provider specific comments, sorts them in order of priority and then distributes to the provider in a visually appealing graphic. The steps are as follows:

-   import third party survey comments 
-   perform sentiment analysis to filter positive comments
-   extract positive comments with named provider
-   verify provider/resource match to comment names
-   use sentiment score to sort matched comments by provider
-   combine into a visual that can be sent to provider



------------------------------------------------------------------------

