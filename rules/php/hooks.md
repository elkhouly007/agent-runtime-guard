# PHP + ARG Hooks

PHP-specific ARG hook considerations.

## Composer Operations

Commands that may trigger ARG:
- `composer install` / `composer update`: downloads and executes packages
- `composer require vendor/package`: adds new code to the project
- Composer scripts in `composer.json` run arbitrary shell commands on install/update

## Artisan and Framework Commands

- `php artisan migrate`: modifies database schema
- `php artisan migrate:fresh` or `migrate:rollback`: destructive database operations
- `php artisan db:seed`: bulk inserts or data manipulation
- `php artisan key:generate`: regenerates application key (invalidates encrypted data)

## PHP CLI Execution

- `php -r "..."`: inline PHP execution (arbitrary code)
- Scripts calling `exec()`, `system()`, `shell_exec()`, or `passthru()`
- `eval()` usage in any context

## Web Server and Config Changes

- `php -S 0.0.0.0:8080`: starts development server on all interfaces
- `.htaccess` modifications that change PHP configuration
- `php.ini` overrides affecting security settings (`disable_functions`, `open_basedir`)

## Secrets in PHP Projects

Common locations:
- `.env` files with `DB_PASSWORD`, `APP_KEY`, `API_SECRET`
- `config/` files that may read env vars
- Hardcoded credentials in legacy code outside the env system

ARG flags hardcoded credential patterns and `exec()`/`shell_exec()` calls with non-literal arguments.
