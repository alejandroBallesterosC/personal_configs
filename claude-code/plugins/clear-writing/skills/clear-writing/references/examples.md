# Before and after examples

Each pair shows a fix. The "after" version is the target style.

## 1. Dashes and jargon

Before: Fresh-annotation re-scoring (cache bypassed) moved means by less than
0.004. Read for the schema: "feature fires" is a calibrated proxy for "the
property holds" at F1 of 0.94 to 0.96 for coherent features.

After: We ran the scoring again with new model calls and no caching. The
average scores changed by less than 0.004, so caching is not the cause. For
most features, the description agrees with how the feature behaves, at an F1 of
about 0.94 to 0.96.

## 2. Filler

Before: It is worth noting that the second pass actually removes quite a lot of
words, and this matters.

After: The second pass removes a lot of words.

## 3. One cramped sentence split into clear ones

Before: The groups the features were sorted into were the authors' own reading,
the example posts were written by hand, and finer detail meant training extra
small models and labeling again.

After: First, the authors sorted the features into groups themselves, based on
their own reading. Second, they wrote the example posts by hand after reading
many posts. Third, when they wanted finer detail, they trained another small
model and labeled the posts again.

## 4. Analogy removed

Before: The feature index is like a card catalog that the optimizer can flip
through.

After: The feature index is a list of named features. The optimizer looks up
which feature matches a request.

## 5. Inanimate thing doing a human action

Before: The logs become searchable records once the job finishes.

After: You can search the logs once the job finishes.

## 6. A padded group of three

Before: Configuring things is messy: random files, infinite pickers, and knobs
you didn't know existed.

After: Configuring things is messy, e.g., the settings are scattered across many
files.

## 7. Empty importance words

Before: This result matters, and it carries weight for the design.

After: As a result, the system can skip the model on most documents.

## 8. Puffery

Before: This release stands as a testament to the team and plays a pivotal role
in parsing.

After: We added streaming in this release, and other teams now use it.

## 9. An "-ing" tail that adds fake analysis

Before: The cache stores results, highlighting its value for speed.

After: The cache stores results, so repeated queries are faster.

## 10. Negative parallelism

Before: It is not just a parser, it is a full toolchain.

After: It is a parser and a formatter.

## 11. Vague attribution

Before: Experts say this approach scales well.

After: In our benchmark, this approach handled a million rows.

## 12. Elegant variation

Before: Upload the document. The file is parsed, and the record is saved.

After: Upload the document. The document is parsed and saved.

## 13. Throat-clearing and binary contrast

Before: Here's the thing: building products is hard. Not because the technology
is complex. Because people are complex. Let that sink in.

After: Building products is hard. The technology is manageable. The people are
not.

## 14. Jargon stack

Before: In today's fast-paced landscape, we need to lean into discomfort and
navigate uncertainty with clarity.

After: We need to move faster and make decisions with less information than we
want.

## 15. Rhetorical setup

Before: What if I told you that the best teams don't optimize for productivity?
Here's what I mean: they optimize for learning. Think about it.

After: The best teams optimize for learning, not for output per hour.
