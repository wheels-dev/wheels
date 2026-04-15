# Wheels vs Rails / Laravel / Django

A systemwide feature comparison of Wheels 4.0 against Rails 8, Laravel 12, and Django 5.

---

## 1. ORM & Data Layer

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| ActiveRecord pattern | Yes | Yes | Yes (Eloquent) | No (Data Mapper) |
| Chainable query builder | `where().orderBy().limit().get()` | `where().order().limit()` | `where()->orderBy()->get()` | `filter().order_by()[:n]` |
| Named scopes | `scope(name, where/handler)` | `scope :name, -> {}` | `scopeName()` | `Manager` methods |
| Associations | hasMany/belongsTo/hasOne (+ polymorphic) | has_many/belongs_to/has_one/HABTM | hasMany/belongsTo/hasOne/belongsToMany | ForeignKey/ManyToMany/OneToOne |
| Polymorphic associations | `belongsTo(polymorphic=true)` + `hasMany(as=)` | `belongs_to :x, polymorphic: true` | `morphTo`/`morphMany` | `GenericForeignKey` (contrib) |
| Through/shortcut assoc | hasMany(shortcut/through) | has_many :through | hasManyThrough | Through models |
| Eager loading | `include="assoc"` | `.includes(:assoc)` | `::with('assoc')` | `select_related/prefetch_related` |
| Batch processing | findEach/findInBatches | find_each/find_in_batches | chunk/chunkById/lazy | iterator() |
| Bulk insert/upsert | `insertAll(records)` / `upsertAll(records, uniqueBy)` | `insert_all` / `upsert_all` | `upsert([...], unique)` | `bulk_create` / `bulk_update` |
| Advisory locks | `withAdvisoryLock(name, callback)` | Via gem (with_advisory_lock) | No native | No native |
| Pessimistic locking | `.forUpdate()` on QueryBuilder | `.lock("FOR UPDATE")` | `->lockForUpdate()` | `.select_for_update()` |
| Dirty tracking | hasChanged/changedFrom/changes | changed?/changes | isDirty/getOriginal | No built-in |
| Soft deletes | Built-in (column flag) | Via gem (paranoia/discard) | Built-in (SoftDeletes trait) | Via package (django-safedelete) |
| Enums | `enum(property, values)` + auto scopes/checkers | `enum :status, {}` | `$casts['status'] = Enum` | `TextChoices/IntegerChoices` |
| Calculated properties | `property(sql="...")` | No direct equiv | `selectRaw/withCasts` | `annotate()` |
| Composite PKs | Yes | Rails 7.1+ | No native | Yes |
| Pagination | `findAll(page, perPage)` | Via gem (kaminari/pagy) | `->paginate()` | `Paginator` |
| Transactions | `invokeWithTransaction` | `ActiveRecord::Base.transaction` | `DB::transaction` | `transaction.atomic()` |
| Mass assignment protection | accessibleProperties/protectedProperties | strong_parameters | $fillable/$guarded | No (forms handle it) |
| Aggregations | sum/avg/min/max/count with group | sum/average/minimum/maximum/count | sum/avg/min/max/count | aggregate(Sum/Avg/...) |
| Parameterized queries | Auto (cfqueryparam) | Auto (bind params) | Auto (PDO binds) | Auto (parameterized) |
| Multi-database | Yes (per-model datasource) | Rails 6+ (multi-db) | Yes (connections) | Yes (database routers) |
| Return formats | objects/structs/query/sql | objects only | objects/arrays | QuerySets |
| Nested properties | nestedProperties(autoSave) | accepts_nested_attributes_for | No native (Livewire) | Inline formsets |
| Database support | MySQL, PostgreSQL, MSSQL, SQLite, H2, CockroachDB, Oracle | PostgreSQL, MySQL, SQLite, Trilogy | MySQL, PostgreSQL, SQLite, SQL Server | PostgreSQL, MySQL, SQLite, Oracle, MariaDB |

**Wheels strengths:** Built-in soft deletes, enum auto-scopes/checkers, multi-return formats (objects/structs/query/sql), calculated properties via SQL, polymorphic associations, bulk insert/upsert with per-DB UPSERT syntax, advisory locks (where supported), 7 database adapters including CockroachDB and H2.

---

