$htmlexport = @"
<html>
<head>
</head>
<body>
<table border="1" style="width:100%">
<tr>
    <th>Name</th>
    <th>Status</th>
    <th>Displayname</th>
<tr>
"@
$Services = Get-Service | Select-Object Name,Status,Displayname
foreach ($service in $Services)
{
$htmlexport += @"
<tr>
    <td>$($Service.name)</td>
    <td>$($Service.status)</td>
    <td>$($Service.displayname)</td>
</tr>
"@
}
$htmlexport += @"
</table>
</body>
</html>
"@

$htmlexport | Out-File D:\services.html