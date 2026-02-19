<# : hybrid batch + powershell script
@echo off
cls
:: Eğer Windows Terminal (WT) etkinse, eski konsolda (conhost) yeniden başlat
if defined WT_SESSION (
    start "" conhost.exe "%~f0" %*
    exit
)

:: Eski konsol açıldıktan sonra ekranı temizle ve boyutu ayarla
cls
mode con: cols=70 lines=4
powershell -noprofile -ExecutionPolicy Bypass -Command "iex (Get-Content '%~f0' -Raw -Encoding UTF8)"
exit /b
#>

param([switch]$Fast)

# Sistem dili algılama
$Lang = (Get-UICulture).TwoLetterISOLanguageName

if ($Lang -eq "tr") {
    # --- TÜRKÇE ---
    $Host.UI.RawUI.WindowTitle = "Windows & Office Lisans Bilgileri"
    Write-Host ""
    Write-Host "`tLisans bilgileri toplanıyor, lütfen bekleyin..."
}
else {
    # --- ENGLISH ---
    $Host.UI.RawUI.WindowTitle = "Windows & Office License Information"
    Write-Host ""
    Write-Host "`tCollecting license information, please wait..."
}


# Parametre verilmese bile varsayılan olarak Fast modunda çalış / default to Fast mode when not explicitly set
if (-not $PSBoundParameters.ContainsKey('Fast')) {
    $Fast = $true
}

# --- DİL AYARLARI VE METİNLER ---
# --- LANGUAGE SETTINGS AND STRINGS ---

# İşletim sistemi arayüz dilini kontrol et
# Check the OS UI language
$uiCulture = (Get-UICulture).Name
$Global:LANG = $null

# Türkçe metinler
# Turkish strings
$TR = @{
    OhookStatus                 = "Office sürümünde kalıcı Office aktivasyonu için Ohook yöntemi işletim sistemine yüklenmiş.`n`n" +
                                  "Office aktivasyon bilgisindeki 'Lisans Durumu : Bildirim' veya 'Yetkisiz Kullanım Süresi' uyarısı varsa bu uyarıyı görmezden gelin.`n`n" +
                                  "Office ürününüz kalıcı olarak etkinleştirilmiş."
    Status0                     = "Lisanssız"
    Status1                     = "Lisanslı"
    Status2                     = "Yetkisiz Kullanım Süresi"
    Status3                     = "KMS Lisansının Süresi Doldu veya Donanım Tolerans Dışı"
    Status4                     = "Orijinal Olmayan Yetkisiz Kullanım Süresi"
    Status5                     = "Bildirim"
    Status6                     = "Uzatılmış Yetkisiz Kullanım Süresi"
    StatusDefault               = "Bilinmeyen"
    Unknown                     = "Bilinmiyor"
    PopupNoProducts             = "Windows ve Office ürünleri bulunamadı veya lisans durumu bilinmiyor.`n`n"
    PopupTitle                  = "                 Windows & Office Lisans Bilgileri`n ------------------------------------------------------------------------`n`n"
    UnknownProduct              = "Bilinmeyen Ürün"
    PopupLicStatus              = "Lisans Durumu"
    PopupChannel                = "Ürün Anahtarı Kanalı"
    PopupPartialKey             = "Kısmi Ürün Anahtarı"
    PopupKmsDays                = "Lisanslı KMS Gün Sayısı"
    PopupKmsName                = "KMS Sunucu Adı"
    PopupKmsIp                  = "KMS Sunucu IP Adresi"
    PopupOhookStatus            = "OHOOK DURUMU :"
    PopupMessageBoxTitle        = "Windows & Office Lisans Bilgileri"
}

