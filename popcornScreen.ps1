# PowerShell Popcorn

# Define our array of Kernel pieces

 

[Array]$Popcorn=$NULL

$Popcorn+="( 0 )"

$Popcorn+=" ( ) "

$Popcorn+=" O "

$Popcorn+=" o "

$Popcorn+=" * "

$Popcorn+=" | "

$Popcorn+=" \ "

$Popcorn+=" - "

$Popcorn+=" . "

$Popcorn+=" . "

 

# Grab the cursor position

$Location=$Host.UI.RawUI.CursorPosition

 

# Get our parameters within the Console

$StartColumn=([int](($popcorn[0].Length/2)+.1))

$MaximumX=$Host.UI.RawUI.WindowSize.Width-$StartColumn

 

$TotalPopcorn=$Popcorn.Count

$MaximumY=$Host.UI.RawUI.WindowSize.Height-$TotalPopcorn

 

#Clear the Screen

CLEAR-HOST

 

# Declare our popping cool function

Function pop-corn()

{

 

#Grab a random position

$StartX=GET-RANDOM $MaximumX

$StartY=(GET-RANDOM $MaximumY)+$TotalPopcorn

 

$Location.X=$StartX

 

For ($p=$TotalPopcorn-1;$p --; $p –ge 0)

            {

                        $Location.Y=($StartY+$p)

 

                        # Move the cursor

                        $Host.UI.RawUI.CursorPosition=$Location

 

                        # Drop a Kernel

                        WRITE-HOST $Popcorn[$p]

 

                        # Move the cursor

                        $Erase=$Location

                        $Erase.Y=($StartY+$p+1)

 

                        # Krush an older Kernel

 

                        $Host.UI.RawUI.CursorPosition=$Erase

                        WRITE-HOST "  "

 

                        # Grab a quick nap

start-sleep -milliseconds 10

            }

}

 

# Let’s decorate the console

$Host.Ui.RawUI.WindowTitle="PowerShell Popcorn"

 

do {

            # You can adjust the 30 Higher or Lower

            # to increase or decrease the possibility of

            # popping

            if ((GET-RANDOM 50) -lt 30)

                        {

                        # irritate your coworkers with noise

                        #[console]::beep(4000+(GET-RANDOM 4000),100)

 

                        # Pop some Corn

                        Pop-Corn                      }

            ELSE

                        # 1000 milliseconds equals one second.

                        # You could make this larger or smaller or even sleep

                        # RANDOM amount of time using

                        #

                        # START-SLEEP –milliseconds (GET-RANDOM 5000)

{ START-SLEEP -milliseconds (Get-Random 100) }

            }

until ($FALSE)