############################################
# Author: NSC				               #
# PCE Deutschland GmbH, Im Langel 4        #
# 59872 Meschede                           #
# 12/2012                                  #
# All rights reserved.                     #
############################################
If (!(Get-Module -Name "SQLite")) {Import-Module "SQLite"}
[String]$Hash_row_value = ""

function eParcel_Check($countrycode,$prod_arr){
	[Boolean]$DeliverState = $true     
	[string]$query = 'SELECT isocode FROM allowed_countries WHERE isocode LIKE "' + $countrycode + '"'
	$prod_str = ""
	foreach($prod in $prod_arr){
		if ($prod_str -eq ""){
			$prod_str = '"' + $prod + '"'
		}else{
			$prod_str += ', "' + $prod + '"'
		}
	}
	[string]$prod_qur = 'SELECT count FROM stock WHERE article IN (' + $prod_str + ')'
	$database = "D:\export\eParcel\data\eParcel.sqlite"
	$connStr = "Data Source = $database"
	$DataSet = New-Object System.Data.DataSet
	$ResDataTable = New-Object System.Data.DataTable
	$ProdDataTable = New-Object System.Data.DataTable
	$conn = New-Object System.Data.SQLite.SQLiteConnection($connStr)
	$conn.Open()

	$dataAdapter = New-Object System.Data.SQLite.SQLiteDataAdapter($query,$conn)
	$dataAdapter.Fill($DataSet) | Out-Null
	$dataAdapter.Fill($ResDataTable) | Out-Null
	$ProdAdapter = New-Object System.Data.SQLite.SQLiteDataAdapter($prod_qur,$conn)
	$ProdAdapter.Fill($ProdDataTable) | Out-Null
	$conn.close()
	$ResTable = $DataSet.Tables[0]
	If($ResDataTable.Rows.Count -gt 0){
		foreach ($DataRow in $ResDataTable.Rows){
			$DataRow | SELECT isocode | Out-Null
		}
	}else{
		$DeliverState = $false
	}
	If ($prod_arr.Count -gt $ProdDataTable.Rows.Count){
		$DeliverState = $false
	}else{
		Foreach ($DataRow in $ProdDataTable){
			$Stockcount = $DataRow | SELECT count
			If ($Stockcount.count -eq 0 -or $Stockcount.count -eq ""){
				$DeliverState = $false
			}
		}
	}
	return $DeliverState
}
function XML_read($datei){
		$UsR_Hash.Clear()
		$XMLpath = "C:\ebootis\interface\intercompany\PCE_DE_Order\" + $datei
		[xml]$xml = get-content $XMLpath

		Foreach ($usr_node in $xml.Order.ItemList.Item){
			if ($UsR_Hash.ContainsKey($usr_node.DeliveryParty.Address.Country)) {
				$UsR_Hash[$usr_node.DeliveryParty.Address.Country] = $UsR_Hash[$usr_node.DeliveryParty.Address.Country] + "," + $usr_node.Article.BuyerAid
			}else{
				$UsR_Hash.Add($usr_node.DeliveryParty.Address.Country, $usr_node.Article.BuyerAid)
			}
			
		}
		return $UsR_Hash
}

$kundendateien = get-ChildItem C:\ebootis\interface\intercompany\PCE_DE_Order\*.* -name -include *.xml

foreach ($datei in $kundendateien)
 	{
		$Usr_Hash = XML_read $datei
		Foreach ($Hash_row in $UsR_Hash.GetEnumerator()){
			$Hash_row_value = $Hash_row.Value
			$DeliverState = eParcel_check $Hash_row.Key $Hash_row_value.split(",")
			If ($DeliverState){
				Copy-Item -Path "C:\ebootis\interface\intercompany\PCE_DE_Order\$datei" -Destination "C:\ebootis\interface\intercompany\PCE_DE_Order\Archiv\$datei"
				Move-Item -Path "C:\ebootis\interface\intercompany\PCE_DE_Order\$datei" -Destination "D:\import\expeedoshop\Bestellungen_eParcel\$datei"
				break
			}else{
				Copy-Item -Path "C:\ebootis\interface\intercompany\PCE_DE_Order\$datei" -Destination "C:\ebootis\interface\intercompany\PCE_DE_Order\Archiv\$datei"
				Move-Item -Path "C:\ebootis\interface\intercompany\PCE_DE_Order\$datei" -Destination "C:\ebootis\interface\intercompany\PCE_DE_Order_2\$datei"
				break
			}
		}
	}
	
#Archiv Ordner leeren

$UsR_Datum = (Get-Date).AddDays(-4)
$UsR_Source = "C:\ebootis\interface\intercompany\PCE_DE_Order\Archiv"
Get-ChildItem $UsR_Source -Recurse | Where {$_.lastwritetime -lt $UsR_Datum -and -not $_.psiscontainer} |% {Remove-Item $_.fullname -Force -Verbose}
<#
if ($datei)
{
#eparcel start
cd "C:\ebootis\interface\intercompany\PCE_DE_Order\ps\"
php eParcel_check.php
sleep 50
robocopy C:\ebootis\interface\intercompany\PCE_DE_Order C:\ebootis\interface\intercompany\PCE_DE_Order_2 /MOV
#>