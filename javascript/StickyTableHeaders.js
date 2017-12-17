/*
This function will act on all tables in a group in order to make the column width the same.
It's needed when you want to create tables with a fixed header, where the 'body' scrolls
The body needs a fixed height !!!
A table group consists of maximum 3 tables:
header
body
footer

The id's must be unique for the group, like:
<table1>_[HeaderCorner|HeaderRow|HeaderColumn|Body]
<table2>_[HeaderCorner|HeaderRow|HeaderColumn|Body]
<tablen>_[HeaderCorner|HeaderRow|HeaderColumn|Body]

A group is defined as follows:

Make SURE that the number of columns in: 
	table1_HeaderCorner=table1_HeaderColumn
and 
	table1_HeaderRow=table1_Body

	layout:
	+-----------------------+--------------------------------------+
	| table1_HeaderCorner   | table1_HeaderRow                     |
	+-----------------------+--------------------------------------+-+
	|                       |                                      |^|
	|                       |                                      |^|
	|                       |                                      | |
	| table1_HeaderColumn   | table1_Body                          | |
	|                       |                                      | |
	|                       |                                      |v|
	|                       |                                      |v|
	+-----------------------+--------------------------------------+-+
	                        |<<                                  >>| |     < horizontal scrollbar
	                        +--------------------------------------+-+
	                                                                ^
	                                                                |
	                                                                vertical scrollbar
>>HTML <<<

<STYLE>
.table1 table td, .table1 table th {
	white-space: nowrap;
	padding-left: 1px;
	padding-right: 1px;
	padding-top: 1px;
	padding-bottom: 1px;
	border:solid thin;
}
</STYLE>

<SCRIPT language="javascript">
var paddingleft=1;
var paddingright=1;
var paddingtop=1;
var paddingbottom=1;
</SCRIPT>


<TABLE class=table1 BORDER=0>
	<TR>
		<TD>
			<DIV id=table1_HeaderCornerDiv>
				<TABLE id=table1_HeaderCorner StickyTableHeaders=yes BORDER=1>
					<TR>
						<TH>....</TH><TH>....</TH>
					</TR>
				</TABLE>
			</DIV>
		</TD>
		<TD>
			<DIV id=table1_HeaderRowDiv>
				<TABLE id=table1_HeaderRow StickyTableHeaders=yes BORDER=1>
					<TR>
						<TH>....</TH><TH>....</TH><TH>....</TH><TH>....</TH>
					</TR>
				</TABLE>
			</DIV>
		</TD>
	</TR>
	<TR>
		<TD VALIGN=top>
			<DIV id=table1_HeaderColumnDiv >
				<TABLE id=table1_HeaderColumn StickyTableHeaders=yes BORDER=1>
					<TR>
						<TD>....</TD><TD>....</TD>
					</TR>
				</TABLE>
			</DIV>
		</TD>
		<TD VALIGN=top>
			<DIV id=table1_BodyDiv>
				<TABLE id=table1_Body StickyTableHeaders=yes BORDER=1>
					<TR>
						<TD>....</TD><TD>....</TD><TD>....</TD><TD>....</TD>
					</TR>
				</TABLE>
			</DIV>
		</TD>
	</TR>
</TABLE>
>>> END HTML <<<

then, at the end of your html page, call the function to align the columns

>>> HTML <<<
<BODY onload="align_tables();" onresize="align_tables();" >
>>> END HTML <<<
	

hope this helps with your fixed header table ...

Paul de Nijs
*/


// Global vars
var table_tags=document.getElementsByTagName('table');
var tags='';
var scrollable_hash={};
var table_rows_columns={};

