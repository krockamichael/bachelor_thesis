# gnucrypt

a glibc crypt(3) wrapper (compat: lua <= 5.3)

# example

	~ > lua5.1 
	Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio
	>
	> -- load module
	> c = require('gnucrypt')
	>
	> -- crypt password
	> print(c.crypt('password', 'salt'))
	sa3tHJ3/KuYvI
	> print(c.crypt('password', '$1$salt'))
	$1$salt$qJH7.N4xYta3aEG/dfqo/0
	> print(c.crypt('password', '$5$salt'))
	$5$salt$Gcm6FsVtF/Qa77ZKD.iwsJlCVPY0XSMgLJL0Hnww/c1
	> print(c.crypt('password', '$6$salt'))
	$6$salt$IxDD3jeSOb5eB1CX5LBsqZFVkJdido3OUILO5Ifz5iwMuTS4XMS130MTSuDDl3aCI6WouIL9AjRbLCelDCy.g.
	>
	> -- compare password
	> print(c.crypt('password', '$6$salt$IxDD3jeSOb5eB1CX5LBsqZFVkJdido3OUILO5Ifz5iwMuTS4XMS130MTSuDDl3aCI6WouIL9AjRbLCelDCy.g.'))
	$6$salt$IxDD3jeSOb5eB1CX5LBsqZFVkJdido3OUILO5Ifz5iwMuTS4XMS130MTSuDDl3aCI6WouIL9AjRbLCelDCy.g.
