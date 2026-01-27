# TODO — Review architecturale

Issues identifiées lors d'une review critique exhaustive du code.

## CRITIQUE

### 1. Ajouter un Mutex autour de @contexts

Le registre `@contexts` est un état mutable global partagé entre threads sans synchronisation. `add_context`, `remove_context`, `find_context` lisent et écrivent sans mutex. Avec `parallel_tests` en mode thread, c'est une race condition garantie.

**Solution**: Ajouter un `Mutex` autour de toutes les opérations sur `@contexts`, ou utiliser `Concurrent::Map`.

**Fichier**: `lib/rspec_in_context/in_context.rb`

### 2. Sécuriser l'accès à hooks.instance_variable_get(:@owner)

Accès à une variable d'instance interne de RSpec. Si ça disparaît dans une future version, `owner` sera `nil` et les contextes scoped ne seront plus jamais nettoyés (silencieusement).

**Solution**: Ajouter un test de smoke vérifiant que `@owner` n'est pas nil. Investiguer si `self` ou `self.class` pourrait servir de substitut.

**Fichier**: `lib/rspec_in_context/in_context.rb:191`

### 3. Sécuriser le prepend sur RSpec::Core::ExampleGroup.subclass

La signature `subclass(parent, description, args, registration_collection, &)` est calquée sur l'implémentation interne de RSpec. La contrainte `"> 3.0"` est trop laxiste pour ce niveau de couplage.

**Solution**: Restreindre à `"~> 3.0"` et ajouter un test de smoke. Investiguer si un hook public RSpec (`after(:context)` ou similaire) pourrait remplacer le prepend.

**Fichiers**: `lib/rspec_in_context/context_management.rb`, `rspec_in_context.gemspec`

## MAJEUR

### 4. Supprimer la dépendance ActiveSupport

`require "active_support/all"` charge TOUT ActiveSupport pour seulement :
- `HashWithIndifferentAccess`
- Un seul appel à `present?` (`namespace&.present?`)

`present?` → `namespace && !namespace.to_s.strip.empty?`
`HashWithIndifferentAccess` → Hash normal avec `.to_s` sur les clés.

**Fichiers**: `lib/rspec_in_context.rb`, `lib/rspec_in_context/in_context.rb`, `rspec_in_context.gemspec`

### 5. Corriger la typo instanciate_context → instantiate_context

Gallicisme dans l'API publique. Le mot correct est `instantiate`.

**Solution**: Ajouter `alias instantiate_context execute_tests` en parallèle. Garder l'ancien alias avec un avertissement de dépréciation.

**Fichier**: `lib/rspec_in_context/in_context.rb`

### 6. Améliorer les tests pour vérifier l'exécution réelle des blocs

Beaucoup de tests utilisent `expect(true).to be_truthy` qui ne vérifient pas que le bloc a réellement été exécuté. Si le bloc n'est pas injecté, le test est simplement absent — pas de failure.

**Solution**: Utiliser des side effects mesurables (compteurs, variables) pour vérifier que les blocs sont réellement exécutés.

**Fichiers**: `spec/rspec_in_context/in_context_spec.rb`, `spec/rspec_in_context/context_management_spec.rb`

### 7. Ajouter clear_all_contexts! pour le nettoyage mémoire

Les contextes globaux (owner nil) ne sont jamais libérés. Pour les suites longues avec des contextes dynamiques, les procs et closures s'accumulent.

**Solution**: Ajouter `RspecInContext::InContext.clear_all_contexts!` et éventuellement l'appeler en `after(:suite)`.

**Fichier**: `lib/rspec_in_context/in_context.rb`

### 8. Resserrer les contraintes de versions des dépendances

`activesupport "> 2.0"` et `rspec "> 3.0"` sont sans borne supérieure. Utiliser `"~>"` pour les dépendances principales. Mettre à jour rake vers `"~> 13.0"`.

**Fichier**: `rspec_in_context.gemspec`

## MINEUR

### 9. Ajouter une classe d'exception de base RspecInContext::Error

Impossible de `rescue RspecInContext::Error` pour attraper toutes les erreurs de la gem. Ajouter `class Error < StandardError; end` et faire hériter `NoContextFound` et `AmbiguousContextName`.

**Fichier**: `lib/rspec_in_context/in_context.rb`

### 10. Supprimer le instance_exec inutile dans define_context

Le `instance_exec do ... end` dans `define_context` (ClassMethods) ne sert à rien car `hooks` est déjà accessible directement.

**Fichier**: `lib/rspec_in_context/in_context.rb:188-196`

### 11. Supprimer faker des dépendances

`faker` est require dans `spec_helper.rb` mais jamais utilisé dans les tests. Code mort.

**Fichiers**: `spec/spec_helper.rb`, `rspec_in_context.gemspec`

## COSMÉTIQUE

### 12. Corriger les typos dans les commentaires

- "find" → "found", "eventualy" → "eventually" (ligne 5 in_context.rb)
- "colisions" → "collisions" (commentaire de namespace)

**Fichier**: `lib/rspec_in_context/in_context.rb`
