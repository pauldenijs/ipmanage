sub mark {
	my ($str_in,$highlight)=@_;
	if ($highlight ne "") {
		$str_in=~s/(${highlight})/<span style='background-color:#ffc158;'>$1<\/span>/gi;
	}
	return ($str_in);
}

sub search_screen {
	my ($FORM)=@_;

	if ($advancedsearchflag eq "") {
		print "<div style=\"display: block;\" id=\"simplesearch\">\n";
	} else {
		print "<div style=\"display: none;\" id=\"simplesearch\">\n";
	}
	print "<TABLE BORDER=0 CELLPADDING=1 CELLSPACING=1>\n";
	print "<TD align=left class='BODYt'>\n";
	print $q->textfield(
		-name=>searchstring,
		-size=>40,
		-value=>'Search',
		-class=>search,
		-maxsize=>80,
		-onmouseover=>"
			document.$FORM.searchstring.focus();
			if (document.$FORM.searchstring.value == 'Search') {
				document.$FORM.searchstring.value='';
			}
			// document.$FORM.action2.value='submitsimplesearch';
			balloon_popLayer(this,'Type in the string to search.<BR>Leading and trailing spaces in the string will be trimmed (deleted)<BR>Note: Hitting the RETURN key will submit the <FONT COLOR=#ff0000>Simple Search!</FONT>');

		",
		-onmouseout=>"
			balloon_hideLayer();
		",
		-onchange=>"
			// document.$FORM.action2.value='submitsimplesearch';
			// document.$FORM.submit();
			document.$FORM.searchstring.value=trim(document.$FORM.searchstring.value);
		",
		-onkeypress=>"
			if (event.keyCode==13) {
				document.$FORM.searchstring.value=trim($FORM.searchstring.value);
				// submit the form with simplesearch ....
				document.$FORM.action2.value='submitsimplesearch';
				document.$FORM.submit();
			}
			return event.keyCode!=13;
		",
	),"\n";
	print "</TD>\n";
	print "<TD align=left class='BODYt'>\n";
	print $q->button(
		-name=>'dummy',
		-value=>'Submit Simple Search',
		-override=>1,
		-class=>button,
		-onclick=>"
			document.$FORM.action2.value='submitsimplesearch';
			document.$FORM.submit();
		",
		),"\n";
	print "</TD>\n";
	print "<TD align=left class='BODYt'>\n";
	print $q->button(
		-name=>'dummy',
		-value=>'Submit RegExpr Search',
		-override=>1,
		-class=>button,
		-onclick=>"
			document.$FORM.action2.value='submitregexpsearch';
			document.$FORM.submit();
		",
		),"\n";
	print "</TD>\n";
	print "<TD align=right WIDTH=20% class='BODYt'>\n";
	print "&nbsp;";
	print "</TD>\n";
	print "<TD align=right class='BODYt'>\n";
	print $q->button(
		-name=>'advancedsearch',
		-value=>'Advanced Search',
		-class=>button,
		-onclick=>"
			swap_divs('simplesearch','advancedsearch');
			document.$FORM.advancedsearchflag.value='yes';
			document.$FORM.searchstring.value='';
		",
		),"\n";
	print "</TD>\n";
	print "</TABLE>\n";
	print "</div>\n";
	
	if ($advancedsearchflag eq "") {
		print "<div style=\"display: none;\" id=\"advancedsearch\">\n";
	} else {
		print "<div style=\"display: block;\" id=\"advancedsearch\">\n";
	}
	print "<TABLE BORDER=0 CELLPADDING=1 CELLSPACING=1>\n";
	print "<TD align=left class='BODYt'>\n";
	&advanced_search($FORM);
	print "</TD>\n";
	print "<TD align=right WIDTH=20% class='BODYt'>\n";
	print "&nbsp;";
	print "</TD>\n";
	print "<TD align=right class='BODYt'>\n";
	print $q->button(
		-name=>'simplesearch',
		-value=>'Simple Search',
		-class=>button,
		-onclick=>"
			swap_divs('advancedsearch','simplesearch');
			document.$FORM.advancedsearchflag.value='';
		",
		),"\n";
	print "</TD>\n";
	print "</TABLE>\n";
	print "</div>\n";
	print "<P>\n";
	if ($advancedsearchflag eq "") {
		print "<SCRIPT language=javascript>";
		print "document.$FORM.simplesearch.focus();";
		print "</SCRIPT>";
	} else {
		print "<SCRIPT language=javascript>";
		print "document.$FORM.advancedsearch.focus();";
		print "</SCRIPT>";
	}
}