## 2. Migrations

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Schema DSL | createTable/changeTable/addColumn | create_table/change_table/add_column | Schema::create/table | models auto-migrate |
| Up/Down | Yes | Yes | Yes (up/down) | Forward-only (auto) |
| Column types | string, text, integer, biginteger, boolean, datetime, date, time, decimal, float, binary, uuid, reference | 20+ types | 30+ types | 20+ field types |
| Timestamps helper | `t.timestamps()` creates createdAt/updatedAt | `t.timestamps` creates created_at/updated_at | `$table->timestamps()` | `auto_now/auto_now_add` |
| Indexes | addIndex/removeIndex | add_index/remove_index | index/dropIndex | db_index=True |
| Foreign keys | addForeignKey/dropForeignKey | add_foreign_key | foreign/foreignId | ForeignKey auto |
| Raw SQL | `execute("SQL")` | `execute("SQL")` | `DB::statement("SQL")` | `RunSQL("SQL")` |
| Auto-generation | Via CLI generators + `AutoMigrator` (model→DB schema diff + rename detection) | Via CLI generators | Via CLI generators | `makemigrations` (auto from models) |
| Reversible | Manual up/down | `change` method (auto-reverse) | Manual up/down | Auto-reverse |
| Seed data | seedOnce() + environment seeds | db/seeds.rb | Seeders | fixtures/loaddata |

**Wheels auto-migrations:** `AutoMigrator.diff(modelName, options)` compares model property definitions against the current DB schema and returns add/remove/change/rename column lists. Renames are detected via explicit hints (`options.renames={"old":"new"}`) plus heuristic suggestions (normalized-token + Levenshtein, configurable threshold). `generateMigrationCFC()` produces a migration CFC with both up() and down() methods, emitting `renameColumn` calls for confirmed renames. Calculated properties excluded from diff.

**Wheels distinction:** `seedOnce()` is idempotent by design — safe to re-run. Rails/Laravel seeds are not idempotent by default.

---

## 3. Routing

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| RESTful resources | `.resources("posts")` | `resources :posts` | `Route::resource('posts')` | No (manual ViewSets in DRF) |
| Nested resources | callback syntax | block syntax | inline | No native |
| Shallow nesting | Yes | Yes | Yes | N/A |
| Named routes | Yes (auto-generated) | Yes (auto-generated) | Yes (->name()) | Yes (name=) |
| Route model binding | `binding=true` on resources | Implicit via type hints | Implicit via type hints | No native |
| Route constraints | whereNumber/whereAlpha/whereUuid/whereSlug/whereIn | `constraints:` hash | `where()` regex | Regex in path() |
| Scopes/Groups | `.scope(path, middleware)` | `scope/namespace` | `Route::group()` | `include()` |
| API versioning | `.version(1)` helper | Manual namespace | `Route::prefix('v1')` | Manual include |
| Wildcard catch-all | `.wildcard()` | `match '*path'` | `Route::fallback()` | `re_path(r'.*')` |
| Health endpoint | `.health()` built-in | Rails 7.1+ built-in | Manual | Manual |
| Format negotiation | `mapFormat` (.json, .xml) | `.json` extension | No native | No native |

**Wheels strengths:** Typed constraint helpers, built-in API versioning helper, format negotiation via URL extension, route model binding at router level.

---

## 4. Controllers

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Before/after filters | `filters(through, type, only, except)` | `before_action/after_action` | Middleware + constructor | `@decorators` or mixins |
| CSRF protection | `protectsFromForgery(with)` | Auto via `protect_from_forgery` | Auto via VerifyCsrfToken | Auto via CsrfViewMiddleware |
| Flash messages | `flashInsert/flash()` | `flash[:key]` | `session()->flash()` | `messages.add_message()` |
| Format negotiation | `provides("html,json")` + renderWith | `respond_to` block | Content negotiation | DRF renderers |
| File serving | `sendFile(file, disposition)` | `send_file` | `response()->download()` | `FileResponse` |
| Email sending | `sendEmail(template, to, subject)` | ActionMailer | Mailable | `send_mail()` |
| Layouts | `usesLayout(template, ajax)` | `layout "name"` | Blade @extends | Template inheritance |
| Request verification | `verifies(post, params, session)` | Strong parameters | FormRequest validation | Form/Serializer validation |
| SSE streaming | `initSSEStream/sendSSEEvent` | ActionCable (WebSocket) | Broadcasting (WebSocket) | Channels (WebSocket) |
| Channel pub/sub | `subscribeToChannel()` | ActionCable channels | Laravel Echo | Django Channels |

**Wheels distinction:** Native SSE support (not WebSocket). Most frameworks default to WebSockets for real-time; Wheels provides SSE as first-class with channel subscriptions, automatic heartbeats, and Last-Event-ID resumption.

