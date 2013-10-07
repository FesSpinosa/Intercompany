<?php

define("ORDER_FOLDER","C:\ebootis\interface\intercompany\PCE_DE_Order\\");
define("EPARCEL_FOLDER","D:\import\expeedoshop\Bestellungen_eParcel\\");
define("EPARCEL_INTERFACE",'D:\export\eParcel\run.php');

echo ORDER_FOLDER;


$files = array();
$handle=opendir(ORDER_FOLDER); 
while (false !== ($file = readdir($handle))) 
{ 
    if(preg_match("/.xml/",$file))
    array_push($files,$file);
}


foreach($files as $file)
{
    if(contains_only_eparcel_products($file))
        {
            echo "eparcel!";
            if(false) //(!is_germany($file))
            {
                continue;
            }
            else
             set_DirectQuantityToDeliver_and_move($file);
        }   
    else
        {
            echo "kein eparcel!";
        } 

}
//var_dump($files);
    
    
############### FUNCTIONS
function contains_only_eparcel_products($file)
    {
        $xml = simplexml_load_file(ORDER_FOLDER.$file);
        
		$cmd = "php ".EPARCEL_INTERFACE." --show-stock";
		exec($cmd,$allowed_products);
		
         
          for ($i=0;$i < count($xml->ItemList->Item);$i++)
          {
			$allowed = false;
            $xml->ItemList->Item[$i]->Article->BuyerAid;
			foreach($allowed_products as $product){
				
			$product = explode(';',$product);
              if($product[0] == $xml->ItemList->Item[$i]->Article->BuyerAid && $product[1] > 0)
              {
                       $allowed = true;
              }
			}
			if(!$allowed)
				return false;
          }
    unset($xml);
    return true;
    }
    
    
function is_germany($file)
{
     $xml = simplexml_load_file(ORDER_FOLDER.$file);
        

    if($xml->OrderHeader->OrderParties->DeliveryParty->Address->Country == "DE")
    {
        unset($xml);
        return true;
    }
    
    else
    {
        unset($xml);
        return false;
    }
    
}
    
    
function set_DirectQuantityToDeliver_and_move($file)
    {
        $xml = simplexml_load_file(ORDER_FOLDER.$file);
        for ($i=0;$i < count($xml->ItemList->Item);$i++)
          {
          $xml->ItemList->Item[$i]->addChild("DirectQuantityToDeliver",$xml->ItemList->Item[$i]->Quantity);
          }
        unlink(ORDER_FOLDER.$file);
        file_put_contents(EPARCEL_FOLDER.$file, $xml->asXml()); 

    }
?>