# İngilizce metinler
# English strings
$EN = @{
    OhookStatus                 = "The Ohook method for permanent Office activation is installed on the operating system for this Office version.`n`n" +
                                  "If there is a 'License Status: Notification' or 'Grace Period' warning in the Office activation info, please ignore this warning.`n`n" +
                                  "Your Office product is permanently activated."
    Status0                     = "Unlicensed"
    Status1                     = "Licensed"
    Status2                     = "Grace Period"
    Status3                     = "KMS License Expired or Hardware Out of Tolerance"
    Status4                     = "Non-Genuine Grace Period"
    Status5                     = "Notification"
    Status6                     = "Extended Grace Period"
    StatusDefault               = "Unknown"
    Unknown                     = "Unknown"
    PopupNoProducts             = "No Windows or Office products found, or license status is unknown.`n`n"
    PopupTitle                  = "                 Windows & Office License Information`n ------------------------------------------------------------------------`n`n"
    UnknownProduct              = "Unknown Product"
    PopupLicStatus              = "License Status"
    PopupChannel                = "Product Key Channel"
    PopupPartialKey             = "Partial Product Key"
    PopupKmsDays                = "Licensed KMS Days Left"
    PopupKmsName                = "KMS Server Name"
    PopupKmsIp                  = "KMS Server IP Address"
    PopupOhookStatus            = "OHOOK STATUS :"
    PopupMessageBoxTitle        = "Windows & Office License Information"
}

# Dil seçimi
# Language selection
if ($uiCulture -eq 'tr-TR') {
    $Global:LANG = $TR
} else {
    $Global:LANG = $EN
}
# --- DİL AYARLARI VE METİNLER SONU ---
# --- END OF LANGUAGE SETTINGS AND STRINGS ---


function Get-OhookStatus {
    $officeBasePath = "C:\Program Files\Microsoft Office\root\vfs\"
    $fs = New-Object -ComObject Scripting.FileSystemObject

    if ($fs.FolderExists($officeBasePath + "System")) {
        $officePath = $officeBasePath + "System\"
    }
    elseif ($fs.FolderExists($officeBasePath + "SystemX86")) {
        $officePath = $officeBasePath + "SystemX86\"
    }
    else {
        return ""
    }

    $sppcFile = $officePath + "sppc.dll"
    $sppcsFile = $officePath + "sppcs.dll"

    if (($fs.FileExists($sppcFile)) -and ($fs.FileExists($sppcsFile))) {
        # DEĞİŞTİRİLDİ / MODIFIED
        return $LANG.OhookStatus
    }
    else {
        return ""
    }
}

function Get-LicenseStatusText {
    param ($code)
    # DEĞİŞTİRİLDİ / MODIFIED
    switch ($code) {
        0 { return $LANG.Status0 }
        1 { return $LANG.Status1 }
        2 { return $LANG.Status2 }
        3 { return $LANG.Status3 }
        4 { return $LANG.Status4 }
        5 { return $LANG.Status5 }
        6 { return $LANG.Status6 }
        default { return $LANG.StatusDefault }
    }
}

 # slmgr çıktısını önbelleğe al / cache slmgr output per product
 $script:SlmgrCache = @{}

 function Get-SlmgrInfoCore {
     param($productID)

     if ($script:SlmgrCache.ContainsKey($productID)) {
         return $script:SlmgrCache[$productID]
     }

     $output = & cscript.exe /nologo "$env:SystemRoot\System32\slmgr.vbs" /dlv $productID 2>&1

     # Kanal satırını bul / find channel line (TR + EN)
     $channelLine = $output | Where-Object { $_ -match 'Ürün Anahtarı Kanalı' -or $_ -match 'Product Key Channel' }
     $channelText = if ($channelLine) { $channelLine -replace '.*:\s*','' } else { '' }

     $kmsName = ''
     $kmsIp   = ''

     if ($channelText -match '(KMS|GVLK|Volume)') {
         # KMS bilgilerini bul (TR + EN) / find KMS info (TR + EN)
         $kmsNameLine = $output | Where-Object { $_ -match 'KMS makinesi adı:' -or $_ -match 'KMS machine name:' }
         $kmsIpLine   = $output | Where-Object { $_ -match 'KMS makinesi IP adresi:' -or $_ -match 'KMS machine IP address:' }

         $kmsName = if ($kmsNameLine) { $kmsNameLine -replace '.*:\s*','' } else { '' }
         $kmsIp   = if ($kmsIpLine)   { $kmsIpLine   -replace '.*:\s*','' } else { '' }

         if ([string]::IsNullOrWhiteSpace($kmsName) -or $kmsName.Trim() -eq '1688') {
             try {
                 $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
                 $regKmsName = (Get-ItemProperty -Path $regPath -Name KeyManagementServiceName -ErrorAction SilentlyContinue).KeyManagementServiceName
                 if ($regKmsName -and $regKmsName -ne '1688') {
                     $kmsName = $regKmsName
                 }
             } catch {
             }
         }
     }

     $info = [pscustomobject]@{
         ChannelRaw = $channelText
         KMSName    = $kmsName
         KMSIp      = $kmsIp
     }

     $script:SlmgrCache[$productID] = $info
     return $info
 }

