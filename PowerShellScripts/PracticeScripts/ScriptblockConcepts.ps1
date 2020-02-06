$variable = 'foo'
$myscriptblock = { "$variable bar" }
& $myscriptblock


Invoke-Expression -Command "write-output 'foo'"

$var = 2
Invoke-Command -ScriptBlock {Write-Output "Invoke command"; 1 + $var}

$foo = {
    param($arg)

    Write-Host "Hello $arg from Foo ScriptBlock" -ForegroundColor Yellow
}

$foo2 = {
    param($arg)

    Write-Host "Hello $arg from Foo2 ScriptBlock" -ForegroundColor Red
}


function Run-Foo([ScriptBlock] $cb, $fooArg){

    #fake getting the args to pass into callback... or it could be passed in...
    if(-not $fooArg) {
        $fooArg = "World" 
    }
    #invoke the callback function
    $cb.Invoke($fooArg);

    #rest of function code....
}

Clear-Host

Run-Foo -cb $foo 
Run-Foo -cb $foo 

Run-Foo -cb $foo2
Run-Foo -cb $foo2 -fooArg "Tim"