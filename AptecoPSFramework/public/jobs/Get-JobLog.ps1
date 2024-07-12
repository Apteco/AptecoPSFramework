
Function Get-JobLog {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    Param(

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$JobId

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Switch]$ConvertInput = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Switch]$ConvertOutput = $false

        #,[Parameter(Mandatory=$true)][String]$ConnectionString

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Int]$Last = 100  # Get the last n entries
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false  # Get all instead of last n

    )

    Process {

        # TODO check if connection is open?

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                #$job = Read-DuckDBQueryAsReader -Name "JobLog" -Query "SELECT * FROM joblog WHERE id = $( $JobId )" -ReturnAsPSCustom
                $job = Invoke-SqlQuery -Query "SELECT * FROM joblog WHERE id = $( $JobId )" -ConnectionName "JobLog" -Stream

                If ( $job.count -eq 0 ) {
                    throw "No job found with id $( $JobId )"
                } elseif ( $job.count -gt 1 ) {
                    throw "Multiple jobs found with id $( $JobId )"
                } else {

                    If ( $ConvertInput -eq $true) {
                        $job.input = ConvertFrom-JsonAsHashtable $job.input
                    }

                    If ( $ConvertOutput -eq $true) {
                        Switch ( $job.returnformat ) {

                            # "ARRAY" {
                            #     ConvertFrom-Json $job.output
                            #     break
                            # }

                            "HASHTABLE" {
                                $job.output = ConvertFrom-JsonAsHashtable $job.output
                                break

                            }

                            default {
                                ConvertFrom-Json $job.output
                                break
                            }

                        }
                        
                    }

                }

                break
            }

            'Collection' {

                $q = "SELECT * FROM joblog ORDER BY id DESC"

                # Add last page
                If ( $All -ne $true ) {
                    $q += " LIMIT $( $Last )"
                }

                #$job = Read-DuckDBQueryAsReader -Name "JobLog" -Query  -ReturnAsPSCustom
                $job = Invoke-SqlQuery -Query $q -ConnectionName "JobLog" -Stream

                If ( $ConvertInput -eq $true -or $ConvertOutput -eq $true ) {

                    $job | ForEach-Object {
                        $j = $_
                        If ( $ConvertInput -eq $true ) {
                            $j.input = ConvertFrom-JsonAsHashtable $j.input
                        }
                        If ( $ConvertOutput -eq $true ) {
                            Switch ( $j.returnformat ) {

                                # "ARRAY" {
                                #     ConvertFrom-Json $job.output
                                #     break
                                # }
    
                                "HASHTABLE" {
                                    $j.output = ConvertFrom-JsonAsHashtable $j.output
                                    break
                                }
    
                                default {
                                    $j.output = ConvertFrom-Json $j.output
                                    break
                                }
    
                            }
                            
                        }
    
                    }

                }

                break
            }
        }

        $job
        
        
    }

}