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

### Retirer `active_support/all`

`require "active_support/all"` charge la totalité d'ActiveSupport pour deux usages :
- `HashWithIndifferentAccess` — remplaçable par un `Hash` classique avec `.to_s` sur les clés
- `namespace&.present?` — remplaçable par `namespace && !namespace.to_s.strip.empty?`

C'est une dépendance lourde pour une gem de test. La retirer réduirait significativement le temps de chargement.

**Files**: `lib/rspec_in_context.rb`, `lib/rspec_in_context/in_context.rb`, `rspec_in_context.gemspec`

- [x] Retirer `faker` — retiré de `spec_helper.rb` et `rspec_in_context.gemspec`

## P1 — Robustesse face aux internals RSpec

### Sécuriser `hooks.instance_variable_get(:@owner)`

Accès direct à une variable d'instance privée de RSpec. Si elle disparaît dans une future version, `owner` sera `nil` et les contextes scopés ne seront jamais nettoyés (silencieusement).

Ajouter un smoke test vérifiant que `@owner` n'est pas nil. Investiguer si `self` ou `self.class` pourrait servir de substitut.

**File**: `lib/rspec_in_context/in_context.rb:191`

### Sécuriser le prepend sur `RSpec::Core::ExampleGroup.subclass`

La signature `subclass(parent, description, args, registration_collection, &)` mirror l'implémentation interne de RSpec. La contrainte `"> 3.0"` est trop large pour ce niveau de couplage.

Restreindre à `"~> 3.0"` et ajouter un smoke test. Investiguer si un hook public RSpec (`after(:context)` ou similaire) pourrait remplacer le prepend.

**Files**: `lib/rspec_in_context/context_management.rb`, `rspec_in_context.gemspec`

### Resserrer les contraintes de version des dépendances

`activesupport "> 2.0"` et `rspec "> 3.0"` n'ont pas de borne supérieure. Tant qu'ActiveSupport est une dépendance, utiliser `"~> 7.0"` (ou la version minimale réellement supportée). Utiliser `"~> 3.0"` pour rspec. Mettre à jour rake vers `"~> 13.0"`.

**File**: `rspec_in_context.gemspec`

## P2 — Qualité de l'API

- [x] Ajouter `RspecInContext::Error` comme classe de base — `NoContextFound` et `AmbiguousContextName` en héritent
- [x] Retirer le `instance_exec` inutile dans `define_context`
- [x] Corriger les typos dans les commentaires (`find` → `found`, `overriden` → `overridden`, `colisions` → `collisions`)

### Corriger le gallicisme `instanciate_context`

Le mot correct en anglais est `instantiate`. Ajouter `alias instantiate_context execute_tests` et déprécier l'ancien alias avec un warning.

**File**: `lib/rspec_in_context/in_context.rb`

## P2 — Tests

### Renforcer les tests `expect(true).to be_truthy`

Beaucoup de tests utilisent `expect(true).to be_truthy` ce qui ne vérifie pas que le bloc a réellement été exécuté. Si le bloc n'est pas injecté, le `it` est simplement absent de la suite — aucun échec. Utiliser des effets de bord mesurables (compteurs, variables partagées) ou vérifier le nombre d'exemples exécutés.

**Files**: `spec/rspec_in_context/in_context_spec.rb`, `spec/rspec_in_context/context_management_spec.rb`

### Vérifier la sémantique de `test_inexisting_context`

Le refactoring appelle `self.class.in_context(...)` à l'intérieur d'un `it` (runtime) au lieu du niveau `describe` (definition-time). `in_context` est conçu pour être appelé au niveau `describe`. L'erreur sera levée dans les deux cas via `find_context`, mais le chemin de code est différent. Vérifier que c'est bien l'intention.

**File**: `spec/support/context_test_helper.rb`

## P3 — Nice to have

### Ajouter `clear_all_contexts!` pour le nettoyage mémoire

Les contextes globaux (owner nil) ne sont jamais libérés. Pour les suites de tests longues avec des contextes générés dynamiquement, les procs et leurs closures s'accumulent.

**File**: `lib/rspec_in_context/in_context.rb`

### Ajouter un Mutex autour de `@contexts`

Le registre `@contexts` est un état mutable global partagé sans synchronisation. Avec `parallel_tests` en mode thread, c'est une race condition. En mode process (le plus courant), pas de risque. À faire si des utilisateurs rapportent des problèmes en mode thread.

**File**: `lib/rspec_in_context/in_context.rb`

- [x] Corriger les typos restantes dans les commentaires — fait avec les fixes P2

### Section migration dans le README

Les utilisateurs upgrading de 1.1.x à 1.2.0 bénéficieraient d'une section expliquant les breaking changes (`AmbiguousContextName`, Ruby >= 3.2).

**File**: `README.md`