---

## 5. Middleware

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Pipeline architecture | Closure-based chain | Rack middleware stack | Pipeline pattern | Middleware classes |
| CORS | Built-in | Via rack-cors gem | Built-in (since 7.x) | Via django-cors-headers |
| Security headers | Built-in (CSP, HSTS, Permissions-Policy) | Via secure_headers gem | Via headers middleware | Via django-csp, SecurityMiddleware |
| Rate limiting | Built-in (3 strategies) | Via rack-attack gem | Built-in (since 8.x) | Via django-ratelimit |
| Request ID | Built-in | Via request_store gem | Via middleware | Via django-request-id |
| Auth middleware | Built-in (strategy pattern) | Devise/Warden | Auth middleware | Auth middleware |
| Route-scoped | Yes (via scope) | No (global only) | Route groups | No (global only) |
| Rate limit strategies | Fixed window, sliding window, token bucket | Via gem config | Fixed window, sliding window | Via package |

**Wheels strength:** All security middleware is built-in with zero external dependencies. Rails and Django require gems/packages for CORS, rate limiting, and security headers. Route-scoped middleware is native.

---

## 6. Views & Templates

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Template engine | CFM (CFML tags + expressions) | ERB / Haml / Slim | Blade | Jinja2/DTL |
| Layouts | `includeLayout()` | `yield/content_for` | `@extends/@section` | `{% extends %}` |
| Partials | `includePartial()` | `render partial:` | `@include` | `{% include %}` |
| Content sections | `contentFor()/includeContent()` | `content_for/yield` | `@yield/@section` | `{% block %}` |
| Form object helpers | textField(objectName, property) | form_with model: | Blade + old() | ModelForm |
| HTML5 inputs | emailField, dateField, colorField, rangeField, searchField, telField, urlField, numberField | email_field, date_field, etc. | Manual | Widget attrs |
| Auto-encoding | Configurable (encodeHtmlTags) | Auto in ERB | Auto in Blade | Auto |
| XSS helpers | `h()`, `hAttr()`, `stripTags()` | `h()`, `sanitize()` | `e()`, `{!! !!}` | `escape`, `mark_safe` |
| Pagination helpers | paginationNav, paginationInfo, individual link helpers | Via gem (pagy/kaminari) | `->links()` | Manual template |
| Asset pipeline | Fingerprinting + Vite integration | Propshaft/Sprockets + esbuild | Vite (native since 9.x) | WhiteNoise/ManifestStaticFiles |
| Link helpers | `linkTo(route=)`, `buttonTo()`, `mailTo()` | `link_to`, `button_to`, `mail_to` | `route()` in Blade | `{% url %}` |

**Wheels strengths:** 8 HTML5 form helpers, built-in pagination view helpers without gems, native Vite integration.

---

## 7. Dependency Injection

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| DI container | Built-in Injector | No native (dry-rb optional) | Service Container (core) | No native |
| Registration API | `map(name).to(path).asSingleton()` | N/A | `$this->app->bind()` | N/A |
| Singleton scope | `.asSingleton()` | N/A | `$this->app->singleton()` | N/A |
| Request scope | `.asRequestScoped()` | N/A | Contextual binding | N/A |
| Auto-wiring | Yes (init param matching) | N/A | Yes (type-hint resolution) | N/A |
| Controller injection | `inject("serviceName")` | N/A | Constructor injection | N/A |
| Global resolver | `service(name)` | N/A | `app(name)` | N/A |
| Interface binding | `bind(interface).to(impl)` | N/A | `$this->app->bind(Interface, Impl)` | N/A |

Only Wheels and Laravel have full DI containers. Wheels uses explicit `map/bind` with scope methods; Laravel uses type-hint auto-resolution. Rails and Django have no built-in DI.

---

## 8. Background Jobs

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Job definition | extends wheels.Job | extends ApplicationJob | implements ShouldQueue | Celery task |
| Queue backends | Database (built-in) | Redis (Sidekiq), DB (Solid Queue) | Redis/DB/SQS/etc. | Redis/RabbitMQ (Celery) |
| Delayed execution | `enqueueIn(seconds)` | `set(wait: 5.minutes)` | `->delay(now()->addMinutes(5))` | `apply_async(eta=)` |
| Scheduled execution | `enqueueAt(datetime)` | `set(wait_until: time)` | `->delay()` | `apply_async(eta=)` |
| Retry with backoff | Built-in exponential | Built-in with options | Built-in with backoff | Via Celery config |
| Dead letter queue | Failed status in DB | Dead set (Sidekiq) | failed_jobs table | Celery result backend |
| Job worker CLI | `wheels jobs work` | `bin/jobs start` (Solid Queue) | `php artisan queue:work` | `celery -A proj worker` |
| Queue stats | `queueStats()` | Via dashboard | Via Horizon | Via Flower |
| Priority support | Yes (priority column) | Yes | Yes | Yes |
| Tenant-aware | Built-in | No native | Via packages | No native |

