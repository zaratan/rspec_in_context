# TODO

Issues identified during review of the codebase and PR #21.

## PR #21 — Resolved

- [x] Stack leak if `find_context` raises — moved `find_context` before `push`
- [x] Indentation of `spec.metadata` in gemspec — fixed by prettier
- [ ] `.ruby-version` 4.0.1 vs CI matrix — `head` covers it, revisit if contributor confusion arises

## P0 — Before merge

- [x] Quote prettier globs in CI — quoted `'lib/**/*.rb'` etc. in both workflow files
- [x] Gitignore `.rubocop-remote-*.yml` — added pattern to `.gitignore`

## P1 — Réduction des dépendances

- [x] Retirer `active_support/all` — remplacé `HashWithIndifferentAccess` par `Hash` avec `.to_s` sur les clés, retiré `present?`. Temps de boot des tests : 0.27s → 0.08s
- [x] Retirer `faker` — retiré de `spec_helper.rb` et `rspec_in_context.gemspec`

## P1 — Robustesse face aux internals RSpec

- [x] Smoke test pour `hooks.instance_variable_get(:@owner)` — vérifie que `@owner` est non-nil et est une Class
- [x] Smoke test pour le prepend de `ContextManagement` sur `ExampleGroup.subclass`
- [x] Resserrer les contraintes de version — `rspec "~> 3.0"`, `rake "~> 13.0"`, `activesupport` retiré

## P2 — Qualité de l'API

- [x] Ajouter `RspecInContext::Error` comme classe de base — `NoContextFound` et `AmbiguousContextName` en héritent
- [x] Retirer le `instance_exec` inutile dans `define_context`
- [x] Corriger les typos dans les commentaires (`find` → `found`, `overriden` → `overridden`, `colisions` → `collisions`)
- [x] Corriger `instanciate_context` — ajouté `instantiate_context` comme alias principal, l'ancien émet un deprecation warning

## P2 — Tests

- [x] Renforcer les tests — block delivery guard dynamique (voir `spec/support/block_delivery_guard.rb`) détecte les blocs non-consommés et les groupes vides. Les `expect(true).to be_truthy` restants sont acceptables car le guard couvre la disparition silencieuse.
- [x] Sémantique de `test_inexisting_context` — vérifiée et documentée. Appelle `find_context` au runtime, qui est la première opération de `in_context`. Le comportement est identique.

## P3 — Nice to have

- [x] Ajouter `clear_all_contexts!` pour le nettoyage mémoire — `RspecInContext::InContext.clear_all_contexts!` réinitialise le registre. Test ajouté avec sauvegarde/restauration du state.
- [x] Ajouter un Mutex autour de `@contexts` — `@contexts_mutex` protège l'initialisation et le clear. Thread-safe pour `parallel_tests` en mode thread.
- [x] Corriger les typos restantes dans les commentaires — fait avec les fixes P2
- [x] Section migration dans le README — section "Migrating to 1.2.0" ajoutée avec breaking changes, deprecations, et nouvelles features. Mise à jour de la mention `instanciate_context` → `instantiate_context`.
