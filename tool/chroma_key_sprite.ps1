param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputPath,

  [int]$TargetWidth = 0,
  [int]$TargetHeight = 0
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$loaded = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $InputPath))
try {
  $rect = [System.Drawing.Rectangle]::new(0, 0, $loaded.Width, $loaded.Height)
  $source = $loaded.Clone(
    $rect,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  )
  try {
    $data = $source.LockBits(
      $rect,
      [System.Drawing.Imaging.ImageLockMode]::ReadWrite,
      [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
      $byteCount = [Math]::Abs($data.Stride) * $data.Height
      $pixels = New-Object byte[] $byteCount
      [Runtime.InteropServices.Marshal]::Copy(
        $data.Scan0,
        $pixels,
        0,
        $byteCount
      )

      for ($y = 0; $y -lt $data.Height; $y++) {
        $row = $y * $data.Stride
        for ($x = 0; $x -lt $data.Width; $x++) {
          $index = $row + $x * 4
          $blue = [int]$pixels[$index]
          $green = [int]$pixels[$index + 1]
          $red = [int]$pixels[$index + 2]
          $blueExcess = $blue - [Math]::Max($red, $green)

          if ($blueExcess -le 0) {
            $pixels[$index + 3] = 255
            continue
          }

          $alpha = [Math]::Max(0, [Math]::Min(255, 255 - $blueExcess))
          if ($alpha -le 64) {
            $pixels[$index] = 0
            $pixels[$index + 1] = 0
            $pixels[$index + 2] = 0
            $pixels[$index + 3] = 0
            continue
          }

          $pixels[$index + 2] = [byte][Math]::Max(
            0,
            [Math]::Min(255, [int][Math]::Round($red * 255.0 / $alpha))
          )
          $pixels[$index + 1] = [byte][Math]::Max(
            0,
            [Math]::Min(255, [int][Math]::Round($green * 255.0 / $alpha))
          )
          $pixels[$index] = [byte][Math]::Max(
            0,
            [Math]::Min(
              255,
              [int][Math]::Round(($blue - (255 - $alpha)) * 255.0 / $alpha)
            )
          )
          $pixels[$index + 3] = [byte]$alpha
        }
      }

      [Runtime.InteropServices.Marshal]::Copy(
        $pixels,
        0,
        $data.Scan0,
        $byteCount
      )
    }
    finally {
      $source.UnlockBits($data)
    }

    $width = if ($TargetWidth -gt 0) { $TargetWidth } else { $source.Width }
    $height = if ($TargetHeight -gt 0) { $TargetHeight } else { $source.Height }
    $output = New-Object System.Drawing.Bitmap(
      $width,
      $height,
      [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
      $graphics = [System.Drawing.Graphics]::FromImage($output)
      try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $offsetX = [int](($width - $source.Width) / 2)
        $offsetY = $height - $source.Height
        $graphics.DrawImageUnscaled($source, $offsetX, $offsetY)
      }
      finally {
        $graphics.Dispose()
      }

      $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
      $outputDirectory = Split-Path -Parent $resolvedOutput
      if ($outputDirectory) {
        New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
      }
      $output.Save(
        $resolvedOutput,
        [System.Drawing.Imaging.ImageFormat]::Png
      )
    }
    finally {
      $output.Dispose()
    }
  }
  finally {
    $source.Dispose()
  }
}
finally {
  $loaded.Dispose()
}