sub advanced_search {
	my ($FORM)=@_;
	print <<__JAVASCRIPT__;
	<SCRIPT LANGUAGE=javascript>
	function checkbrackets(form) {
		var openbracket=0;
		var closebracket=0;
	
		for (i=0;i<form.bracketopen.length;i++) {
			if (form.bracketopen[i].value != '') {
				openbracket++;
			}
			if (form.bracketclose[i].value != '') {
				closebracket++;
			}
		}
	
		if (openbracket > closebracket) {
			alert("Unmatched close bracked !");
			return false;
		} 
		if (openbracket < closebracket) {
			alert("Unmatched open bracked !");
			return false;
		} 
	
		var message=''
		var realnr=0;
	
		for (i=0;i<form.nrfields.value;i++) {
			realnr=i + 1;
			if (form.fieldvalue[i]!=undefined) {
				if (form.fieldvalue[i].value=='') {
					message+="Warning: row " + realnr + " is empty!\\n";
				}
			}
		}
	
		if (message != '') {
			message+="\\nDo you want to continue ?\\n";
			var answer=confirm(message);
			if (!answer) {
				return false;
			}
		}
	
		return true;
	}
	</SCRIPT>
__JAVASCRIPT__
	
	@bracket_open=['','('];
	@bracket_close=['',')'];
	
	@selectvalues=[
		'contains',
		'doesnotcontain',
		'is',
		'isnot',
		'beginswith', 
		'endswith',
		'greaterorequal',
		'lowerorequal',
		'rlike',
		];
	
	%selectlabels=(
		'contains'		=>'contains',
		'doesnotcontain'	=>'does not contain',
		'is'			=>'is',
		'isnot'			=>'is not',
		'beginswith'		=>'begins with', 
		'endswith'		=>'ends with',
		'endswith'		=>'ends with',
		'greaterorequal'	=>'greater or equal then',
		'lowerorequal'		=>'lower or equal then',
		'rlike'			=>'regular expression',
		);
	
	@fieldvalues=[
		'ip_hosts.ipdotted',
		'ip_hosts.hostname',
		'ip_hosts.aliases',
		'ip_hosts.comment',
		'ip_hosts.modifier',
		'ip_hosts.modified',
		];
	
	%fieldlabels=(
		'ip_hosts.ipdotted'		=>'Host IP',
		'ip_hosts.hostname'		=>'Host Name',
		'ip_hosts.aliases'		=>'Alias(ses)',
		'ip_hosts.comment'		=>'Comment',
		'ip_hosts.modifier'		=>'Modifier',
		'ip_hosts.modified'		=>'Modified',
		);
	
	print "<TABLE BORDER=0 CELLPADDING=1 CELLSPACING=1>\n";
	print "<TR>\n";
	print "<TD COLSPAN=9 ALIGN=CENTER class='BODYt'>\n";
	print "<H2>Advanced Search</H2>\n";
	print "</TD>\n";
	print "</TR>\n";
	
	for ($i=0;$i<$nrfields;$i++) {
		if ($i) {
			print "<TR>\n";
			print "<TD COLSPAN=9 ALIGN=CENTER class='BODYt'>\n";
			print $q->popup_menu(
				-override=>1,
				-name=>andor,
				-values=>['AND','OR'],
				-default=>$andor[$i-1],
			),"\n";
	
			print "</TD>\n";
			print "</TR>\n";
		} 
	
		print "<TR>\n";
	
		print "<TD class='BODYt'>\n";
		print $i+1;
		print "</TD>\n";
		
	
		print "<TD class='BODYt'>\n";
		print $q->popup_menu(
			-override=>1,
			-name=>bracketopen,
			-values=>@bracket_open,
			-default=>$bracketopen[$i],
			),"\n";
		print "</TD>\n";
	
		print "<TD class='BODYt'>\n";
		print $q->popup_menu(
			-override=>1,
			-name=>field,
			-values=>@fieldvalues,
			-labels=>\%fieldlabels,
			-default=>$field[$i],
			),"\n";
		print "</TD>\n";
	
		print "<TD class='BODYt'>\n";
		print $q->popup_menu(
			-override=>1,
			-name=>selection,
			-values=>@selectvalues,
			-labels=>\%selectlabels,
			-default=>$selection[$i],
			),"\n";
		print "</TD>\n";
	
		print "<TD class='BODYt'>\n";
		print $q->textfield(
			-name=>fieldvalue,
			-override=>1,
			-size=>80,
			-maxlength=>80,
			-default=>$fieldvalue[$i],
			),"\n";
		print "</TD>\n";
	
		print "<TD class='BODYt'>\n";
		print $q->popup_menu(
			-override=>1,
			-name=>bracketclose,
			-values=>@bracket_close,
			-default=>$bracketclose[$i],
			),"\n";
		print "</TD>\n";
	
		print "<TD WIDTH=10 class='BODYt'>\n";
		print "&nbsp;";
		print "</TD>\n";
	
		print "<TD class='BODYt'>\n";
		print $q->button(
			-name=>plus,
			-value=>'+',
			-class=>button,
			-onclick=>"
				document.$FORM.action2.value='plus';
				document.$FORM.nrfields.value++;
				document.$FORM.submit();
			",
			),"\n";
		print "</TD>\n";
	
		print "<TD class='BODYt'>\n";
		print $q->button(
			-name=>min,
			-value=>'-',
			-class=>button,
			-onclick=>"
				document.$FORM.field[$i].value='';
				document.$FORM.selection[$i].value='';
				document.$FORM.fieldvalue[$i].value='';
				if (document.$FORM.andor[$i]!=undefined) {
					document.$FORM.andor[$i].value='';
				}
				document.$FORM.action2.value='min';
				document.$FORM.nrfields.value--;
				document.$FORM.submit();
			",
			),"\n";
		print "</TD>\n";
	
		print "</TR>\n";
	
	}
	print "<TR>\n";
	print "<TD COLSPAN=9 ALIGN=CENTER class='BODYt'>\n";
	print $q->button(
		-name=>'dummy',
		-value=>'Submit Advanced Search',
		-override=>1,
		-class=>button,
		-onclick=>"
			if (!checkbrackets(document.$FORM)) {
				return false;
			}
			document.$FORM.action2.value='submitadvancedsearch';
			document.$FORM.submit();
		",
	),"\n";
	print "</TD>\n";
	print "</TR>\n";
	print "</TABLE>\n";
	
	print "<BR>\n";
	
	### where clause textfield, change hidden to textfield for debug
	print $q->hidden(
		-name=>whereclause,
		-default=>$whereclause,
		-override=>1,
		-size=>160,
		-maxsize=>256,
		),"\n";
}