function Get-SlmgrDlvInfo {
    param($productID)

    $info = Get-SlmgrInfoCore -productID $productID
    $channelText = $info.ChannelRaw

    # OEM dm veya OEM:NONSLP gibi ifadeleri düzgün yaz
    if ($channelText -match '^dm$') {
        return "OEM-DM"
    }
    elseif ($channelText -match '^(OEM)[:\-]?(.*)$') {
        return "OEM:$($matches[2].Trim())"
    }
    elseif ($channelText -and $channelText.Trim() -ne '') {
        return $channelText.Trim()
    }
    else {
        # DEĞİŞTİRİLDİ / MODIFIED
        return $LANG.Unknown
    }
}

function Get-KMSInfoFromSlmgr {
    param($productID)

    $info = Get-SlmgrInfoCore -productID $productID
    $channelText = $info.ChannelRaw

    if ($channelText -match '(KMS|GVLK|Volume)') {
        return @{
           Channel = $channelText.Trim()
           KMSName = $info.KMSName.Trim()
           KMSIp = $info.KMSIp.Trim()
        }
    }
    else {
        return @{
            Channel = $channelText.Trim()
            KMSName = ''
            KMSIp = ''
        }
    }
}

function Get-ChannelFromProductWmi {
    param(
        $Product
    )

    try {
        $desc   = ("" + $Product.Description)
        $family = ("" + $Product.LicenseFamily)
        $combined = ($desc + " " + $family)
        if ([string]::IsNullOrWhiteSpace($combined)) { return $null }

        $t = $combined.ToUpperInvariant()

        # OEM türleri
        if ($t -match 'OEM[-_: ]?DM')       { return 'OEM-DM' }
        if ($t -match 'OEM[-_: ]?NONSLP')   { return 'OEM:NONSLP' }

        # MAK / GVLK / KMS / Volume / Retail
        if ($t -match 'MAK')                { return 'Volume:MAK' }
        if ($t -match 'GVLK' -or $t -match 'KMSCLIENT' -or $t -match 'KMS CLIENT') { return 'Volume:GVLK' }
        if ($t -match 'VOLUME')             { return 'Volume' }
        if ($t -match 'RETAIL')             { return 'Retail' }
    } catch {
    }

    return $null
}

function Get-Products {
    try {
        $query = "SELECT * FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL"
        $allProducts = Get-CimInstance -Query $query | Where-Object { $_.LicenseStatus -ne 0 }
        return $allProducts
    } catch {
        return @()
    }
}