**Wheels distinction:** Zero-dependency job queue (uses app database, auto-creates table). No Redis/RabbitMQ required. Multi-tenant aware out of the box.

---

## 9. CLI Tooling

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Project scaffold | `wheels new myapp` | `rails new myapp` | `composer create-project` | `django-admin startproject` |
| Model generator | `wheels g model User name email` | `rails g model User name email` | `php artisan make:model User -m` | Manual |
| Controller generator | `wheels g controller Users` | `rails g controller Users` | `php artisan make:controller` | Manual |
| Scaffold generator | `wheels g scaffold Post` | `rails g scaffold Post` | No native | No native |
| API resource gen | `wheels g api-resource Product` | `rails g scaffold_controller --api` | `php artisan make:controller --api` | DRF ViewSet (manual) |
| Migration generator | `wheels g migration CreateUsers` | `rails g migration CreateUsers` | `php artisan make:migration` | `makemigrations` (auto) |
| Admin generator | `wheels g admin User` | No native (gem) | No native (Filament/Nova) | `admin.site.register(User)` |
| Interactive console | `wheels console` | `rails console` | `php artisan tinker` | `manage.py shell` |
| Route listing | `wheels routes` | `rails routes` | `php artisan route:list` | Extension needed |
| Test runner | `wheels test run` | `rails test` | `php artisan test` | `manage.py test` |
| Code analysis | `wheels analyze` | No native | No native | No native |
| Snippet templates | `wheels g snippets auth` | No native | Removed | No native |
| MCP integration | Built-in (tools auto-exposed) | No | No | No |

**Wheels strengths:** Admin generator, code analysis, snippet templates, and MCP integration (unique). Django's auto-migrations and built-in admin are the counterweight.

---

## 10. Package/Plugin Ecosystem

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Package format | vendor/ directory + package.json | RubyGems | Composer packages | PyPI packages |
| Dependency resolution | Topological sort (requires/replaces/suggests) | Bundler | Composer | pip |
| Mixin targeting | Declare targets (controller, model, global, etc.) | Module inclusion | Service providers | INSTALLED_APPS |
| Lazy loading | Yes (per-package opt-in) | Zeitwerk autoload | Lazy service providers | INSTALLED_APPS |
| Error isolation | Failed packages skipped, logged | No (crash on load) | No (crash on boot) | No (crash on startup) |
| Service providers | Yes (register/boot pattern) | Railtie/Engine | ServiceProvider (register/boot) | AppConfig (ready) |
| Ecosystem size | Small (first-party focus) | Very large (rubygems.org) | Very large (packagist) | Very large (PyPI) |

**Wheels distinction:** Error isolation is unique — a broken package doesn't crash the app. Ecosystem size is the obvious gap.

---

## 11. Testing

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Test framework | TestBox (BDD) | Minitest/RSpec | PHPUnit/Pest | pytest/unittest |
| BDD syntax | `describe/it/expect` | RSpec `describe/it/expect` | Pest `describe/it/expect` | pytest style |
| Fixtures/Factories | Test models + populate.cfm | Fixtures + FactoryBot | Factories (Eloquent) | Fixtures + factory_boy |
| HTTP/integration testing | Built-in `TestClient` (`visit/get/post`, `assertOk/assertSee/assertJson/...`) | Integration tests + Capybara | HTTP tests + Dusk | Client + Selenium |
| Database isolation | Per-test reload option | Transactions/DatabaseCleaner | RefreshDatabase trait | TransactionTestCase |
| Parallel testing | Built-in `ParallelRunner` (cfthread, partitioned bundles) | Minitest parallel | `--parallel` | `--parallel` flag |
| Browser testing | No native (use external tools) | System tests (Capybara) | Dusk (Selenium) | Selenium/Playwright |
| Multi-engine testing | Lucee + Adobe CF + BoxLang | Single runtime | Single runtime | Single runtime |

