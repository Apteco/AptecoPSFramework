


        function Invoke-EmarsysLogin {
            [CmdletBinding()]
            param (
                #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
                #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
            )
        
            begin {
        
                
        
            }
        
            process {

                # if the class is not already initialised, do it now
                If ( $null -eq $Script:variableCache.emarsys ) {

                    $stringSecure = ConvertTo-SecureString -String ( Convert-SecureToPlaintext $Script:settings.login.secret ) -AsPlainText -Force
                    $cred = [pscredential]::new( $Script:settings.login.username, $stringSecure )
                
                    # Read static attribute
                    #[Emarsys]::allowNewFieldCreation
                
                    # Create emarsys object
                    $emarsys = [Emarsys]::new($cred,$settings.base)

                    # Save the emarsys object in cache
                    $Script:variableCache.Add("emarsys",$emarsys)

                }

            }
        
            end {
        
            }
        
        }
        
        
        