function Show-LicenseStatusPopup {
    Add-Type -AssemblyName PresentationFramework

    $products = Get-Products

    # -Fast modunda slmgr'i mümkün olduğunca az üründe çalıştır / in -Fast mode, limit slmgr usage
    $fastMainOnly = $Fast
    $ohookMessage = Get-OhookStatus

    $output = ""

    if ($products.Count -eq 0) {
        # DEĞİŞTİRİLDİ / MODIFIED
        $output += $LANG.PopupNoProducts
    } else {
        # DEĞİŞTİRİLDİ / MODIFIED
        $output += $LANG.PopupTitle

        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $osCaption = $os.Caption
        $osNameWritten = $false

        foreach ($p in $products) {
            # DEĞİŞTİRİLDİ / MODIFIED
            $type = if ($p.Name -match 'Office') { '' } elseif ($p.Name -match '^Windows') { '' } else { $LANG.UnknownProduct }
            $statusText = Get-LicenseStatusText $p.LicenseStatus

            if ($p.Name -match '^Windows' -and -not $osNameWritten) {
                $output += "$osCaption`n"
                $osNameWritten = $true
            }

            $isMainProduct = ($p.Name -match '^Windows' -or $p.Name -match 'Office')
           
             # Önce WMI üzerinden kanal bilgisini tahmin et, gerekirse slmgr'a düş / 
            # First, try to infer channel from WMI; fall back to slmgr only if needed
            $channel = $null
            $channelWmi = Get-ChannelFromProductWmi -Product $p
            if ($channelWmi) {
                $channel = $channelWmi
            } else {
                if ($fastMainOnly -and -not $isMainProduct) {
                    # Fast modda ana olmayan ürünlerde slmgr çağrısını atla
                    $channel = $LANG.Unknown
                } else {
                    $channel = Get-SlmgrDlvInfo -productID $p.ID
                }
            }

            if ($p.Name -match 'Office') {
                $output += "$($p.Name)`n"
            }

            $output += "`n"
            # DEĞİŞTİRİLDİ / MODIFIED
            $output += "$($LANG.PopupLicStatus)		: $statusText`n"
            $output += "`n"
            # DEĞİŞTİRİLDİ / MODIFIED
            $output += "$($LANG.PopupChannel)       	: $channel`n"
            # DEĞİŞTİRİLDİ / MODIFIED
            $output += "$($LANG.PopupPartialKey)       	: $($p.PartialProductKey)`n"

             # KMS bilgilerini sadece KMS lisansı varsa göster; mümkün olduğunca slmgr'dan kaçın
            $kmsInfo = @{
                Channel = $channel
                KMSName = ''
                KMSIp   = ''
            }

            $isKmsLikeChannel = ($channel -match 'KMS' -or $channel -match 'GVLK' -or $channel -match 'Volume')
            if ($isKmsLikeChannel -and -not ($fastMainOnly -and -not $isMainProduct)) {
                $kmsInfo = Get-KMSInfoFromSlmgr -productID $p.ID
            }
            if ($p.GracePeriodRemaining -gt 0) {
                $daysLeft = [math]::Floor($p.GracePeriodRemaining / (24*60))
                # DEĞİŞTİRİLDİ / MODIFIED
                $output += "$($LANG.PopupKmsDays)	: $daysLeft`n"

                $kmsNameTrimmed = $kmsInfo.KMSName.Trim()
                if (-not [string]::IsNullOrWhiteSpace($kmsNameTrimmed) -and $kmsNameTrimmed -ne '1688') {
                    if ($kmsNameTrimmed -match '^(.*):\d+$') {
                        $kmsHost = $matches[1].Trim()
                        if ($kmsHost -eq '') {
                            # DEĞİŞTİRİLDİ / MODIFIED
                                $output += "$($LANG.PopupKmsName)		: $($LANG.Unknown)`n"
                        } else {
                            # DEĞİŞTİRİLDİ / MODIFIED
                                $output += "$($LANG.PopupKmsName)		: $kmsHost`n"
                        }
                    } else {
                        # DEĞİŞTİRİLDİ / MODIFIED
                            $output += "$($LANG.PopupKmsName)		: $kmsNameTrimmed`n"
                    }
                }

                if ($kmsInfo.KMSIp -ne '') {
                    # DEĞİŞTİRİLDİ / MODIFIED
                    $output += "$($LANG.PopupKmsIp)	: $($kmsInfo.KMSIp)`n"
                }
            }

            $output += "------------------------------------------------------------------------`n"
            $output += "`n"
        }
    }

if ($ohookMessage -ne "") {
    $officeLicenseExists = $false
    foreach ($p in $products) {
        if ($p.Name -match 'Office') {
            $officeLicenseExists = $true
            break
        }
    }
    if ($officeLicenseExists) {
        # DEĞİŞTİRİLDİ / MODIFIED
        $output += "$($LANG.PopupOhookStatus)`n"
        $output += $ohookMessage
    }
}

    Add-Type -AssemblyName System.Windows.Forms
    # DEĞİŞTİRİLDİ / MODIFIED
    [System.Windows.Forms.MessageBox]::Show($output, $LANG.PopupMessageBoxTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information, [System.Windows.Forms.MessageBoxDefaultButton]::Button1, [System.Windows.Forms.MessageBoxOptions]::ServiceNotification)
}

Show-LicenseStatusPopup