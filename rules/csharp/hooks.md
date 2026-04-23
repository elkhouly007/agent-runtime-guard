# C# + ARG Hooks

C#-specific ARG hook considerations.

## .NET CLI Commands

.NET commands that may trigger ARG:
- `dotnet publish --runtime win-x64 --self-contained` deploying to production paths
- `dotnet ef database update` running migrations against production databases
- `dotnet nuget push` publishing packages to NuGet

## Secrets Management

C# projects commonly use:
- `appsettings.json` with connection strings and API keys (check for production secrets)
- `secrets.json` via `dotnet user-secrets` (local development, not committed)
- Environment variables read via `IConfiguration`

ARG will intercept these if they appear in Bash tool call inputs. Use Azure Key Vault, AWS Secrets Manager, or HashiCorp Vault for production.

## Entity Framework Migrations

Database migration commands carry risk:
- `dotnet ef migrations add` is safe (generates files only)
- `dotnet ef database update` applies migrations to a real database — confirm the target connection string
- `dotnet ef database drop` is destructive — ARG may flag this

## IIS and Windows Service Deployment

Windows-specific deployment commands:
- `iisreset` and `net stop/start` affect running services
- Windows service installation commands (`sc create`, `sc start`)
- Registry modifications for service configuration

These are legitimate operations but should be reviewed before execution.
