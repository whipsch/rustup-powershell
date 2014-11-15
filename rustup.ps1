# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
# <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
# option. This }le may not be copied, modi}ed, or distributed
# except according to those terms.

function Expand-ZIPFile($file, $destination)
{
    $shell = new-object -com shell.application
    echo "Zip file: $file"
    $zip = $shell.namespace($file)
    if (Test-Path "$destination")
    {
        $dst = $shell.namespace($destination)
    }
    else
    {
        mkdir $destination
        $dst = $shell.namespace($destination)
    }
    $dst.Copyhere($zip.items())
}

function which($name)
{
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function pause()
{
    Write-Host "Press any key to continue ..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


Import-Module BitsTransfer

$TMP_DIR = "c:\temp\rustup-tmp-install3"
rm $TMP_DIR -Recurse
mkdir $TMP_DIR

# 1: Detect 32 or 64 bit
switch ([IntPtr]::Size)
{ 
    4 {
        $arch = 32
        $rust_dl = "https://static.rust-lang.org/dist/rust-nightly-i686-pc-windows-gnu.exe"
        $cargo_dl = "https://static.rust-lang.org/cargo-dist/cargo-nightly-i686-w64-mingw32.tar.gz"
    } 
    8 {
        $arch = 64
        $rust_dl = "https://static.rust-lang.org/dist/rust-nightly-x86_64-pc-windows-gnu.exe"
        $cargo_dl = "https://static.rust-lang.org/cargo-dist/cargo-nightly-x86_64-w64-mingw32.tar.gz"
    }
    default {echo "ERROR: The processor architecture could not be determined." ; exit 1}
}

# 2: Detect/install 7zip
$7zip_dl= "http://downloads.sourceforge.net/sevenzip/7za920.zip"
$7z_path = "$TMP_DIR\7za920.zip"
Start-BitsTransfer $7zip_dl $7z_path -Description "Downloading 7zip"
Expand-ZIPFile �File $7z_path �Destination "$TMP_DIR"
$7z = "$TMP_DIR\7za.exe"

# 3: Download the rust and cargo binaries
$rust_installer = "$TMP_DIR\rust_install.exe"
$cargo_binary = "$TMP_DIR\cargo_install.tar.gz"

Start-BitsTransfer $rust_dl $rust_installer -Description "Downloading Rust"

Start-BitsTransfer $cargo_dl $cargo_binary -Description "Downloading Cargo"

echo "Downloads complete."

# 4: Install the rust binaries
Start-Process $rust_installer -Wait
# Looking for the dir which has rustc in it, which may fail if the user doesn't add rust\bin to
# their path or for multiple rust versions
$rust_bin = which "rustc.exe" | Split-Path

# 5: Place the cargo binaries in the rust bin folder
Start-Process .\7za.exe -ArgumentList "e .\cargo_bin.tar.gz" -Wait
Start-Process .\7za.exe -ArgumentList "e .\cargo_bin.tar *.exe -r" -Wait
mv "$TMP_DIR\cargo.exe" $rust_bin

pause