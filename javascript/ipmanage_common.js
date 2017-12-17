ConfirmWindow=null;
var image_dir;

// get screen available width and height if not already defined;
var saw=screen.availWidth;
var sah=screen.availHeight;

function DoNothing() {;}

function PopupBlocked() {
	var options="";
	options+="toolbar=0,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";
	var h=100;
	var w=100;
	// not in the middle, but on the right bottom
	var t=sah-h;
	var l=saw-w;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;

	var PUwin=window.open('','putest',options);
	if (PUwin && PUwin.top) {
		PUwin.close();
		return false;
	} else {
		return true;
	}
}

function set_image_dir(dir) {
	image_dir=dir;
}

function gotoSite(url) {
        if (url != "NOWHERE") {
                this.location = url;
        }
}


function check_supassword(form) {
	if (form.supassword.value != "") {
		var pwd_msg="";
		pwd_msg += "*" + "Super User Password" + "\n";
		pwd_msg += "contains invalid characters \n";
		pwd_msg += "Valid Characters are: \n";
		pwd_msg += "! # $ & + - : ; = ? @ _ > < 0-9 A-Z a-z SPACE\n";
		for (var i=0;i<form.supassword.value.length;i++) {
			var ch=form.supassword.value.substring(i,i+1);
			if (	ch < ""   || 
				ch == "%" ||
				ch == "\"" ||
				(ch > "&" && ch < "+") ||
				(ch >"," && ch < "0") ||
				(ch > "Z" && ch < "_") ||
				ch > "z" ) {  
				alert(pwd_msg);
				return false;
			} 
		}
	}
	if (form.remote_user.value != "admin" && form.supassword.value == "") {
		var pwd_msg="";
		pwd_msg +="WARNING:\n";
		pwd_msg +="It is recommended to specify a super user ";
		pwd_msg +="password. Otherwise the password will be set to ";
		pwd_msg +="default, which might not be given to you by the ";
		pwd_msg +="system administrators!\n\n";
		pwd_msg +="Click the OK button to continue with the default ";
		pwd_msg +="super user pasword you might not know.\n\n";
		pwd_msg +="Click the CANCEL button to go back and set ";
		pwd_msg +="your own super user pasword.\n\n";
		var answer=confirm(pwd_msg);
		if (!answer) {
			return false;
		} 
	}
	return true;
}

function fillSelectFromArray(selectCtrl, itemArray, defaultItem) {
	var i, j, d;
	// empty existing items
	for (i = selectCtrl.options.length; i >= 0; i--) {
		selectCtrl.options[i] = null; 
	}

	j=0;
	d=0;
	if (itemArray != null) {
		// add new items
		for (i = 0; i < itemArray.length; i++) {
			selectCtrl.options[j] = new Option(itemArray[i][0]);
			if (selectCtrl.options[j].text == defaultItem) {
				d=j;
			} 
			if (itemArray[i][1] != null) {
				selectCtrl.options[j].value = itemArray[i][1]; 
			}
			j++;
		}
		// select first item (prompt) for sub list
		if (itemArray.length) {
			selectCtrl.options[d].selected = true;
		}
   	}
}

/*
function TinyWindow(file,window) {
        var options = "width=1,height=1";
        msgWindow=open(file,window,options);
        if (msgWindow.opener == null) msgWindow.opener = self;
        msgWindow.focus();
	msgWindow.close();
}
*/


