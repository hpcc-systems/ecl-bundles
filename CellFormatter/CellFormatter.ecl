EXPORT CellFormatter := MODULE, FORWARD
    IMPORT Std;

    /***************************************************************************
     * Background:
     *   The ECl Watch Result Viewer can display cells containing the following 
     *   types of text: 
     *    - Plain Text (the default)
     *    - HTML (@since 4.0.2)
     *    - JavaScript (@since 4.0.2) 
     *
     *   To activate the "HTML" or "JavaScript" modes, the user simply appends 
     *   either "__html" or "__javascript" to the column name.
     *   To override the default width, simply append a size prior to 
     *   "__html/__javascript", i.e. "MyField__1024__html".
     *
     * Plain Text Formatting:
     *   When plain text is rendered in the cell it is "HTML Encoded" to ensure that 
     *   Special HTML characters are displayed correctly (<, > &, ', " etc.). This 
     *   is (and always has been) the default mode.   
     *   
     * HTML Formatting:
     *   When a columns name ends in "__html" the text to be rendered skips the 
     *   "HTML Encoding" function.  This allows the user to embed raw HTML.
     *   For example:
     *    - <b>This is a naughty string!</b>
     *    - <a href="http://www.google.ie/search?q=HPCCSystems">Find HPCCSystems</a>
     *   
     * JavaScript Formatting:
     *   When a columns name ends in "__javascript" the text is "injected" into the 
     *   cell rendering process.  Prior to injection, it declares the following local
     *   variables:
     *    - __row: A JavaScript object containg all the data in the current row. 
     *    - __width: The width of the column. 
     *    - __cell: The result cell DOM Node (for manipulation by the JavaScript). 
     *    
     * Quick Test/Demo:  
     *   CellFormatter.__selfTest.All;
     *    
     **************************************************************************/

    EXPORT Bundle := MODULE(Std.BundleBase)
        EXPORT Name := 'CellFormatter';
        EXPORT Description := 'Result Cell Formatting Helpers';
        EXPORT Authors := ['Gordon Smith'];
        EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
        EXPORT Copyright := 'Copyright (C) 2013 HPCC Systems';
        EXPORT DependsOn := [];
        EXPORT Version := '1.0.0';
    END;

    /***************************************************************************
     *  HTML Cell Formatters
     ***************************************************************************/
    EXPORT HTML := MODULE
        EXPORT Element(ANY innerText, STRING tag, STRING attributes = '') := FUNCTION
            RETURN '<' + tag + IF(attributes = '', '', ' ' + attributes) + '>' + innerText + '</' + tag + '>';
        END; 

        /***************************************************************************
         *  Text Formatting Tags
         ***************************************************************************/
        //  <h1..6>  Header Text
        EXPORT Header(ANY innerText, INTEGER4 size=1) := FUNCTION
            RETURN IF (size > 0 AND size <= 6, Element(innerText, 'h' + size), innerText);
        END; 
        //  <a>     Hyperlink
        EXPORT Hyperlink(ANY innerText, STRING url) := FUNCTION
            RETURN Element(innerText, 'a', 'href="' + url + '"');
        END; 
        //  <b>     Defines bold text
        EXPORT Bold(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'b');
        END; 
        //  <em>    Defines emphasized text 
        EXPORT Emphasis(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'em');
        END;
       //  <i>     Defines a part of text in an alternate voice or mood
        EXPORT Italic(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'i');
        END; 
        //  <small> Defines smaller text
        EXPORT Small(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'small');
        END; 
        //  <strong>    Defines important text
        EXPORT Strong(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'strong');
        END; 
        //  <sub>   Defines subscripted text
        EXPORT Subscript(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'sub');
        END; 
        //  <sup>   Defines superscripted text
        EXPORT Superscript(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'sup');
        END; 
        //  <ins>   Defines inserted text
        EXPORT Inserted(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'ins');
        END; 
        //  <del>   Defines deleted text
        EXPORT Deleted(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'del');
        END; 
        //  <mark>  Defines marked/highlighted text
        EXPORT Mark(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'mark');
        END; 

        /***************************************************************************
         *  "Computer Output" Tags
         ***************************************************************************/
        //  <code>  Defines computer code text
        EXPORT Code(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'code');
        END; 
        //  <kbd>   Defines keyboard text 
        EXPORT KeyboardText(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'kbd');
        END; 
        //  <samp>  Defines sample computer code
        EXPORT SampleCode(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'samp');
        END; 
        //  <var>   Defines a variable
        EXPORT Variable(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'var');
        END; 
        //  <pre>   Defines preformatted text
        EXPORT PreformattedText(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'pre');
        END; 
        
        /***************************************************************************
         *  Citations, Quotations, and Definition Tags
         ***************************************************************************/
        //  <abbr>  Defines an abbreviation or acronym
        EXPORT Abbreviation(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'abbr');
        END; 
        //  <address>   Defines contact information for the author/owner of a document 
        EXPORT Address(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'address');
        END; 
        //  <bdo>   Defines the text direction
        EXPORT RightToLeft(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'bdo', 'dir="rtl"');
        END; 
        //  <blockquote>     Defines a section that is quoted from another source
        EXPORT BlockQuote(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'blockquote');
        END; 
        //  <q> Defines an inline (short) quotation
        EXPORT ShortQuotation(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'q');
        END; 
        //  <cite>  Defines the title of a work
        EXPORT Citation(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'cite');
        END; 
        //  <dfn>   Defines a definition term
        EXPORT Definition(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'dfn');
        END; 

        /***************************************************************************
         *  Tables
         ***************************************************************************/
        //  <table> Defines a table
        EXPORT Table(ANY innerText, BOOLEAN border=true) := FUNCTION
            RETURN Element(innerText, 'table', IF(border, 'border=1', ''));
        END; 
        //  <th>    Defines a header cell in a table
        EXPORT TableHeader(ANY innerText, STRING colspan='', STRING headers='', STRING rowspan='', STRING scope='') := FUNCTION
            STRING attributes := 
                IF(colspan != '',   ' colspan="'    + colspan + '"', '') + 
                IF(headers != '',   ' headers="'    + headers + '"', '') + 
                IF(rowspan != '',   ' rowspan="'    + rowspan + '"', '') + 
                IF(scope != '',     ' scope="'      + scope + '"', '');
            RETURN Element(innerText, 'th', attributes);
        END; 
        //  <tr>    Defines a row in a table
        EXPORT TableRow(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'tr');
        END; 
        //  <td>    Defines a cell in a table
        EXPORT TableCell(ANY innerText, STRING colspan='', STRING headers='', STRING rowspan='') := FUNCTION
            STRING attributes := 
                IF(colspan != '',   ' colspan="'    + colspan + '"', '') + 
                IF(headers != '',   ' headers="'    + headers + '"', '') + 
                IF(rowspan != '',   ' rowspan="'    + rowspan + '"', ''); 
            RETURN Element(innerText, 'td');
        END; 
        //  <caption>   Defines a table caption
        EXPORT Caption(ANY innerText) := FUNCTION
            RETURN Element(innerText, 'caption');
        END; 
        //  <colgroup>  Specifies a group of one or more columns in a table for formatting
        EXPORT ColumnGroup(ANY innerText, STRING span='') := FUNCTION
            STRING attributes := IF(span != '',   ' span="'    + span + '"', ''); 
            RETURN Element(innerText, 'colgroup', attributes);
        END; 
        //  <col>   Specifies column properties for each column within a <colgroup> element
        EXPORT Column(ANY innerText, STRING span='') := FUNCTION
            STRING attributes := IF(span != '',   ' span="'    + span + '"', ''); 
            RETURN Element(innerText, 'col', attributes);
        END; 
        //  <thead> Groups the header content in a table
        EXPORT TableHead(ANY innerText, STRING span='') := FUNCTION
            RETURN Element(innerText, 'thead');
        END; 
        //  <tbody> Groups the body content in a table
        EXPORT TableBody(ANY innerText, STRING span='') := FUNCTION
            RETURN Element(innerText, 'tbody');
        END; 
        //  <tfoot> Groups the footer content in a table
        EXPORT TableFoot(ANY innerText, STRING span='') := FUNCTION
            RETURN Element(innerText, 'tfoot');
        END; 
    END;

    /***************************************************************************
     *  JavaScript Cell Formatters
     ***************************************************************************/
    EXPORT JavaScript := MODULE
        /***************************************************************************
         *  Safely set the the innerText of a cell.
         *
         *  @see  <a href="http://www.w3schools.com/css/default.asp">CSS Styles</a>
         ***************************************************************************/
        EXPORT setInnerText(ANY innerText) := FUNCTION
            RETURN '__cell.innerHTML = entities.encode("' + innerText + '");'; 
        END;

        /***************************************************************************
         *  Sets an individual cell style.
         *
         *  @see  <a href="http://www.w3schools.com/css/default.asp">CSS Styles</a>
         ***************************************************************************/
        EXPORT setCellStyle(STRING style, STRING value) := FUNCTION
            RETURN 
                'require(["dojo/dom-style"], function(domStyle) {' +
                '    domStyle.set(__cell, "' + style + '", "' + value + '");' + 
                '});'; 
        END;

        /***************************************************************************
         *  Sets the background and foreground color of the cell.
         ***************************************************************************/
        EXPORT colorCell(ANY innerText, STRING backgroundColor = '', STRING color = '') := FUNCTION
            RETURN 
                setCellStyle('backgroundColor', backgroundColor) + 
                setCellStyle('color', color) +
                setInnerText(innerText);
        END;

        /***************************************************************************
         *  Formats various "Label/Value" Charts.  Requires a nested dataset with 
         *  suitable label and value column(s).
         *
         *  Chart Types:
         *   - Bar
         *   - Pie
         *   - Bubble
         *
         *    @param dataCol        The column which contains the nested dataset. 
         *    @param labelField     The "Label" column within the nested dataset.  
         *    @param valueField     The "Value" column within the nested dataset.  
         ***************************************************************************/
        EXPORT Chart(STRING dataCol, STRING labelField, STRING valueField) := MODULE
            SHARED prefix := 'var __sourceData=lang.clone(__row.' + dataCol + ');var getLabel=function(e){return e.' + labelField + '};var getValue=function(e){return+e.' + valueField + '};' +
                'require(["d3/d3.v3.min.js"],function () {';
            SHARED postfix := '});';
        
            EXPORT Bar := prefix +
                'dojo.query("head").append("<style>.axisBC path, .axisBC line { fill: none; stroke: #000; shape-rendering: crispEdges; } .barBC { fill: steelblue; } .x.axisBC path { display: none; } </style>");var margin={top:20,right:20,bottom:30,left:40},width=500-margin.left-margin.right,height=500-margin.top-margin.bottom;var formatPercent=d3.format(",d");var x=d3.scale.ordinal().rangeRoundBands([0,width],.1);var y=d3.scale.linear().range([height,0]);var xAxis=d3.svg.axis().scale(x).orient("bottom");var yAxis=d3.svg.axis().scale(y).orient("left").tickFormat(formatPercent);var svg=d3.select(__cell).append("svg").attr("width",width+margin.left+margin.right).attr("height",height+margin.top+margin.bottom).append("g").attr("transform","translate("+margin.left+","+margin.top+")");x.domain(__sourceData.map(function(e){return getLabel(e)}));y.domain([0,d3.max(__sourceData,function(e){return getValue(e)})]);svg.append("g").attr("class","x axisBC").attr("transform","translate(0,"+height+")").call(xAxis);svg.append("g").attr("class","y axisBC").call(yAxis).append("text").attr("transform","rotate(-90)").attr("y",6).attr("dy",".71em").style("text-anchor","end").text("Count");svg.selectAll(".barBC").data(__sourceData).enter().append("rect").attr("class","barBC").attr("x",function(e){return x(getLabel(e))}).attr("width",x.rangeBand()).attr("y",function(e){return y(getValue(e))}).attr("height",function(e){return height-y(getValue(e))});' + 
                postfix;
            EXPORT Pie := prefix +
                'var diameter=500;var radius=diameter/2;var color=d3.scale.category20c();var arc=d3.svg.arc().outerRadius(radius-10).innerRadius(0);var pie=d3.layout.pie().sort(null).value(function(e){return getValue(e)});var svg=d3.select(__cell).append("svg").attr("width",diameter).attr("height",diameter).append("g").attr("transform","translate("+radius+","+radius+")");var g=svg.selectAll(".arc").data(pie(__sourceData)).enter().append("g").attr("class","arc");g.append("path").attr("d",arc).style("fill",function(e){return color(getLabel(e.data))});g.append("text").attr("transform",function(e){return"translate("+arc.centroid(e)+")"}).attr("dy",".35em").style("text-anchor","middle").text(function(e){return getLabel(e.data)});' +
                postfix;
            EXPORT Bubble := prefix +
                'var diameter=500;var color=d3.scale.category20c();var format=d3.format(",d");var bubble=d3.layout.pack().sort(null).value(function(e){return getValue(e)}).size([diameter,diameter]).padding(1.5);var svg=d3.select(__cell).append("svg").attr("width",diameter).attr("height",diameter).attr("class","bubble");var root={children:__sourceData};var node=svg.selectAll(".node").data(bubble.nodes(root).filter(function(e){return!e.children})).enter().append("g").attr("class","node").attr("transform",function(e){return"translate("+e.x+","+e.y+")"});node.append("title").text(function(e){return getLabel(e)+": "+format(getValue(e))});node.append("circle").attr("r",function(e){return e.r}).style("fill",function(e){return color(getLabel(e))});node.append("text").attr("dy",".3em").style("text-anchor","middle").text(function(e){return getLabel(e).substring(0,e.r/3)});' +
                postfix;
        END;

        /***************************************************************************
         *  Formats "Label/Value(s)" Charts.  Requires a nested dataset with one 
         *  label column and several value columns.  
         *  Note:  Any column which is not the label is assumed to be a value.
         *
         *  Chart Types:
         *   - ParallelCoordinates
         *
         *    @param dataCol        The column which contains the nested dataset. 
         *    @param labelField     The "Label" column within the nested dataset.  
         ***************************************************************************/
        EXPORT MultipleValueChart(STRING dataCol, STRING labelField) := MODULE
            SHARED prefix := 'var __sourceData=lang.clone(__row.' + dataCol + ');var getLabel=function(e){return e.' + labelField + '};var __labelField = "' + labelField + '";' +
                'require(["d3/d3.v3.min.js"],function () {';
            SHARED postfix := '});';
        
            EXPORT ParallelCoordinates := prefix +
                'dojo.query("head").append("<style>svg{font:10px sans-serif} .background path{fill:none;stroke:#ccc;stroke-opacity:.4;shape-rendering:crispEdges} .foreground path{fill:none;stroke:#4682B4;stroke-opacity:.7} .brush .extent{fill-opacity:.3;stroke:#fff;shape-rendering:crispEdges} .axis line,.axis path{fill:none;stroke:#000;shape-rendering:crispEdges} .axis text{text-shadow:0 1px 0 #fff;cursor:move}</style>");var position=function(e){var t=dragging[e];return t==null?x(e):t};var transition=function(e){return e.transition().duration(500)};var path=function(e){return line(dimensions.map(function(t){return[position(t),y[t](e[t])]}))};var brush=function(){var e=dimensions.filter(function(e){return!y[e].brush.empty()}),t=e.map(function(e){return y[e].brush.extent()});foreground.style("display",function(n){return e.every(function(e,r){return t[r][0]<=n[e]&&n[e]<=t[r][1]})?null:"none"})};var m=[30,10,10,10],w=500-m[1]-m[3],h=500-m[0]-m[2];var x=d3.scale.ordinal().rangePoints([0,w],1),y={},dragging={};var line=d3.svg.line(),axis=d3.svg.axis().orient("left"),background,foreground;var svg=d3.select(__cell).append("svg").attr("width",w+m[1]+m[3]).attr("height",h+m[0]+m[2]).append("g").attr("transform","translate("+m[3]+","+m[0]+")");x.domain(dimensions=d3.keys(__sourceData[0]).filter(function(e){return e!=__labelField&&(y[e]=d3.scale.linear().domain(d3.extent(__sourceData,function(t){return+t[e]})).range([h,0]))}));background=svg.append("g").attr("class","background").selectAll("path").data(__sourceData).enter().append("path").attr("d",path);foreground=svg.append("g").attr("class","foreground").selectAll("path").data(__sourceData).enter().append("path").attr("d",path);var g=svg.selectAll(".dimension").data(dimensions).enter().append("g").attr("class","dimension").attr("transform",function(e){return"translate("+x(e)+")"}).call(d3.behavior.drag().on("dragstart",function(e){dragging[e]=this.__origin__=x(e);background.attr("visibility","hidden")}).on("drag",function(e){dragging[e]=Math.min(w,Math.max(0,this.__origin__+=d3.event.dx));foreground.attr("d",path);dimensions.sort(function(e,t){return position(e)-position(t)});x.domain(dimensions);g.attr("transform",function(e){return"translate("+position(e)+")"})}).on("dragend",function(e){delete this.__origin__;delete dragging[e];transition(d3.select(this)).attr("transform","translate("+x(e)+")");transition(foreground).attr("d",path);background.attr("d",path).transition().delay(500).duration(0).attr("visibility",null)}));g.append("g").attr("class","axis").each(function(e){d3.select(this).call(axis.scale(y[e]))}).append("text").attr("text-anchor","middle").attr("y",-9).text(String);g.append("g").attr("class","brush").each(function(e){d3.select(this).call(y[e].brush=d3.svg.brush().y(y[e]).on("brush",brush))}).selectAll("rect").attr("x",-8).attr("width",16);' + 
                postfix;
        END;

        /***************************************************************************
         *  Formats various "Tree" Structures.  Requires a nested dataset with  
         *  suitable label, children and value columns.  
         *  Note:  The "children" column should contain a matching nested dataset to
         *         its parent.
         *
         *  Tree Types:
         *   - ClusterDendrogram
         *   - ReingoldTilfordTree
         *   - CirclePacking
         *   - SunburstPartition
         *
         *    @param dataCol        The column which contains the nested dataset. 
         *    @param labelField     The "Label" column within the nested dataset.  
         *    @param childrenField  The "Children" column that conatins another nested 
         *                          dataset.  
         *    @param valueField     The "Value" column within the nested dataset.  
         ***************************************************************************/
        EXPORT Tree(STRING dataCol, STRING labelField, STRING childrenField, STRING valueField) := MODULE
            SHARED prefix := 'var __sourceData=lang.clone(__row.' + dataCol + ');var getLabel=function(e){return e.' + labelField + '};var getChildren=function(e){return e.' + childrenField + '};var getValue=function(e){return+e.' + valueField + '};' +
                'require(["d3/d3.v3.min.js"],function () {';
            SHARED postfix := '});';

            EXPORT ClusterDendrogram := prefix + 
                'dojo.query("head").append("<style>.nodeCD circle { fill: #fff; stroke: steelblue; stroke-width: 1.5px;}.nodeCD { font: 10px sans-serif;}.linkCD { fill: none; stroke: #ccc; stroke-width: 1.5px;}</style>");var width=500,height=500;var cluster=d3.layout.cluster().size([height,width-160]).children(function(e){return getChildren(e)});var diagonal=d3.svg.diagonal().projection(function(e){return[e.y,e.x]});var svg=d3.select(__cell).append("svg").attr("width",width).attr("height",height).append("g").attr("transform","translate(40,0)");var nodes=cluster.nodes(__sourceData),links=cluster.links(nodes);var link=svg.selectAll(".link").data(links).enter().append("path").attr("class","linkCD").attr("d",diagonal);var node=svg.selectAll(".node").data(nodes).enter().append("g").attr("class","nodeCD").attr("transform",function(e){return"translate("+e.y+","+e.x+")"});node.append("circle").attr("r",4.5);node.append("text").attr("dx",function(e){return getChildren(e)?-8:8}).attr("dy",3).style("text-anchor",function(e){return getChildren(e)?"end":"start"}).text(function(e){return getLabel(e)});' +
                postfix;
            EXPORT ReingoldTilfordTree := prefix +
                'dojo.query("head").append("<style>.nodeRTT circle {  fill: #fff;  stroke: steelblue;  stroke-width: 1.5px;}.nodeRTT {  font: 10px sans-serif;}.linkRTT {  fill: none;  stroke: #ccc;  stroke-width: 1.5px;}</style>");var diameter=500;var tree=d3.layout.tree().size([360,diameter/2-20]).children(function(e){return getChildren(e)}).separation(function(e,t){return(e.parent==t.parent?1:2)/e.depth});var diagonal=d3.svg.diagonal.radial().projection(function(e){return[e.y,e.x/180*Math.PI]});var svg=d3.select(__cell).append("svg").attr("width",diameter).attr("height",diameter-0).append("g").attr("transform","translate("+diameter/2+","+diameter/2+")");var nodes=tree.nodes(__sourceData),links=tree.links(nodes);var link=svg.selectAll(".link").data(links).enter().append("path").attr("class","linkRTT").attr("d",diagonal);var node=svg.selectAll(".node").data(nodes).enter().append("g").attr("class","nodeRTT").attr("transform",function(e){return"rotate("+(e.x-90)+")translate("+e.y+")"});node.append("circle").attr("r",4.5);node.append("text").attr("dy",".31em").attr("text-anchor",function(e){return e.x<180?"start":"end"}).attr("transform",function(e){return e.x<180?"translate(8)":"rotate(180)translate(-8)"}).text(function(e){return getLabel(e)});' +
                postfix;
            EXPORT CirclePacking := prefix + 
                'dojo.query("head").append("<style>.nodeCP circle{ fill: rgb(31, 119, 180); fill-opacity: .25; stroke: rgb(31, 119, 180); stroke-width: 1px;}.leafCP circle {  fill: #ff7f0e;  fill-opacity: 1;}</style>");var diameter=500,format=d3.format(",d");var pack=d3.layout.pack().size([diameter-4,diameter-4]).children(function(e){return getChildren(e)}).value(function(e){return getValue(e)});var svg=d3.select(__cell).append("svg").attr("width",diameter).attr("height",diameter).append("g").attr("transform","translate(2,2)");var node=svg.datum(__sourceData).selectAll(".node").data(pack.nodes).enter().append("g").attr("class",function(e){return getChildren(e)?"nodeCP":"leafCP nodeCP"}).attr("transform",function(e){return"translate("+e.x+","+e.y+")"});node.append("title").text(function(e){return getLabel(e)+(getChildren(e)?"":": "+format(getValue(e)))});node.append("circle").attr("r",function(e){return e.r});node.filter(function(e){return!getChildren(e)}).append("text").attr("dy",".3em").style("text-anchor","middle").text(function(e){return getLabel(e).substring(0,e.r/3)});' +           
                postfix;
            EXPORT SunburstPartition := prefix +
                'function computeTextRotation(e){var t=x(e.x+e.dx/2)-Math.PI/2;return t/Math.PI*180}dojo.query("head").append("<style>path { stroke: #fff; fill-rule: evenodd; } </style>");var width=500,height=500,radius=Math.min(width,height)/2;var x=d3.scale.linear().range([0,2*Math.PI]);var y=d3.scale.sqrt().range([0,radius]);var color=d3.scale.category20c();var svg=d3.select(__cell).append("svg").attr("width",width).attr("height",height).append("g").attr("transform","translate("+width/2+","+(height/2+10)+")");var partition=d3.layout.partition().children(function(e){return getChildren(e)}).value(function(e){return getValue(e)});var arc=d3.svg.arc().startAngle(function(e){return Math.max(0,Math.min(2*Math.PI,x(e.x)))}).endAngle(function(e){return Math.max(0,Math.min(2*Math.PI,x(e.x+e.dx)))}).innerRadius(function(e){return Math.max(0,y(e.y))}).outerRadius(function(e){return Math.max(0,y(e.y+e.dy))});var g=svg.selectAll("g").data(partition.nodes(__sourceData)).enter().append("g");var path=g.append("path").attr("d",arc).style("fill",function(e){return color(getLabel(getChildren(e)?e:e.parent))});var text=g.append("text").attr("x",function(e){return y(e.y)}).attr("dx","6").attr("dy",".35em").text(function(e){return getLabel(e)});text.attr("transform",function(e){return"rotate("+computeTextRotation(e)+")"});' +
                postfix;
        END;

        /***************************************************************************
         *  Formats various "Graph" Structures.  Requires two nested datasets   
         *  "vertices" and "edges".  
         *  The vertices dataset should contain a label and group (category) column.
         *  The edges dataset should contain source, target and weight fields.
         *
         *  Graph Types:
         *   - ForceDirected
         *   - CoOccurrence
         *
         *    @param verticesCol    The column which contains the vertices dataset. 
         *    @param labelField     The "Label" column within the vertices dataset.  
         *    @param groupField     The "Group" column within the vertices dataset. 
         *    @param edgesCol       The column which contains the edges dataset. 
         *    @param sourceField    The "Source" column within the edges dataset.  
         *    @param targetField    The "Target" column within the edges dataset. 
         *    @param weightField    The "Weight" column within the edges dataset. 
         ***************************************************************************/
        EXPORT Graph(STRING verticesCol, STRING labelField, STRING groupField, STRING edgesCol, STRING sourceField, STRING targetField, STRING weightField) := MODULE
            SHARED prefix := 'require(["d3/d3.v3.min.js"],function () {' +
                'var _target = {domNode: __cell, width: __width, height: __width};' +
                'var _data = {vertices: __row.' + verticesCol + ', vertexName: "' + labelField + '", vertexCategory: "' + groupField + '", edges: __row.' + edgesCol + ', edgeSource: "' + sourceField + '", edgeTarget: "' + targetField + '", edgeWeight: "' + weightField + '"};' + 
                'var target={domNode:"",width:500,height:500};lang.mixin(target,_target);var data={vertices:[],vertexName:"name",vertexCategory:"category",edges:[],edgeSource:"source",edgeTarget:"target",edgeWeight:"weight"};lang.mixin(data,_data);var __verticesData=lang.clone(data.vertices).map(function(e){e.name=e[data.vertexName];e.category=e[data.vertexCategory];return e});var __edgesData=lang.clone(data.edges).map(function(e){e.source=+e[data.edgeSource];e.target=+e[data.edgeTarget];e.weight=+e[data.edgeWeight];return e});';
            SHARED postfix :=  '});';
            
            EXPORT ForceDirected := prefix + 
                'var color=d3.scale.category20();var force=d3.layout.force().gravity(.05).distance(100).charge(-100).size([target.width,target.height]);var svg=d3.select(target.domNode).append("svg").attr("width",target.width).attr("height",target.height).append("g");force.nodes(__verticesData).links(__edgesData);var link=svg.selectAll(".linkFD").data(__edgesData).enter().append("line").style("stroke-width",function(e){return Math.sqrt(e.weight)}).style("stroke","#999").style("stroke-opacity",".6");var node=svg.selectAll(".nodeFD").data(__verticesData).enter().append("g").call(force.drag);node.append("circle").attr("r",5).style("fill",function(e){return color(e.category)}).style("stroke","#fff").style("stroke-width","1.5px");node.append("title").text(function(e){return e.name});node.append("text").attr("dx", 12).attr("dy", ".35em").text(function(e) { return e.name });force.on("tick",function(){link.attr("x1",function(e){return e.source.x}).attr("y1",function(e){return e.source.y}).attr("x2",function(e){return e.target.x}).attr("y2",function(e){return e.target.y});node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })});force.start();' + 
                postfix;
            EXPORT CoOccurrence := prefix + 
                'function row(e){var t=d3.select(this).selectAll(".cell").data(e.filter(function(e){return e.z})).enter().append("rect").attr("class","cell").attr("x",function(e){return x(e.x)}).attr("width",x.rangeBand()).attr("height",x.rangeBand()).style("fill-opacity",function(e){return z(e.z)}).style("fill",function(e){return nodes[e.x].category==nodes[e.y].category?c(nodes[e.x].category):null}).on("mouseover",mouseover).on("mouseout",mouseout)}function mouseover(e){d3.selectAll(".row text").classed("active",function(t,n){return n==e.y});d3.selectAll(".column text").classed("active",function(t,n){return n==e.x})}function mouseout(){d3.selectAll("text").classed("active",false)}function order(e){x.domain(orders[e]);var t=svg.transition().duration(2500);t.selectAll(".row").delay(function(e,t){return x(t)*4}).attr("transform",function(e,t){return"translate(0,"+x(t)+")"}).selectAll(".cell").delay(function(e){return x(e.x)*4}).attr("x",function(e){return x(e.x)});t.selectAll(".column").delay(function(e,t){return x(t)*4}).attr("transform",function(e,t){return"translate("+x(t)+")rotate(-90)"})}dojo.query("head").append("<style>text.active { fill: red; } </style>");var margin={top:80,right:0,bottom:10,left:100};target.width-=margin.left+margin.right;target.height-=margin.top+margin.bottom;var x=d3.scale.ordinal().rangeBands([0,target.width]),z=d3.scale.linear().domain([0,4]).clamp(true),c=d3.scale.category10().domain(d3.range(10));var svg=d3.select(target.domNode).append("svg").attr("width",target.width).attr("height",target.height+margin.top+margin.bottom).style("margin-left",0+"px").append("g").attr("transform","translate("+margin.left+","+margin.top+")");var matrix=[],nodes=__verticesData,n=nodes.length;nodes.forEach(function(e,t){e.index=t;e.count=0;matrix[t]=d3.range(n).map(function(e){return{x:e,y:t,z:0}})});__edgesData.forEach(function(e){matrix[e.source][e.target].z+=e.weight;matrix[e.target][e.source].z+=e.weight;matrix[e.source][e.source].z+=e.weight;matrix[e.target][e.target].z+=e.weight;nodes[e.source].count+=e.weight;nodes[e.target].count+=e.weight});var orders={name:d3.range(n).sort(function(e,t){return d3.ascending(nodes[e].name,nodes[t].name)}),count:d3.range(n).sort(function(e,t){return nodes[t].count-nodes[e].count}),category:d3.range(n).sort(function(e,t){return nodes[t].category-nodes[e].category})};x.domain(orders.category);svg.append("rect").attr("width",target.width).attr("height",target.height).style("fill","#eee");var row=svg.selectAll(".row").data(matrix).enter().append("g").attr("class","row").attr("transform",function(e,t){return"translate(0,"+x(t)+")"}).each(row);row.append("line").attr("x2",target.width).style("stroke","#fff");row.append("text").attr("x",-6).attr("y",x.rangeBand()/2).attr("dy",".32em").attr("text-anchor","end").text(function(e,t){return nodes[t].name});var column=svg.selectAll(".column").data(matrix).enter().append("g").attr("class","column").attr("transform",function(e,t){return"translate("+x(t)+")rotate(-90)"});column.append("line").attr("x1",-target.width).style("stroke","#fff");column.append("text").attr("x",6).attr("y",x.rangeBand()/2).attr("dy",".32em").attr("text-anchor","start").text(function(e,t){return nodes[t].name});' + 
                postfix;
        END;
    END;
    
    EXPORT __selfTest := MODULE
        //  HTML
        htmlRecord := RECORD
            UNICODE Example__html;
        END;
        htmlDataset := DATASET([
            {HTML.Bold('Bold Text')},
            {HTML.Italic('Italic Text')},
            {HTML.Bold(HTML.Italic('Bold and Italic Text'))},
            {HTML.HyperLink('HPCC Systems', 'http://hpccsystems.com')},
            {HTML.Header('Header 1', 1) + HTML.Header('Header 2', 2) + HTML.Header('Header 3', 3) + HTML.Header('Header 4', 4)+ HTML.Header('Header 5', 5) + HTML.Header('Header 6', 6)},
            {HTML.Table(
                HTML.TableRow(HTML.TableHeader('Column 1') + HTML.TableHeader('Column 2')) +
                HTML.TableRow(HTML.TableCell('Cell 1, 1') + HTML.TableCell('cell 1, 2')) + 
                HTML.TableRow(HTML.TableCell('Cell 2, 1') + HTML.TableCell(u'Unicode Text:非常によい編集者であ非る非常によい編集者である非常によい編集者である'))
            , TRUE)}
        ], htmlRecord);
        EXPORT HTMLTest := htmlDataset;

        //  JavaScript
        jsRecord := RECORD
            UNICODE Example__javascript;
        END;
        jsDataset := DATASET([
            {JavaScript.setInnerText('Plain <Text>')},
            {JavaScript.setCellStyle('text-align', 'center') + JavaScript.setInnerText('Center Text')},
            {JavaScript.colorCell(u'Pink and Orange 非常', 'pink', 'orange')}
        ], jsRecord);
        EXPORT JavaScriptTest := jsDataset;

        //  Chart
        chartRecord := RECORD
            STRING Label;
            INTEGER4 Value;
        END;
        sampleRecord := RECORD
            DATASET(chartRecord) sourceData;
            STRING Bar__javascript;
            STRING Pie__javascript;
            STRING Bubble__javascript;
         END;
         sampleChart := JavaScript.Chart('sourcedata', 'label', 'value');
         
         sampleDataset := DATASET([
            {[
                {'English', 55},
                {'French', 5},
                {'Maths', 72},
                {'Science', 78},
                {'Art', 72},
                {'Computers', 100},
                {'Science', 80},
                {'Geog.', 40}
            ], sampleChart.Bar, sampleChart.Pie, sampleChart.Bubble}
         ], sampleRecord);
        
        EXPORT ChartTest := sampleDataset;
        
        //  MultipleValueChart
        MultipleValueChartRecord := RECORD
            VARSTRING labelX;
            INTEGER economy_mpg;
            INTEGER cylinders;
            INTEGER displacement_cc;
            INTEGER power_hp;
            INTEGER weight_lb;
            INTEGER _0_60_mph_s;
            INTEGER year;
        END;
        sampleRecord := RECORD
            dataset(MultipleValueChartRecord) sourceData;
            VARSTRING pc__javascript;
        END;
        sampleMultipleValueChart := JavaScript.MultipleValueChart('sourcedata', 'labelx');
        
        sampleDataset := DATASET([{[
            {'Ford Maverick', 15, 6, 250, 72, 3158, 19, 75}, 
            {'Ford Maverick', 18, 6, 250, 88, 3021, 16, 73}, 
            {'Ford Maverick', 21, 6, 200, 0, 2875, 17, 74}, 
            {'Ford Maverick', 21, 6, 200, 85, 2587, 16, 70}, 
            {'Ford Maverick', 24, 6, 200, 81, 3012, 17, 76}
            ], sampleMultipleValueChart.ParallelCoordinates}], sampleRecord);
            
        EXPORT MultipleValueChartTest := sampleDataset;                

        //  Tree
        leafRecord := RECORD
            STRING label;
            INTEGER4 value;
        END;
        parentRecord := RECORD
            STRING label;
            DATASET(leafRecord) children;
        END;
        grandParentRecord := RECORD
            STRING label;
            DATASET(parentRecord) children;
        END;
        greatGrandParentRecord := RECORD
            STRING label;
            DATASET(grandParentRecord) children;
        END;
        sampleRecord := RECORD
            greatGrandParentRecord sourceData;
            STRING ClusterDendrogram__javascript;
            STRING ReingoldTilfordTree__javascript;
            STRING CirclePacking__javascript;
            STRING SunburstPartition__javascript;
         END;
         sampleTree := JavaScript.Tree('sourcedata', 'label', 'children', 'value');
         
         sampleDataset := DATASET([
            {{'A', [
                {'AA', [
                    {'AAA', [
                        {'AAAA', 10}
                    ]}, 
                    {'AAB', [
                        {'AABA', 20},
                        {'AABB', 30},
                        {'AABC', 40}
                    ]}
                ]},
                {'AB', [
                    {'ABA', [
                        {'ABAA', 30},
                        {'ABAB', 40},
                        {'ABAC', 40},
                        {'ABAD', 40}
                    ]}, 
                    {'ABB', [
                        {'ABBA', 30},
                        {'ABBB', 50}
                    ]},
                    {'ABC', [
                        {'ABCA', 30},
                        {'ABCB', 50}
                    ]}
                ]}
            ]}, sampleTree.ClusterDendrogram, sampleTree.ReingoldTilfordTree, sampleTree.CirclePacking, sampleTree.SunburstPartition}
         ], sampleRecord);
        
        EXPORT TreeTest := sampleDataset;

        //  Graphs
        vertexRecord := RECORD
            STRING Label;
            INTEGER4 Category;
        END;
        verticesDataset := DATASET([
            {'6601 Park of Commerce Boulevard, Boca Raton', 1},
            {'Bruce Wayne', 2},
            {'Lex Luther', 2},
            {'HPCC Systems', 3},
            {'LexisNexis RISK', 3},
            {'4225, Birchwood Drive, Boca Raton', 1}
        ], vertexRecord);
        edgeRecord := RECORD
            INTEGER4 source;
            INTEGER4 target;
            INTEGER4 weight;
        END;
        edgesDataset := DATASET([
            {0, 3, 15},
            {0, 4, 15},
            {1, 3, 5},
            {1, 4, 5},
            {2, 3, 5},
            {5, 2, 15}
         ], edgeRecord);

        sampleRecord := RECORD
            DATASET(vertexRecord) vertices;
            DATASET(edgeRecord) edges;
            STRING ForceDirected__javascript;
            STRING CoOccurrence__javascript;
        END;
        sampleGraph := JavaScript.Graph('vertices', 'label', 'category', 'edges', 'source', 'target', 'weight');
        sampleDataset := DATASET([{
        verticesDataset, edgesDataset, sampleGraph.ForceDirected, sampleGraph.CoOccurrence
        }], sampleRecord);
         
        EXPORT GraphTest := sampleDataset;

        //  All
        EXPORT All := SEQUENTIAL(OUTPUT(HTMLTest, NAMED('HTML')), 
            OUTPUT(JavaScriptTest, NAMED('JavaScript')),
            OUTPUT(ChartTest, NAMED('Chart')),
            OUTPUT(MultipleValueChartTest, NAMED('MultipleValueChart')),
            OUTPUT(TreeTest, NAMED('Tree')),
            OUTPUT(GraphTest, NAMED('Graph'))
            );
    END;
END;
