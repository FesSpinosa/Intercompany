############################################
# Author: NSC				               #
# PCE Deutschland GmbH, Im Langel 4        #
# 59872 Meschede                           #
# 12/2012                                  #
# All rights reserved.                     #
############################################
If (!(Get-Module -Name "SQLite")) {Import-Module "SQLite"}

function eParcel_Check($countrycode,$prod_arr)
{
	[Boolean]$DeliverState = $true     
	$connStr = "Data Source = $database"
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
	$database = "F:\PHP Projekte\Git_Projekte\GSC-eParcel\data\eParcel.sqlite"
	
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
			$DataRow | SELECT isocode | Out-GridView
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

function XML_read(){
	$dateien = Get-ChildItem 'C:\Users\Falk Espenhahn\Documents\GitHub\Intercompany\*.*' -name -Include *.xml
foreach ($datei in $dateien){
	$XMLpath = "C:\Users\Falk Espenhahn\Documents\GitHub\Intercompany\" + $datei
	[xml]$xml = get-content $XMLpath

	Foreach ($usr_node in $xml.Order.ItemList.Item){
		Write-Host $usr_node.DeliveryParty.Address.Country " - " $usr_node.Article.BuyerAid
	}
	Write-Host " ---- "
}
}

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