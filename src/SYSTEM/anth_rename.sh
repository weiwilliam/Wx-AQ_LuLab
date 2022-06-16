for file in `ls wrfchem*`;do mv $file `echo $file|sed 's/2018/year/g'`;done;


