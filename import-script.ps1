############################################
# Author: NSC				               #
# PCE Deutschland GmbH, Im Langel 4        #
# 59872 Meschede                           #
# 12/2012                                  #
# All rights reserved.                     #
############################################

$kundendateien = get-ChildItem C:\ebootis\interface\intercompany\PCE_DE_Order\*.* -name -include *.xml

foreach ($datei in $kundendateien)
 	{
	}

if ($datei)
{
#eparcel start
cd "C:\ebootis\interface\intercompany\PCE_DE_Order\ps\"
php eParcel_check.php
sleep 50
robocopy C:\ebootis\interface\intercompany\PCE_DE_Order C:\ebootis\interface\intercompany\PCE_DE_Order_2 /MOV
}