function initialize_sticky_headers() {
	for (var i=0;i<table_tags.length;i++) {
		if (table_tags[i].id.length >0 ) {
			if (table_tags[i].getAttribute('StickyTableHeaders')=='yes') {
				tags+=table_tags[i].id + ',';
				// split the table name and the HeaderCorner, HeaderRow, HeaderColumn and Body
				var a=table_tags[i].id.split('_');
				// a[0] is the table name
				// a[1] is the HeaderCorner, HeaderRow, HeaderColumn and Body
				var arr_number=0;
				if (scrollable_hash[a[0]] != undefined) {
					arr_number=scrollable_hash[a[0]].length;
					scrollable_hash[a[0]][a[1]]=table_tags[i].id;
				} else {
					scrollable_hash[a[0]]=[];
					scrollable_hash[a[0]][a[1]]=table_tags[i].id;
				}
			}
		}
	}
	align_tables_sticky_headers();
	// resize_scrolling_area_sticky_headers();
}

function align_tables_sticky_headers() {
	for (var n in scrollable_hash) {
		if (scrollable_hash.hasOwnProperty(n)) {			// n is the table name

			var HeaderCorner=document.getElementById(scrollable_hash[n]['HeaderCorner']);
			var HeaderRow=document.getElementById(scrollable_hash[n]['HeaderRow']);
			var HeaderColumn=document.getElementById(scrollable_hash[n]['HeaderColumn']);
			var Body=document.getElementById(scrollable_hash[n]['Body']);

			// pick the rows and the columns that have real cell sizes, so it's possible to use a 
			// colspan for the rows and rowspan for the columns.
			// 
			// define as follows:
			// 
			// var reference_rows_cols={};
			// reference_rows_cols['table1']=[];
			// if you want the first row of the HeadeRow to span the whole size, lets say as a subcategory or something:
			// reference_rows_cols['table1']['HeaderCorner']=[1,0];
			// reference_rows_cols['table1']['HeaderRow']=[1,0];
			// reference_rows_cols['table1']['HeaderColumn']=[0,0];
			// reference_rows_cols['table1']['Body']=[0,0];
			// 'table1' should be the varabele 'n' in this routine

			var row_HeaderCorner=0;
			var col_HeaderCorner=0;
			var row_HeaderRow=0;
			var col_HeaderRow=0;
			var row_HeaderColumn=0;
			var col_HeaderColumn=0;
			var row_Body=0;
			var col_Body=0;
			if (typeof reference_rows_cols != 'undefined' ) {
				if (typeof reference_rows_cols[n] != 'undefined') {
					if (reference_rows_cols[n]['HeaderCorner'] != undefined ) {
						row_HeaderCorner=reference_rows_cols[n]['HeaderCorner'][0];
						col_HeaderCorner=reference_rows_cols[n]['HeaderCorner'][1];
				
					}
					if (reference_rows_cols[n]['HeaderRow'] != undefined ) {
						row_HeaderRow=reference_rows_cols[n]['HeaderRow'][0];
						col_HeaderRow=reference_rows_cols[n]['HeaderRow'][1];
					}
					if (reference_rows_cols[n]['HeaderColumn'] != undefined ) {
						row_HeaderColumn=reference_rows_cols[n]['HeaderColumn'][0];
						col_HeaderColumn=reference_rows_cols[n]['HeaderColumn'][1];
					}
					if (reference_rows_cols[n]['Body'] != undefined ) {
						row_Body=reference_rows_cols[n]['Body'][0];
						col_Body=reference_rows_cols[n]['Body'][1];
					}
				}
			}


			// get the cellpadding and cellspacing of the Body, hey, since a Body should always be there!!!
			var cellpadding=0;
			var cellspacing=0;
			if (Body) {
				cellpadding=parseInt(Body.cellPadding);
				cellpadding=parseInt(Body.cellSpacing);
			}
			// cellpadding and cellspacing has nothing to do with the cell sizes. Use the padding instead
			// you would THINK that you can get the paddinLeft and paddingRight from the cell property, but it just says nothing, empty!
			// so this doesn't work: 
			// var paddingleft=HeaderCorner.rows[0].cells[0].style.paddingLeft);
			// so set the variables in javascript the same as in your stylesheet.

			width_padding=paddingleft+paddingright;
			height_padding=paddingtop+paddingbottom;

			var row_counter=0;
			var height_array=new Array();
			var column_counter=0;
			var width_array=new Array();

			// first set the width of the cells in all tables:
			if (HeaderCorner) {
				for (i=0;i<HeaderCorner.rows[row_HeaderCorner].cells.length;i++) {
					// set width of all cols of HeaderCorner and HeaderColumn to be the same
					var w=0;
					if (HeaderCorner.rows[row_HeaderCorner].cells[i].clientWidth < HeaderColumn.rows[row_HeaderColumn].cells[i].clientWidth) {
						w=HeaderColumn.rows[row_HeaderColumn].cells[i].clientWidth - width_padding + "px";
					} else {
						w=HeaderCorner.rows[row_HeaderCorner].cells[i].clientWidth - width_padding + "px";
					}
					width_array[column_counter++]=w;
				}
			}

			if (HeaderRow) {
				for (i=0;i<HeaderRow.rows[row_HeaderRow].cells.length;i++) {
				// set width of all cols of HeaderRow and Body to be the same
					var w=0;
					if (HeaderRow.rows[row_HeaderRow].cells[i].clientWidth < Body.rows[row_Body].cells[i].clientWidth) {
						w=Body.rows[0].cells[i].clientWidth - width_padding + "px";
					} else {
						w=HeaderRow.rows[row_HeaderRow].cells[i].clientWidth - width_padding + "px";
					}
					width_array[column_counter++]=w;
				}
			}

			// now adjust the height ...
			if (HeaderCorner) {
				for (i=0;i<HeaderCorner.rows.length;i++) {
					// set height of all rows of HeaderCorner and HeaderRow to be the same
					var h=0;
					if (HeaderCorner.rows[i].cells[col_HeaderCorner].clientHeight < HeaderRow.rows[i].cells[col_HeaderRow].clientHeight) {
						h=HeaderRow.rows[i].cells[col_HeaderCorner].clientHeight + height_padding + "px";
					} else {
						h=HeaderCorner.rows[i].cells[col_HeaderCorner].clientHeight + height_padding + "px";
					}
					height_array[row_counter++]=h;
				}
			}

			if (HeaderColumn) {
				for (i=0;i<HeaderColumn.rows.length;i++) {
					// set height of all rows of HeaderColumn and Body to be the same
					h=0;
					if (HeaderColumn.rows[i].cells[col_HeaderColumn].clientHeight < Body.rows[i].cells[col_Body].clientHeight) {
						h=Body.rows[i].cells[col_Body].clientHeight + height_padding + "px";
					} else {
						h=HeaderColumn.rows[i].cells[col_HeaderColumn].clientHeight + height_padding + "px";
					}
					height_array[row_counter++]=h;
				}
			}

			// make a new stylesheet
			var new_stylesheet = document.createElement('style');
			document.getElementsByTagName('head')[0].appendChild(new_stylesheet);

			// Safari does not see the new stylesheet unless you append something.
			// However!  IE will blow chunks, so ... filter it thusly:
			if (!window.createPopup) {
				new_stylesheet.appendChild(document.createTextNode(''));
			}
			var sheets = document.styleSheets[document.styleSheets.length - 1];

			var rules={};

			for(t=0;t<width_array.length;t++) {
				var classname='.' + n + '_c' + t;
				var v=width_array[t];
				rules[classname]='{width:' + v + '; max-width:' + v + '; min-width:' + v + ';}';
			}
			for(t=0;t<height_array.length;t++) {
				var classname='.' + n + '_r' + t;
				var v=height_array[t];
				rules[classname]='{height:' + v + '; max-height:' + v + '; min-height:' + v + ';}';
			}

			// loop through and insert
			for (selector in rules) {
				if (sheets.insertRule) {
					// it's an IE browser
					try {
						sheets.insertRule(selector + rules[selector], sheets.cssRules.length);
					} catch(e) {}
				} else {
					// it's a W3C browser
					try {
						sheets.addRule(selector, rules[selector]);
					} catch(e) {}
				}
			}
		}
	}
}


