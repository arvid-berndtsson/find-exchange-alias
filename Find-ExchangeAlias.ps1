[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Alias,

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

function Test-ExchangeOnlineConnection {
    try {
        $connections = @(Get-ConnectionInformation -ErrorAction Stop |
            Where-Object { $_.State -eq 'Connected' })
        return ($connections.Count -gt 0)
    }
    catch {
        return $false
    }
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    throw 'The ExchangeOnlineManagement module is not installed. Install it with: Install-Module ExchangeOnlineManagement -Scope CurrentUser'
}

Import-Module ExchangeOnlineManagement

if (-not (Test-ExchangeOnlineConnection)) {
    Connect-ExchangeOnline -ShowBanner:$false -ShowProgress:$false
}

# Accept either an Exchange alias, such as "privacy", or a complete address.
$lookup = $Alias.Trim()
$lookupAddress = if ($lookup -match '@') { $lookup } else { $null }

$recipients = Get-EXORecipient -ResultSize Unlimited -Properties @(
    'Alias',
    'DisplayName',
    'PrimarySmtpAddress',
    'RecipientType',
    'RecipientTypeDetails',
    'EmailAddresses',
    'ExternalDirectoryObjectId',
    'HiddenFromAddressListsEnabled'
)

$matches = foreach ($recipient in $recipients) {
    $addresses = @($recipient.EmailAddresses | ForEach-Object {
        # Exchange returns values such as SMTP:primary@example.com and
        # smtp:alias@example.com. Prefix matching is case-insensitive.
        $_.ToString() -replace '^(?i:smtp|sip|x500|x400):', ''
    })

    $aliasMatch = [string]::Equals(
        [string]$recipient.Alias,
        $lookup,
        [System.StringComparison]::OrdinalIgnoreCase
    )

    $addressMatches = if ($lookupAddress) {
        @($addresses | Where-Object {
            [string]::Equals($_, $lookupAddress, [System.StringComparison]::OrdinalIgnoreCase)
        })
    }
    else {
        @()
    }

    if (-not ($aliasMatch -or $addressMatches.Count -gt 0)) {
        continue
    }

    [PSCustomObject]@{
        DisplayName                   = $recipient.DisplayName
        Alias                         = $recipient.Alias
        PrimarySmtpAddress            = [string]$recipient.PrimarySmtpAddress
        RecipientType                 = $recipient.RecipientType
        RecipientTypeDetails          = $recipient.RecipientTypeDetails
        ExternalDirectoryObjectId     = $recipient.ExternalDirectoryObjectId
        HiddenFromAddressListsEnabled = $recipient.HiddenFromAddressListsEnabled
        MatchingEmailAddresses        = $addressMatches
    }
}

$matches = @($matches | Sort-Object RecipientTypeDetails, DisplayName)

if ($matches.Count -eq 0) {
    if ($AsJson) {
        Write-Output '[]'
    }
    else {
        Write-Output "No Exchange recipient matched '$Alias'."
    }

    exit 1
}
elseif ($AsJson) {
    $matches | ConvertTo-Json -Depth 5
}
else {
    $matches | Format-List
}
