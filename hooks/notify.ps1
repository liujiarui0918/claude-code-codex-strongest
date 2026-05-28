#requires -version 5.1
$ErrorActionPreference = 'Stop'

# Read stdin payload (empty allowed -> default message).
try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($jsonText)) {
        $payload = [pscustomobject]@{ message = 'Claude Code needs attention' }
    } else {
        $payload = $jsonText | ConvertFrom-Json
    }
} catch {
    exit 0
}

try {
    # Extract message: $payload.message OR $payload.notification.message
    $message = $null
    try { if ($payload.message) { $message = [string]$payload.message } } catch { }
    if ([string]::IsNullOrWhiteSpace($message)) {
        try {
            if ($payload.notification -and $payload.notification.message) {
                $message = [string]$payload.notification.message
            }
        } catch { }
    }
    if ([string]::IsNullOrWhiteSpace($message)) { $message = 'Claude Code needs attention' }

    $shown = $false

    # Path 1: BurntToast (richer toast; only if module is installed).
    try {
        $btAvailable = $null
        try {
            $btAvailable = Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue
        } catch { $btAvailable = $null }

        if ($btAvailable) {
            try {
                Import-Module BurntToast -ErrorAction Stop
                New-BurntToastNotification -Text 'Claude Code', $message -ErrorAction Stop | Out-Null
                $shown = $true
            } catch {
                $shown = $false
            }
        }
    } catch { }

    # Path 2: native WinRT toast.
    if (-not $shown) {
        try {
            [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
            [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

            $escMessage = [System.Net.WebUtility]::HtmlEncode($message)
            $xml = @"
<toast><visual><binding template="ToastGeneric"><text>Claude Code</text><text>$escMessage</text></binding></visual></toast>
"@

            $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
            $doc.LoadXml($xml)
            $toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show($toast)
            $shown = $true
        } catch {
            $shown = $false
        }
    }

    # Path 3: system sound fallback.
    if (-not $shown) {
        try { [System.Media.SystemSounds]::Asterisk.Play() } catch { }
    }

    exit 0
} catch {
    exit 0
}
