Function Request-Choice {

    param(
         [Parameter(Mandatory=$true)][string]$title
        ,[Parameter(Mandatory=$true)][string]$message
        ,[Parameter(Mandatory=$true)][string[]]$choices
        ,[Parameter(Mandatory=$false)][int]$defaultChoice = 0
    )

    $i = 1
    $choicesConverted = [System.Collections.ArrayList]@()
    $choices | ForEach-Object {
        $choice = $_
        [void]$choicesConverted.add((New-Object System.Management.Automation.Host.ChoiceDescription "`b&$( $i ) - $( $choice )`n" )) # putting a string afterwards shows it as a help message
        $i += 1
    }
    $options = [System.Management.Automation.Host.ChoiceDescription[]]$choicesConverted
    $result = $host.ui.PromptForChoice($title, $message, $options, $defaultChoice)

    return $result +1 # add one for index

}