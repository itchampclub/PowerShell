<#
.Synopsis
   Noble termination script
.DESCRIPTION
   Script to process a user account after termination. This script will automate the following tasks:
    a.) Archive the user account's homeshare if it exists
    b.) Archive the account's mailbox if it exists
    c.) Finally, delete the account from the active directory
.EXAMPLE
   Example of how to use this workflow
.EXAMPLE
   Another example of how to use this workflow
.INPUTS
   This script uses the native Get-ADUser to lookup user accounts.
.OUTPUTS
   Output from this should be formated to be able to place into a ticket for completion.
#>
workflow Remove-NobleUser 
{
    Param
    (
        # User or users to remove due to termination.
        [string[]]
        $Usernames
    )
    

}