$file = Get-Item ".\dsim_work" -ErrorAction SilentlyContinue

if ($file) {
Remove-Item -Recurse -Force dsim_work
}
 
$start_time = Get-Date -UFormat %s
 
dlib map -lib ieee $env:STD_LIBS/ieee08
 
dvhcom +acc+b -vhdl2008 -lib work -f filelist.txt

dvlcom +acc+b +incdir+.\source\+.\sv\ dbg_link\sv_sim\sv\*.sv
 
$end_time = Get-Date -UFormat %s
Write-Host "Build time was $([int]$end_time - [int]$start_time) seconds."
 
$start_time = Get-Date -UFormat %s

for ($i = 0; $i -le 31; $i++) {
    dsim +acc+b -lib work -top work.tb_top -sv_seed $i -l logs\dsim$i.log
    Write-Host ""
    Write-Host ""
}
 
$end_time = Get-Date -UFormat %s
Write-Host "Execution time was $([int]$end_time - [int]$start_time) seconds."
Get-Date