# Exchange recipient alias finder

Find which Exchange Online recipient owns an alias or email address.

The search covers all recipient types returned by `Get-EXORecipient`, including:

- User mailboxes
- Shared mailboxes
- Room and equipment mailboxes
- Microsoft 365 groups
- Distribution lists
- Mail-enabled security groups
- Dynamic distribution lists
- Mail contacts and other mail-enabled recipients

## Requirements

- PowerShell 7 or Windows PowerShell
- The ExchangeOnlineManagement module
- An account authorized to read Exchange recipients

Install the module if needed:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

## Usage

The `.ps1` file must be run through PowerShell. Do not execute it directly from macOS `zsh` or another Unix shell.

From PowerShell:

```powershell
./Find-ExchangeAlias.ps1 -Alias privacy
```

From macOS Terminal or another Unix shell, use the included wrapper:

```sh
./find-exchange-alias -Alias privacy
```

Alternatively, invoke PowerShell explicitly:

```sh
pwsh -NoProfile -File ./Find-ExchangeAlias.ps1 -Alias privacy
```

Search by a complete email address, including a secondary SMTP address:

```sh
./find-exchange-alias -Alias privacy@arvid.tech
```

Return machine-readable JSON:

```sh
./find-exchange-alias -Alias privacy -AsJson
```

The script reuses an existing connected Exchange Online session. If no connected session exists, it starts `Connect-ExchangeOnline` and uses the normal interactive authentication flow.

## File naming and platform support

The project intentionally uses different naming styles for the two entry points:

- `Find-ExchangeAlias.ps1` uses PowerShell's conventional `Verb-Noun` style and is the native PowerShell implementation.
- `find-exchange-alias` is lowercase and executable from macOS, Linux, and other Unix-like shells.
- `README.md` uses the conventional Markdown filename.

Use the lowercase wrapper as the cross-platform command when working from macOS Terminal or Linux. Use the `.ps1` file directly from PowerShell. Linux filesystems are commonly case-sensitive, so use the filenames exactly as shown.

Examples:

```sh
# macOS, Linux, or another Unix-like shell
./find-exchange-alias -Alias privacy@arvid.tech
```

```powershell
# Windows PowerShell or PowerShell on any platform
.\Find-ExchangeAlias.ps1 -Alias privacy@arvid.tech
```

```sh
# Explicit PowerShell invocation from any shell
pwsh -NoProfile -File ./Find-ExchangeAlias.ps1 -Alias privacy@arvid.tech
```

## What it checks

The script searches both:

- The recipient's Exchange `Alias` property
- Every address in `EmailAddresses`, including secondary SMTP proxy addresses

Matching is case-insensitive. When a complete email address is supplied, the result identifies the matching proxy address where applicable.

## Output

For every match, the script returns:

- Display name
- Exchange alias
- Primary SMTP address
- Recipient type and detailed recipient type
- Microsoft Entra object ID, where available
- Whether the recipient is hidden from address lists
- Matching email addresses

The normal output is formatted for interactive use. Use `-AsJson` for automation or sharing structured results.

Exit code is `0` when one or more matches are found and `1` when there are no matches.

The script is read-only. It does not modify recipients, aliases, group membership, mailbox permissions, or forwarding settings.
