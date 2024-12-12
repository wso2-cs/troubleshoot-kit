# Check if IS_HOME is provided as a command-line argument
if ($args.Count -eq 0) {
    Write-Host "Usage: script.ps1 <IS_HOME>"
    exit 1
}

$IS_HOME = $args[0]
$WEBAPP_DIR="$IS_HOME\repository\deployment\server\webapps"

# Define the search pattern
$search_pattern="org.springframework"

# Define directories to include
$include_dirs = @(
    "$WEBAPP_DIR",
    "$IS_HOME\repository\components\dropins"
)

$exclude_dirs=@(
    "$WEBAPP_DIR\api#users#v1\",
    "$WEBAPP_DIR\api#users#v1#recovery\",
    "$WEBAPP_DIR\forgetme#v1.0\",
    "$WEBAPP_DIR\wso2\",
    "$WEBAPP_DIR\api#identity#oauth2#dcr#v1.1\",
    "$WEBAPP_DIR\api#identity#oauth2#v1.0\",
    "$WEBAPP_DIR\api#identity#config-mgt#v1.0\",
    "$WEBAPP_DIR\api#identity#oauth2#uma#permission#v1.0\",
    "$WEBAPP_DIR\scim2\",
    "$WEBAPP_DIR\oauth2\",
    "$WEBAPP_DIR\api#identity#entitlement\",
    "$WEBAPP_DIR\api#identity#consent-mgt#v1.0\",
    "$WEBAPP_DIR\api#identity#recovery#v0.9\",
    "$WEBAPP_DIR\mexut\",
    "$WEBAPP_DIR\api#identity#auth#v1.1\",
    "$WEBAPP_DIR\api#health-check#v1.0\",
    "$WEBAPP_DIR\api#users#v2#me#webauthn\",
    "$WEBAPP_DIR\api\",
    "$WEBAPP_DIR\api#identity#oauth2#uma#resourceregistration#v1.0\",
    "$WEBAPP_DIR\api#identity#user#v1.0\",
    "$WEBAPP_DIR\api#identity#template#mgt#v1.0.0\"
)

# Loop through each directory in include_dirs and get the results
$results = @();
foreach ($dir in $include_dirs) {
    $files = Get-ChildItem -Path $dir -Recurse -Include * | Select-String -Pattern "$search_pattern" | ForEach-Object { $_.Path };
    $results += $files;
}

# Exclude the exclude_dirs
$filtered = @();
foreach ($result in $results) {
    $isExcluded = $false;
    foreach ($exclude_dir in $exclude_dirs) {
        if ($result -like "*$exclude_dir*") {
            $isExcluded = $true;
            break;
        }
    }
    if(!$isExcluded) {
        $filtered += $result;
    }
}

if ($filtered.Count -eq 0) {
    Write-Output 'There are no Spring dependencies.' | Tee-Object -file results.txt;
} else {
    Write-Output 'List of Spring dependencies found:';
    Write-Output $filtered | ForEach-Object { Write-Output $_ } | Tee-Object -file results.txt; 
}