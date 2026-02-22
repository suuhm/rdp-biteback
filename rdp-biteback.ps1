#
# RDP-BiteBack v1.0 beta - A termsrv Patch Tool
# Author: suuhm
# Web: https://github.com/suuhm/rdp-biteback
#

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----------------- Configuration / global variables -----------------
$_FILE  = "C:\Windows\System32\termsrv.dll"
$OLDHEX = "\b39 81 3C 06 00 00 0F .. .. .. .. ..\b"
$NEWHEX = "B8 00 01 00 00 89 81 38 06 00 00 90"

# ----------------- Functions -----------------

function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $txtStatus.AppendText("[$timestamp] $Message`r`n")
}

function ConvertTo-Hex {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$InputObject
    )
    $hex = [char[]]$InputObject | ForEach-Object { '{0:x2}' -f [int]$_ }
    if ($hex -ne $null) { return (-join $hex) }
}

function Run-Patch {
    try {
        Write-Log "Starting patch for `"$($_FILE)`"..."

        if (-not (Test-Path $_FILE)) {
            Write-Log "Error: File not found: $_FILE"
            return
        }

        $backup = "$($_FILE).bak"
        Copy-Item -Force $_FILE $backup
        Write-Log "Backup created: $backup"

        Write-Log "Stopping services TermService and UmRdpService..."
        Stop-Service -Name TermService -Force -ErrorAction SilentlyContinue
        Stop-Service -Name UmRdpService -Force -ErrorAction SilentlyContinue

        Write-Log "Taking ownership and setting permissions..."
        takeown /f $_FILE | Out-Null
        icacls $_FILE /grant Administrators:F | Out-Null

        Write-Log "Reading file and applying hex replacement..."
        $byteArray  = Get-Content $_FILE -Raw -Encoding Byte
        $byteString = $byteArray.ForEach('ToString', 'X2') -join ' '

        $newByteString = $byteString -replace $OLDHEX, $NEWHEX

        if ($newByteString -eq $byteString) {
            Write-Log "Warning: Pattern not found, nothing was replaced."
        } else
            {
            [byte[]] $newByteArray = -split $newByteString -replace '^', '0x'
            Set-Content $_FILE -Encoding Byte -Value $newByteArray
            Write-Log "Patch successfully written."
        }

        Write-Log "Starting services UmRdpService and TermService..."
        Start-Service -Name UmRdpService -ErrorAction SilentlyContinue
        Start-Service -Name TermService -ErrorAction SilentlyContinue

        Write-Log "Patch process completed."
    }
    catch {
        Write-Log "Error while patching: $($_.Exception.Message)"
    }
}

function Restart-Services {
    try {
        Write-Log "Restarting TermService and UmRdpService..."
        Stop-Service -Name TermService -Force -ErrorAction SilentlyContinue
        Stop-Service -Name UmRdpService -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-Service -Name UmRdpService -ErrorAction SilentlyContinue
        Start-Service -Name TermService -ErrorAction SilentlyContinue
        Write-Log "Services restarted."
    }
    catch {
        Write-Log "Error restarting services: $($_.Exception.Message)"
    }
}

function Select-TermsrvFile {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "DLL files (*.dll)|*.dll|All files (*.*)|*.*"
    $ofd.Title  = "Select termsrv.dll"
    $ofd.FileName = "termsrv.dll"

    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $_FILE = $ofd.FileName
        $txtFilePath.Text = $_FILE
        Write-Log "New file selected: $_FILE"
    }
}

function Check-Patch {
    try {
        Write-Log "Checking patch status for `"$($_FILE)`"..."

        if (-not (Test-Path $_FILE)) {
            Write-Log "Error: File not found: $_FILE"
            return
        }

        $byteArray  = Get-Content $_FILE -Raw -Encoding Byte
        $byteString = $byteArray.ForEach('ToString', 'X2') -join ' '

        if ($byteString -match $NEWHEX) {
            Write-Log "Status: File appears to be already patched (NEWHEX found)."
            [System.Windows.Forms.MessageBox]::Show(
                "The file appears to be already patched.",
                "Patch status",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        } else {
            Write-Log "Status: File appears to be not patched (NEWHEX not found)."
            [System.Windows.Forms.MessageBox]::Show(
                "The file appears to be not patched.",
                "Patch status",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    }
    catch {
        Write-Log "Error while checking patch status: $($_.Exception.Message)"
    }
}

function Show-Credits {
    $creditsForm = New-Object System.Windows.Forms.Form
    $creditsForm.Text = "Credits"
    $creditsForm.Size = New-Object System.Drawing.Size(400,390)
    $creditsForm.StartPosition = "CenterParent"
    $creditsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $creditsForm.MaximizeBox = $false
    $creditsForm.MinimizeBox = $false

    $scriptDir = Split-Path $PSCommandPath -Parent
    $imagePath = Join-Path $scriptDir "logo.png"
    
    if (Test-Path $imagePath) {
        try {
            $img = [System.Drawing.Image]::FromFile($imagePath)
            
            $pictureBox = New-Object System.Windows.Forms.PictureBox
            $pictureBox.Size = New-Object System.Drawing.Size(230,170)
            $pictureBox.Location = New-Object System.Drawing.Point(80,10)
            $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
            $pictureBox.Image = $img
            $creditsForm.Controls.Add($pictureBox)
            
            $textTop = 220
            $btnTop = 300
        }
        catch {
            $textTop = 20
            $btnTop = 120
        }
    } else {
        $textTop = 20
        $btnTop = 120
    }


    $lbl = New-Object System.Windows.Forms.Label
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(90,200)
    $lbl.Text = "rdp-biteback - A termsrv Patch Tool`r`n`r`nAuthor: suuhm`r`nWeb: https://github.com/suuhm/rdp-biteback`r`nVersion: 1.0`r`n`r`nUse at your own risk."
    $creditsForm.Controls.Add($lbl)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "OK"
    $btnOk.Size = New-Object System.Drawing.Size(80,25)
    $btnOk.Location = New-Object System.Drawing.Point(110,310)
    $btnOk.Add_Click({ $creditsForm.Close() })
    $creditsForm.Controls.Add($btnOk)

    $creditsForm.ShowDialog() | Out-Null
}

# ----------------- GUI -----------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "RDP-BiteBack v1.0 beta - A termsrv Patch Tool"
$form.Size = New-Object System.Drawing.Size(650,420)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $true

# File path label
$lblFile = New-Object System.Windows.Forms.Label
$lblFile.Text = "File:"
$lblFile.AutoSize = $true
$lblFile.Location = New-Object System.Drawing.Point(10,15)
$form.Controls.Add($lblFile)

# File path textbox
$txtFilePath = New-Object System.Windows.Forms.TextBox
$txtFilePath.Location = New-Object System.Drawing.Point(60,10)
$txtFilePath.Size = New-Object System.Drawing.Size(430,20)
$txtFilePath.ReadOnly = $true
$txtFilePath.Text = $_FILE
$form.Controls.Add($txtFilePath)

# Browse button
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Location = New-Object System.Drawing.Point(500,8)
$btnBrowse.Size = New-Object System.Drawing.Size(120,24)
$btnBrowse.Add_Click({ Select-TermsrvFile })
$form.Controls.Add($btnBrowse)

# Layout constants for symmetry
$buttonWidth  = 200
$buttonHeight = 50
$buttonTop    = 40

# Patch button (left)
$btnPatch = New-Object System.Windows.Forms.Button
$btnPatch.Text = "PATCH"
$btnPatch.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$btnPatch.Size = New-Object System.Drawing.Size($buttonWidth,$buttonHeight)
$btnPatch.Location = New-Object System.Drawing.Point(70,$buttonTop)
$btnPatch.Add_Click({ Run-Patch })
$form.Controls.Add($btnPatch)

# Check Patch button (right, same size)
$btnCheck = New-Object System.Windows.Forms.Button
$btnCheck.Text = "CHECK PATCH"
$btnCheck.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$btnCheck.Size = New-Object System.Drawing.Size($buttonWidth,$buttonHeight)
$btnCheck.Location = New-Object System.Drawing.Point(70,$($buttonTop+60))
$btnCheck.Add_Click({ Check-Patch })
$form.Controls.Add($btnCheck)

# Restart button (centered below)
$btnRestart = New-Object System.Windows.Forms.Button
$btnRestart.Text = "Restart services"
$btnRestart.Location = New-Object System.Drawing.Point(330,55)
$btnRestart.Size = New-Object System.Drawing.Size(150,30)
$btnRestart.Add_Click({ Restart-Services })
$form.Controls.Add($btnRestart)

# Credits button (right below)
$btnCredits = New-Object System.Windows.Forms.Button
$btnCredits.Text = "Credits"
$btnCredits.Location = New-Object System.Drawing.Point(330,110)
$btnCredits.Size = New-Object System.Drawing.Size(150,30)
$btnCredits.Add_Click({ Show-Credits })
$form.Controls.Add($btnCredits)

# Status / log textbox
$txtStatus = New-Object System.Windows.Forms.TextBox
$txtStatus.Location = New-Object System.Drawing.Point(10,160)
$txtStatus.Size = New-Object System.Drawing.Size(610,210)
$txtStatus.Multiline = $true
$txtStatus.ScrollBars = "Vertical"
$txtStatus.ReadOnly = $true
$txtStatus.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($txtStatus)

Write-Log "Tool started. Default file: $_FILE"

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.Add_Shown({$form.Activate()})
[System.Windows.Forms.Application]::Run($form)
