
cmon=tostring_with_format(mm, "%2.2i")
cday=tostring_with_format(dd, "%2.2i")
chr=tostring_with_format(hh, "%2.2i")	
cyr=tostring_with_format(yy, "%4.4i")
cdom=tostring_with_format(domain, "%2.2i")

fepa = "./wrfchemi_d"+cdom+"_"+cyr+"-"+cmon+"-"+cday+"_"+chr+":00:00"
fe = addfile(fepa, "w")

times = fe->Times
times(0,:) = tochar(cyr+"-"+cmon+"-"+cday+"_"+chr+":00:00")

fe->Times = times 
	

