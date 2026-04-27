# Principles For Prompting Lower-End Models

Use these principles when delegating implementation work to smaller or less reliable models, especially for multi-phase features with behavioral requirements.

## Principle 1: Use a structured prompt skeleton every time

Do not hand lower-end models a loose paragraph and expect consistent implementation. Structure the prompt with explicit sections:

- `ROLE`: what kind of engineer or designer the model should act as
- `TASK`: what to build or change
- `CONTEXT`: stack, files, environment, current architecture
- `INPUTS / OUTPUTS`: what data comes in and what artifacts must come out
- `CONSTRAINTS`: behavioral, style, performance, and architectural rules
- `OUTPUT FORMAT`: what the model should return at the end
- `VERIFICATION`: what checks it must run before stopping

Treat the prompt as the model's memory. If a rule matters, it must appear in the prompt body, not just in your head.

## Principle 2: Define the goal first, then the details

Start with one short statement of the actual goal before listing implementation detail. Lower-end models drift when they see mechanics before purpose.

Good pattern:

- goal: "make the recents area compact, thumbnail-led, and visually close to the Canva reference"
- then: file list, constraints, actions, and verification

This keeps the model oriented when it hits ambiguity.

## Principle 3: Convert product goals into explicit acceptance rules

Do not rely on the model to infer user-story behavior from architecture alone. State concrete rules such as:

- explicit private save must trigger thumbnail generation immediately
- autosave must not trigger immediate generation
- normal in-app navigation away from the editor must send an exit signal
- browser close must still lead to eventual thumbnail generation from the latest persisted draft

Require the model to verify each rule against the final code before stopping.

## Principle 4: Reduce ambiguity to one meaning per instruction

Avoid prompts where one sentence can be read multiple ways. If a requirement could be interpreted differently, rewrite it.

Examples:

- instead of "handle exits," say "send an exit signal on normal in-app navigation, `beforeunload`, and `pagehide`"
- instead of "support thumbnails," say "generate, persist, and surface thumbnails in the private and premade dashboards"

One instruction should imply one implementation target.

## Principle 5: Mark non-negotiable behaviors as hard constraints

When one implementation shortcut would silently violate the product goal, forbid it directly. Use phrases like:

- do not depend solely on `beforeunload`
- do not build a simplified parallel renderer unless it matches the live output closely enough to be visually interchangeable
- do not stop at backend generation if the UI still cannot surface the generated thumbnail

This reduces the chance that the model treats critical details as optional.

## Principle 6: Specify the source of truth and the derived artifacts separately

State both of these explicitly:

- `scene` JSON remains the source of truth
- thumbnail images are cached derivatives

Then list the derived-artifact obligations:

- when the derivative becomes stale
- when it must regenerate
- where it is stored
- where it is surfaced in the UI

Lower-end models often implement only the storage half unless the display half is named as a separate requirement.

## Principle 7: Require fidelity rules, not just "same data"

If the implementation must visually match an existing renderer, do not only say "use the same scene data." Also say:

- preserve the same aspect ratio as the real thumbnail surface
- preserve the same positioning math
- preserve the same background assets
- preserve the same frame masking behavior
- preserve slider rendering closely enough for side-by-side comparison

If exact renderer reuse is not possible, require the model to document every intentional approximation.

## Principle 8: Separate trigger cases and make the matrix executable

Spell out each trigger independently:

- autosave
- manual draft save
- manual template save
- clean editor exit
- crash or abandoned session timeout

For each trigger, state:

- whether scene data is persisted
- whether heartbeat is updated
- whether thumbnail is marked stale
- whether generation happens immediately, is deferred, or is skipped

Lower-end models are prone to implementing only the first and most obvious trigger cases.

## Principle 9: Break complex work into explicit phases

Do not ask for "the full feature" in one undifferentiated block. Decompose it into phases or ordered tasks such as:

1. schema
2. backend mapping
3. save-flow wiring
4. generation orchestration
5. UI surfacing
6. verification

Each phase should have its own deliverable and checks. Lower-end models perform better when the sequence is manual and explicit.

