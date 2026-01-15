param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

Write-Host "Staging all changes..."
git add .

Write-Host "Committing with message: $Message"
git commit -m "$Message"

Write-Host "Pushing to remote..."
git push

Write-Host "Done!"