sub build_show_query {
	print STDERR "Building sql query\n";

	my ($csv_out)=@_;

	if ($searchstring eq "Search") {
		$searchstring = "";
	}

	if ($action2 eq "") {
		$action2 = "submitsimplesearch";
	}

	$cmd1="";

	if ($action2 eq "submitsimplesearch") {
		if ($searchstring ne "") {
			$cmd1="
			WHERE (
				ip_hosts.ipdotted		like '%$searchstring%'  OR
				ip_hosts.hostname		like '%$searchstring%'  OR
				ip_hosts.aliases		like '%$searchstring%'  OR
				ip_hosts.comment		like '%$searchstring%'  OR
				ip_hosts.modifier		like '%$searchstring%'  OR
				ip_hosts.modified		like '%$searchstring%'
			)
			";
		} else {
			$cmd1='';	
		}
	} 
	if ($action2 eq "submitregexpsearch") {
		if ($searchstring ne "") {
			$cmd1="
			WHERE (
				ip_hosts.ipdotted		rlike '$searchstring'  OR
				ip_hosts.hostname		rlike '$searchstring'  OR
				ip_hosts.aliases		rlike '$searchstring'  OR
				ip_hosts.comment		rlike '$searchstring'  OR
				ip_hosts.modifier		rlike '$searchstring'  OR
				ip_hosts.modified		rlike '$searchstring' 
			)
			";
		} else {
			$cmd1='';	
		}
	} 
	if ($action2 eq "submitadvancedsearch") {
		if ($whereclause ne '') {
			$cmd1="WHERE ($whereclause)";
		} 
	}

	# build the sql query for the normal "show"
	my $cmd="";

	if ($cmd1 ne '') {
		$cmd="
			SELECT	
				ip_hosts.ip,
				ip_hosts.hostname,
				ip_hosts.aliases,
				ip_hosts.comment,
				ip_hosts.modified,
				ip_hosts.modifier,
				DATE_FORMAT(ip_hosts.modified,'%d-%b-%Y %H:%i')
			FROM ip_hosts
			$cmd1
			ORDER BY ip 
		"; 
	}

	print STDERR "$cmd\n" if ($debug);
	return ($cmd);
}

sub build_whereclause_var {
	if ($nrfields eq "") {
		$nrfields=1;
	}

	if ($action2 eq "submitadvancedsearch") {
		$whereclause="";
		for ($i=0;$i<$nrfields;$i++) {
			$whereclause .= $bracketopen[$i] if ($bracketopen[$i] ne "");
			$whereclause.=$field[$i]." "; 
			if ($selection[$i] eq "contains") {
				$whereclause.="LIKE '%".$fieldvalue[$i]."%'"; 
			} elsif ($selection[$i] eq "doesnotcontain") {
				$whereclause.="NOT LIKE '%".$fieldvalue[$i]."%'";
			} elsif ($selection[$i] eq "is") {
				$whereclause.="= '$fieldvalue[$i]'" ; 
			} elsif ($selection[$i] eq "isnot") {
				$whereclause.="!= '$fieldvalue[$i]'";
			} elsif ($selection[$i] eq "beginswith") {
				$whereclause.="LIKE '".$fieldvalue[$i]."%'";
			} elsif ($selection[$i] eq "endswith") {
				$whereclause.="LIKE '%".$fieldvalue[$i]."'";
			} elsif ($selection[$i] eq "greaterorequal") {
				$whereclause.=">= '$fieldvalue[$i]'";
			} elsif ($selection[$i] eq "lowerorequal") {
				$whereclause.="<= '$fieldvalue[$i]'";
			} elsif ($selection[$i] eq "rlike") {
				$whereclause.="RLIKE '".$fieldvalue[$i]."'";
			} 
			$whereclause.=$bracketclose[$i] if ($bracketclose[$i] ne "");
			$whereclause.=" $andor[$i] " unless ($i==$nrfields-1);
		} 
		print STDERR "\$whereclause = $whereclause\n";
	}
}
	
1;