## Principle 10: Force the model to wire end-to-end, not layer-by-layer

After describing backend work, add a separate requirement to prove the behavior is visible to users. For example:

- if private thumbnails are generated, the private dashboard must load enough template data to render them
- if a new template field is added, schema, repository mapping, backend contracts, frontend contracts, and UI consumers must all be updated

This prevents "backend complete, user experience incomplete" drift.

## Principle 11: State constraints explicitly, including style and output constraints

Lower-end models need explicit constraints, not implied taste. State things like:

- no external libraries
- preserve existing behavior
- no extra abstractions
- minimal copy
- no oversized empty containers
- return only code changes plus verification summary

If output shape matters, control it directly.

## Principle 12: Use examples when visual or structural taste matters

If the target resembles a known reference, say what specifically should be borrowed from it.

Examples:

- "like Canva Recents: thumbnail-first, compact, light, low-copy"
- "not like the current layout: oversized cards with empty whitespace"

If useful, provide:

- one good example
- one bad example
- one list of transferable characteristics

## Principle 13: Require negative checks against the likely shortcuts

Add a short "must not" list based on the most likely failures:

- must not rely only on browser unload events
- must not leave `thumbnail_updated_at` unwritten
- must not generate landscape snapshots for portrait thumbnail slots
- must not show only template ids where thumbnails are expected
- must not simplify slider output to a single flat image without calling that out

Lower-end models often need help recognizing the dangerous shortcuts before they take them.

## Principle 14: Ask for an implementation checklist at the end of each phase

Require a short self-audit after each phase:

- what user behavior is now satisfied
- what is still intentionally deferred
- what verification was run
- what assumptions remain

This makes it harder for the model to move on with half-finished work.

## Principle 15: Make verification behavior-based, not just compile-based

Do not accept only build and typecheck success. Require checks like:

- explicit save causes thumbnail generation
- stale draft is regenerated after heartbeat timeout
- private template cards display stored thumbnails when ready
- generated image matches the portrait thumbnail surface

Compile success is necessary, but it does not protect against behavioral drift.

## Principle 16: Ask the model to verify, not just generate

Prompt the model to do both:

- generate the implementation
- verify the implementation against requirements

Useful requirements:

- name any requirement still partial
- list likely regressions
- identify unverified runtime assumptions

This increases reliability more than asking for code alone.

## Principle 17: Tell the model to compare the final code back to the user story

End the prompt with a mandatory final step:

- reread the user story
- list each scenario
- confirm where in code each scenario is satisfied
- name any scenario that is still partial or assumed

This is one of the most effective ways to catch "architecturally plausible but behaviorally incomplete" implementations.

## Principle 18: Call out inherited shared styles that must be removed or replaced

Lower-end models often keep heavyweight wrapper classes because they already exist, even when those classes directly conflict with the target design. If the brief depends on visual restraint, name the inherited styles that must not survive.

Examples:

- remove `panel` shells from the recents area if they create dashboard chrome
- do not keep primary CTA button styles on every card action if the target is lightweight browsing
- replace old layout wrappers instead of piling overrides on top of them

Say explicitly whether the model should delete, replace, or narrowly override the inherited style.

## Principle 19: Require screenshot-based comparison, not just rule-following

When the target comes from a visual reference, require the model to compare its result against the screenshot and name the remaining impurities before stopping.

Useful checks:

- what still feels heavier, louder, or more crowded than the reference
- which container, button, or spacing treatment is still breaking the intended mood
- whether the first viewport reads the same way as the reference at a glance

This catches cases where the model technically satisfies the layout instructions but the page still feels wrong.

## Principle 20: Force a first-impression check for the top of the page

If the user wants a new top-of-page hierarchy, do not let the model keep an older hero, overview, or marketing block above the requested content unless the prompt explicitly allows it.

State this directly:

- the requested surface must appear in the first viewport
- older hero content must move below it, collapse into a toolbar, or be removed
- success is judged by the first impression, not by whether the new section exists somewhere higher than before

This is especially important for dashboard and library pages where one leftover hero can undo the whole redesign.