function SizedNewWindow(file,window,w,h) {
	// changed to hide the postdata
	var formname="popup";
	var sData="";
	var postdata_array = [''];
	var anchor='';

	// figure out if we have an anchor, like #BOTTOM or something ....
	anchor_array=file.split("#");
	if (anchor_array.length > 1) {
		url_array=anchor_array[0].split("?");
		anchor="#" + anchor_array[1];
	} else {
		url_array=file.split("?");
	}
	
	// do we have postdata ???
	if (url_array.length > 1) {
		postdata_array=url_array[1].split("&");
	}

	sData+= "<form name=" + formname + " action=" + url_array[0] + anchor + " method='post'><BR>";
	sData+= "<div style='display:none;'>"
	for (i=0;i<postdata_array.length;i++) {
		name_value_array=postdata_array[i].split("=");
		if (name_value_array == '') {
			continue;
		}
		sData+="<input type=text name='" +  name_value_array[0] + "' value='" + name_value_array[1] + "' /><BR>";
	}
	sData+= "</form><BR>";
	sData+= "<script type='text/javascript'>";
	sData+= "document." + formname + ".submit();";
	sData+= "</script>";
	sData+= "<div style='display:none;'>"


	var options="";
	options+="toolbar=0,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";

	var t=(sah-h)/2;
	var l=(saw-w)/2;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;

	// changed to hide the postdata
	// msgWindow=open(file,window,options);
	// if (msgWindow.opener == null) msgWindow.opener = self;
	// msgWindow.focus();

	msgWindow=open('',window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.document.write(sData);
	msgWindow.document.close();
	msgWindow.focus();
}

function SizedNewWindowTop(file,window,w,h) {
	// changed to hide the postdata
	var formname="popup";
	var sData="";
	var postdata_array = [''];
	var anchor='';

	// figure out if we have an anchor, like #BOTTOM or something ....
	anchor_array=file.split("#");
	if (anchor_array.length > 1) {
		url_array=anchor_array[0].split("?");
		anchor="#" + anchor_array[1];
	} else {
		url_array=file.split("?");
	}
	
	// do we have postdata ???
	if (url_array.length > 1) {
		postdata_array=url_array[1].split("&");
	}

	sData+= "<form name=" + formname + " action=" + url_array[0] + anchor + " method='post'><BR>";
	sData+= "<div style='display:none;'>"
	for (i=0;i<postdata_array.length;i++) {
		name_value_array=postdata_array[i].split("=");
		if (name_value_array == '') {
			continue;
		}
		sData+="<input type=text name='" +  name_value_array[0] + "' value='" + name_value_array[1] + "' /><BR>";
	}
	sData+= "</form><BR>";
	sData+= "<script type='text/javascript'>";
	sData+= "document." + formname + ".submit();";
	sData+= "</script>";
	sData+= "<div style='display:none;'>"


	var options="";
	options+="toolbar=0,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";

	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=0,";
	attr+="left=0,";
	options += attr;

	// changed to hide the postdata
	// msgWindow=open(file,window,options);
	// if (msgWindow.opener == null) msgWindow.opener = self;
	// msgWindow.focus();
	msgWindow=open('',window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.document.write(sData);
	msgWindow.document.close();
	msgWindow.focus();
}

function SizedNewWindowToolbar(file,window,w,h) {
	// changed to hide the postdata
	var formname="popup";
	var sData="";
	var postdata_array = [''];
	var anchor='';

	// figure out if we have an anchor, like #BOTTOM or something ....
	anchor_array=file.split("#");
	if (anchor_array.length > 1) {
		url_array=anchor_array[0].split("?");
		anchor="#" + anchor_array[1];
	} else {
		url_array=file.split("?");
	}
	
	// do we have postdata ???
	if (url_array.length > 1) {
		postdata_array=url_array[1].split("&");
	}

	sData+= "<form name=" + formname + " action=" + url_array[0] + anchor + " method='post'><BR>";
	sData+= "<div style='display:none;'>"
	for (i=0;i<postdata_array.length;i++) {
		name_value_array=postdata_array[i].split("=");
		if (name_value_array == '') {
			continue;
		}
		sData+="<input type=text name='" +  name_value_array[0] + "' value='" + name_value_array[1] + "' /><BR>";
	}
	sData+= "</form><BR>";
	sData+= "<script type='text/javascript'>";
	sData+= "document." + formname + ".submit();";
	sData+= "</script>";
	sData+= "<div style='display:none;'>"

	var options="";
	options+="toolbar=1,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";
//	options += "width=" + w + ",height=" + h;
	var t=(sah-h)/2;
	var l=(saw-w)/2;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;

	// changed to hide the postdata
	// msgWindow=open(file,window,options);
	// if (msgWindow.opener == null) msgWindow.opener = self;
	// msgWindow.focus();
	msgWindow=open('',window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.document.write(sData);
	msgWindow.document.close();
	msgWindow.focus();
}

function SizedNewWindowSel(file,window,w,h,sel) {
	file+=sel;
	// changed to hide the postdata
	var formname="popup";
	var sData="";
	var postdata_array = [''];
	var anchor='';

	// figure out if we have an anchor, like #BOTTOM or something ....
	anchor_array=file.split("#");
	if (anchor_array.length > 1) {
		url_array=anchor_array[0].split("?");
		anchor="#" + anchor_array[1];
	} else {
		url_array=file.split("?");
	}
	
	// do we have postdata ???
	if (url_array.length > 1) {
		postdata_array=url_array[1].split("&");
	}

	sData+= "<form name=" + formname + " action=" + url_array[0] + anchor + " method='post'><BR>";
	sData+= "<div style='display:none;'>"
	for (i=0;i<postdata_array.length;i++) {
		name_value_array=postdata_array[i].split("=");
		if (name_value_array == '') {
			continue;
		}
		sData+="<input type=text name='" +  name_value_array[0] + "' value='" + name_value_array[1] + "' /><BR>";
	}
	sData+= "</form><BR>";
	sData+= "<script type='text/javascript'>";
	sData+= "document." + formname + ".submit();";
	sData+= "</script>";
	sData+= "<div style='display:none;'>"

	var options="";
	options+="toolbar=0,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";
	var t=(sah-h)/2;
	var l=(saw-w)/2;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;

	// changed to hide the postdata
	// msgWindow=open(file+sel,window,options);
	// if (msgWindow.opener == null) msgWindow.opener = self;
	// msgWindow.focus();
	msgWindow=open('',window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.document.write(sData);
	msgWindow.document.close();
	msgWindow.focus();
}

function NewWindow(file,window) {
	// changed to hide the postdata
	var formname="popup";
	var sData="";
	var postdata_array = [''];
	var anchor='';

	// figure out if we have an anchor, like #BOTTOM or something ....
	anchor_array=file.split("#");
	if (anchor_array.length > 1) {
		url_array=anchor_array[0].split("?");
		anchor="#" + anchor_array[1];
	} else {
		url_array=file.split("?");
	}
	
	// do we have postdata ???
	if (url_array.length > 1) {
		postdata_array=url_array[1].split("&");
	}

	sData+= "<form name=" + formname + " action=" + url_array[0] + anchor + " method='post'><BR>";
	sData+= "<div style='display:none;'>"
	for (i=0;i<postdata_array.length;i++) {
		name_value_array=postdata_array[i].split("=");
		if (name_value_array == '') {
			continue;
		}
		sData+="<input type=text name='" +  name_value_array[0] + "' value='" + name_value_array[1] + "' /><BR>";
	}
	sData+= "</form><BR>";
	sData+= "<script type='text/javascript'>";
	sData+= "document." + formname + ".submit();";
	sData+= "</script>";
	sData+= "<div style='display:none;'>"

	var options= "scrollbars=1,resizable=1,";
	options += "statusbar=0,menubar=0,toolbar=1,location=0,";
	options += "width=1000,height=800";

	// changed to hide the postdata
	// msgWindow=open(file,window,options);
	// if (msgWindow.opener == null) msgWindow.opener = self;
	// msgWindow.focus();
	msgWindow=open('',window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.document.write(sData);
	msgWindow.document.close();
	msgWindow.focus();
}


function NewWindowClassic(file,window) {
	var options= "scrollbars=1,resizable=1,";
	options += "statusbar=0,menubar=0,toolbar=1,location=0,";
	options += "width=1000,height=800";

	msgWindow=open(file,window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.focus();
}

function SizedNewWindowClassic(file,window,w,h) {
	var options= "scrollbars=1,resizable=1,";
	options += "statusbar=0,menubar=0,toolbar=1,location=0,";
	var t=(sah-h)/2;
	var l=(saw-w)/2;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;

	msgWindow=open(file,window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.focus();
}


function NewWindow_arg(arg,file,window) {
	var options= "scrollbars=1,resizable=1,";
	options += "statusbar=0,menubar=0,toolbar=1,location=0,";
	options += "width=1000,height=800";

	file=file + arg;
	msgWindow=open(file,window,options);

	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.focus();
}

function EmptySizedNewWindow(file,window,w,h) {
	var options="";
	options+="toolbar=0,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";
	var t=(sah-h)/2;
	var l=(saw-w)/2;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;
	msgWindow=open(file,window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.focus();
}

function move(fbox, tbox) {
	var arrFbox = new Array();
	var arrTbox = new Array();
	var arrLookup = new Array();
	var i;
	for (i = 0; i < tbox.options.length; i++) {
		arrLookup[tbox.options[i].text] = tbox.options[i].value;
		arrTbox[i] = tbox.options[i].text;
	}
	var fLength = 0;
	var tLength = arrTbox.length;
	for(i = 0; i < fbox.options.length; i++) {
		arrLookup[fbox.options[i].text] = fbox.options[i].value;
		if (fbox.options[i].selected && fbox.options[i].value != "") {
			arrTbox[tLength] = fbox.options[i].text;
			tLength++;
		}
		else {
			arrFbox[fLength] = fbox.options[i].text;
			fLength++;
   		}
	}
	arrFbox.sort();
	arrTbox.sort();
	fbox.length = 0;
	tbox.length = 0;
	var c;
	for(c = 0; c < arrFbox.length; c++) {
		var no = new Option();
		no.value = arrLookup[arrFbox[c]];
		no.text = arrFbox[c];
		fbox[c] = no;
	}
	for(c = 0; c < arrTbox.length; c++) {
		var no = new Option();
		no.value = arrLookup[arrTbox[c]];
		no.text = arrTbox[c];
		tbox[c] = no;
   	}
}

function SetCookie(cookiename,cookievalue,cookiepath,mseconds) {
	var str = ""
	var expires = null

	now=new Date();
	if (mseconds > 0) {
		expires=new Date(now.getTime()+mseconds)
	}

	str += cookiename + "=" + cookievalue
	if (mseconds > 0) {
		str += ";expires=" + expires.toGMTString();
	}
	str += ";path=" + cookiepath

	document.cookie=str
}

function DelCookie (cookiename) {
	var cookiedate = new Date();  // current date & time
	cookiedate.setTime (cookiedate.getTime() - 1000);
	document.cookie=cookiename += "=; expires=" + cookiedate.toGMTString();
}

function GetCookie(name) {
	var dc = document.cookie;
	var prefix = name + "=";
	var begin = dc.indexOf("; " + prefix);
	if (begin == -1) {
		begin = dc.indexOf(prefix);
		if (begin != 0) return null;
	} else {
		begin += 2;
	}
	var end = document.cookie.indexOf(";", begin);
	if (end == -1) {
		end = dc.length;
	}
	return unescape(dc.substring(begin + prefix.length, end));
}


function SetNonpersistCookie(cookiename,cookievalue,cookiepath) {
	var str = ""
	var expires = null

	str += cookiename + "=" + cookievalue
	str += ";path=" + cookiepath

	document.cookie=str
}

function load(file,target) {
	target.window.location.href = file;
}

function popupbox(url,wname) {
	var fwopts = "resizable=1,menubar=1,toolbar=1,location=1,";
	fwopts += "scrollbars=1,statusbar=1,";
	fwopts += "width=500,height=600";

	var wopts="width=550,height=600,resizable=1";
	PopUpWindow=window.open(url,'wname',wopts);
//	PopUpWindow=window.open(url,'wname',fwopts);
}

function Refresh_IC(s){
	window.opener.document.main.refresh.click();
	window.close();
}

function Refresh_IC_noclose(s){
	window.opener.document.main.refresh.click();
}

// document.onkeypress = check_key;
function check_key(evt) {
	var evt  = (evt) ? evt : ((event) ? event : null);
	var node = (evt.target) ? evt.target :
	((evt.srcElement) ? evt.srcElement : null);
	return evt.keyCode;
}

function show_browser() {
	var mstr="browserinfo:\n";
	for (var i in navigator) {
		mstr += "navigator." + i
		mstr +=" = " + navigator[i]
		mstr += "\n"
	}
	mstr+="\n";
	alert(mstr);
}

function to_js_string(mystring) {
	/*
	converts all characters not in 0-9A-Za-z_ (\W) to %XX, so that they can be used in a url and javascript
	*/

	var ret_string='';
	var pattern=/\W/;

	for (var i=0;i<mystring.length;i++) {
		var ch=mystring.substring(i,i+1);
		mymatch=pattern.test(ch);
		if (mymatch) {
			ch='%' + mystring.charCodeAt(i).toString(16);
			ch=ch.toUpperCase();
		}
		ret_string+=ch;
	}
	return ret_string;
}

function check_field_characters(field,fieldname) {
	/* check for unsupported characters */
	for (var i=0;i<field.length;i++) {
		var ch=field.substring(i,i+1);
		if (ch < " " || ch == "\"" || ch == "$" || ch == "`" || ch == "%" || ch == "'" || ch > "z") {
			var msg="Invalid character: " + ch;
			msg+="\nin " + fieldname + " field!";
			alert(msg);
			return false;
		}
	}
	return true;

	/*
	var pattern=/[ 0-9A-Z_-\[\]a-z]/;
	for (var i=0;i<field.length;i++) {
		var ch=field.substring(i,i+1);
		mymatch=pattern.test(ch);
		if (! mymatch) {
			var msg="Invalid character: " + ch;
			msg+="\nin " + fieldname + " field!";
			alert(msg);
			return false;
		}
	}
	return true;
	*/
}

function mysort(what,index,reversed) {
	// call this routine with: result=mysort(ARRAY.1.0)
	// where result is your new array, and ARRAY is your miltidemensional
	// array, 1 is the array sort field and 0 is NOT reversed
	function sort_array(a,b) {
		month_array_string=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
		month_array_nr=['01','02','03','04','05','06','07','08','09','10','11','12'];
		a = a[index];
		b = b[index];
		/*
		a_array=a.split("-");
		b_array=b.split("-");
		for (i=0;i<12;i++) {
			if (a_array[1]==month_array_string[i]) {
				a=a_array[2]+month_array_nr[i]+a_array[0];
			}
		}
		for (i=0;i<12;i++) {
			if (b_array[1]==month_array_string[i]) {
				b=b_array[2]+month_array_nr[i]+b_array[0];
			}
		}
		*/
		if (reversed) {
			return b == a ? 0 : (b < a ? -1 : 1);
		} else {
			return a == b ? 0 : (a < b ? -1 : 1);
		}
	}
	return what.sort(sort_array);
}

function comboSetFocus(f) {
	/* I was struggling with getting focus on some objects where a list
	was longer than the size. When doing a suvmit the selection was still
	there, but it was out of the selection list. Anyway, to refocus you
	must reset the selected item, and set it again. Sorry this was the
	only solution i came up with .....
	*/
	var tmp=f.selectedIndex;
	if (tmp == -1) return; 
	f[tmp].selected=false;
	f[tmp].selected=true;
}
	
if (document.layers) {navigator.family = "nn4"}
if (document.all) {navigator.family = "ie4"}
if (window.navigator.userAgent.toLowerCase().match("gecko")) {navigator.family = "gecko"}

function change_text_in_id(obj,text,blinkflag) {
	if(navigator.family =="nn4") {
		if (blinkflag) {
			text="<blink>" + text + "</blink>";
		} 
        	document.obj.document.write(text);
        	document.obj.document.close();
        } else if (navigator.family =="ie4") {
        	obj.innerHTML=text;
		if (blinkflag) {
        		obj.style.color="#ff0000";
		} else {
        		document.getElementById(obj).style.color="#0000ff";
		}
        } else if (navigator.family =="gecko") {
        	document.getElementById(obj).innerHTML=text;
		if (blinkflag) {
        		document.getElementById(obj).style.color="#ff0000";
		} else {
        		document.getElementById(obj).style.color="#0000ff";
		}
        }
}

function toggle_autorefresh(obj) {
	var ar=GetCookie('AutoRefreshOFF');
	if (ar=="1") {
		DelCookie('AutoRefreshOFF');
		change_text_in_id(obj,'Autorefresh: ON',0);
	} else {
		SetCookie('AutoRefreshOFF','1','',7776000000);
		change_text_in_id(obj,'Autorefresh: OFF',0);
	}
}

function toggle_notifier(obj) {
	var nf=GetCookie('NotifierOn');
	if (nf=="1") {
		DelCookie('NotifierOn');
		change_text_in_id(obj,'Notifier: OFF',0);
	} else {
		SetCookie('NotifierOn','1','',7776000000);
		change_text_in_id(obj,'Notifier: ON',0);
	}
}


overdiv="0";
//  #########  CREATES POP UP BOXES
function popLayer(a,xoffset) {
	if (xoffset==undefined) {
		xoffset=15;
	}
	if (navigator.family == "gecko") {
		pad="0"; bord="1 bordercolor=black";
	} else {
		pad="1"; bord="0";
	}
	desc="<table cellspacing=0 cellpadding="+pad+" border="+bord
	+" bgcolor=ff0000#><tr><td>\n"
        +"<table cellspacing=0 cellpadding=3 border=0 width=100%>"
	+"<tr><td class=popupbg><center><font size=-1>\n"
        +a
        +"\n</td></tr></table>\n"
        +"</td></tr></table>";
	if(navigator.family =="nn4") {
        	document.object1.document.write(desc);
        	document.object1.document.close();
        	document.object1.left=x+xoffset;
        	document.object1.top=y+5;
		document.object1.style.opacity=0.9;
        } else if (navigator.family =="ie4") {
        	object1.innerHTML=desc;
        	object1.style.pixelLeft=x+xoffset;
        	object1.style.pixelTop=y+5;
        } else if (navigator.family =="gecko") {
        	document.getElementById("object1").innerHTML=desc;
        	document.getElementById("object1").style.left=x+xoffset;
        	document.getElementById("object1").style.top=y+5;
		document.getElementById("object1").style.opacity=0.9;
        }
}

// routines for object 2
center_poplayer_div="0";
function CenterImgPopLayer(text,w,h) {
	var t=(window.innerHeight-h)/2;
	var l=(window.innerWidth-w)/2;
//	alert(window.innerHeight + "," + window.innerWidth + "," + l + "," + t);

	if (navigator.family == "gecko") {
		pad="0"; bord="1 bordercolor=black";
	} else {
		pad="1"; bord="0";
	}
	var desc="<table cellspacing=0 cellpadding="+pad+" border="+bord
	+" bgcolor=ff0000#><tr><td>\n"
        +"<table cellspacing=0 cellpadding=0 border=0 width=100%>"
	+"<tr><td class=popupbg><center><font size=-1>\n"
        +text
        +"\n</td></tr></table>\n"
        +"</td></tr></table>";
	if(navigator.family =="nn4") {
        	document.object2.document.write(desc);
        	document.object2.document.close();
        	document.object2.left=l;
        	document.object2.top=t;
		document.object2.style.opacity=0.9;
        } else if (navigator.family =="ie4") {
        	object2.innerHTML=desc;
        	object2.style.pixelLeft=l;
        	object2.style.pixelTop=t;
        } else if (navigator.family =="gecko") {
        	document.getElementById("object2").innerHTML=desc;
        	document.getElementById("object2").style.left=l;
        	document.getElementById("object2").style.top=t;
		document.getElementById("object2").style.opacity=0.9;
        }
}


function MoveAway_object2() {
	if (navigator.family =="nn4") {
		eval(document.object2.top=-sah);
		eval(document.object2.left=-saw);
	} else if (navigator.family =="ie4") {
		object2.innerHTML="";
       	 	object2.style.pixelTop=-sah;
       	 	object2.style.pixelLeft=-saw;
	} else if (navigator.family =="gecko") {
		document.getElementById("object2").style.top=-sah;
		document.getElementById("object2").style.left=-saw;
	}
}

function CenterImgHideLayer() {
	if (center_poplayer_div == "0") {
		obj_object2=new fadingObject('object2',100,0); 
		obj_object2.fadeTo(99,5);
		setTimeout('obj_object2.fadeTo(0,5)',200);
		setTimeout('MoveAway_object2()',2000);
        }
}
// end of routines for object 2

function v_move_pref(box,dir) {
	var arrbox = new Array();
	var i;
	var saved_value,saved_text;
	if (dir == "up") {
		for(i = 0; i < box.options.length; i++) {
			if (box.options[i].selected && 
					box.options[i].value != "" && i != 0) {
				saved_text=box.options[i-1].text;
				saved_value=box.options[i-1].value;
				box.options[i-1].text=box.options[i].text;
				box.options[i-1].value=box.options[i].value;
				box.options[i].text=saved_text;
				box.options[i].value=saved_value;
				box.options[i].selected=false;
				box.options[i-1].selected=true;
			}
		}
	} else {
		for(i = box.options.length-1; i>-1 ; i--) {
			if (box.options[i].selected && 
					box.options[i].value != "" 
					&& i != box.options.length-1) {
				saved_text=box.options[i+1].text;
				saved_value=box.options[i+1].value;
				box.options[i+1].text=box.options[i].text;
				box.options[i+1].value=box.options[i].value;
				box.options[i].text=saved_text;
				box.options[i].value=saved_value;
				box.options[i].selected=false;
				box.options[i+1].selected=true;
			}
		}
	}
}	

function hideLayer() {
	if (overdiv == "0") {
        	if (navigator.family =="nn4") {
			eval(document.object1.top="-500");
		} else if (navigator.family =="ie4") {
			object1.innerHTML="";
		} else if (navigator.family =="gecko") {
			document.getElementById("object1").style.top="-500";
		}
        }
}


function main_timer_update() {
	MainNow = new Date();
	var diff = MainStop - MainNow;
	var d=new Date(diff);	
	seconds = (MainStop - MainNow) / 1000;
	seconds = Math.round(seconds);
	MainID=window.setTimeout('main_timer_update(MainStart);',1000);
	main.refreshcounter.value=seconds;
}



function BottomSizedNewWindow(file,window,w,h) {
	var options="";
	options+="toolbar=0,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";
	var t=sah-h;
	var l=saw-w;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;
	msgWindow=open(file,window,options);
	if (msgWindow.opener == null) msgWindow.opener = self;
	msgWindow.focus();
}

function fadingObject(id,rate,CloseAt) {
	this.id = id;

	this.getOpacity = function() {
		if (document.all) {
			return document.all[this.id].filters['alpha'].opacity;
		}
		else if (document.getElementById) {
			return document.getElementById(this.id).style.MozOpacity*100;
		}
	}

	this.setOpacity = function(percent) {
		if (document.all) {
			document.all[this.id].filters['alpha'].opacity = percent;
		}
		else if (document.getElementById) {
			document.getElementById(this.id).style.MozOpacity = percent/100;
		}
	}

	this.fadeTo = function(newOpacity, deltaPercent) {
		window.clearTimeout(this.timeout);
		if (CloseAt) {
			if(this.getOpacity()==CloseAt) {window.close();} 
		}
		currentOpacity = this.getOpacity();
		if (newOpacity > currentOpacity) {
			if (currentOpacity < newOpacity - deltaPercent) {
				this.setOpacity(currentOpacity + deltaPercent);
				this.timeout = window.setTimeout('obj_'+this.id+'.fadeTo('+newOpacity+', '+deltaPercent+')', rate);
			}
			else {
				this.setOpacity(newOpacity);
			}
		}
		else if (newOpacity < currentOpacity) {
			if (currentOpacity > newOpacity + deltaPercent) {
				this.setOpacity(currentOpacity - deltaPercent);
				this.timeout = window.setTimeout('obj_'+this.id+'.fadeTo('+newOpacity+', '+deltaPercent+')', rate);
			}
			else {
				this.setOpacity(newOpacity);
			}
		}
	}
}


function userpass_crypt(str) {
	var chstr="";
	var strinhex="";
	
	// random shift number 32-64
	var s=Math.floor(32*Math.random()+32);
	var shiftinhex=s.toString(16);

	// length of the string in hex + the random shift nr
	var lengthindec=str.length+s;
	var lengthinhex=lengthindec.toString(16);

	for (i=0;i<str.length;i++) {
		// add random shift number to the character
		var d=str.charCodeAt(i)+s;
		var h=d.toString(16);
		strinhex+=h;
		// reverse the string
		chstr=h + chstr;
	}
	// now add bogus hex numbers to the end of the string to make it
	// 64 characters
	var fillstr="";
	for (i=str.length;i<30;i++) {
		var r=Math.floor(96*Math.random())+32+s;
		var rh=r.toString(16);
		fillstr+=rh;
	}
	// add the shift number in hex to the beginning of the string
	chstr=lengthinhex + chstr + fillstr;

	// now get the whole string and swap all the nibbles
	var saved=shiftinhex;
	for (i=0;i<chstr.length;i++) {
		saved+=chstr.substring(i+1,i+2);
		saved+=chstr.substring(i,i+1);
		i++;
	}
	return (saved);
}

function userpass_decrypt(str) {
	var crypt_array=new Array();
	// retrieve the shift number from the string, and convert to a 
	// integer
	var s=parseInt(str.substring(0,2),16);
	// retrieve the length of the original string, and convert to a
	// integer
	var linhex=str.substring(3,4);
	linhex+=str.substring(2,3);
	var l=parseInt(linhex,16)-s;

	var j=0;
	var crypted_string=str.substring(4,str.length);
	for (i=0;i<crypted_string.length;i++) {
		if (i%2==0) {
			var hn=crypted_string.substring(i+1,i+2); 
			var ln=crypted_string.substring(i,i+1); 
			var chinhex=hn + ln;
			var ascii_int=parseInt(chinhex,16)-s;
			crypt_array[j++]=
				String.fromCharCode(ascii_int.toString(10));
		}
	}

	var uncrypted_string="";
	for (i=l-1;i>-1;i--) {
		uncrypted_string+=crypt_array[i];
	}
	return (uncrypted_string);
}


function mousebutton(event) {
	var button;
	if (event.which == null)
		button= (event.button < 2) ? "LEFT" :
			((event.button == 4) ? "MIDDLE" : "RIGHT");
	else
		button= (event.which < 2) ? "LEFT" :
			((event.which == 2) ? "MIDDLE" : "RIGHT");
	dont(event);
	return button;
}

function dont(event) {
//	if (event.preventDefault)
		event.preventDefault();
//	else
//		event.returnValue= false;
//	return false;
}

var browserusedheight=window.outerHeight-window.innerHeight;
var browserusedwidth=window.outerWidth-window.innerWidth;

function sbar_detect() {
        if ( document.body.clientHeight < document.body.offsetHeight) {
                 return true;
        }
        if ( document.body.clientWidth < document.body.offsetWidth) {
                 return true;
        }
        return false;
}

function resize_to_fit() {
        var h=document.documentElement.clientHeight;
        var w=document.documentElement.clientWidth;

        if (sbar_detect()) {
                h=h+browserusedheight;
                w=w+browserusedwidth;
                if (h > screen.availHeight) {
                        h = screen.availHeight;
                } else {
                        document.documentElement.style.overflow = "hidden";
                }
                if (w > screen.availWidth) {
                        w = screen.availWidth;
                } else {
                        document.documentElement.style.overflow = "hidden";
                }
                window.resizeTo(w,h);
                document.body.style.marginRight='0px';
                document.body.style.marginTop='0px';
                document.documentElement.style.overflow = "auto";
        }
}

function show_totd() {
	if (GetCookie('totd')==null) {
		// alert('TIP');
		SetCookie('totd',1,'',2419200000);
	}
}

function resizeWin(id) {
	winWidth=document.getElementById(id).offsetWidth;
	winHeight=document.getElementById(id).offsetHeight;

	var nx=winWidth+30;
	var ny=winHeight+60;

	if (ny > sah) {
		ny = sah-60;
	}
	if (nx > saw) {
		nx = saw-30;
	}

	window.resizeTo(nx,ny)
}


function show_url_in_popLayer(url) {
	var http;
	if (navigator.appName=='Microsoft Internet Explorer') {
		http = new ActiveXObject('Microsoft.XMLHTTP');
	} else {
		http = new XMLHttpRequest();
	}
	http.open('get', url);
	var content="";
	http.onreadystatechange = function () {
		if (http.readyState == 4) {
			if (http.responseText.length) {
				popLayer(http.responseText,-500);
			}
		}
	}
	http.send(null);
}


var __userAgent = navigator.userAgent;
var __isIE =  navigator.appVersion.match(/MSIE/) != null;
var __IEVersion = __getIEVersion();
var __isIENew = __isIE && __IEVersion >= 8;
var __isIEOld = __isIE && !__isIENew;

var __isFireFox = __userAgent.match(/firefox/i) != null;
var __isFireFoxOld = __isFireFox && ((__userAgent.match(/firefox\/2./i) != null) || (__userAgent.match(/firefox\/1./i) != null));
var __isFireFoxNew = __isFireFox && !__isFireFoxOld;

var __isWebKit =  navigator.appVersion.match(/WebKit/) != null;
var __isChrome =  navigator.appVersion.match(/Chrome/) != null;
var __isOpera =  window.opera != null;
var __operaVersion = __getOperaVersion();
var __isOperaOld = __isOpera && (__operaVersion < 10);

function __getIEVersion() {
	var rv = -1; // Return value assumes failure.
	if (navigator.appName == 'Microsoft Internet Explorer') {
		var ua = navigator.userAgent;
		var re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
		if (re.exec(ua) != null) {
			rv = parseFloat(RegExp.$1);
		}
	}
	return rv;
}

function __getOperaVersion() {
	var rv = 0; // Default value
	if (window.opera) {
		var sver = window.opera.version();
		rv = parseFloat(sver);
	}
	return rv;
}

function __parseBorderWidth(width) {
	var res = 0;
	if (typeof(width) == "string" && width != null && width != "" ) {
		var p = width.indexOf("px");
		if (p >= 0) {
			res = parseInt(width.substring(0, p));
		} else {
			//do not know how to calculate other values 
			//(such as 0.5em or 0.1cm) correctly now
			//so just set the width to 1 pixel
			res = 1; 
		}
	}
	return res;
}

//returns border width for some element
function __getBorderWidth(element) {
	var res = new Object();
	res.left = 0; res.top = 0; res.right = 0; res.bottom = 0;
	if (window.getComputedStyle) {
		//for Firefox
		var elStyle = window.getComputedStyle(element, null);
		res.left = parseInt(elStyle.borderLeftWidth.slice(0, -2));  
		res.top = parseInt(elStyle.borderTopWidth.slice(0, -2));  
		res.right = parseInt(elStyle.borderRightWidth.slice(0, -2));  
		res.bottom = parseInt(elStyle.borderBottomWidth.slice(0, -2));  
	} else {
		//for other browsers
		res.left = __parseBorderWidth(element.style.borderLeftWidth);
		res.top = __parseBorderWidth(element.style.borderTopWidth);
		res.right = __parseBorderWidth(element.style.borderRightWidth);
		res.bottom = __parseBorderWidth(element.style.borderBottomWidth);
	}
	return res;
}

//returns the absolute position of some element within document
function getElementAbsolutePos(element) {
	var res = new Object();
	res.xleft = 0; res.ytop = 0;
	res.xright = 0; res.ybottom = 0;
	if (element !== null) { 
		if (element.getBoundingClientRect) {
			var viewportElement = document.documentElement;  
			var box = element.getBoundingClientRect();
			var scrollLeft = viewportElement.scrollLeft;
			var scrollTop = viewportElement.scrollTop;
			res.xleft = box.left + scrollLeft;
			res.ytop = box.top + scrollTop;
		} else { //for old browsers
			res.xleft = element.offsetLeft;
			res.ytop = element.offsetTop;
			var parentNode = element.parentNode;
			var borderWidth = null;
			while (offsetParent != null) {
				res.xleft += offsetParent.offsetLeft;
				res.ytop += offsetParent.offsetTop;
				var parentTagName = offsetParent.tagName.toLowerCase();	
				if ((__isIEOld && parentTagName != "table") || ((__isFireFoxNew || __isChrome) && parentTagName == "td")) {
					borderWidth = kGetBorderWidth (offsetParent);
					res.xleft += borderWidth.left;
					res.ytop += borderWidth.top;
				}
				if (offsetParent != document.body && offsetParent != document.documentElement) {
					res.xleft -= offsetParent.scrollLeft;
					res.ytop -= offsetParent.scrollTop;
				}
				//next lines are necessary to fix the problem 
				//with offsetParent
				if (!__isIE && !__isOperaOld || __isIENew) {
					while (offsetParent != parentNode && parentNode !== null) {
						res.xleft -= parentNode.scrollLeft;
						res.ytop -= parentNode.scrollTop;
						if (__isFireFoxOld || __isWebKit) {
							borderWidth = kGetBorderWidth(parentNode);
							res.xleft += borderWidth.left;
							res.ytop += borderWidth.top;
						}
						parentNode = parentNode.parentNode;
					}    
				}
				parentNode = offsetParent.parentNode;
				offsetParent = offsetParent.offsetParent;
			}
		}
	}
	res.width=element.offsetWidth;
	res.height=element.offsetHeight;
	res.xleft = parseInt(res.xleft);
	res.ytop = parseInt(res.ytop);
	res.xright=res.xleft+res.width;
	res.ybottom=res.ytop+res.height;

	return res;
}


//  ########  TRACKS MOUSE POSITION FOR POPUP PLACEMENT
var mouse_x=0;
var mouse_y=0;
var x=0;
var y=0;
var StatusMouse=0;

function handlerMM(e) {
	if ('pageX' in e) { // all browsers except IE before version 9
		mouse_x = e.pageX;
		mouse_y = e.pageY;
	} else {
		mouse_x = event.clientX + document.body.scrollLeft;
		mouse_y = event.clientY + document.body.scrollTop;
	}
	// older popLayer uses x and y
	x=mouse_x;
	y=mouse_y;

	if (StatusMouse) {
		document.onmousemove=showMousePosition;
	}
}
document.onmousemove=handlerMM;

function showMousePosition(e) {
	var mX, mY;
	if ('pageX' in e) { // all browsers except IE before version 9
		mX = e.pageX;
		mY = e.pageY;
	} else {
		mX = window.event.clientX + document.body.scrollLeft;
		mY = window.event.clientY + document.body.scrollTop;
	}
	if (lom.x_y_pos != "undefined") {
		lom.x_y_pos.value="X="+mX+"  Y="+mY;
	}
	return true;
}
//  ########  TRACKS MOUSE POSITION FOR POPUP PLACEMENT


//  #########  CREATES POP UP BOXES
var overballoon="0";
var arrowheadimg=["../images/blackarrowleft.gif","../images/blackarrowup.gif","../images/blackarrowright.gif","../images/blackarrowdown.gif"];

function initializetooltip(){
	var tiparrow=document.createElement("img");
	tiparrow.setAttribute("src", arrowheadimg[0]);
	tiparrow.setAttribute("id", "arrowhead");
	document.body.appendChild(tiparrow);

	var balloon_message=document.createElement("div");
	balloon_message.setAttribute("id", "Balloon_Message");
	balloon_message.onmouseover=function () {overballoon=1;};
	balloon_message.onmouseout=function () {overballoon=0;setTimeout('balloon_hideLayer()',1000);};
	document.body.appendChild(balloon_message);
}

function displaytiparrow(img_array_nr,ax,ay) { 
        tiparrow=document.getElementById("arrowhead");
        tiparrow.src=arrowheadimg[img_array_nr];
	tiparrow.style.left=ax;
	tiparrow.style.top=ay;
	tiparrow.style.height="13px";
	tiparrow.style.width="13px";
        tiparrow.style.visibility="visible";
}

function show_url_in_balloon_popLayer(obj,url) {
        var http;
        if (navigator.appName=='Microsoft Internet Explorer') {
                http = new ActiveXObject('Microsoft.XMLHTTP');
        } else {
                http = new XMLHttpRequest();
        }
        http.open('get', url);
        var content="";
        http.onreadystatechange = function () {
                if (http.readyState == 4) {
                        if (http.responseText.length) {
                                balloon_popLayer(obj,http.responseText);
                        }
                }
        }
        http.send(null);
}

var element_style_array=new Array();

function balloon_popLayer(element,content) {
	if (! document.getElementById("Balloon_Message")) {
		// oops, the initializetooltip() didn't run yet ? 
		return false;
	}

	/* this all uses a stylesheet :
	<STYLE>
	.popupbg  {
		background-color: #ffffe0;
	}
	#arrowhead{
		z-index: 99;
		position:absolute;
		top: -500px;
		left: -500px;
		visibility: hidden;
		height:13px;
		width:13px;
	}
	#Balloon_Message {
		position:absolute;
		background-color:#000000;
		color:black;
		border-color:black;
		border-style:solid;
		border-width:1px;
		visibility:hidden;
		left:0px;
		top:0px;
		z-index:+1;
	}
	</STYLE>
	*/

	var el=getElementAbsolutePos(element);
	pad="0"; bord="1 bordercolor=black";
	var content_width=0;
	var content_height=0;

        var desc=
		"<table cellspacing=3 cellpadding=0 border=0 class=popupbg >" 
		+"<tr>"
		+"<td class=popupbg>"
		+	"<table cellspacing=0 cellpadding=0 border=0 width=100%>" 
		+	"<tr>"
		+	"<td class=popupbg>"
		+		"<center><font size=-1>"
		+		content 
		+		"</font></center>"
		+	"</td>"
		+	"</tr>"
		+	"</table>"
		+"</td>"
		+"</tr>"
		+"</table>";

	document.getElementById("Balloon_Message").innerHTML=desc;

	content_width=document.getElementById("Balloon_Message").offsetWidth;				// width of the popup
	content_height=document.getElementById("Balloon_Message").offsetHeight;				// height of the popup

	// Find the biggest area in the window to put the popup box. The popup box should NEVER be placed on top of the element.
	var new_x_pos=-5000;
	var new_y_pos=-5000;
	var arrow_type=-1;
	var arrow_x=-500;
	var arrow_y=-500;


	// Order of preference: East,South,West,North
	// The arrow is set to 13x13 (see function displaytiparrow() )

	// try East, South, West, North as a FULL fit first.
	// if they all fail, then try
	// South then at last East with NO restrictions 
	if ( (window.innerHeight > content_height) && (window.innerWidth - el.xright + 13 > content_width) ) {
		// East: (full fit)
		arrow_type=0;
		arrow_x=el.xright;
		if (mouse_y > el.ybottom - 13 ) {
			arrow_y=el.ybottom - 13;
		} else if ( mouse_y < el.ytop + 13 ) { 
			arrow_y=el.ytop;
		} else {
			arrow_y=mouse_y + 7;
		}
		new_x_pos=el.xright + 13;
		if (window.innerHeight - el.ytop > content_height) {
			new_y_pos=el.ytop;
			if (el.ytop<0) {
				new_y_pos-=el.ytop;
			}
		} else {
			// ok move up as much as possible
			new_y_pos=window.innerHeight - content_height;
			if (el.ytop<0) {
				new_y_pos-=el.ytop;
			}
		}
		if (arrow_y - 13 < new_y_pos) {
			arrow_y = new_y_pos;
		} 
		if (arrow_y + 13  > new_y_pos + content_height) {
			arrow_y = new_y_pos + content_height - 13;
		}
	} else if ( (window.innerHeight - el.ybottom > content_height) && (window.innerWidth > content_width) ) {
		// South: (full fit)
		arrow_type=1;
		arrow_y=el.ybottom;
		if (mouse_x > el.xright - 13 ) {
			arrow_x=el.xright - 13;
		} else if ( mouse_x < el.xleft + 13 ) { 
			arrow_x=el.xleft;
		} else {
			arrow_x=mouse_x + 7;
		}
		new_y_pos=el.ybottom + 13;
		if (window.innerWidth - el.xright > content_width) {
			new_x_pos=0;
			if (el.xright > window.innerWidth) {
				new_x_pos=window.innerWidth - content_width;
			}
		} else {
			new_x_pos=el.xright - content_width;
			if (new_x_pos < 0) {
				new_x_pos=0;
			}
		}
		if (arrow_x - 13 < new_x_pos) {
			arrow_x = new_x_pos + 13;
		}
		if (arrow_x + 13 > new_x_pos + content_width) {
			arrow_x = new_x_pos + content_width - 13;
		}
	} else if ( (window.innerHeight > content_width) && (el.xleft > content_width + 13) ) {
		// West: (full fit)
		arrow_type=2;
		arrow_x=el.xleft - 13;
		if (mouse_y > el.ybottom - 13 ) {
			arrow_y=el.ybottom - 13;
		} else if ( mouse_y < el.ytop + 13 ) { 
			arrow_y=el.ytop;
		} else {
			arrow_y=mouse_y + 7;
		}
		new_x_pos=el.xleft - 13 - content_width;
		if (window.innerHeight - el.ytop > content_height) {
			new_y_pos=el.ytop;
			if (el.ytop<0) {
				new_y_pos-=el.ytop;
			}
		} else {
			// ok move up as much as possible
			new_y_pos=window.innerHeight - content_height;
			if (el.ytop<0) {
				new_y_pos-=el.ytop;
			}
		}
		if (arrow_y - 13 < new_y_pos) {
			arrow_y = new_y_pos;
		} 
		if (arrow_y + 13  > new_y_pos + content_height) {
			arrow_y = new_y_pos + content_height - 13;
		}
	} else if ( (el.ytop - 13 > content_height) && (window.innerWidth > content_width) ) {
		// North: (full fit)
		arrow_type=3;
		arrow_y=el.ytop - 13;
		if (mouse_x > el.xright - 13 ) {
			arrow_x=el.xright - 13;
		} else if ( mouse_x < el.xleft + 13 ) { 
			arrow_x=el.xleft;
		} else {
			arrow_x=mouse_x + 7;
		}
		new_y_pos=el.ytop - 13 - content_height;
		if (window.innerWidth - el.xright > content_width) {
			new_x_pos=0;
			if (el.xright > window.innerWidth) {
				new_x_pos=window.innerWidth - content_width;
			}
		} else {
			new_x_pos=el.xright - content_width;
			if (new_x_pos < 0) {
				new_x_pos=0;
			}
		}
		if (arrow_x - 13 < new_x_pos) {
			arrow_x = new_x_pos + 13;
		}
		if (arrow_x + 13 > new_x_pos + content_width) {
			arrow_x = new_x_pos + content_width - 13;
		}
	// calculate area right of and below the area, the biggest wins ....
	} else if ( window.Height * (window.Width - el.xright - 13) > (window.Height - 13 - el.ybottom) * window.Width) {
		// East!
		arrow_type=0;
		arrow_x=el.xright;
		if (mouse_y > el.ybottom - 13 ) {
			arrow_y=el.ybottom - 13;
		} else if ( mouse_y < el.ytop + 13 ) { 
			arrow_y=el.ytop;
		} else {
			arrow_y=mouse_y + 7;
		}
		new_x_pos=el.xright + 13;
		if (window.innerHeight - el.ytop > content_height) {
			new_y_pos=el.ytop;
			if (el.ytop<0) {
				new_y_pos-=el.ytop;
			}
		} else {
			// ok move up as much as possible
			new_y_pos=window.innerHeight - content_height;
			if (el.ytop<0) {
				new_y_pos-=el.ytop;
			}
		}
		if (arrow_y - 13 < new_y_pos) {
			arrow_y = new_y_pos;
		} 
		if (arrow_y + 13  > new_y_pos + content_height) {
			arrow_y = new_y_pos + content_height - 13;
		}
	} else {
		// South
		arrow_type=1;
		arrow_y=el.ybottom;
		if (mouse_x > el.xright - 13 ) {
			arrow_x=el.xright - 13;
		} else if ( mouse_x < el.xleft + 13 ) { 
			arrow_x=el.xleft;
		} else {
			arrow_x=mouse_x + 7;
		}
		new_y_pos=el.ybottom + 13;
		if (window.innerWidth - el.xright > content_width) {
			new_x_pos=0;
			if (el.xright > window.innerWidth) {
				new_x_pos=window.innerWidth - content_width;
			}
		} else {
			new_x_pos=el.xright - content_width;
			if (new_x_pos < 0) {
				new_x_pos=0;
			}
		}
		if (arrow_x - 13 < new_x_pos) {
			arrow_x = new_x_pos + 13;
		}
		if (arrow_x + 13 > new_x_pos + content_width) {
			arrow_x = new_x_pos + content_width - 13;
		}
	}
  
	displaytiparrow(arrow_type,arrow_x,arrow_y);
	document.getElementById("Balloon_Message").style.left=new_x_pos;
	document.getElementById("Balloon_Message").style.top=new_y_pos;
	document.getElementById("Balloon_Message").style.opacity=0.9;
	document.getElementById("Balloon_Message").style.visibility="visible";

	/* debug stuff
	document.me.h.value=content_height;
	document.me.w.value=content_width;
	document.me.aw.value=window.innerWidth;
	document.me.ah.value=window.innerHeight;
	document.me.o_left_x.value=el.xleft;
	document.me.o_right_x.value=el.xright;
	document.me.o_top_y.value=el.ytop;
	document.me.o_bottom_y.value=el.ybottom;
	document.me.w.value=el.width;
	document.me.h.value=el.height;
	document.me.mx.value=mouse_x
	document.me.my.value=mouse_y;
	*/

	/* doesn't seem to work ....
	old_element_style=element.style.border;
	element_style_array.push(new Array(element,old_element_style));
	element.style.border='thin dotted #ff0000';
	// just in case the balloon_hideLayer misses it .....
	setTimeout(function(){element.style.border=old_element_style;},15000);
	*/
}

function balloon_hideLayer() {
	if (! document.getElementById("Balloon_Message")) {
		// oops, the initializetooltip() didn't run yet ? 
		return false;
	}
	if (overballoon == "0") {
		document.getElementById("Balloon_Message").style.top="-5000";
		if (document.getElementById("arrowhead")) {
                        document.getElementById("arrowhead").style.top="-5000";
		}
        }

	/* doesn't seem to work
	while (element_style_array.length) {
		element_style_array[0][0].style.border=element_style_array[0][1];
		element_style_array.splice(0, 1);
	}
	*/
}

function trim(stringToTrim) {
	return stringToTrim.replace(/^\s+|\s+$/g,"");
}

function DivCoordinates(obj_id) {
	var obj=document.getElementById(obj_id);
	var res=new Object();
	res.xleft=0;res.ytop=0;res.xright=0;res.ybottom=0;
	res.width=0;res.height=0;
	res.xleft=obj.offsetLeft;
	res.ytop=obj.offsetTop;

	if (obj.offsetParent != null) {
		// res.xleft+=obj.offsetParent.offsetLeft=obj.offsetParent.scrollLeft;
		res.xleft+=obj.offsetParent.offsetLeft-obj.offsetParent.scrollLeft;
		res.ytop+=obj.offsetParent.offsetTop-obj.offsetParent.scrollTop;
	}

	res.width=obj.offsetWidth;
	res.height=obj.offsetHeight;
	res.xright=res.xleft+res.width;
	res.ybottom=res.ytop+res.height;
	return res;
}

function toggle_animation(event,obj_id) {
	if (event.keyCode != 83) {
		return false;
	}
	var obj=document.getElementById(obj_id);
	var animation=GetCookie('animation');
	if (animation == 'no') {
		obj.src='../images/asterixanim.gif';
		DelCookie('animation');
	} else {
		obj.src='../images/asterixnoanim.gif';
		SetCookie('animation','no','',7776000000)
	}
}

function validate_ip(ip) {
	if (ip.value.length >0 ) {
		var ip_pattern = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
		mymatch=ip_pattern.test(ip.value);

		if (!mymatch) {
			ip.style.color='#ff0000';
			alert('invalid IP address');
			return false;
		}
		var ip_array=ip.value.split('.');
		for (j=0;j<4;j++) {
			if (ip_array[j] > 255) {
				ip.style.color='#ff0000';
				alert('invalid IP address (octet > 255) ');
				return false;
			}
		}
	}
	ip.style.color='#000000';
	return true;
}
                                    
function validate_network_input(network_bitmask) {
	// validates the network input as ip/bitmask

	var a=network_bitmask.value.split('\/');
	var network=a[0];
	var bitmask=a[1];

	if (! network.length || ! bitmask) {
		alert('input in the form: X.X.X.X/Y please!');
		return false;
	}

	if (network.length >0 ) {
		var ip_pattern = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
		mymatch=ip_pattern.test(network);

		if (!mymatch) {
			network_bitmask.style.color='#ff0000';
			alert('invalid IP address');
			return false;
		}
		var ip_array=network.split('.');
		for (j=0;j<4;j++) {
			if (ip_array[j] > 255) {
				network_bitmask.style.color='#ff0000';
				alert('invalid IP address (octet > 255) ');
				return false;
			}
		}
	}
	if (bitmask < 0 || bitmask >32) {
		alert("bitmask should be >= 0 and <= 32");
		return false;
	}
	network_bitmask.style.color='#000000';
	return true;
}

function select_multi_checkboxes(event,this_checkbox,form,obj_name,checkbox_nr) {
	if (event.shiftKey) {
		msg='Shift key was pressed while picking ';
		msg+=this_checkbox.value;
		msg+=" previous=";
		msg+=previous_checkbox_checked;
		msg+="(" + obj_name[previous_checkbox_checked].checked + ")";
		msg+=" current=";
		msg+=checkbox_nr;
		msg+="(" + obj_name[checkbox_nr].checked + ")";

		// alert(msg);
		var action='';
		if (obj_name[previous_checkbox_checked].checked==true) {
			action='true';
		}
		// alert('setting all check boxes ' + previous_checkbox_checked + ' - ' + checkbox_nr + ' to: ' + action);
	
		if (previous_checkbox_checked > checkbox_nr) {
			for (i=checkbox_nr;i<=previous_checkbox_checked;i++) {
				obj_name[i].checked=action;
				if (obj_name[i].disabled) {
					obj_name[i].checked='';
				}
			}
		} 
		if (previous_checkbox_checked < checkbox_nr) {
			for (i=previous_checkbox_checked;i<=checkbox_nr;i++) {
				obj_name[i].checked=action;
				if (obj_name[i].disabled) {
					obj_name[i].checked='';
				}
			}
		} 
	} else {
		// alert('You picked ' + this_checkbox.value);
	}

	var span_id='';
	for (i=1;i<obj_name.length;i++) {
		span_id='span_' + i;
		document.getElementById(span_id).style.backgroundColor='#777777';
	}
	previous_checkbox_checked=checkbox_nr;
	span_id='span_' + checkbox_nr;
	document.getElementById(span_id).style.backgroundColor='#ff0000';
	return;
} 

function check_hostname_field(hostname) {
	hostname=hostname.replace(/[^a-zA-Z0-9-]/g,'');
	hostname=hostname.toLowerCase();
	return hostname;
}

function check_aliases_field(aliases) {
	aliases=aliases.replace(/,/g,' ');
	aliases=aliases.replace(/[^a-zA-Z0-9-\s+]/g,'');
	aliases=aliases.replace(/\s+/g,' ');
	aliases=aliases.toLowerCase();
	return aliases;
}

function swap_divs(id1,id2,new_val) {
        if (document.getElementById) { // DOM3 = IE5, NS6
                if (document.getElementById(id1).style.display == "none"){
                        document.getElementById(id1).style.display = 'block';
                } else {
                        document.getElementById(id1).style.display = 'none';
                }
                if (document.getElementById(id2).style.display == "none"){
                        document.getElementById(id2).style.display = 'block';
                } else {
                        document.getElementById(id2).style.display = 'none';
                }
        } else {
                if (document.layers) {
                        if (document.id1.display == "none"){
                                document.id1.display = 'block';
                        } else {
                                document.id1.display = 'none';
                        }
                        if (document.id2.display == "none"){
                                document.id2.display = 'block';
                        } else {
                                document.id2.display = 'none';
                        }
                } else {
                        if (document.all.id1.style.visibility == "none"){
                                document.all.id1.style.display = 'block';
                        } else {
                                document.all.id1.style.display = 'none';
                        }
                        if (document.all.id2.style.visibility == "none"){
                                document.all.id2.style.display = 'block';
                        } else {
                                document.all.id2.style.display = 'none';
                        }
                }
        }
}


/*  this stuff is based on the tr id's but a opacity change will also change the borders!
function toggle_restricted_old(event,obj_id,ip,modifier) {
	if (event.keyCode != 82) {
		return false;
	}

	// We disable/enable rows based on the status of the checkbox disabled status
	// which is obj_id;
	var obj=document.getElementById(obj_id);

	var row_ids_hc=ip + '_row_id_hc';
	var row_ids_body=ip + '_row_id_body';
	var tr_hc=document.getElementById(row_ids_hc);
	var tr_body=document.getElementById(row_ids_body);
	var tds_hc = tr_hc.getElementsByTagName('td');
	var tds_body = tr_body.getElementsByTagName('td');

	var opacity='1';

	if (obj.disabled) {
		opacity='1';
		obj.disabled=false;
	} else {
		opacity='0.5';
		obj.disabled=true;
	}

	for(var i = 0; i < tds_hc.length; i++) {
   		tds_hc[i].style.opacity=opacity;
	}
	for(var i = 0; i < tds_body.length; i++) {
   		tds_body[i].style.opacity=opacity;
	}
}
*/


function toggle_restricted(event,ip,modifier) {
	if (event.keyCode != 82) {
		return false;
	}

	// We disable/enable rows based on the status of the checkbox disabled status
	// the id of that checkbox  object is called XXX_checkbox_id 
	// where XXX is the decimal ip-address
	var ip_checkbox_id=ip + "_checkbox_id";
	var checkbox_obj=document.getElementById(ip_checkbox_id);

	// Change the opacity of each row that has the name XXX_row_name
	// where XXX is the decimal ip-address
	var ip_row_name=ip + "_row_name";
	
	var ip_rows = document.getElementsByName(ip_row_name);

	var opacity='1';

	if (checkbox_obj.disabled) {
		opacity='1';
		checkbox_obj.disabled=false;
		var url='./ipmanage_restricted_ip.pl?&ip=' + ip + '&action=delete';
		parent.window.document.getElementById('hidden_cgi').src=url;
	} else {
		opacity='0.5';
		checkbox_obj.disabled=true;
		var url='./ipmanage_restricted_ip.pl?&ip=' + ip + '&action=add';
		parent.window.document.getElementById('hidden_cgi').src=url;
	}

	for(var i = 0; i < ip_rows.length; i++) {
   		ip_rows[i].style.opacity=opacity;
	}
}




function disable_restricted(ip) {
	// We disable rows that have the ip-address ip
	// the id of that checkbox  object is called XXX_checkbox_id 
	// where XXX is the decimal ip-address
	var ip_checkbox_id=ip + "_checkbox_id";
	var checkbox_obj=document.getElementById(ip_checkbox_id);

	// Change the opacity of each row that has the name XXX_row_name
	// where XXX is the decimal ip-address
	var ip_row_name=ip + "_row_name";
	
	var ip_rows = document.getElementsByName(ip_row_name);

	var opacity='0.5';

	for(var i = 0; i < ip_rows.length; i++) {
   		ip_rows[i].style.opacity=opacity;
	}
	
	if (checkbox_obj != null) {
		checkbox_obj.disabled=true;
	}
}
