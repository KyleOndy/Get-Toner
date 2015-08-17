function Get-Toner ($printServer)
{
  $printers = Get-WmiObject -Class Win32_Printer -ComputerName $printServer | select Caption,Location,portname

  $TonerStatus = @()
  foreach ($printer in $printers)
  {
    $SNMP = New-Object -ComObject olePrn.OleSNMP
    $SNMP.open($printer.portname,"public",2,3000)
    # OID for printer status
    $raw = $SNMP.gettree("43.11.1.1")

    # Break the single string into multipule strings for easier processing
    $split = $raw -split [environment]::NewLine

    # Due to all the descriptions appearing first, the associated values are offset 1/2 the total list from their respective descritpion
    $offset = $split.Count / 2

    # Magic Value of 8, there are 8 description values, so this gives us the total number of items we are working with
    $lines = $offset / 8



    for ($i = 0; $i -lt $lines; $i++)
    {
    <#
    Offset of values

    (0)  MarkerSuppliesMarkerIndex.1.1
    (1)  MarkerSuppliesColorantIndex.1.1
    (2)  MarkerSuppliesClass.1.1
    (3)  MarkerSuppliesType.1.1
    (4)  MarkerSuppliesDescription.1.1
    (5)  MarkerSuppliesSupplyUnit.1.1
    (6)  MarkerSuppliesMaxCapacity.1.1
    (7)  MarkerSuppliesLevel.1.1

    #>
      $description = $split[$offset + $i + ($lines * 4)]
      $maxCapacity = $split[$offset + $i + ($lines * 6)]
      $level = $split[$offset + $i + ($lines * 7)]

      $obj = [pscustomobject]@{
        "PrinterDescription" = $printer.Caption;
        "PrinterLocation" = $printer.Location;
        "PrinterIP" = $printer.portname;
        "Description" = $description;
        "MaxCapacity" = [int]$maxCapacity;
        "Level" = [int]$level;
        "Remaining" = [int]($level / $maxCapacity * 100)
      }
      $TonerStatus += $obj
    }
  }
  $TonerStatus
}