**Wheels TestClient:** Fluent HTTP test client for integration tests. Chainable API: `visit("/users").assertOk().assertSee("John")`. Includes assertions for status codes, body content (`assertSee`/`assertDontSee`/`assertSeeInOrder`), JSON responses (`assertJson`/`assertJsonPath` with dot notation), redirects, headers, and cookies. Cookies are tracked across requests for session support.

**Wheels ParallelRunner:** Discovers test bundles, partitions them across N workers via round-robin, fires parallel HTTP requests through `cfthread`, and aggregates JSON results. Configurable worker count and timeout.

**Wheels distinction:** Must test across multiple CFML engines and databases. Unique overhead but unique quality assurance.

---

## 12. Infrastructure & DevOps

| Capability | Wheels | Rails | Laravel | Django |
|---|---|---|---|---|
| Dev server | Wheels CLI (zero-Docker) | Puma | Built-in PHP server | Built-in runserver |
| Multi-tenant | Built-in datasource switching | Via gem | Via packages | Via django-tenants |
| MCP server | Built-in (`/wheels/mcp`) | No | No | No |
| CI matrix | Engines x databases x OS | Ruby versions x databases | PHP versions x databases | Python versions x databases |

**Wheels unique:** Built-in MCP server endpoint for AI tool integration. No other framework has this natively.

---

## Where Wheels Leads

1. **Built-in middleware** — CORS, rate limiting (3 strategies), security headers, auth all ship with the framework
2. **SSE support** — Native Server-Sent Events with channels, heartbeats, and Last-Event-ID
3. **Error-isolated packages** — Broken packages don't crash the app
4. **Zero-dependency job queue** — Database-backed with exponential backoff, no Redis required
5. **MCP integration** — Built-in AI tool endpoint, unique to Wheels
6. **Admin generator** — `wheels g admin User` generates full CRUD
7. **Enum auto-scopes** — `enum()` generates scopes AND boolean checkers
8. **Route model binding at router level** — Resolves before controller instantiation
9. **Multi-engine CI** — Tests across Lucee, Adobe CF, BoxLang x 7 databases
10. **Bulk insert/upsert** — `insertAll()` and `upsertAll()` with per-DB UPSERT syntax for all 7 adapters
11. **Polymorphic associations** — `belongsTo(polymorphic=true)` and `hasMany(as=)` with type-discriminator JOINs
12. **Advisory locks** — `withAdvisoryLock(name, callback)` with try/finally release; pessimistic `forUpdate()` on QueryBuilder
13. **Auto-migrations** — `AutoMigrator.diff(modelName)` generates migration CFCs from model→DB schema differences
14. **HTTP test client** — Fluent `visit().assertOk().assertSee()` integration testing
15. **Parallel test runner** — `ParallelRunner` partitions bundles across worker threads
16. **Auto-migration rename detection** — `AutoMigrator.diff()` accepts explicit rename hints AND runs heuristic similarity analysis (normalized-token + Levenshtein) to suggest likely renames. Rails requires manual `rename_column`; Django uses interactive CLI only. Wheels offers both programmatic hints and automatic suggestions in the diff engine.

## Where Wheels Trails

1. **Ecosystem size** — Dozens of packages vs thousands of gems/composer packages/PyPI packages
2. **Community size** — Small compared to Rails/Laravel/Django communities
3. **WebSocket support** — SSE covers many use cases but no bidirectional channel (deliberate design choice given CFML's request-response model)
4. **Browser testing** — No native integration (Capybara/Dusk equivalents); HTTP-level testing via TestClient is supported
5. **Asset pipeline maturity** — Vite integration is new; Rails/Laravel have years of refinement

## Recently Closed Gaps (April 2026)

The following gaps were closed in v4.0:

- **Bulk operations** ([#2101](https://github.com/wheels-dev/wheels/pull/2101)) — `insertAll`/`upsertAll`
- **Polymorphic associations** ([#2104](https://github.com/wheels-dev/wheels/pull/2104))
- **Advisory locks + SELECT FOR UPDATE** ([#2103](https://github.com/wheels-dev/wheels/pull/2103))
- **Auto-migrations from models** ([#2102](https://github.com/wheels-dev/wheels/pull/2102))
- **HTTP test client** ([#2099](https://github.com/wheels-dev/wheels/pull/2099))
- **Parallel test execution** ([#2100](https://github.com/wheels-dev/wheels/pull/2100))
- **Auto-migration rename detection** — explicit hints + heuristic suggestions via `AutoMigrator`, new `wheels dbmigrate diff` CLI command, MCP `wheels_migrate(action="diff")`
