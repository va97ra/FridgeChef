# FridgeChef Agent Notes

## Product Intent
- The built-in chef must develop real culinary understanding, not just the appearance of understanding.
- Do not optimize for "feels smart" by only adding more recipes, badges, or UI polish.
- The target is a chef that understands taste balance, ingredient pairings, cooking technique, and the structural logic of dishes.

## What "Real Understanding" Means In This Project
- The chef should reason about flavor balance: richness, acidity, sweetness, freshness, bitterness, spice, texture, and finish.
- The chef should reason about dish structure: what makes a soup, cold soup, salad, batter dish, fritter, bake, porridge, pasta, stew, and so on.
- The chef should reason about technique: heat, sequencing, moisture protection, binding, reduction, browning, resting, and serving temperature.
- The chef should know forbidden or weak substitutions, not only valid combinations.
- The chef should reject recipes that are technically possible but culinarily wrong.

## Implementation Priorities
- Prefer domain modeling, validators, and hard culinary constraints over simply expanding blueprint count.
- Before adding many new dishes, strengthen the chef's reasoning model if a dish family is not yet structurally understood.
- Every important dish family should have:
  - structural rules
  - required anchors
  - forbidden substitutions or failures
  - technique checks
  - finish and serving logic
- Generated recipes should pass a culinary self-check before being shown to the user.

## Russian Cuisine Direction
- Russian dishes should be modeled as real dish families, not only as isolated blueprints.
- When adding dishes like okroshka, blini, draniki, rassolnik, ukha, syrniki, and similar, encode the family rules behind them.

## Guardrails
- Do not collapse the roadmap into "add more recipes" if the chef still lacks structural understanding.
- Do not use calories/macros to drive ranking unless the user explicitly asks for that behavior.
- Nutrition in the current roadmap is display-only estimation, not decision logic.

## Validation Expectations
- Add positive tests for correct dishes.
- Add negative tests for culinarily invalid variants.
- Add regression tests when introducing new family rules or validators.
