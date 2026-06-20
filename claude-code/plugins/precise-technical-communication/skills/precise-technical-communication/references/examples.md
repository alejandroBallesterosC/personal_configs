# Examples

The examples use invented data. They show the required level of context and evidence.

## Example 1: Summary experiment result

### Compressed version

Seven of ten baskets fail OOS. Only two are robust.

### Precise version

I evaluated ten synthetic baskets named B1 through B10. I built each basket from the five assets with the highest trailing 12 month return at its construction date. I used January 2022 through December 2023 to construct and tune the baskets. I used January through June 2024 as the final test period. I did not use that period to select assets or thresholds.

For this test, a basket met the criterion when both of these conditions were true:

1. Its total return in the final test period was above 0%.
2. Its maximum loss from a peak to a later low was below 15%.

| Basket | Return in final period | Maximum loss | Result and reason |
| --- | ---: | ---: | --- |
| B1 | 4.1% | 11.0% | Met both criteria. |
| B2 | 2.8% | 9.4% | Met both criteria. |
| B3 | 1.2% | 17.3% | Missed the loss criterion. |
| B4 | -0.8% | 8.2% | Missed the return criterion. |
| B5 | -3.1% | 18.5% | Missed both criteria. |
| B6 | 0.6% | 16.1% | Missed the loss criterion. |
| B7 | -1.4% | 12.7% | Missed the return criterion. |
| B8 | 3.0% | 15.8% | Missed the loss criterion. |
| B9 | -0.2% | 10.1% | Missed the return criterion. |
| B10 | 1.9% | 14.2% | Met both criteria. |

Three baskets met the stated criterion: B1, B2, and B10. Seven missed at least one part of it: B3 through B9.

I have not called any basket "robust" because this test used one six month final test period. To support that claim, I would also test several separate periods and report how sensitive the result is to the construction date, asset universe, and threshold choices.

## Example 2: Implementation summary

### Compressed version

Fixed the authentication race and added robust retry handling.

### Precise version

I changed `src/auth/session.ts` in `refreshSession` and added tests in `src/auth/session.test.ts`.

Before the change, two requests that saw the same expired token could both start a refresh request. The response that finished last overwrote the token stored by the other request, even when it contained an older expiry time.

The new code stores one active refresh promise per session. Requests for the same session now wait for that promise instead of starting another refresh. The code removes the stored promise after success or failure, so a later request can try again.

The retry rule now applies only to network timeouts and HTTP 502, 503, and 504 responses. It makes at most two additional attempts with delays of 100 ms and 300 ms. It does not retry HTTP 400 or 401 responses because another attempt with the same request would not correct those responses.

Verification performed:

1. `pnpm test src/auth/session.test.ts` passed 14 tests.
2. The new concurrency test started two refresh calls and confirmed that the mock server received one request.
3. The retry tests confirmed three total attempts for a 503 response and one attempt for a 401 response.

I did not run the full browser integration suite. The remaining risk is code outside `refreshSession` that writes the same token store without using the shared promise.

## Example 3: Codebase explanation

### Compressed version

The import pipeline normalizes the payload and fans out to workers.

### Precise version

A request enters the import path at `POST /imports`, which is registered in `src/routes/imports.ts`.

1. `createImport` reads the uploaded file and calls `validateHeaders`. This rejects files that omit `account_id` or `amount`.
2. `normalizeRows` converts `amount` to integer cents, trims surrounding spaces from `account_id`, and records validation errors for each row.
3. `saveImport` writes one import record and the accepted rows in the same database transaction.
4. After the transaction commits, `enqueueImportBatches` splits accepted row identifiers into batches of 500 and publishes one `ProcessImportBatch` job per batch.
5. A worker handles each job in `src/workers/processImportBatch.ts`. It loads the rows, writes account updates, and marks the batch complete.
6. `finalizeImport` marks the whole import complete only after every batch is complete. If any batch reaches its retry limit, it marks the import failed and stores the batch error.

The term "fan out" would hide two details that affect behavior: the batch size is 500, and jobs start only after the database transaction commits.

I inferred this flow from the route, service, and worker code. I did not run an import or inspect the queue configuration, so I did not verify the number of concurrent workers or the delay between retries.

## Example 4: Search result and uncertainty

### Compressed version

Nothing uses the legacy flag.

### Precise version

I searched the tracked files in this repository with `rg "LEGACY_FLAG|legacyFlag|getLegacyFlag"`. I also inspected the environment loader in `src/config/env.ts` and the feature flag wrapper in `src/flags/index.ts`.

I found the flag declaration in `src/config/env.ts`, but I found no code that reads the resulting `legacyFlag` value. This supports removing the declaration from this repository.

This search does not rule out references in deployment configuration, generated files excluded from version control, or another repository. I did not inspect those sources.

## Example 5: Benchmark claim

### Compressed version

The new parser is significantly faster and more stable.

### Precise version

I compared parser version 2.3.0 with version 2.4.0 on the same 10,000 JSON documents. Each document was between 4 KB and 64 KB. I ran both versions with Node.js 24.1.0 on the same machine, used five warmup runs, then measured 30 runs.

Version 2.3.0 had a median time of 842 ms and a 95th percentile time of 901 ms. Version 2.4.0 had a median time of 617 ms and a 95th percentile time of 654 ms. The median decreased by 225 ms, or 26.7%, under this setup.

The standard deviation between runs was 19 ms for version 2.3.0 and 17 ms for version 2.4.0. That difference is small relative to the total runtime. I would not describe it as evidence of greater stability without more runs under variable system load.

I did not measure memory use, malformed input, or files larger than 64 KB. The result applies only to the tested document sizes and machine.