function resize_scrolling_area_sticky_headers() {
	for (var n in scrollable_hash) {
		if (scrollable_hash.hasOwnProperty(n)) {			// n is the table name
			var scrollX = true;
			var scrollY = true;
			var total_width=document.documentElement.clientWidth - 50;
			var total_height=document.documentElement.clientHeight - 50;

			var HeaderCornerDiv=document.getElementById(scrollable_hash[n]['HeaderCorner'] + 'Div');
			var HeaderCorner=document.getElementById(scrollable_hash[n]['HeaderCorner']);

			var HeaderRowDiv=document.getElementById(scrollable_hash[n]['HeaderRow'] + 'Div');
			var HeaderRow=document.getElementById(scrollable_hash[n]['HeaderRow']);

			var HeaderColumnDiv=document.getElementById(scrollable_hash[n]['HeaderColumn'] + 'Div');
			var HeaderColumn=document.getElementById(scrollable_hash[n]['HeaderColumn']);

			var BodyDiv=document.getElementById(scrollable_hash[n]['Body'] + 'Div');
			var Body=document.getElementById(scrollable_hash[n]['Body']);

			var HeaderColumnWrapperDiv=document.getElementById(scrollable_hash[n]['HeaderColumn'] + 'WrapperDiv');

			if (HeaderRow) {
				HeaderRowDiv.style.overflow="scroll";
			}
			BodyDiv.style.overflow="scroll";
			BodyDiv.style.overflowX="scroll";
			BodyDiv.style.overflowY="scroll";

			var isIE = true;
			var scrollbarWidth = 17;
			if (!document.all) {
				isIE = false;
				scrollbarWidth = 17;
			}

			/* table_sizes are the max width and height of a table
			   they must be defined as follows (globally):

			   var table_sizes={};
			   table_sizes['table1']=[1600,800]; 
			   table_sizes['table2']=[600,700];

			   where in this case 'n' corresponds to that table name (table1, table2)
			*/ 
			
			if (typeof table_sizes != 'undefined') {
				if (table_sizes[n] != undefined) {
					if (table_sizes[n][0] != 0) {		// aha, the width of the table is defined!
						total_width=table_sizes[n][0];
					}
				}
			}
			if (HeaderColumn) {
				width=total_width - HeaderColumn.offsetWidth;
			} else {
				width=total_width;
			}
			if (width > Body.offsetWidth) {
				width=Body.offsetWidth;			// the width of the Body Table!!!!
				BodyDiv.style.overflowX = "hidden";
				scrollX = false;
			}
			
			if (typeof table_sizes != 'undefined') {
				if (table_sizes[n] != undefined) {
					if (table_sizes[n][1] != 0) {		// aha, the height of the table is defined!
						total_height=table_sizes[n][1];
					}
				}
			}
			
			if (HeaderRow) {
				height=total_height - HeaderRowDiv.offsetHeight;
			} else {
				height=total_height;
			}
			if (height > Body.offsetHeight) {
				height=Body.offsetHeight;		// the height of the Body Table!!!!
				BodyDiv.style.overflowY = "hidden";
				scrollY = false;
			}

			if (HeaderRow) {
				HeaderRowDiv.style.width = width + "px";
				HeaderRowDiv.style.overflow = "hidden";
			}
			if (HeaderColumn) {
				HeaderColumnDiv.style.height = height + "px";
				HeaderColumnDiv.style.overflow = "hidden";
				if (HeaderColumnWrapperDiv) {
					HeaderColumnDiv.style.overflowY = "scroll";
					// make HeaderColumnDiv so big that the scrollbar is tottally right ...
					HeaderColumnDiv.style.maxWidth=HeaderCorner.offsetWidth + 100 + "px";
					HeaderColumnDiv.style.minWidth=HeaderCorner.offsetWidth + 100 + "px";
					HeaderColumnWrapperDiv.style.maxWidth=HeaderCorner.offsetWidth  + "px";
				}
			}

			
			BodyDiv.style.width = width + scrollbarWidth + "px";
			BodyDiv.style.height = height + scrollbarWidth + "px";

			
			if (!scrollX && isIE) {
				BodyDiv.style.overflowX = "hidden";
				BodyDiv.style.height = BodyDiv.offsetHeight - scrollbarWidth + "px";
			}

			if (!scrollY && isIE) {
				BodyDiv.style.overflowY = "hidden";
				BodyDiv.style.width = BodyDiv.offsetWidth - scrollbarWidth + "px";
			}

			if (!scrollX && !isIE) {
				BodyDiv.style.overflowX = "hidden";
				BodyDiv.style.height = BodyDiv.offsetHeight - scrollbarWidth + "px";
			}

			if (!scrollY && !isIE) {
				BodyDiv.style.overflowY = "hidden";
				BodyDiv.style.width = BodyDiv.offsetWidth - scrollbarWidth + "px";
			}
			
			if (!scrollX && !scrollY && !isIE) {
				BodyDiv.style.overflow = "hidden";
			}
			
			var boundary_hash={};
			var boundary_array=new Array();
			var b_counter=0;
			for (i=0;i<cell_dups.length;i++) {
				var a=cell_dups[i][0].split('_');
				var b=cell_dups[i][1].split('_');
				if (a[0] == n && b[0] == n) {
					boundary_hash[cell_dups[i][0]]=document.getElementsByName(cell_dups[i][0]);    // fill the hash with the objects
					boundary_array[b_counter++]=[cell_dups[i][0],cell_dups[i][1]];
				}
			}


			BodyDiv.onscroll = function() {
				if (HeaderRow) {
					HeaderRowDiv.scrollLeft = BodyDiv.scrollLeft;
				}
				if (HeaderColumn) {
					HeaderColumnDiv.scrollTop = BodyDiv.scrollTop;
				}

				for (b=0;b<boundary_array.length;b++) {
					for(i=0;i<boundary_hash[boundary_array[b][0]].length;i++) {
						var r=GetDivCoordinates(boundary_hash[boundary_array[b][0]][i]);
						if (r.ytop <= BodyDiv.scrollTop) {
							var lala= boundary_hash[boundary_array[b][0]][i].innerHTML;
							var boundary_element=document.getElementsByName(boundary_array[b][1]);
							for(j=0;j<boundary_element.length;j++) { 
								boundary_element[j].innerHTML=boundary_hash[boundary_array[b][0]][i].innerHTML;
							}
						}
					}
				}
			};

			if (HeaderColumnWrapperDiv) {
				HeaderColumnDiv.onscroll = function() {
					if (HeaderColumn) {
						BodyDiv.scrollTop=HeaderColumnDiv.scrollTop;
					}

					for (b=0;b<boundary_array.length;b++) {
						for(i=0;i<boundary_hash[boundary_array[b][0]].length;i++) {
							var r=GetDivCoordinates(boundary_hash[boundary_array[b][0]][i]);
							if (r.ytop <= BodyDiv.scrollTop) {
								var lala= boundary_hash[boundary_array[b][0]][i].innerHTML;
								var boundary_element=document.getElementsByName(boundary_array[b][1]);
								for(j=0;j<boundary_element.length;j++) { 
									boundary_element[j].innerHTML=boundary_hash[boundary_array[b][0]][i].innerHTML;
								}
							}
						}
					}
				};
			}

/*
			// for debugging ....
			var txt='';
			txt+=Body.offsetWidth;
			document.getElementById('message').innerHTML=txt;
*/

		}
	}
}

function GetDivCoordinates(obj) {
        var res=new Object();
        res.xleft=0;res.ytop=0;res.xright=0;res.ybottom=0;
        res.width=0;res.height=0;

        res.xleft=obj.offsetLeft;
        res.ytop=obj.offsetTop;
        if (obj.offsetParent != null) {
                // res.xleft+=obj.offsetParent.offsetLeft=obj.offsetParent.scrollLeft;
                res.xleft+=obj.offsetParent.offsetLeft - obj.offsetParent.scrollLeft;
                res.ytop+= obj.offsetParent.offsetTop -  obj.offsetParent.scrollTop;
        }
        res.width=obj.offsetWidth;
        res.height=obj.offsetHeight;

        res.xright=res.xleft+res.width;
        res.ybottom=res.ytop+res.height;
        return res;
}
