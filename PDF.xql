xquery version "3.1";
(:~
 : This module based on the one provided in the shakespare example app
 : produces a xslfo temporary object and passes it to FOP to produce a PDF
 : @author Pietro Liuzzo 
 :)


declare namespace http = "http://expath.org/ns/http-client";
declare namespace fo = "http://www.w3.org/1999/XSL/Format";
declare namespace xslfo = "http://exist-db.org/xquery/xslfo";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace s = "local.print";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace d = "betmas.domlib";


declare variable $local:BMappUrl := 'https://betamasaheft.eu/';
declare variable $local:settings := doc('settings.xml')/s:settings;
declare variable $local:catalogue := doc('driver.xml')/tei:teiCorpus;
declare variable $local:bibliography := doc('data/bibliography.xml');
declare variable $local:entries := $local:catalogue//tei:TEI;
declare variable $local:prefix := $local:settings//s:localPrefix;
declare variable $local:listPrefixDef := $local:catalogue//tei:listPrefixDef;
declare variable $local:Z := if ($local:settings/s:zotero/text()) then
    $local:settings/s:zotero/text()
else
    'https://api.zotero.org/groups/358366/items';
declare variable $local:zstyle := if ($local:settings/s:zstyle/text()) then
    $local:settings/s:zstyle/text()
else
    'hiob-ludolf-centre-for-ethiopian-studies';
declare variable $local:bibtype := $local:settings/s:bibSettings/s:bibliographygeneration/text();

(:the basis of transformation is a series of strings for components:)
declare variable $local:values as element(value)+ := (
<value
    num="1"
    char="I"/>,
<value
    num="4"
    char="IV"/>,
<value
    num="5"
    char="V"/>,
<value
    num="9"
    char="IX"/>,
<value
    num="10"
    char="X"/>,
<value
    num="40"
    char="XL"/>,
<value
    num="50"
    char="L"/>,
<value
    num="90"
    char="XC"/>,
<value
    num="100"
    char="C"/>,
<value
    num="400"
    char="CD"/>,
<value
    num="500"
    char="D"/>,
<value
    num="900"
    char="CM"/>,
<value
    num="1000"
    char="M"/>
);

declare variable $local:domlib := doc('https://raw.githubusercontent.com/BetaMasaheft/BetMas/master/db/apps/lists/domlib.xml');
declare variable $local:bmeditors := doc('https://raw.githubusercontent.com/BetaMasaheft/BetMas/master/db/apps/lists/editors.xml')//tei:list;
declare variable $local:title := fo:tei2fo($local:catalogue/tei:teiHeader//tei:titleStmt/tei:title);

(:return the concatenation of strings by continuous reduction:)
declare function local:n2roman($num as xs:integer) as xs:string
{
    (:as long as we have a number, keep going:)
    if ($num) then
        (:reduce by the largest number that has a string value:)
        
        for $val in $local:values[@num <= $num][fn:last()]
        return
            (:using the highest value:)
            fn:concat($val/@char, local:n2roman($num - xs:integer($val/@num
            )))
            (:nothing left:)
    else
        ""
};
(:~ helper functx function, returning the index at which a substring starts :)
declare function functx:index-of-string($arg as xs:string?, $substring as xs:string) as xs:integer* {
    
    if (contains($arg, $substring))
    then
        (string-length(substring-before($arg, $substring)) + 1,
        for $other in
        functx:index-of-string(substring-after($arg, $substring),
        $substring)
        return
            $other +
            string-length(substring-before($arg, $substring)) +
            string-length($substring))
    else
        ()
};


declare function functx:index-of-node($nodes as node()*,
$nodeToFind as node()) as xs:integer* {
    
    for $seq in (1 to count($nodes))
    return
        $seq[$nodes[$seq] is $nodeToFind]
};

declare function functx:capitalize-first($arg as xs:string?) as xs:string? {
    
    concat(upper-case(substring($arg, 1, 1)),
    substring($arg, 2))
};

declare function fo:editorName($ref) {
    if (string-length($ref) != 2) then
        ()
    else
        (
        if ($local:bmeditors//tei:item[@xml:id = $ref])
        then
            $local:bmeditors//tei:item[@xml:id = $ref]/text()
        else
            string($ref)
        )
};

declare function fo:printTitleID($ref as xs:string?) as xs:string? {
    let $r := if (starts-with($ref, $local:BMappUrl)) then
        substring-after($ref, $local:BMappUrl)
    else
        $ref
    return
        json-doc(replace(concat($local:BMappUrl, 'api/', replace($r, ':', '_'), '/title/json'), '\s', ''))?title
};

declare function fo:getFile($id) {
    let $r := if (starts-with($id, $local:BMappUrl)) then
        $local:BMappUrl
    else
        ($local:BMappUrl || $id)
    return
        doc(concat($r, '.xml'))
};

declare function fo:lang($lang as xs:string) {
    switch ($lang)
        case 'ar'
            return
                (attribute baseline-shift {'2pt'}, attribute font-size {'14pt'}, attribute font-family {'Scheherazade'}, attribute writing-mode {'rl'})
        case 'so'
            return
                (attribute font-family {'coranica'}, attribute writing-mode {'rl'})
        case 'aa'
            return
                (attribute font-family {'coranica'}, attribute writing-mode {'rl'})
        case 'x-oh'
            return
                (attribute font-family {'coranica'}, attribute writing-mode {'rl'})
        case 'he'
            return
                (attribute font-family {'Titus'}, attribute writing-mode {'rl'})
        case 'syr'
            return
                (attribute font-family {'Titus'}, attribute writing-mode {'rl'})
        case 'grc'
            return
                attribute font-family {'Cardo'}
        case 'cop'
            return
                attribute font-family {'Titus'}
        case 'gez'
            return
                (attribute font-family {'Ludolfus'}, attribute letter-spacing {'0.5pt'}, attribute font-size {'0.9em'})
        case 'ti'
            return
                (attribute font-family {'Ludolfus'}, attribute letter-spacing {'0.5pt'}, attribute font-size {'0.9em'})
        case 'amh'
            return
                (attribute font-family {'Ludolfus'}, attribute letter-spacing {'0.5pt'}, attribute font-size {'0.9em'})
        case 'sa'
            return
                attribute font-family {'NotoSansDevanagari'}
        default return
            attribute font-family {'Ludolfus'}
};

declare function fo:entitiesWithRef($node) {
    let $n := substring-after($node/@target, '#')
    let $attid := string(root($node)/tei:TEI/@xml:id) || generate-id($node) || string($node/@ref)
    return
        <fo:inline
            id="{$attid}">{
                if ($node/@target and not($node/text())) then
                    (if (starts-with($node/@target, '#')) then
                        <fo:basic-link
                            internal-destination="{$n}">{$n}</fo:basic-link>
                    else
                        <fo:basic-link
                            external-destination="{$node/@target}"></fo:basic-link>)
                else
                    if ($node/@target and $node/text()) then
                        <fo:basic-link
                            external-destination="{$node/@target}">{fo:tei2fo($node/text())}</fo:basic-link>
                    else
                        if ($node/@ref and $node/text()) then
                            fo:tei2fo($node/node())
                        else
                            if ($node/text() or $node/tei:*) then
                                (
                                let $lang := if ($node/@xml:lang) then
                                    $node/@xml:lang
                                else
                                    $node/following-sibling::tei:textLang/@mainLang
                                return
                                    if ($lang) then
                                        fo:lang($lang)
                                    else
                                        (),
                                fo:tei2fo($node/node()))
                            else
                                if ($node/@ref) then
                                    
                                    let $r := if (starts-with($node/@ref, $local:BMappUrl)) then
                                        string($node/@ref)
                                    else
                                        $local:BMappUrl ||
                                        '/' || string($node/@ref)
                                    
                                    let $t := if ($node/node()) then
                                        fo:tei2fo($node/node())
                                    else
                                        fo:printTitleID($node/@ref)
                                    return
                                        <fo:basic-link
                                            external-destination="{$r}">{$t}</fo:basic-link>
                                else
                                    'no title provided'
            }</fo:inline>
};

declare function fo:entitiesWithRefNoID($node) {
    let $n := substring-after($node/@target, '#')
    return
        <fo:inline>{
                if ($node/@target and not($node/text())) then
                    if (starts-with($node/@target, '#')) then
                        <fo:basic-link
                            internal-destination="{$n}">{$n}</fo:basic-link>
                    else
                        <fo:basic-link
                            external-destination="{$node/@target}"></fo:basic-link>
                else
                    if ($node/@target and $node/text()) then
                        <fo:basic-link
                            external-destination="{$node/@target}">{fo:tei2fo($node/text())}</fo:basic-link>
                    else
                        if ($node/@ref and $node/text()) then
                            fo:tei2fo($node/node())
                        else
                            if ($node/text() or $node/tei:*) then
                                (
                                let $lang := if ($node/@xml:lang) then
                                    $node/@xml:lang
                                else
                                    $node/following-sibling::tei:textLang/@mainLang
                                return
                                    if ($lang) then
                                        fo:lang($lang)
                                    else
                                        (),
                                fo:tei2fo($node/node()))
                            else
                                if ($node/@ref) then
                                    
                                    let $r := if (starts-with($node/@ref, $local:BMappUrl)) then
                                        string($node/@ref)
                                    else
                                        $local:BMappUrl ||
                                        '/' || string($node/@ref)
                                    
                                    let $t := if ($node/node()) then
                                        fo:tei2fo($node/node())
                                    else
                                        fo:printTitleID($node/@ref)
                                    return
                                        <fo:basic-link
                                            external-destination="{$r}">{$t}</fo:basic-link>
                                else
                                    'no title provided'
            }</fo:inline>
};

declare function fo:ContentsTitle($title) {
    (:
if tei:title[@xml:lang="gez"][@xml:id="t1"] 
then 
if  tei:title[@xml:lang='en'][@corresp='#t1'][@type='main']
  then
2) äthiopischer titel ja, englischer Titel keine Übersetzung vom äthiopischen, 
    tei:title[@xml:lang='en'][@corresp='#t1'][@type='main'] + ( tei:title[@xml:lang="gez"][@xml:id="t1"] )
    e.g. Psalter (ዳዊት፡)
 else 
1) englischer titel Übersetzung vom äthiopischen, 
     " tei:title[@xml:lang='en'][@corresp='#t1'] "  + ( tei:title[@xml:lang="gez"][@xml:id="t1"] )
     e.g. “The Canticles of the Prophets” (መሓልየ፡ ነቢያት)
else
    
3) kein äthiopischer Titel, nur descriptiver englischer Titel

tei:title[@xml:lang='en']
e.g. On the length of the day during the months of the
year, CAe 5886
:)
    let $tref := $title/@ref
    return
        if ($tref) then
            let $fullref := string($title/@ref)
            let $incomplete := if ($title/@type = 'incomplete') then
                ', incomplete'
            else
                ()
            let $tigrinya := if ($title/following-sibling::tei:textLang[@mainLang != "gez"]
            or $title/following-sibling::tei:textLang[@otherLangs])
            then
                let $languages := $title/ancestor::tei:TEI//tei:langUsage
                let $ml := string($title/following-sibling::tei:textLang/@mainLang)
                let $mlL := $languages/tei:language[@ident = $ml]/text()
                let $ol := string($title/following-sibling::tei:textLang/@otherLangs)
                let $olL := $languages/tei:language[@ident = $ol]/text()
                return
                    ', in ' || $mlL || (if ($olL) then
                        (' and ' || $olL)
                    else
                        ())
            else
                ()
            let $ref := if (contains($fullref, '#')) then
                substring-before($fullref, '#')
            else
                $fullref
            let $record := fo:getFile($ref)//tei:TEI
            let $geeztitle := $record//tei:titleStmt/tei:title[@xml:lang = "gez"][@xml:id][not(@type)][1]
            let $gezid := '#' || string($geeztitle/@xml:id)
            let $maintitleENgez := $record//tei:titleStmt/tei:title[@xml:lang = 'en'][@type = 'main']
            let $titleENgez := $record//tei:titleStmt/tei:title[@xml:lang = 'en'][@corresp = $gezid]
            let $titleENNOgez := $record//tei:titleStmt/tei:title[@xml:lang = 'en']
            let $TITSEL := if ($geeztitle) then
                (
                if ($maintitleENgez) then
                    string-join($maintitleENgez/text(), ' ') || ' (' || string-join($geeztitle/text(), ' ') || ')'
                else
                    '‘' || string-join($titleENgez/text(), ' ') || '’' || ' (' || string-join($geeztitle/text(), ' ') || ')'
                )
            else
                string-join($titleENNOgez/text(), ' ')
            return
                $TITSEL || $incomplete || ', CAe ' || substring($ref, 4, 4) || $tigrinya || '.'
        else
            $title/text()

};

declare function fo:zoteroCit($ZoteroUniqueBMtag as xs:string) {
    let $url := concat($local:Z, '?tag=', $ZoteroUniqueBMtag, '&amp;include=citation&amp;locale=en-GB&amp;style=', $local:zstyle)
    let $parseedZoteroApiResponse := json-doc($url)
    let $string := '<inline xmlns="http://www.w3.org/1999/XSL/Format">' || replace($parseedZoteroApiResponse?1?citation, '&lt;span&gt;', '') => replace('&lt;/span&gt;', '') => replace('&lt;/i&gt;', '</inline>') => replace('&lt;i&gt;', '<inline font-style="italic">') || '</inline>'
    
    return
        parse-xml($string)
};

declare function fo:Zotero($ZoteroUniqueBMtag as xs:string) {
    let $data := concat($local:Z, '?tag=', $ZoteroUniqueBMtag, '&amp;format=bib&amp;locale=en-GB&amp;style=', $local:zstyle, '&amp;linkwrap=1')
    let $datawithlink := fo:tei2fo(doc($data)//*:div[@class = 'csl-entry'])
    return
        $datawithlink
};

declare function fo:titleSelector($fullref) {
    let $ref := if (contains($fullref, '#')) then
        substring-before($fullref, '#')
    else
        $fullref
    let $record := fo:getFile($ref)//tei:TEI
    let $geeztitle := $record//tei:titleStmt/tei:title[@xml:lang = "gez"][@xml:id][not(@type)][1]
    let $gezid := '#' || string($geeztitle/@xml:id)
    let $maintitleENgez := $record//tei:titleStmt/tei:title[@xml:lang = 'en'][@type = 'main']
    let $titleENgez := $record//tei:titleStmt/tei:title[@xml:lang = 'en'][@corresp = $gezid]
    let $titleENNOgez := $record//tei:titleStmt/tei:title[@xml:lang = 'en']
    let $TITSEL := if ($geeztitle) then
        (
        if ($maintitleENgez) then
            string-join($maintitleENgez/text(), ' ') || ' (' || string-join($geeztitle/text(), ' ') || ')'
        else
            '“' || string-join($titleENgez/text(), ' ') || '”' || ' (' || string-join($geeztitle/text(), ' ') || ')'
        )
    else
        string-join($titleENNOgez/text(), ' ')
    return
        $TITSEL || ', CAe ' || substring($ref, 4, 4)
};

declare function fo:figDesc2fo($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(tei:placeName)
                return
                    fo:entitiesWithRefNoID($node)
            case element(tei:persName)
                return
                    fo:entitiesWithRefNoID($node)
            case element()
                return
                    fo:tei2fo($node)
            default
                return
                    $node
};

declare function fo:tei2foSinRef($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(span)
                return
                    <fo:inline>{
                            if ($node/@style[. = "font-style:normal;"]) then
                                attribute font-style {'normal'}
                            else
                                ()
                        }{$node/text()}</fo:inline>
            
            case element(tei:pb)
                return
                    ' (fol. ' || string($node/@n) || ') '
            
            case element(tei:cb)
                return
                    ' (' || string($node/@n) || ') '
            
            case element(tei:gap)
                
                return
                    switch ($node/@reason)
                        case 'lost'
                            return
                                <fo:inline>[...]</fo:inline>
                        case 'illegible'
                            return
                                <fo:inline>&lt;...&gt;</fo:inline>
                        case 'omitted'
                            return
                                <fo:inline>...</fo:inline>
                        case 'ellipsis'
                            return
                                if ($node/parent::tei:q) then
                                    ()
                                else
                                    <fo:inline>(...)</fo:inline>
                        default return
                            <fo:inline>[- ca. {(string($node/@quantity) || ' ' || string($node/@unit))}{
                                    if (xs:integer($node/@quantity) gt 1) then
                                        's'
                                    else
                                        ()
                                } -]</fo:inline>
        case element(tei:del)
            return
                <fo:inline>[...]</fo:inline>
        case element(tei:choice)
            return
                <fo:inline>{$node/tei:sic/text()} (!)</fo:inline>
        case element(tei:sic)
            return
                <fo:inline>{$node/text()} (!)</fo:inline>
        case element(tei:add)
            return
                fo:tei2fo($node/node())
        case element(tei:space)
            return
                <fo:inline>[////]</fo:inline>
        case element(tei:subst)
            return
                '{' || string-join(fo:tei2fo($node/tei:add)) || '}'
        case element(tei:supplied)
            return
                <fo:inline>[{fo:tei2fo($node/node())}]</fo:inline>
        case element(tei:add)
            return
                fo:tei2fo($node/node())
        case element(tei:handShift)
            return
                fo:tei2fo($node/node())
        case element(tei:hi)
            return
                
                if ($node/@rend = 'rubric') then
                    fo:tei2fo($node/node())
                else
                    if ($node/@rendition) then
                        switch ($node/@rendition)
                            case 'simple:italic'
                                return
                                    <fo:inline
                                        font-style='italic'>{fo:tei2fo($node/text())}</fo:inline>
                            case 'simple:bold'
                                return
                                    <fo:inline
                                        font-weight='bold'>{fo:tei2fo($node/text())}</fo:inline>
                            case 'simple:smallcaps'
                                return
                                    <fo:inline
                                        font-size="0.75em">{upper-case(fo:tei2fo($node/text()))}</fo:inline>
                            default return
                                <fo:inline>{fo:tei2fo($node/node())}</fo:inline>
                else
                    fo:tei2fo($node/node())
    case element(tei:certainty)
        return
            <fo:inline>(?)</fo:inline>
    case element(tei:persName)
        return
            fo:tei2foSinRef($node/node())
    
    case element(tei:placeName)
        return
            fo:tei2foSinRef($node/node())
    
    case element(tei:title)
        return
            fo:tei2foSinRef($node/node())
    case element()
        return
            fo:tei2fo($node/node())
    default
        return
            $node
};


declare function fo:tei2fo($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(a)
                return
                    <fo:basic-link
                        external-destination="{string($node/@href)}">{fo:tei2fo($node/text())}</fo:basic-link>
            case element(i)
                return
                    <fo:inline
                        font-style="italic">{fo:tei2fo($node/node())}</fo:inline>
            case element(span)
                return
                    <fo:inline>{
                            if ($node/@style[. = "font-style:normal;"]) then
                                attribute font-style {'normal'}
                            else
                                ()
                        }{$node/text()}</fo:inline>
            
            case element(tei:pb)
                return
                    ' (fol. ' || string($node/@n) || ') '
            
            case element(tei:cb)
                return
                    ' (' || string($node/@n) || ') '
            
            case element(tei:gap)
                
                return
                    switch ($node/@reason)
                        case 'lost'
                            return
                                <fo:inline>[...]</fo:inline>
                        case 'illegible'
                            return
                                <fo:inline>&lt;...&gt;</fo:inline>
                        case 'omitted'
                            return
                                <fo:inline>...</fo:inline>
                        case 'ellipsis'
                            return
                                if ($node/parent::tei:q) then
                                    ()
                                else
                                    <fo:inline>(...)</fo:inline>
                        default return
                            <fo:inline>[- ca. {(string($node/@quantity) || ' ' || string($node/@unit))}{
                                    if (xs:integer($node/@quantity) gt 1) then
                                        's'
                                    else
                                        ()
                                } -]</fo:inline>
        case element(tei:del)
            return
                <fo:inline>[...]</fo:inline>
        case element(tei:choice)
            return
                <fo:inline>{$node/tei:sic/text()} (!)</fo:inline>
        case element(tei:sic)
            return
                <fo:inline>{$node/text()} (!)</fo:inline>
        case element(tei:add)
            return
                fo:tei2fo($node/node())
        case element(tei:space)
            return
                <fo:inline>[////]</fo:inline>
        case element(tei:subst)
            return
                '{' || string-join(fo:tei2fo($node/tei:add)) || '}'
        case element(tei:supplied)
            return
                (:switch ($node/@reason)
                    case 'omitted'
                        return
                            <fo:inline>&lt;{fo:tei2fo($node/node())}&gt;</fo:inline>
                    case 'undefined'
                        return
                            <fo:inline>[{fo:tei2fo($node/node())} (?)]</fo:inline>
                    default return:)
                <fo:inline>[{fo:tei2fo($node/node())}]</fo:inline>
        case element(tei:add)
            return
                fo:tei2fo($node/node())
        case element(tei:handShift)
            return
                fo:tei2fo($node/node())
        case element(tei:hi)
            return
                
                if ($node/@rend = 'rubric') then
                    fo:tei2fo($node/node())
                else
                    if ($node/@rendition) then
                        switch ($node/@rendition)
                            case 'simple:italic'
                                return
                                    <fo:inline
                                        font-style='italic'>{fo:tei2fo($node/text())}</fo:inline>
                            case 'simple:bold'
                                return
                                    <fo:inline
                                        font-weight='bold'>{fo:tei2fo($node/text())}</fo:inline>
                            case 'simple:smallcaps'
                                return
                                    <fo:inline
                                        font-size="0.75em">{upper-case(fo:tei2fo($node/text()))}</fo:inline>
                            default return
                                <fo:inline>{fo:tei2fo($node/node())}</fo:inline>
                else
                    fo:tei2fo($node/node())
    case element(tei:certainty)
        return
            <fo:inline>(?)</fo:inline>
    
    case element(tei:foliation)
        return
            fo:tei2fo($node/node())
    case element(tei:note)
        return
            let $root := root($node)
            let $notes := $root//tei:note
            let $n := count($node/preceding::tei:note) + 1
            return
                <fo:footnote>
                    <fo:inline
                        font-size="7pt"
                        vertical-align="text-top">{$n}</fo:inline>
                    
                    <fo:footnote-body
                        text-align="justify"
                        text-indent="0">
                        <fo:list-block>
                            <fo:list-item>
                                <fo:list-item-label>
                                    <fo:block>
                                        <fo:inline
                                            vertical-align="text-top"
                                            font-size="9pt"
                                        >{$n}</fo:inline>
                                    </fo:block>
                                </fo:list-item-label>
                                <fo:list-item-body>
                                    <fo:block
                                        hyphenate="true"
                                        space-before="0.45cm"
                                        font-size="9pt"
                                        line-height="11pt"
                                        margin-left="0.45cm"
                                    >
                                        {fo:tei2fo($node/node())}
                                    </fo:block>
                                </fo:list-item-body>
                            </fo:list-item>
                        </fo:list-block>
                    </fo:footnote-body>
                </fo:footnote>
    
    case element(tei:p)
        return
            <fo:block
                xml:lang="en"
                hyphenate="true">{
                    if ($node/preceding-sibling::tei:p) then
                        (attribute text-indent {'0.43cm'})
                    else
                        ()
                }{fo:tei2fo($node/node())}</fo:block>
    
    case element(tei:figure)
        return
            (:    If your image is not dispalying well, remember to take a good screenshot and modify it to 300dpi.
if it does not fit to the page set the width attribute in the source file, as that is the one used to set the viewport size to which the image is adapted
:)
            <fo:block
                id="{string(root($node)/tei:TEI/@xml:id)}{$node/tei:graphic/@xml:id}{generate-id($node)}"
            >
                
                {
                    
                    for $g in $node/tei:graphic
                    return
                        
                        <fo:block-container
                            height="85mm">
                            <fo:block
                                hyphenate="true"
                                text-align="center"
                                margin-top="3mm"
                                margin-bottom="3mm"
                                page-break-inside="avoid"
                                page-break-after="avoid">
                                <fo:external-graphic
                                    src="{
                                            if (starts-with($g/@url, 'http')) then
                                                string($g/@url)
                                            else
                                                let $base := base-uri($node)
                                                let $lastSlash := functx:index-of-string($base, '/')[last()]
                                                return
                                                    concat(substring($base, 1, $lastSlash), string($g/@url))
                                        }"
                                    content-width="scale-down-to-fit"
                                    width="90%"
                                    scaling="uniform"
                                    display-align="center"
                                />
                            
                            </fo:block>
                            <fo:block
                                hyphenate="true"
                                margin-bottom="0.3cm"
                                font-size="smaller"
                                margin-left="5mm"
                                margin-right="5mm"
                                page-break-before="avoid"
                                text-align="center">
                                {
                                    'Fig. ' || (count($g/preceding::tei:graphic) + 1) || ' '
                                }{fo:tei2fo($g/tei:desc)}
                            </fo:block>
                        </fo:block-container>
                }
            
            </fo:block>
    case element(tei:signatures)
        return
            fo:tei2fo($node/node())
    
    case element(tei:summary)
        return
            if ($node/parent::tei:decoDesc) then
                fo:tei2fo($node/node())
            else
                ()
    case element(tei:seg)
        return
            if ($node/@part = 'I') then
                ('Incipit: ', fo:tei2fo($node/node()))
            else
                if ($node/@type = 'script') then
                    fo:tei2fo($node/node())
                else
                    if ($node/@type = 'supplication') then
                        fo:tei2fo($node/node())
                    else
                        ()
    case element(tei:q)
        return
            if ($node//text()) then
                <fo:inline>
                    {
                        if ($node/@xml:lang) then
                            fo:lang($node/@xml:lang)
                        else
                            ()
                    }
                    {fo:tei2fo($node/node())}
                </fo:inline>
            else
                let $nl := string($node/@xml:lang)
                let $languages := root($node)//tei:langUsage
                let $matchLang := $languages/tei:language[@ident = $nl]
                return
                    <fo:block>Text in {$matchLang[1]/text()}</fo:block>
    
    case element(tei:place)
        return
            <fo:block
            >({
                    for $pn in $node/tei:placeName
                    return
                        (<fo:inline>{fo:tei2fo($pn/text())}</fo:inline>,
                        <fo:inline
                            vertical-align="super"
                            font-size="8pt">{string($pn/@xml:lang)}</fo:inline>,
                        <fo:inline>
                        </fo:inline>)
                };)
                {fo:tei2fo($node/node()[not(name() = 'listBibl')][not(name() = 'placeName')][not(name() = 'location')])}
            </fo:block>
    case element(tei:person)
        return
            if (root($node)/tei:TEI/@type = 'pers') then
                <fo:block
                >( {
                        for $pn in $node/tei:persName
                        return
                            (<fo:inline>{fo:tei2fo($pn/node())}</fo:inline>,
                            <fo:inline
                                vertical-align="super"
                                font-size="8pt">{string($pn/@xml:lang)}
                            </fo:inline>)
                    } )
                    {fo:tei2fo($node/node()[not(name() = 'persName')])}
                </fo:block>
            else
                fo:tei2fo($node/node())
    case element(tei:list)
        return
            let $par := if ($node/ancestor::tei:quote) then
                1
            else
                ()
            return
                <fo:list-block
                    provisional-distance-between-starts="6mm"
                    provisional-label-separation="6mm"
                >
                    {attribute start-indent {((0.43 * (1 + count($node/ancestor::tei:list))) + $par) || "cm"}}
                    {fo:tei2fo($node/node())}
                </fo:list-block>
    
    
    case element(tei:item)
        return
            <fo:list-item>
                <fo:list-item-label
                    end-indent="label-end()">
                    <fo:block>
                        {
                        <fo:inline>
                                {
                                if ($node/tei:label)
                                    then
                                        fo:tei2fo($node/tei:label/node())
                                    else
                                        (let $upperalphabet := ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'J', 'K', 'L')
                                        let $loweralphabet := ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'j', 'k', 'l')
                                        let $romanUpper := ('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X')
                                        let $romanLower := ('i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x')
                                        let $position := count($node/preceding-sibling::tei:item) + 1
                                        return
                                            switch ($node/parent::tei:list/@type)
                                                case 'ordered:upperalpha'
                                                    return
                                                        $upperalphabet[$position]
                                                case 'ordered:upperroman'
                                                    return
                                                        $romanUpper[$position]
                                                case 'ordered:loweralpha'
                                                    return
                                                        $loweralphabet[$position]
                                                case 'ordered:lowerroman'
                                                    return
                                                        $romanLower[$position]
                                                default return
                                                    $position
                                    )
                                    || ')'
                            }
                        </fo:inline>
                    }
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body
                start-indent="body-start()">
                <fo:block
                    hyphenate="true">{
                        
                        fo:tei2fo($node/node())
                    }</fo:block>
            </fo:list-item-body>
        </fo:list-item>
case element(tei:listWit)
    return
        <fo:block
            margin-top="3mm"
        >
            <fo:block>{string($node/@rend)}</fo:block>
            {fo:tei2fo($node/node())}
        </fo:block>

case element(tei:witness)
    return
        
        <fo:block
            margin-bottom="2mm">{
                if ($node/@xml:id) then
                    <fo:inline
                        font-weight="bold">{(string($node/@xml:id) || ': ')}</fo:inline>
                else
                    ()
            }
            {
                if ($node/@type = 'external') then
                    <fo:basic-link
                        external-destination="{string($node/@facs)}"
                        font-weight="bold">{string($node/@corresp)}</fo:basic-link>
                else
                    fo:printTitleID(string($node/@corresp))
            }</fo:block>


case element(tei:titleStmt)
    return
        (<fo:block
            id="{string(root($node)/tei:TEI/@xml:id)}{generate-id($node/tei:title)}"
            font-size="12pt"
            text-align="center"
            font-weight='700'
            margin-bottom="12.24pt"
            margin-top="25.2pt">{fo:tei2fo($node/tei:title)}</fo:block>,
        <fo:block
            font-size="12pt"
            text-align="center"
            font-variant="small-caps"
            margin-bottom="25pt">{string-join($node/tei:author/text(), ', ')}</fo:block>)
case element(tei:signed)
    return
        <fo:block
            text-align="right">{fo:tei2fo($node/text())}</fo:block>

case element(tei:date)
    return
        if ($node/text()) then
            fo:tei2fo($node/node())
        else
            if ($node/@notBefore and $node/@notAfter) then
                <fo:inline>{string($node/@notBefore) || '-' || string($node/@notAfter)}</fo:inline>
            else
                if ($node/@when) then
                    <fo:inline>{string($node/@when)}</fo:inline>
                else
                    if ($node/@type = 'foundation')
                    then
                        <fo:inline>(Foundation: {fo:tei2fo($node/text())})</fo:inline>
                    else
                        fo:tei2fo($node/node())

case element(tei:origDate)
    return
        
        if ($node/text()) then
            <fo:inline>
                {
                    if ($node/@xml:lang) then
                        fo:lang($node/@xml:lang)
                    else
                        ()
                }
                {fo:tei2fo($node/node())}</fo:inline>
        else
            if ($node/@notBefore and $node/@notAfter) then
                <fo:inline>
                    {
                        if ($node/@xml:lang) then
                            fo:lang($node/@xml:lang)
                        else
                            ()
                    }
                    {string($node/@notBefore) || '–' || string($node/@notAfter)}</fo:inline>
            else
                if ($node/@when) then
                    <fo:inline>
                        {
                            if ($node/@xml:lang) then
                                fo:lang($node/@xml:lang)
                            else
                                ()
                        }
                        {string($node/@when)}</fo:inline>
                else
                    if ($node/@notBefore and not($node/@notAfter)) then
                        <fo:inline>
                            {
                                if ($node/@xml:lang) then
                                    fo:lang($node/@xml:lang)
                                else
                                    ()
                            }
                            {string($node/@notBefore) || '–'}</fo:inline>
                    else
                        if ($node/@notAfter and not($node/@notBefore)) then
                            <fo:inline>
                                {
                                    if ($node/@xml:lang) then
                                        fo:lang($node/@xml:lang)
                                    else
                                        ()
                                }
                                {'–' || string($node/@notAfter)}</fo:inline>
                        else
                            ()



case element(tei:label)
    return
        <fo:block>{fo:tei2fo($node/text())}</fo:block>

case element(tei:l)
    return
        
        (
        <fo:inline
            vertical-align="super"
            font-size="8pt">{
                if ($node/tei:ref) then
                    <fo:basic-link
                        external-destination="{string($node/tei:ref/@target)}">{string($node/@n)}</fo:basic-link>
                else
                    string($node/@n)
            }</fo:inline>,
        fo:tei2fo($node/node())
        )

case element(tei:listBibl)
    return
        <fo:block
            margin-top="5mm">
            <fo:block
                margin-bottom="3mm"
                font-size="larger"
                font-weight="bold">{functx:capitalize-first(string($node/@type))} Bibliography</fo:block>
            {
                if ($node/tei:bibl) then
                    let $file := $node/ancestor::tei:TEI
                    for $b in $node/tei:bibl
                    let $z := fo:Zotero($b/tei:ptr/@target)
                    let $zt := substring(string-join($z), 1, 10)
                        order by $zt
                    return
                        if ($b/node()) then
                            <fo:block
                                font-family="Titus"
                                start-indent="1cm"
                                text-indent="-1cm">
                                {$z}
                                {
                                    if ($b/@corresp) then
                                        
                                        let $corr := if (contains($b/@corresp, ' '))
                                        then
                                            (for $x in tokenize($b/@corresp, ' ')
                                            return
                                                $x)
                                        else
                                            string($b/@corresp)
                                        let $corresps := for $cor in $corr
                                        return
                                            if (starts-with($cor, '#')) then
                                                substring-after($cor, '#')
                                            else
                                                $cor
                                        let $correspsEl := for $c in $corresps
                                        let $ref := $file//id($c)
                                        return
                                            (
                                            (if ($ref/text()) then
                                                fo:tei2fo($ref/text())
                                            else
                                                if ($ref/name() = 'listWit') then
                                                    for $wit in $ref/tei:witness
                                                    let $i := string($wit/@corresp)
                                                    return
                                                        fo:printTitleID($i)
                                                else
                                                    if ($ref/name() = 'witness') then
                                                        let $i := string($ref/@corresp)
                                                        return
                                                            fo:printTitleID($i)
                                                    else
                                                        concat($ref/name(), ' ', string($ref/@corresp)))
                                            ||
                                            
                                            (if ($ref/@xml:lang) then
                                                concat(' [', $file//tei:language[@ident = $ref/@xml:lang], ']')
                                            else
                                                ()))
                                        return
                                            (' (about: ' ||
                                            string-join($correspsEl, '; ')
                                            || ')'
                                            )
                                    else
                                        ()
                                }
                            </fo:block>
                        else
                            ()
                else
                    fo:tei2fo($node/node())
            }
        </fo:block>

case element(tei:bibl)
    return
        let $rootid := string(root($node)/tei:TEI/@xml:id)
        let $bibid := string($node/tei:ptr/@target)
        return
            <fo:basic-link
                internal-destination="{replace($bibid, ':', '_')}"><fo:inline
                    id="{$rootid}{generate-id($node/tei:ptr)}{replace($bibid, ':', '_')}">
                    {
                        fo:zoteroCit($node/tei:ptr/@target)
                    }
                    {
                    if ($node/tei:citedRange) then
                            ', ' || (let $citRanges := for $cR in $node/tei:citedRange
                            let $unit := switch ($cR/@unit)
                                case 'paragraph'
                                    return
                                        '§ '
                                case 'paragraphs'
                                    return
                                        '§§ '
                                case 'footnote'
                                    return
                                        'n.'
                                case 'page'
                                    return
                                        ' '
                                default return
                                    (string($cR/@unit) || ' ')
                        return
                            concat($unit, replace($cR/text(), '-', '–'))
                        return
                            string-join($citRanges, ' '))
                    else
                        ()
                }</fo:inline></fo:basic-link>

case element(tei:head)
    return
        
        <fo:block
            hyphenate="true"
            page-break-after="avoid"
            id="{string(root($node)/tei:TEI/@xml:id)}{generate-id($node)}">
            {
                if ($node/parent::tei:div[@type = 'chapter']) then
                    
                    (attribute font-weight {'700'},
                    attribute font-size {'12pt'},
                    attribute text-align {'center'},
                    attribute space-before {'25.2pt'},
                    attribute space-after {'12.24pt'})
                else
                    if ($node/parent::tei:div[@type = 'section']) then
                        (attribute font-weight {'700'},
                        attribute margin-top {'12.5pt'},
                        attribute margin-bottom {'6.25pt'})
                    else
                        if ($node/parent::tei:div[@type = 'subsection']) then
                            (attribute font-weight {'700'},
                            attribute margin-top {'12.5pt'},
                            attribute margin-bottom {'3.1pt'}
                            )
                        else
                            ()
            }
            {
                if ($node/parent::tei:div[@type = 'section'])
                then
                    let $section := $node/parent::tei:div[@type = 'section'][tei:head]
                    let $parents := for $parent in $section/ancestor::tei:div
                        order by $parent/position() descending
                    return
                        count($parent/preceding-sibling::tei:div) + 1
                    return
                        concat(
                        string-join($parents, '.'),
                        '.',
                        count($section/preceding-sibling::tei:div[@type = 'section']) + 1
                        , ' ')
                else
                    (:                    div type chapter:)
                    ()
            }
            {$node/text()}
        </fo:block>
case element(tei:div)
    return
        <fo:block
            hyphenate="true">{
                if ($node/@xml:id) then
                    attribute id {string(root($node)/tei:TEI/@xml:id) || '#' || string($node/@xml:id)}
                else
                    ()
            }{fo:tei2fo($node/node())}</fo:block>

case element(tei:ab)
    return
        if ($node/@type = 'foundation') then
            (<fo:block
                font-size="1.2em"
                space-before="2mm"
                space-after="3mm">{functx:capitalize-first(string($node/@type))}</fo:block>,
            <fo:block>{fo:tei2fo($node/node())}</fo:block>)
        
        else
            if ($node/@type = 'history') then
                <fo:block>{fo:tei2fo($node/node())}</fo:block>
            else
                <fo:block
                    linefeed-treatment="preserve">{fo:tei2fo($node/node()[not(name() = 'title')])}</fo:block>


case element(tei:lb)
    return
        ()
case element(tei:desc)
    return
        <fo:inline>
            {
                if ($node/@xml:lang) then
                    fo:lang($node/@xml:lang)
                else
                    ()
            }
            {fo:tei2fo($node/node())}
        </fo:inline>

case element(tei:locus)
    return
        
        let $valandcomma :=
        (
        let $fF := if ($node/preceding-sibling::text())
        then
            let $prevTextNode := $node/preceding-sibling::text()
            let $clean := replace(string-join($prevTextNode), '\s', '')
            return
                if (matches($clean, '[^\.]$'))
                then
                    'f'
                else
                    'F'
        else
            'F'
        let $fFornot := if (($node/preceding-sibling::element())[1]/name() = 'locus' and matches($node/preceding-sibling::node()[1], ' and ')) then
            ($fF || 'ol')
        else
            if (($node/preceding-sibling::element())[1]/name() = 'locus') then
                'x'
            else
                if ((($node/following-sibling::element())[1]/name() = 'locus') and
                not(contains($node/following-sibling::node()[1], ' and'))) then
                    ($fF || 'ols')
                else
                    ($fF || 'ol')
        
        let $value :=
        (if ($node/@from and $node/@to)
        then
            
            (
            if ($fFornot = 'x') then
                ()
            else
                ($fFornot ||
                (if (ends-with($fFornot, 's')) then
                    ' '
                else
                    's ')
                ))
            || string($node/@from) || '–' || string($node/@to)
        else
            if ($node/@from) then
                ((if ($fFornot = 'x') then
                    ()
                else
                    ($fFornot || (if (ends-with($fFornot, 's')) then
                        ' '
                    else
                        's ')))
                || string($node/@from || ' and following'))
            else
                if ($node/@target)
                then
                    let $targets :=
                    if (contains($node/@target, ' '))
                    then
                        let $ts := for $t in tokenize($node/@target, ' ')
                        return
                            substring-after($t, '#')
                        return
                            (if ($fFornot = 'x') then
                                ()
                            else
                                ($fFornot || (if (ends-with($fFornot, 's')) then
                                    ' '
                                else
                                    's ')))
                            || string-join($ts, ', ')
                    else
                        ((if ($fFornot = 'x') then
                            ()
                        else
                            ($fFornot || (if (ends-with($fFornot, 'l')) then
                                '. '
                            else
                                ' ')))
                        || substring-after(string($node/@target), '#'))
                    let $cutlistoftargets := if (count($targets) ge 3) then
                        (subsequence($targets, 1, 3), 'etc.')
                    else
                        $targets
                    return
                        string-join($cutlistoftargets, ', ')
                else
                    $node/node()
        )
        return
            $value
        ,
        if ((($node/following-sibling::element())[not(@xml:lang = 'ar')][1]/name() = 'locus') and
        not(contains($node/following-sibling::node()[1], ' and'))) then
            ', '
        else
            ()
        )
        
        return
            replace(string-join($valandcomma), ' , ', ', ')

case element(tei:notatedMusic)
    return
        <fo:block>
            <fo:inline
                font-weight="bold"
                font-family="Ludolfus">{functx:capitalize-first(string($node/name()))}: </fo:inline>
            {fo:tei2fo($node/node())}
        </fo:block>

case element(tei:msItem)
    return
        (<fo:block
            hyphenate="true"
            font-family="Ludolfus"
            space-after="3mm">
            {
                attribute id {string(root($node/tei:title[@ref])/tei:TEI/@xml:id) || generate-id($node/tei:title[@ref]) || string($node/tei:title/@ref)
                }
            }
            <fo:inline>
                {
                    let $number := if ($node/parent::tei:msItem)
                    then
                        (let $parents := for $msItem in $node/ancestor::tei:msItem
                        return
                            if ($msItem/parent::tei:msItem) then
                                count($msItem/preceding-sibling::tei:msItem) + 1
                            else
                                local:n2roman(count($msItem/preceding-sibling::tei:msItem) + 1)
                        return
                            string-join($parents, '-') || '-' ||
                            (count($node/preceding-sibling::tei:msItem) + 1)
                        )
                    else
                        (:                    first order msItem:)
                        local:n2roman((count($node/preceding-sibling::tei:msItem) + 1))
                    return
                        $number || ') '
                }
                
                {
                    if ($node/tei:locus) then
                        replace(concat(string-join(fo:tei2fo($node/tei:locus)), ': '), '(\S)(Fol.)', '$1, ')
                    else
                        ()
                }{
                    <fo:inline
                        xml:lang="en"
                        hyphenate="true">{fo:ContentsTitle($node/tei:title)}</fo:inline>
                }</fo:inline>
            {
                if ($node/tei:note) then
                    <fo:block
                        start-indent="10mm">
                        {
                            for $i in $node/tei:note
                            return
                                fo:tei2fo($i/node())
                        }</fo:block>
                else
                    ()
            }
            {
                if ($node/tei:incipit) then
                    <fo:block
                        start-indent="10mm">
                        {
                            'Incipit: ',
                            for $i in $node/tei:incipit
                            return
                                fo:tei2fo($i)
                        }</fo:block>
                else
                    ()
            }
            {
                if ($node/tei:explicit) then
                    <fo:block
                        start-indent="10mm">
                        {
                            'Explicit: ',
                            for $i in $node/tei:explicit
                            return
                                fo:tei2fo($i)
                        }</fo:block>
                else
                    ()
            }
        </fo:block>,
        for $m in $node/tei:msItem
            order by count($m/preceding-sibling::tei:msItem)
        return
            fo:tei2fo($m)
        )

case element(tei:incipit)
    return
        <fo:inline>
            {
                if ($node/@xml:lang) then
                    fo:lang($node/@xml:lang)
                else
                    ()
            }
            {fo:tei2fo($node/node()[not(name() = 'locus')])}
        </fo:inline>

case element(tei:table)
    return
        
        <fo:table
            margin-bottom="5mm"
            margin-top="5mm">
            {
                if ($node/tei:row[@role = 'label']//tei:cell/@rend) then
                    ()
                else
                    (
                    attribute inline-progression-dimension {"auto"},
                    attribute table-layout {"auto"}
                    )
            }
            {
                if ($node/@rend) then
                    (attribute font-size {$node/@rend}, attribute line-height {'11pt'})
                else
                    ''
            }
            {
                for $column at $p in $node/tei:row[@role = 'label']//tei:cell
                return
                    <fo:table-column
                        column-number="{$p}">
                        {
                            if ($column/@rend) then
                                attribute column-width {string($column/@rend)}
                            else
                                ()
                        }</fo:table-column>
            }
            
            <fo:table-header>
                <fo:table-row>
                    {
                        for $column at $p in $node/tei:row[@role = 'label']//tei:cell
                        return
                            <fo:table-cell>
                                <fo:block
                                    hyphenate="false"
                                    font-weight="bold"
                                    margin-right="10pt">{$column/text()}</fo:block>
                            </fo:table-cell>
                    }
                </fo:table-row>
            </fo:table-header>
            
            <fo:table-body>
                {fo:tei2fo($node/tei:row[not(@role)])}
            </fo:table-body>
        </fo:table>

case element(tei:row)
    return
        <fo:table-row
            margin-bottom="3mm">{fo:tei2fo($node/tei:cell)}</fo:table-row>

case element(tei:cell)
    return
        <fo:table-cell
            margin-right="2mm"><fo:block>{fo:tei2fo($node/node())}</fo:block></fo:table-cell>


case element(tei:explicit)
    return
        <fo:block
            start-indent="10mm">
            {
                if ($node/@xml:lang) then
                    fo:lang($node/@xml:lang)
                else
                    ()
            }
            {fo:tei2fo($node/node()[not(name() = 'locus')])}
        </fo:block>
case element(tei:colophon)
    return
        (<fo:block>
            {
                if ($node/@xml:lang) then
                    fo:lang($node/@xml:lang)
                else
                    ()
            }{
                if ($node/tei:locus) then
                    (fo:tei2fo($node/tei:locus) || ': ')
                else
                    ()
            }
            {
                <fo:inline>{
                        if ($node/tei:note/@xml:lang) then
                            fo:lang($node/tei:note/@xml:lang)
                        else
                            ()
                    }{fo:tei2fo($node/tei:note/node())}</fo:inline>
            }
            {fo:tei2fo($node/node()[not(name() = 'locus')][not(name() = 'foreign')][not(name() = 'note')])}
        </fo:block>,
        for $text in $node/tei:foreign
        return
            <fo:block>
                {
                    if ($text/@xml:lang) then
                        fo:lang($text/@xml:lang)
                    else
                        ()
                }
                {fo:tei2fo($text/node())}
            </fo:block>)
case element(tei:title)
    return
        if ($node/ancestor::tei:titleStmt) then
            fo:tei2fo($node/node())
        else
            fo:entitiesWithRef($node)
case element(tei:origPlace)
    return
        if ($node/ancestor::tei:titleStmt) then
            fo:tei2fo($node/node())
        else
            fo:entitiesWithRef($node)
case element(tei:placeName)
    return
        if ($node/ancestor::tei:titleStmt) then
            fo:tei2fo($node/node())
        else
            fo:entitiesWithRef($node)
case element(tei:cit)
    return
        (:     Francesca said: if the quotation is longer than 50 words, then it should be in the text (inline), if not should be in display (block with indentation) :)
        (let $wordcount := count(tokenize(string-join($node/tei:quote[1]//text(), ' '), '\s+'))
        return
            if ($node/parent::tei:epigraph) then
                <fo:block
                    hyphenate="false"
                    start-indent="1cm"
                    margin-top="6.25pt"
                    margin-bottom="6.25pt">
                    {
                        if ($node/@xml:lang) then
                            fo:lang($node/@xml:lang)
                        else
                            ()
                    }
                    {
                        for $q at $p in $node//tei:quote
                        return
                            <fo:block
                                hyphenate="false"
                                page-break-after="avoid">
                                {
                                    if ($q/@xml:lang) then
                                        ($q/@xml:lang,
                                        fo:lang($q/@xml:lang))
                                    else
                                        ()
                                }
                                {
                                    if ($p = 2) then
                                        '('
                                    else
                                        ()
                                }
                                {fo:tei2fo($q/node())}
                                {
                                    if ($p = 2) then
                                        ')'
                                    else
                                        ()
                                }
                            
                            </fo:block>
                    }
                    <fo:block
                        hyphenate="true"
                        text-align="right">
                        {fo:tei2fo($node/node()[not(name() = 'quote')])}
                    </fo:block>
                </fo:block>
            
            else
                if ($wordcount ge 50 and not($node/parent::tei:epigraph)) then
                    <fo:block
                        hyphenate="true"
                        text-indent="0"
                        start-indent="1cm"
                        margin-top="6.25pt"
                        margin-bottom="6.25pt">
                        {
                            if ($node/@xml:lang) then
                                fo:lang($node/@xml:lang)
                            else
                                ()
                        }
                        {fo:tei2fo($node/node())}{
                            if ($node/@type = 'nodot') then
                                ''
                            else
                                '.'
                        }
                    </fo:block>
                else
                    <fo:inline>
                        {
                            if ($node/@xml:lang) then
                                fo:lang($node/@xml:lang)
                            else
                                ()
                        }‘{fo:tei2fo($node/tei:quote)}’{
                            if ($node/node()[name() != 'quote']) then
                                ' '
                            else
                                ''
                        }{fo:tei2fo($node/node()[name() != 'quote'])}
                    </fo:inline>
        )

case element(tei:quote)
    return
        
        (let $wordcount := count(tokenize(string-join($node//text(), ' '), '\s+'))
        
        return
            if ($wordcount ge 50) then
                <fo:inline
                    page-break-after="avoid">
                    {
                        if ($node/@xml:lang) then
                            ($node/@xml:lang,
                            fo:lang($node/@xml:lang))
                        else
                            ()
                    }
                    {fo:tei2fo($node/node())}
                </fo:inline>
            else
                <fo:inline>
                    {
                        if ($node/@xml:lang) then
                            ($node/@xml:lang,
                            fo:lang($node/@xml:lang))
                        else
                            ()
                    }
                    {fo:tei2fo($node/node())}
                </fo:inline>)

case element(tei:ref)
    return
        let $refid := string(root($node)/tei:TEI/@xml:id) || generate-id($node) || 'ref'
        return
            if ($node[@cRef][@corresp][@rend])
            then
                fo:dtsref($node, $refid)
            else
                if ($node[text()]) then
                    fo:tei2fo($node/node())
                else
                    if ($node[not(@type)]/@cRef) then
                        if ($node/parent::tei:cit) then
                            let $wordcount := count(tokenize(string-join($node/parent::tei:cit/tei:quote[1]//text(), ' '), '\s+'))
                            return
                                if ($wordcount lt 50) then
                                    <fo:inline
                                        id="{$refid}">({$node/text()})</fo:inline>
                                else
                                    <fo:block
                                        page-break-after="avoid"
                                        id="{$refid}"
                                        text-align="right"
                                        hyphenate="true">{$node/text()}</fo:block>
                        else
                            <fo:inline
                                id="{$refid}">{$node/text()}</fo:inline>
                    else
                        if ($node/@type) then
                            <fo:inline>{
                                    switch ($node/@type)
                                        case 'internal'
                                            return
                                                (
                                                let $pointer := substring-after($node/@target, '#')
                                                let $nodePointer := fo:getFile($pointer)
                                                let $pointerid := string(root($nodePointer)/tei:TEI/@xml:id) || string($node/@target)
                                                return
                                                    ('p. ',
                                                    <fo:basic-link
                                                        internal-destination="{$pointerid}"><fo:page-number-citation
                                                            ref-id="{$pointerid}"/></fo:basic-link>)
                                                )
                                        case 'ins'
                                            return
                                                <fo:basic-link
                                                    external-destination="https://betamasaheft.eu/{$node/@cRef}"><fo:inline
                                                        id="{string(root($node)/tei:TEI/@xml:id)}{generate-id($node)}ins">{$node/text()}</fo:inline></fo:basic-link>
                                        case 'BM'
                                            return
                                                <fo:basic-link
                                                    external-destination="https://betamasaheft.eu/{$node/@target}">CAe {substring($node/text(), 4, 4)}, ID: {$node/text()}</fo:basic-link>
                                        case 'manuscript'
                                            return
                                                let $chid := substring-after($node/@target, '#')
                                                let $chapter := collection('/db/apps/BetMasData/manuscripts')//id($chid)
                                                return
                                                    (<fo:basic-link
                                                        internal-destination="{$chid}">
                                                        <fo:inline>{'Ms. ' || $chapter//tei:msIdentifier/tei:idno[not(@xml:lang)]/text()}</fo:inline>,
                                                        p.</fo:basic-link>,
                                                    <fo:page-number-citation
                                                        ref-id="{$chid}"/>)
                                        case 'figure'
                                            return
                                                (let $corresp := substring-after($node/@target, '#')
                                                let $figure := root($node)//tei:*[@xml:id = $corresp]
                                                return
                                                    ('Fig. ' || (count($figure/preceding::tei:graphic) + 1)))
                                        case 'work'
                                            return
                                                <fo:basic-link
                                                    external-destination="https://betamasaheft.eu/{$node/@corresp}">{fo:titleSelector($node/@corresp)}</fo:basic-link>
                                        default return
                                            string($node/@target)
                            }
                        </fo:inline>
                    else
                        if ($node/name() = 'persName' or $node/name() = 'placeName') then
                            (if ($node/parent::tei:titleStmt) then
                                fo:tei2fo($node/node())
                            else
                                fo:entitiesWithRef($node))
                        else
                            if ($node[starts-with(@target, '#h')]) then
                                'hand ' || substring-after($node/@target, '#h')
                            else
                                if ($node[starts-with(@target, '#')]) then
                                    let $root := $node/ancestor::tei:TEI
                                    let $target := substring-after($node/@target, '#')
                                    return
                                        replace($target, '\s\([a-zA-Z0-9\-_\.\s]+\)', '')
                                else
                                    (:     if the url is too long, add here and there              &#x200b;   and it will break there if needed  :)
                                    <fo:basic-link
                                        external-destination="{string($node/@target)}"
                                        hyphenate="false">&lt;{
                                            if ($node/text()) then
                                                $node/text()
                                            else
                                                string($node/@target)
                                        }&gt;</fo:basic-link>



case element(tei:persName)
    return
        if ($node/parent::tei:titleStmt) then
            fo:tei2fo($node/node())
        else
            fo:entitiesWithRef($node)

case element(tei:measure)
    return
        <fo:inline>
            
            {' ' || $node/text()}
            {
                if ($node/@type) then
                    (' ' || string($node/@type))
                else
                    ()
            }
            {
                if ($node/@unit) then
                    (' ' || string($node/@unit))
                else
                    ()
            }
        
        </fo:inline>

case element(tei:foreign)
    return
        <fo:inline>
            {
                if ($node/@xml:lang = 'gez' and not(matches($node, '\p{IsEthiopic}'))) then
                    ()
                else
                    if ($node/@xml:lang = 'ar' and not(matches($node, '\p{IsArabic}'))) then
                        ()
                    else
                        if ($node/@xml:lang) then
                            fo:lang($node/@xml:lang)
                        else
                            ()
            }
            {fo:tei2fo($node/node())}
        </fo:inline>

case element(tei:roleName)
    return
        fo:tei2fo($node/node())
case element(tei:milestone)
    return
        <fo:block
            hyphenate="true"
            page-break-after="always"/>

case element(tei:sourceDesc)
    return
        ()
case element()
    return
        fo:tei2fo($node/node())
case text()
    return
        if (matches($node, '\p{IsEthiopic}'))
        then
            replace($node, '᎓', '፡')
            => replace(' ፡', '፡ ')
            => replace('(\S{2})', '​$1')
            => replace('(​(፡))', '$2')
            => replace('(​$)', '')
        else
            $node
default
    return
        $node
};

declare function fo:dtsref($node, $refid) {
    let $label := $node/@cRef
    let $passage := $node/@corresp
    let $abbreviation := $local:catalogue//tei:list[@xml:id = 'abbreviations']
    let $refabbr := $abbreviation/tei:item[tei:label = $label]
    let $endpoint := $refabbr/@corresp
    let $ident := substring-before($endpoint, ':')
    let $prefix := $local:listPrefixDef//tei:prefixDef[@ident = $ident]
    let $endpointurl := replace(substring-after($endpoint, ':'), $prefix/@matchPattern, $prefix/@replacementPattern)
    let $collections := try {
        json-doc($endpointurl)
    } catch * {
        map {'error': $err:description}
    }
    let $navigation := if (string-length($collections?('dts:references')) gt 0) then
        $collections?('dts:references')
    else
        'no navigation api available'
    let $passages := if (string-length($collections?('dts:passage')) gt 0) then
        $collections?('dts:passage')
    else
        'no passage api available'
    
    
    return
        (:            try and handle that using DTS:)
        (
        
        (if ($node/@rend = 'quote') then
            (<fo:block
                id="{$refid}"
                page-break-after="avoid"
                text-align="right"
                hyphenate="true">{
                    let $dtsdoc := if (starts-with($passages, 'no')) then
                        $passages
                    else
                        let $passagescall := if (starts-with($passages, '/')) then
                            replace($endpointurl, 'collections', 'document')
                        else
                            $passages
                        let $dtsfragment := try {
                            doc(concat($passagescall, '&amp;ref=', $passage))
                        } catch * {
                            <p>not found {$err:description}</p>
                        }
                        return
                            try {
                                $dtsfragment//text()
                            } catch * {
                                <p>{$err:description}</p>
                            }
                    return
                        $dtsdoc
                }<fo:block>({fo:tei2fo($node/node())})</fo:block>
            </fo:block>
            )
        else
            (:            rend as citation:)
            (if (starts-with($navigation, 'no')) then
                ()
            else
                let $navigationcall := if (starts-with($navigation, '/')) then
                    replace($endpointurl, 'collections', 'navigation')
                else
                    $navigation
                let $dtsnavigationcall := json-doc($navigationcall)
                let $member := ($dtsnavigationcall?member?*,
                $dtsnavigationcall?('hydra:member')?*)
                let $ref := ($member[?('dts:ref') = $passage], $member[?ref = $passage])
                return
                    (<fo:block>{'ref text: ', fo:tei2fo($node/node())}</fo:block>,
                    <fo:inline>{($ref?('dts:citeType'), $dtsnavigationcall?citeType) || ' ' || ($ref?('dts:ref'), $ref?ref)}
                    </fo:inline>,
                    if (count($ref?('dts:dublincore')?('dc:source')) gt 0) then
                        for $canvas in $ref?('dts:dublincore')?('dc:source')?*
                        let $iiif := json-doc($canvas?('@id'))
                        return
                            
                            <fo:external-graphic
                                src="{$iiif?images?*?resource?('@id')}"
                                content-width="scale-down-to-fit"
                                width="90%"
                                scaling="uniform"
                                display-align="center"
                            />
                    else
                        ()
                    
                    ))
        ))

};

declare function fo:titlepage() {
    <fo:page-sequence
        master-reference="Aethiopica-master">
        
        <fo:flow
            flow-name="xsl-region-body"
            font-family="Ludolfus">
            <fo:block-container
                font-size="12pt"
                space-before="25.2pt"
                space-after="12.24pt"
                font-family="Ludolfus"
                font-weight="700"
                text-align="center"
                display-align="center"><fo:block>{$local:title}</fo:block></fo:block-container>
            <fo:block
                font-size="12pt"
                space-before="25.2pt"
                space-after="12.24pt"
                font-family="Ludolfus"
                font-weight="700"
                text-align="center"
                display-align="center">{string-join($local:catalogue//tei:titleStmt/tei:author, ', ')}</fo:block>
            
            <fo:block
                text-align="center"
                font-size="20pt"
                font-style="italic"
                space-before="2em"
                space-after="2em">
            
            </fo:block>
        
        </fo:flow>
    </fo:page-sequence>
};


(:~ produces the list of figures:)
declare function fo:list-of-images() {
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-master"
        format="i">
        <fo:static-content
            flow-name="rest-region-before-odd">
            <fo:table>
                <fo:table-column
                    column-width="30%"/>
                <fo:table-column
                    column-width="40%"/>
                <fo:table-column
                    column-width="30%"/>
                
                <fo:table-body>
                    <fo:table-row>
                        <fo:table-cell>
                            <fo:block
                                text-align="right"></fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block
                                text-align="center"
                                font-size="9pt"
                                font-family="Ludolfus">List of Figures</fo:block>
                        </fo:table-cell>
                        <fo:table-cell><fo:block
                                font-size="9pt"
                                font-family="Ludolfus"
                                text-align="right">
                                <fo:page-number/>
                            </fo:block>
                        </fo:table-cell>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
        </fo:static-content>
        <fo:static-content
            flow-name="rest-region-before-even">
            <fo:table>
                <fo:table-column
                    column-width="30%"/>
                <fo:table-column
                    column-width="40%"/>
                <fo:table-column
                    column-width="30%"/>
                
                <fo:table-body>
                    <fo:table-row>
                        <fo:table-cell>
                            <fo:block
                                font-size="9pt"
                                font-family="Ludolfus"
                                text-align="left"><fo:page-number/></fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block
                                text-align="center"
                                font-size="9pt"
                                font-family="Ludolfus">List of Figures</fo:block>
                        </fo:table-cell>
                        <fo:table-cell><fo:block
                                font-size="9pt"
                                font-family="Ludolfus"
                                text-align="right">
                            
                            </fo:block>
                        </fo:table-cell>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
        </fo:static-content>
        <fo:static-content
            flow-name="rest-region-before-first">
            <fo:table>
                <fo:table-column
                    column-width="30%"/>
                <fo:table-column
                    column-width="40%"/>
                <fo:table-column
                    column-width="30%"/>
                
                <fo:table-body>
                    <fo:table-row>
                        <fo:table-cell>
                            <fo:block
                                text-align="right"></fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block
                                text-align="center"
                                font-size="9pt"
                                font-family="Ludolfus"></fo:block>
                        </fo:table-cell>
                        <fo:table-cell><fo:block
                                font-size="9pt"
                                font-family="Ludolfus"
                                text-align="right"></fo:block>
                        </fo:table-cell>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
        </fo:static-content>
        
        <fo:static-content
            flow-name="xsl-footnote-separator">
            <fo:block
                space-before="5mm"
                space-after="5mm">
                <fo:leader
                    leader-length="30%"
                    rule-thickness="0pt"/>
            </fo:block>
        </fo:static-content>
        
        <fo:flow
            flow-name="xsl-region-body"
            font-family="Ludolfus">
            <fo:block
                id="listfigures"
                font-size="12pt"
                space-before="25.2pt"
                space-after="12.24pt"
                font-family="Ludolfus"
                font-weight="700"
                text-align="center"
                display-align="center">List of Figures</fo:block>
            {
                for $F at $p in $local:catalogue//tei:figure
                let $count := count($F/tei:graphic/preceding::tei:graphic) + 1
                    order by $count
                return
                    <fo:block
                        text-align-last="justify"
                        start-indent="1cm"
                        text-indent="-1cm"
                        space-after="1pt"
                        font-size="10.5pt"
                        font-family="Ludolfus">
                        <fo:inline
                            font-weight="bold">
                            {'Fig. ' || $count || ' '}</fo:inline>
                        <fo:inline>{fo:figDesc2fo($F/tei:graphic/tei:desc/node())}
                        </fo:inline>
                        <fo:leader
                            leader-pattern="dots"/>
                        <fo:basic-link
                            internal-destination="{string(root($F)/tei:TEI/@xml:id)}{$F/tei:graphic/@xml:id}{generate-id($F)}">
                            <fo:page-number-citation
                                ref-id="{string(root($F)/tei:TEI/@xml:id)}{$F/tei:graphic/@xml:id}{generate-id($F)}"/>
                        </fo:basic-link>
                    </fo:block>
            }
        </fo:flow>
    </fo:page-sequence>
};

declare function fo:table-of-contents() {
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-master"
        format="i">
        {fo:static('', 'Table of Contents')}
        <fo:flow
            flow-name="xsl-region-body"
            font-family="Ludolfus">
            <fo:block-container
                font-size="12pt"
                space-before="25.2pt"
                space-after="12.24pt"
                font-family="Ludolfus"
                font-weight="700"
                text-align="center"
                display-align="center"><fo:block>{$local:title}</fo:block></fo:block-container>
            <fo:block
                font-size="12pt"
                space-before="25.2pt"
                space-after="12.24pt"
                font-family="Ludolfus"
                font-weight="700"
                text-align="center"
                display-align="center">Table of Contents</fo:block>
            
            {
        for $settingsValue in $local:settings/s:orderOfParts/element()
                return
                    if ($settingsValue = 'yes') then
                        switch ($settingsValue/name())
                            case 'aknowledgments'
                                return
                                    <fo:block
                                        text-align-last="justify"
                                        space-after="1pt"
                                        font-size="10.5pt"
                                        font-family="Ludolfus"
                                        margin-bottom="0.5cm">
                                        <fo:inline>Acknowledgements</fo:inline>
                                        <fo:leader
                                            leader-pattern="dots"/>
                                        <fo:basic-link
                                            internal-destination="Acknowledgement">
                                            <fo:page-number-citation
                                                ref-id="Acknowledgement"/>
                                        </fo:basic-link>
                                    
                                    </fo:block>
                            case 'listofimages'
                                return
                                    <fo:block
                                        text-align-last="justify"
                                        space-after="1pt"
                                        font-size="10.5pt"
                                        font-family="Ludolfus"
                                        margin-bottom="0.5cm">
                                        <fo:inline>List of Figures</fo:inline>
                                        <fo:leader
                                            leader-pattern="dots"/>
                                        <fo:basic-link
                                            internal-destination="listfigures">
                                            <fo:page-number-citation
                                                ref-id="listfigures"/>
                                        </fo:basic-link>
                                    
                                    </fo:block>
                            case 'introduction'
                                return
                                    <fo:block
                                        text-align-last="justify"
                                        space-after="1pt"
                                        font-size="10.5pt"
                                        font-family="Ludolfus"
                                        margin-bottom="0.5cm">
                                        <fo:inline>Introduction</fo:inline>
                                        <fo:leader
                                            leader-pattern="dots"/>
                                        <fo:basic-link
                                            internal-destination="introduction">
                                            <fo:page-number-citation
                                                ref-id="introduction"/>
                                        </fo:basic-link>
                                    
                                    </fo:block>
                            case 'bibliography'
                                return
                                    <fo:block
                                        text-align-last="justify"
                                        space-after="1pt"
                                        font-size="10.5pt"
                                        font-family="Ludolfus"
                                        margin-bottom="0.5cm">
                                        <fo:inline>Bibliography</fo:inline>
                                        <fo:leader
                                            leader-pattern="dots"/>
                                        <fo:basic-link
                                            internal-destination="bibliography">
                                            <fo:page-number-citation
                                                ref-id="introduction"/>
                                        </fo:basic-link>
                                    </fo:block>
                            case 'catalogue'
                                return
                                    (<fo:block
                                        text-align-last="justify"
                                        space-after="1pt"
                                        font-size="10.5pt"
                                        font-family="Ludolfus"
                                        margin-bottom="0.5cm">
                                        <fo:inline>Catalogue</fo:inline>
                                        <fo:leader
                                            leader-pattern="dots"/>
                                    
                                    </fo:block>
                                    ,
                                    for $r in $local:entries
                                    let $msID := string($r/@xml:id)
                                    let $signature := $r//tei:msDesc/tei:msIdentifier/tei:idno[not(@xml:lang)]
                                    let $msmainid := number(substring-after(normalize-space($signature/text()), $local:prefix))
                                    let $pointer := if ($r/@xml:id) then
                                        string($r/@xml:id)
                                    else
                                        $r//tei:idno[@type = 'filename']/text()
                                        order by $msmainid
                                    return
                                        <fo:block
                                            text-align-last="justify"
                                            space-after="1pt"
                                            font-size="10.5pt"
                                            margin-left="1cm"
                                            font-family="Ludolfus">
                                            <fo:inline
                                                font-weight="800">{$signature/text()}</fo:inline>
                                            <fo:leader
                                                leader-pattern="dots"/>
                                            <fo:basic-link
                                                internal-destination="{$pointer}">
                                                <fo:page-number-citation
                                                    ref-id="{$pointer}"/>
                                            </fo:basic-link>
                                        
                                        </fo:block>
                                    )
                            case 'indexes'
                                return
                                    (
                                    <fo:block
                                        margin-top="0.5cm"/>,
                                    for $index in $local:settings/s:indexes/element()
                                    return
                                        if ($index = 'yes') then
                                            switch ($index/name())
                                                case 'persons'
                                                    return
                                                        <fo:block
                                                            text-align-last="justify"
                                                            space-after="1pt"
                                                            font-size="10.5pt"
                                                            font-family="Ludolfus">
                                                            <fo:inline>Index of Persons</fo:inline>
                                                            <fo:leader
                                                                leader-pattern="dots"/>
                                                            <fo:basic-link
                                                                internal-destination="IndexPersons">
                                                                <fo:page-number-citation
                                                                    ref-id="IndexPersons"/>
                                                            </fo:basic-link>
                                                        </fo:block>
                                                case 'places'
                                                    return
                                                        <fo:block
                                                            text-align-last="justify"
                                                            space-after="1pt"
                                                            font-size="10.5pt"
                                                            font-family="Ludolfus"
                                                        >
                                                            <fo:inline>Index of Places</fo:inline>
                                                            <fo:leader
                                                                leader-pattern="dots"/>
                                                            <fo:basic-link
                                                                internal-destination="IndexPlaces"><fo:page-number-citation
                                                                    ref-id="IndexPlaces"/>
                                                            </fo:basic-link>
                                                        </fo:block>
                                                case 'works'
                                                    return
                                                        <fo:block
                                                            text-align-last="justify"
                                                            space-after="1pt"
                                                            font-size="10.5pt"
                                                            font-family="Ludolfus"
                                                        >
                                                            <fo:inline>Index of Texts</fo:inline>
                                                            <fo:leader
                                                                leader-pattern="dots"/>
                                                            <fo:basic-link
                                                                internal-destination="IndexWorks"><fo:page-number-citation
                                                                    ref-id="IndexWorks"/>
                                                            </fo:basic-link>
                                                        </fo:block>
                                                case 'subjects'
                                                    return
                                                        <fo:block
                                                            text-align-last="justify"
                                                            space-after="1pt"
                                                            font-size="10.5pt"
                                                            font-family="Ludolfus"
                                                        >
                                                            <fo:inline>Index of Subjects</fo:inline>
                                                            <fo:leader
                                                                leader-pattern="dots"/>
                                                            <fo:basic-link
                                                                internal-destination="IndexSubjects"><fo:page-number-citation
                                                                    ref-id="IndexSubjects"/>
                                                            </fo:basic-link>
                                                        </fo:block>
                                                case 'languages'
                                                    return
                                                        <fo:block
                                                            text-align-last="justify"
                                                            space-after="1pt"
                                                            font-size="10.5pt"
                                                            font-family="Ludolfus"
                                                        >
                                                            <fo:inline>Index of Languages</fo:inline>
                                                            <fo:leader
                                                                leader-pattern="dots"/>
                                                            <fo:basic-link
                                                                internal-destination="IndexLanguages"><fo:page-number-citation
                                                                    ref-id="IndexSubjects"/>
                                                            </fo:basic-link>
                                                        </fo:block>
                                                case 'keywords'
                                                    return
                                                        <fo:block
                                                            text-align-last="justify"
                                                            space-after="1pt"
                                                            font-size="10.5pt"
                                                            font-family="Ludolfus"
                                                        >
                                                            <fo:inline>Index of Keywords</fo:inline>
                                                            <fo:leader
                                                                leader-pattern="dots"/>
                                                            <fo:basic-link
                                                                internal-destination="IndexKeywords"><fo:page-number-citation
                                                                    ref-id="IndexKeywords"/>
                                                            </fo:basic-link>
                                                        </fo:block>
                                                default return
                                                    ()
                                    else
                                        ()
                                )
                        case 'images'
                            return
                                (<fo:block
                                    margin-top="0.5cm"/>,
                                <fo:block
                                    text-align-last="justify"
                                    space-after="1pt"
                                    font-size="10.5pt"
                                    font-family="Ludolfus"
                                >
                                    <fo:inline>Plates</fo:inline>
                                    <fo:leader
                                        leader-pattern="dots"/>
                                    <fo:basic-link
                                        internal-destination="Appendix"><fo:page-number-citation
                                            ref-id="Appendix"/>
                                    </fo:basic-link>
                                </fo:block>)
                        default return
                            ()
            else
                ()
    }
</fo:flow>
</fo:page-sequence>
};



declare function fo:additions($additions as element(tei:additions)) {
    if ($additions/node()) then
        let $additionsExceptions := tokenize($local:settings/s:additionsExceptions, ',')
        return
            <fo:block>
                {
                    if ($additions//tei:item[starts-with(@xml:id, 'a')][not(tei:desc/@type = $additionsExceptions)]) then
                        (<fo:block
                            font-style="italic"
                            space-after="3mm"
                            space-before="2mm"
                            page-break-inside="avoid"
                            page-break-after="avoid">Additional notes</fo:block>,
                        <fo:list-block
                            provisional-label-separation="1em"
                            provisional-distance-between-starts="2em">
                            {
                                for $addition in $additions//tei:item[starts-with(@xml:id, 'a')]
                                return
                                    <fo:list-item>
                                        <fo:list-item-label
                                            end-indent="label-end()">
                                            <fo:block>{count($addition/preceding-sibling::tei:item[starts-with(@xml:id, 'a')]) + 1})</fo:block>
                                        </fo:list-item-label>
                                        <fo:list-item-body
                                            start-indent="body-start()">
                                            <fo:block>
                                                {
                                                    if ($addition/tei:locus) then
                                                        concat(fo:tei2fo($addition/tei:locus), ': ')
                                                    else
                                                        ()
                                                }{
                                                    if ($addition/tei:desc/tei:title) then
                                                        fo:ContentsTitle($addition//tei:desc/tei:title)
                                                    else
                                                        ()
                                                }{fo:tei2fo($addition/tei:desc/node()[not(name() = 'title')])}</fo:block>
                                            {
                                                if ($addition/tei:q/node()) then
                                                    <fo:block>{
                                                            for $q in $addition/tei:q[not(@xml:lang = 'en')]
                                                            return
                                                                (fo:tei2fo($q), ' ')
                                                        }</fo:block>
                                                else
                                                    ()
                                            }
                                        </fo:list-item-body>
                                    </fo:list-item>
                            }</fo:list-block>)
                    else
                        ()
                }
                
                
                {
                    if ($additions//tei:item[starts-with(@xml:id, 'e')][not(tei:desc/@type = $additionsExceptions)]) then
                        (<fo:block
                            font-style="italic"
                            space-after="3mm"
                            space-before="2mm"
                            page-break-inside="avoid"
                            page-break-after="avoid">Varia</fo:block>,
                        <fo:list-block
                            provisional-label-separation="1em"
                            provisional-distance-between-starts="2em">
                            {
                                for $addition in $additions//tei:item[starts-with(@xml:id, 'e')]
                                return
                                    <fo:list-item>
                                        <fo:list-item-label
                                            end-indent="label-end()">
                                            <fo:block>{count($addition/preceding-sibling::tei:item[starts-with(@xml:id, 'e')]) + 1})</fo:block>
                                        </fo:list-item-label>
                                        <fo:list-item-body
                                            start-indent="body-start()">
                                            <fo:block>
                                                {
                                                    if ($addition/tei:locus) then
                                                        concat(fo:tei2fo($addition/tei:locus), ': ')
                                                    else
                                                        ()
                                                }{
                                                    if ($addition/tei:desc/tei:title) then
                                                        fo:ContentsTitle($addition//tei:desc/tei:title)
                                                    else
                                                        ()
                                                }{fo:tei2fo($addition/tei:desc/node()[not(name() = 'title')])}</fo:block>
                                            {
                                                if ($addition/tei:q/node()) then
                                                    <fo:block>{
                                                            for $q in $addition/tei:q[not(@xml:lang = 'en')]
                                                            return
                                                                (fo:tei2fo($q), ' ')
                                                        }</fo:block>
                                                else
                                                    ()
                                            }
                                        </fo:list-item-body>
                                    </fo:list-item>
                            }</fo:list-block>)
                    else
                        ()
                }
            </fo:block>
    else
        ()
};

declare function fo:deco($decos as element(tei:decoDesc), $lang) {
    if ($lang = 'ar') then
        <fo:block
            space-after="3mm"
            space-before="2mm">{fo:lang('ar')}زخرفة:</fo:block>
    else
        <fo:block
            font-style="italic"
            space-after="3mm"
            space-before="2mm"
            page-break-inside="avoid"
            page-break-after="avoid">Decoration</fo:block>,
    (
    if ($lang = 'ar') then
        ()
    else
        (if ($decos//tei:summary) then
            <fo:block
                margin-top="3mm"
                margin-bottom="3mm">{fo:tei2fo($decos/tei:summary)}</fo:block>
        else
            ()),
    <fo:list-block
        provisional-label-separation="1em"
        provisional-distance-between-starts="2em">
        {
            if ($lang = 'ar') then
                fo:lang('ar')
            else
                ()
        }
        {
            
            let $decoSele := if ($lang = 'ar') then
                $decos/tei:decoNote[descendant::tei:*[@xml:lang = 'ar']]
            else
                $decos/tei:decoNote[not(@xml:lang = 'ar')]
            for $deco in $decoSele
            let $p := count($deco/preceding::tei:decoNote) + 1
            return
                <fo:list-item
                    space-after="2mm">
                    <fo:list-item-label>
                        {
                            if ($lang = 'ar') then
                                ()
                            else
                                attribute end-indent {"label-end()"}
                        }
                        <fo:block>{
                                if ($lang = 'ar') then
                                    ()
                                else
                                    $p || ')'
                            }</fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body>
                        {
                            if ($lang = 'ar') then
                                ()
                            else
                                attribute start-indent {"body-start()"}
                        }
                        {
                            if ($lang = 'ar') then
                                <fo:block>
                                    {fo:lang('ar')}
                                    {fo:tei2fo($deco/tei:desc[@xml:lang = $lang])}
                                    {
                                        if ($deco/tei:q[@xml:lang = $lang])
                                        then
                                            (<fo:block
                                                line-height="12.5pt"
                                                baseline-shift="baseline"
                                                font-family="Ludolfus"
                                                letter-spacing="0.5pt"
                                                font-size="10.5pt">
                                                {fo:tei2foSinRef($deco/tei:q[@xml:lang = 'gez']/node())}
                                            </fo:block>,
                                            '"',
                                            fo:tei2foSinRef($deco/tei:q[@xml:lang = $lang]),
                                            '"'
                                            )
                                        else
                                            ()
                                    }</fo:block>
                            else
                                <fo:block>
                                    {
                                        if ($deco/tei:locus) then
                                            (string-join(fo:tei2fo($deco/tei:locus)) || ': ')
                                        else
                                            ()
                                    }
                                    {fo:tei2fo($deco/tei:desc)}
                                    {
                                        if ($deco/tei:q) then
                                            (' Legend: ',
                                            fo:tei2fo($deco/tei:q[@xml:lang = 'gez']),
                                            if ($deco/tei:q[@xml:lang = 'en'])
                                            then
                                                '‘' || string-join(fo:tei2fo($deco/tei:q[@xml:lang = 'en'])) || '’'
                                            else
                                                ())
                                        else
                                            ()
                                    }</fo:block>
                        }
                    </fo:list-item-body>
                </fo:list-item>
        }
    
    </fo:list-block>)
};



declare function fo:collation($collation as element(tei:collation)) {
    if ($collation//tei:item or $collation//tei:note) then
        let $cq := count($collation//tei:item)
        return
            (<fo:block
                font-style="italic"
                space-after="3mm"
                space-before="2mm"
                page-break-inside="avoid"
                page-break-after="avoid">Quire structure</fo:block>,
            if ($collation/ancestor::tei:msPart//tei:signatures)
            then
                <fo:block
                    space-after="3mm">{fo:tei2fo($collation/ancestor::tei:msPart//tei:signatures)}</fo:block>
            else
                if ($collation/ancestor::tei:msDesc//tei:signatures[not(ancestor::tei:msPart)])
                then
                    <fo:block
                        space-after="3mm">{fo:tei2fo($collation/ancestor::tei:msDesc//tei:signatures[not(ancestor::tei:msPart)])}</fo:block>
                else
                    (),
            <fo:block>{$cq} quire{
                    if ($cq = 1) then
                        ()
                    else
                        's'
                }. {
                    let $quires := for $q at $p in $collation//tei:item
                        order by $q/@xml:id
                    return
                        (: e.g. DSEthiop1
                I10(fols. 1-10) – II10(fols. 11-20) – 
                III6+4(s.l. 3 s.b. 7; s.l. 4 s.b. 7; s.l. 7 s.b. 3; s.l. 8 s.b. 3/fols. 21-30) – 
                IV10(fols. 31-40) – V10(fols. 41-50) – 
                VI8+2(s.l. 8 s.b. 3; s.l. 3 s.b. 8/fols. 51-60) – :)
                        <quire>
                            <sequence>{
                                    if (matches($q/@n, '[A-Z]')) then
                                        string($q/@n)
                                    else
                                        local:n2roman(xs:integer($q/@n))
                                }</sequence>
                            <desc><fo:inline
                                    font-size="7pt"
                                    vertical-align="text-top">{
                                        let $stubs := if ($q/text()[preceding::tei:locus])
                                        then
                                            (let $anastring := analyze-string(string-join($q/text()), '(stub)')
                                            return
                                                count($anastring//*:group[@nr = 1]))
                                        else
                                            0
                                        let $dimdec := string($q/tei:dim[@unit = 'leaf'])
                                        let $dim := if ($stubs ge 1) then
                                            (string((xs:integer($dimdec) - $stubs)) || '+' || string($stubs))
                                        else
                                            $dimdec
                                        return
                                            (
                                            $dim ||
                                            ' (' || (if (matches(string-join($q/text()[preceding::tei:locus]), '[a-z]+'))
                                            then
                                                (
                                                let $cleanup := replace(normalize-space(string-join($q/text())), 'stub before \d+\s?', '')
                                                => replace('stub after \d+\s?', '') => replace(' s.l.', ', ')
                                                => replace('[\s,]+$', '')
                                                let $string := if (string-length($cleanup) ge 1) then
                                                    (
                                                    if (starts-with($cleanup, 's.l.')) then
                                                        $cleanup
                                                    else
                                                        's.l. ' || $cleanup)
                                                else
                                                    ()
                                                let $bar := if (string-length($string) ge 1) then
                                                    '/'
                                                else
                                                    ()
                                                return
                                                    $string || $bar)
                                            else
                                                ())
                                            ||
                                            fo:locustext($q/tei:locus)
                                            || ')'
                                            )
                                    }</fo:inline>
                            </desc>
                            <hyphen>{
                                    if ($p = $cq)
                                    then
                                        ()
                                    else
                                        ' – '
                                }</hyphen>
                        
                        </quire>
                    
                    return
                        $quires/node()/node()
                }</fo:block>
            )
    else
        ()
};

declare function fo:locustext($locus) {
    let $loci := for $l in $locus
    return
        replace(translate(fo:tei2fo($l), 'rv', ''), 'F', 'f')
    return
        string-join($loci, ', ')
};

declare function fo:paleo($handDesc as element(tei:handDesc)) {
    <fo:table>
        <fo:table-column
            column-number="1"
            column-width="15%"/>
        <fo:table-column
            column-number="2"
            column-width="85%"/>
        <fo:table-body>
            {
                for $handnote in $handDesc/tei:handNote
                return
                    <fo:table-row
                        space-after="2mm">
                        <fo:table-cell>
                            <fo:block>
                                <fo:inline>Hand {substring-after($handnote/@xml:id, 'h')}:</fo:inline>
                            </fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block
                                hyphenate="true">
                                
                                <!-- {fo:tei2fo($handnote/tei:seg[@type='script'])}{' '}-->
                                {fo:tei2fo($handnote/tei:desc)}
                                {
                                    if ($handnote/tei:seg[@type = 'ink']) then
                                        <fo:block>Ink: {fo:tei2fo($handnote/tei:seg[@type = 'ink']/node())}</fo:block>
                                    else
                                        ()
                                }
                                {
                                    if ($handnote/tei:seg[@type = 'rubrication']) then
                                        <fo:block>Rubrication: {fo:tei2fo($handnote/tei:seg[@type = 'rubrication']/node())}</fo:block>
                                    else
                                        ()
                                }
                                {
                                    if ($handnote/tei:list[@type = 'abbreviations']) then
                                        <fo:block>Abbreviations: {fo:tei2fo($handnote/tei:list[@type = 'abbreviations'])}</fo:block>
                                    else
                                        ()
                                }
                            </fo:block>
                        </fo:table-cell>
                    </fo:table-row>
            }
        </fo:table-body>
    </fo:table>
};


declare function fo:authorheader($nodes as element(tei:author)*) {
    for $node in $nodes
    return
        let $parts := for $w in tokenize($node/text(), ' ')
        return
            $w
        return
            (:                mock up small caps:)
            (for $p in $parts
            return
                (<fo:inline>{$p}</fo:inline>,
                if (index-of($parts, $p) = count($parts)) then
                    ()
                else
                    ' '
                ),
            if ($node/following-sibling::tei:author) then
                ', '
            else
                ())
};

declare function fo:ms($part, $lang) {
    let $ms := for $m in fo:material($part, $lang)
    return
        if ($lang = 'ar')
        then
            $m/text()
        else
            functx:capitalize-first(string($m/@key))
    return
        string-join(distinct-values($ms), ' ')
};

declare function fo:material($part, $lang) {
    let $thissupport := $part//tei:support[1]
    return
        if ($lang = 'ar')
        then
            $thissupport//tei:material[@xml:lang = $lang]
        else
            $thissupport//tei:material[not(@xml:lang)]
};

declare function fo:folios($part, $lang) {
    (if ($lang = 'ar') then
        $part//tei:measure[@unit = 'leaf'][@xml:lang = $lang]/text()
    else
        ($part//tei:measure[@unit = 'leaf'][not(@xml:lang)])[1]/text())
};

declare function fo:quires($part, $lang) {
    if ($part//tei:measure[@unit = 'quire'][1]) then
        ', ' || (if ($lang = 'ar') then
            $part//tei:measure[@unit = 'quire'][@xml:lang = $lang]/text()
        else
            string-join($part//tei:measure[@unit = 'quire'][not(@xml:lang)]/text(), ', ')) || (if ($lang = 'ar') then
            ()
        else
            ' quires. ')
    else
        () (:' no measure[@unit="quire"]':)
};

declare function fo:dimensions($part, $lang) {
    let $dimensions := if ($lang = 'ar') then
        $part//tei:dimensions[@type = 'outer'][@xml:lang = $lang]
    else
        $part//tei:dimensions[@type = 'outer'][not(@xml:lang)]
    return
        if ($dimensions) then
            (if ($lang = 'ar') then
                '،'
            else
                ', ') ||
            (if ($lang = 'ar') then
                'مم'
            else
                ()) ||
            string-join($dimensions/node()/text(), '×') || ' ' ||
            (if ($lang = 'ar') then
                'مم'
            else
                string($dimensions/@unit))
        else
            ()
};

declare function fo:origDate($part, $lang) {
    let $od := if ($lang = 'ar')
    then
        $part//tei:origin//tei:origDate[@xml:lang = $lang]
    else
        $part//tei:origin//tei:origDate[not(@xml:lang)]
    for $origDate in $od
    let $formatDate := fo:tei2fo($origDate)
    return
        ', ' || string-join($formatDate, ' ')
};


declare function fo:intro($part, $lang) {
    if ($part[descendant::tei:msPart]) then
        (
        let $material := fo:ms($part, $lang)
        let $form := ' ' || lower-case(($part//tei:objectDesc/@form)[1]) || ', composite'
        let $dimensions := fo:dimensions($part, $lang) || ', '
        let $folios := for $f in fo:folios($part, $lang)
        return
            $f || (if ($lang = 'ar') then
                ()
            else
                ' fols')
        let $quires := fo:quires($part, $lang)
        let $date := for $p in $part//tei:msPart
        let $partN := string(substring-after($p/@xml:id, 'p'))
        return
            if ($p//tei:origDate[@when or @notBefore or @notAfter])
            then
                (let $od := if ($lang = 'ar')
                then
                    $p//tei:origin//tei:origDate[@xml:lang = $lang]
                else
                    $p//tei:origin//tei:origDate[not(@xml:lang)]
                let $origdates := for $origDate in $od
                let $formatDate := fo:tei2fo($origDate)
                return
                    ', ' || string-join($formatDate, ' ') || '.'
                return
                    (if ($lang = 'ar') then
                        ()
                    else
                        (' Unit ' || $partN || ': ') || string-join($origdates))
                )
            else
                ()
        let $decideDate := if (count($date) gt 1)
        then
            string-join($date)
        else
            (
            
            let $generalDate := if ($part//tei:origDate[@when or @notBefore or @notAfter])
            then
                fo:origDate($part, $lang)
            else
                ()
            let $units := for $p in $part//tei:msPart
            let $partN := string(substring-after($p/@xml:id, 'p'))
            return
                if ($lang = 'ar') then
                    ()
                else
                    ('Unit ' || $partN || ': ') || string-join($generalDate, ' ') || '. '
            return
                ' ' || string-join($units)
            )
        return
            $material || $form || $dimensions || string-join($folios, ', ') || $quires || $decideDate
        )
    else
        (
        let $material := fo:ms($part, $lang)
        let $form := ' ' || lower-case(($part//tei:objectDesc/@form)[1])
        let $dimensions := fo:dimensions($part, $lang) || ', '
        let $folios := fo:folios($part, $lang) || (if ($lang = 'ar') then
            ()
        else
            ' fols')
        let $quires := fo:quires($part, $lang)
        let $date := if ($part//tei:origDate[@when or @notBefore or @notAfter])
        then
            fo:origDate($part, $lang)
        else
            ()
        return
            $material || $form || $dimensions || $folios || $quires || $date || '.'
        )
};

declare function fo:contents($contents) {
    <fo:block
        space-before="2mm">
        <fo:block
            font-style="italic"
            space-after="3mm"
            page-break-inside="avoid"
            page-break-after="avoid">Main Contents</fo:block>
        {
            for $n in $contents/node()
                order by count($n/preceding-sibling::node()[name() = $n/name()])
            return
                fo:tei2fo($n)
        }
    </fo:block>,
    fo:colophon($contents)
};

declare function fo:colophon($part) {
    if ($part//tei:colophon) then
        <fo:block
            space-before="2mm">
            <fo:block
                font-style="italic"
                space-after="3mm"
                page-break-inside="avoid"
                page-break-after="avoid">Colophon</fo:block>
            
            <fo:list-block
                provisional-label-separation="1em"
                provisional-distance-between-starts="2em">
                {
                    for $c in $part//tei:colophon
                    return
                        <fo:list-item>
                            <fo:list-item-label
                                end-indent="label-end()">
                                <fo:block>{count($c/preceding-sibling::tei:colophon) + 1})</fo:block>
                            </fo:list-item-label>
                            <fo:list-item-body
                                start-indent="body-start()">
                                <fo:block>
                                    {fo:tei2fo($c)}
                                </fo:block>
                            </fo:list-item-body>
                        </fo:list-item>
                }</fo:list-block>
        
        </fo:block>
    else
        ()
};

declare function fo:binding($binding as element(tei:binding)) {
    if ($binding[descendant::tei:decoNote[@xml:id = 'b1']]) then
        <fo:block
            space-before="2mm">
            <fo:block
                font-style="italic"
                space-after="3mm"
                page-break-inside="avoid"
                page-break-after="avoid">Binding</fo:block>
            {
                for $bindingNote in $binding//tei:decoNote
                return
                    fo:tei2fo($bindingNote)
            }
        </fo:block>
    else
        ()
};


declare function fo:layout($layoutDesc as element(tei:layoutDesc)) {
    if ($layoutDesc//tei:layout) then
        (<fo:block
            space-before="2mm">
            <fo:block
                font-style="italic"
                space-after="3mm"
                page-break-inside="avoid"
                page-break-after="avoid">Layout</fo:block>
            <fo:list-block
                provisional-label-separation="1em"
                provisional-distance-between-starts="2em">
                {
                    for $l in $layoutDesc//tei:layout
                    return
                        <fo:list-item
                            space-after="3mm">
                            <fo:list-item-label
                                end-indent="label-end()">
                                <fo:block>{count($l/preceding-sibling::tei:layout) + 1})</fo:block>
                            </fo:list-item-label>
                            <fo:list-item-body
                                start-indent="body-start()">
                                <fo:block>{
                                        if ($l/tei:locus) then
                                            (string-join(fo:tei2fo($l/tei:locus)) || ': ')
                                        else
                                            ()
                                    }{string($l/@columns)}
                                    column{
                                        if (number($l/@columns) gt 1) then
                                            's'
                                        else
                                            ()
                                    } ({
                                        if (matches($l/@writtenLines, '\s')) then
                                            replace($l/@writtenLines, '\s', '–')
                                        else
                                            string($l/@writtenLines)
                                    } written lines){fo:tei2fo($l/tei:p)}</fo:block>
                                {
                                    if ($l/tei:dimensions[not(@type)]) then
                                        <fo:block
                                            start-indent="10mm"
                                            space-before="3mm"
                                            space-after="3mm">text area
                                            {
                                                let $dim := $l/tei:dimensions[not(@type)]
                                                return
                                                    string-join($dim/node()/text(), ' × ') || string($dim/@unit)
                                            }
                                            {
                                                let $dimID := string($l/tei:dimensions[not(@type)]/@xml:id)
                                                return
                                                    ' (' || lower-case(fo:tei2fo($l/tei:note[matches(@corresp, $dimID)]/tei:locus)) || ')'
                                            }</fo:block>
                                    else
                                        ()
                                }
                            </fo:list-item-body>
                        </fo:list-item>
                }</fo:list-block>
        </fo:block>,
        if ($layoutDesc//tei:layout//tei:ab[@type = 'pricking' or @type = 'ruling'][@subtype = 'pattern'] and
        $layoutDesc/ancestor::tei:TEI//tei:support//tei:material[@key != 'paper']) then
            <fo:block
                space-before="2mm">
                <fo:block
                    font-style="italic"
                    space-after="3mm">Ruling pattern</fo:block>
                <fo:list-block
                    provisional-label-separation="1em"
                    provisional-distance-between-starts="2em">
                    {
                        for $rulprick in $layoutDesc//tei:layout//tei:ab[@type = 'pricking' or @type = 'ruling'][@subtype = 'pattern']
                        return
                            <fo:list-item>
                                <fo:list-item-label
                                    end-indent="label-end()">
                                    <fo:block>{count($rulprick/preceding::tei:ab[@type = 'pricking' or @type = 'ruling'][@subtype = 'pattern']) + 1})</fo:block>
                                </fo:list-item-label>
                                <fo:list-item-body
                                    start-indent="body-start()">
                                    <fo:block>{
                                            if ($rulprick/preceding-sibling::tei:locus) then
                                                (fo:tei2fo($rulprick/preceding-sibling::tei:locus) || ': ')
                                            else
                                                ()
                                        }
                                        {normalize-space(replace(string-join($rulprick/text(), ' '), ' Ruling pattern:', ''))}</fo:block>
                                </fo:list-item-body>
                            </fo:list-item>
                    }</fo:list-block>
            </fo:block>
        else
            ()
        )
    else
        ()
};

declare function fo:palaeography($handDesc as element(tei:handDesc)) {
    if ($handDesc//tei:handNote) then
        <fo:block
            space-before="2mm">
            <fo:block
                font-style="italic"
                space-after="3mm"
                page-break-inside="avoid"
                page-break-after="avoid">Palaeography</fo:block>
            {fo:paleo($handDesc)}
        </fo:block>
    else
        ()
};




declare function fo:other($part) {
    if ($part//tei:binding//tei:decoNote[descendant::tei:term[@key = 'leafStringMark']]
    or $part//tei:support/tei:p
    or $part//tei:notatedMusic
    or $part//tei:layout//tei:ab[@type = 'ruling'][not(@subtype)][contains(., 'misṭāra')]) then
        <fo:block
            space-before="2mm">
            <fo:block
                font-style="italic"
                space-after="3mm"
                page-break-inside="avoid"
                page-break-after="avoid">Other details</fo:block>
            {
                let $deco := $part//tei:binding//tei:decoNote[descendant::tei:term[@key = 'leafStringMark']]
                return
                    fo:tei2fo($deco/node())
            }
            {
                let $supportP := $part//tei:support/tei:p
                return
                    <fo:block>{fo:tei2fo($supportP/node())}</fo:block>
            }
            {
                let $mN := $part//tei:musicalNotation
                return
                    <fo:block>{fo:tei2fo($mN/node())}</fo:block>
            }
            {
                let $mistara := $part//tei:layout//tei:ab[@type = 'ruling'][not(@subtype)][contains(., 'misṭāra')]
                return
                    <fo:block>{fo:tei2fo($mistara/node())}</fo:block>
            }
        </fo:block>
    else
        ()
};

declare function fo:history($h) {
    if ($h/node()) then
        <fo:block
            space-before="2mm">
            <fo:block
                font-style="italic"
                space-after="3mm"
                page-break-inside="avoid"
                page-break-after="avoid">History</fo:block>
            {
                for $his at $p in $h
                return
                    <fo:block>{fo:tei2fo($his/node()[not((self::tei:origDate and not(text())))][not(@xml:lang = "ar")])}</fo:block>
            }
        </fo:block>
    else
        ()
};

declare function fo:URL($mainID) {
    <fo:block
        space-before="2mm"
        space-after="3mm"
        margin-bottom="16.25pt"
        page-break-before="avoid">URL: <fo:basic-link
            external-destination="https://betamasaheft.eu/{$mainID}">https://betamasaheft.eu/{$mainID}</fo:basic-link>
    </fo:block>
};

declare function fo:URL($mainID, $anchor) {
    <fo:block
        space-before="2mm"
        space-after="3mm"
        margin-bottom="16.25pt"
        page-break-before="avoid">URL: <fo:basic-link
            external-destination="https://betamasaheft.eu/{$mainID}#{$anchor}">https://betamasaheft.eu/{$mainID}#{$anchor}</fo:basic-link>
    </fo:block>
};

declare function fo:msStructure($part, $p) {
    let $uid := fo:uid($part)
    let $partType := fo:partType($part)
    return
        (
        <fo:block
            space-before="2mm"
            space-after="3mm">
            {
                if ($partType = '') then
                    attribute id {$part/ancestor::tei:TEI/@xml:id}
                else
                    ()
            }
            {
                if ($p = 0) then
                    fo:intro($part, '')
                else
                    ()
            }
        </fo:block>,
        if (($p = 0) and ($part[descendant::tei:msPart]) and
        $part//tei:binding[not(ancestor::tei:msPart)])
        then
            fo:binding($part//tei:binding[not(ancestor::tei:msPart)])
        else
            (),
        if (($p = 0) and ($part[descendant::tei:msPart]) and
        $part//tei:collation[not(ancestor::tei:msPart)])
        then
            fo:collation($part//tei:collation[not(ancestor::tei:msPart)])
        else
            (),
        (:if(($p = 0) and ($part[descendant::tei:msPart]) and 
            $part//tei:condition[not(ancestor::tei:msPart)]) 
            then fo:condition($part//tei:condition[not(ancestor::tei:msPart)]) else (),:)
        if (($p = 0) and ($part[descendant::tei:msPart]))
        then
            ((: we are parsing a msDesc (p=0) and this is a composite manuscript main part, 
        so, do nothing, contents will be done when parsing each part :) )
        else
            (
            if ($partType != '')
            then
                <fo:block
                    space-before="2mm"
                    space-after="3mm">{functx:capitalize-first($partType) || ' ' || $p}</fo:block>
            else
                (),
            fo:contents(($part//tei:msContents)[1]),
            fo:colophon($part),
            if (($part//tei:additions)[1]) then
                fo:additions(($part//tei:additions)[1])
            else
                (),
            if (($part//tei:binding)[1]) then
                fo:binding(($part//tei:binding)[1])
            else
                (),
            if (($part//tei:collation)[1] and not($part//tei:material[@key = 'paper'])) then
                fo:collation(($part//tei:collation)[1])
            else
                (),
            if (($part//tei:layoutDesc)[1]) then
                fo:layout(($part//tei:layoutDesc)[1])
            else
                (),
            if (($part//tei:handDesc)[1]) then
                fo:palaeography(($part//tei:handDesc)[1])
            else
                (),
            if (($part//tei:decoDesc)[1]) then
                fo:deco(($part//tei:decoDesc)[1], '')
            else
                (),
            fo:other($part),
            if (($part//tei:condition)[1]) then
                fo:condition($part//tei:condition)
            else
                (),
            if (($part//tei:history)[1]) then
                fo:history($part//tei:history)
            else
                ()
            )
        )
};

declare function fo:condition($condition) {
    <fo:block
        space-before="2mm">
        <fo:block
            font-style="italic"
            space-after="3mm"
            page-break-inside="avoid"
            page-break-after="avoid">Condition</fo:block>
        
        <fo:block>{fo:tei2fo($condition/node())}</fo:block>
    </fo:block>
};

declare function fo:msidentifier($msIdentifier as element(tei:msIdentifier)) {
    <fo:block
        space-before="2mm"
        space-after="3mm">
        {
            (
            <fo:inline>{
                    if ($msIdentifier/tei:idno/@xml:lang) then
                        fo:lang($msIdentifier/tei:idno/@xml:lang)
                    else
                        ()
                }{string-join($msIdentifier/tei:idno/text(), ' ')}</fo:inline>,
            if ($msIdentifier/tei:altIdentifier/tei:idno/text())
            then
                ('. Also identified as ',
                for $alt in $msIdentifier/tei:altIdentifier/tei:idno
                return
                    <fo:inline>{
                            if ($alt/@xml:lang) then
                                fo:lang($alt/@xml:lang)
                            else
                                ()
                        }{string-join($alt/text(), ', ')}</fo:inline>)
            else
                ())
        }</fo:block>
};

declare function fo:ifThereIs($element) {
    (:this checks which function, with which parameters to call for each element, if it exists
if the element is not present nothing is done:)
    switch ($element/name())
        case 'msIdentifier'
            return
                fo:msidentifier($element)
        case 'history'
            return
                fo:history($element)
        case 'contents'
            return
                fo:contents($element)
        case 'colophon'
            return
                fo:colophon($element)
        case 'additions'
            return
                fo:additions($element)
        case 'binding'
            return
                fo:binding($element)
        case 'decoDesc'
            return
                fo:deco($element, $element/@xml:lang)
        case 'layout'
            return
                fo:colophon($element)
        case 'handDesc'
            return
                fo:palaeography($element)
        case 'collation'
            return
                fo:collation($element)
        case 'objectDesc'
            return
                fo:tei2fo($element/tei:physDesc/tei:objectDesc/node()[not(self::tei:collation)])
        default return
            fo:tei2fo($element/node())

};

declare function fo:SimpleMsstructureelements($part) {
    for $entrypart in $local:settings/s:catalogueEntries/element()
    let $mainid := string(root($part)/ancestor-or-self::tei:TEI/@xml:id)
    let $anchor := string($part/@xml:id)
    return
        if ($entrypart = 'yes') then
            switch ($entrypart/name())
                case 'shelfmark'
                    return
                        fo:ifThereIs($part/tei:msIdentifier)
                case 'history'
                    return
                        fo:ifThereIs($part/tei:history)
                case 'contents'
                    return
                        fo:ifThereIs($part/tei:msContents)
                case 'objectDesc'
                    return
                        fo:ifThereIs($part/tei:physDesc/tei:objectDesc)
                case 'additions'
                    return
                        fo:ifThereIs($part/tei:physDesc/tei:additions)
                case 'binding'
                    return
                        fo:ifThereIs($part/tei:physDesc/tei:bindingDesc/tei:binding)
                case 'collation'
                    return
                        fo:ifThereIs($part/tei:physDesc/tei:objectDesc/tei:collation)
                case 'layout'
                    return
                        fo:ifThereIs($part/tei:pyhsDesc/tei:layoutDesc)
                case 'hands'
                    return
                        fo:ifThereIs($part/tei:physDesc/tei:handDesc)
                case 'decorations'
                    return
                        fo:ifThereIs($part/tei:physDesc/tei:decoDesc)
                case 'URI'
                    return
                        fo:URL($mainid, $anchor)
                default return
                    ()
    else
        ()
};

declare function fo:SimpleMsStructure($file) {
    <fo:block
        space-before="2mm"
        space-after="3mm">
        {fo:tei2fo($file/tei:sourceDesc/node()[not(self::tei:msDesc)])}
    </fo:block>,
    let $msDesc := $file//tei:msDesc
    return
        (fo:SimpleMsstructureelements($msDesc),
        for $part in $msDesc/(tei:msPart | tei:msFrag)
        return
            fo:SimpleMsStructureParts($part)
        )
};

declare function fo:SimpleMsStructureParts($part) {
    
    (
    <fo:block
        space-before="2mm"
        space-after="3mm">
        Part {string($part/@xml:id)}
    </fo:block>,
    fo:SimpleMsstructureelements($part)
    )
};

declare function fo:uid($part) {
    if ($part/name() = 'msFrag')
    then
        substring-after($part/@xml:id, 'f')
    else
        if ($part/name() = 'msPart')
        then
            substring-after($part/@xml:id, 'p')
        else
            ()
};

declare function fo:partType($part) {
    if ($part/name() = 'msFrag')
    then
        'fragment'
    else
        if ($part/name() = 'msPart')
        then
            'unit'
        else
            ()
};


declare function fo:msheader($msId) {
    <fo:block
        id="{string($msId/ancestor::tei:TEI/@xml:id)}"
        text-align="center"
        page-break-inside="avoid"
        page-break-after="avoid"
        space-before="3mm">
        <fo:block
            font-weight="800">{$msId/tei:idno[not(@xml:lang)]/text()}</fo:block>
        <fo:block>{
                if ($msId/tei:altIdentifier/tei:idno)
                then
                    ('(',
                    for $altID in $msId/tei:altIdentifier[tei:idno]
                    let $all := count($msId/tei:altIdentifier[tei:idno])
                    return
                        <fo:inline>{
                                if ($altID/tei:idno/@xml:lang) then
                                    fo:lang($altID/tei:idno/@xml:lang)
                                else
                                    (),
                                $altID/tei:idno/text()
                            }</fo:inline>
                    , ')')
                else
                    ()
            }
        </fo:block>
        <fo:block>{
                if ($msId/tei:altIdentifier/tei:idno[@xml:id])
                then
                    ('[',
                    for $arabicID in $msId/tei:altIdentifier[tei:idno[@corresp]]
                    let $all := count($msId/tei:altIdentifier[tei:idno[@corresp]])
                    let $c := count($arabicID/preceding-sibling::tei:altIdentifier[tei:idno[@corresp]])
                        order by $c
                    return
                        <fo:inline>{
                                fo:lang($arabicID/tei:idno/@xml:lang),
                                $arabicID/tei:idno/text() || (if ($all = ($c + 1)) then
                                    ''
                                else
                                    '; ')
                            }</fo:inline>
                    ,
                    ']')
                else
                    ()
            }
        </fo:block>
    </fo:block>
};


declare function fo:bookmarks() {
    <fo:bookmark-tree>
        {
            for $file in $local:entries
            let $ID := if ($file/@xml:id) then
                string($file/@xml:id)
            else
                $file//tei:idno[@type = 'filename']/text()
            let $shelf := $file//tei:msDesc/tei:msIdentifier/tei:idno[not(@xml:lang)]/text()
            let $num := number(substring-after($shelf, $local:prefix))
                order by $num
            return
                <fo:bookmark
                    internal-destination="{$ID}">
                    <fo:bookmark-title>
                        {$shelf}</fo:bookmark-title>
                
                </fo:bookmark>
        }
    </fo:bookmark-tree>
};


declare function fo:sortingkey($input) {
    string-join($input)
    => replace('ʾ', '')
    => replace('ʿ', '')
    => replace('\s', '')
    => translate('ƎḤḪŚṢṣḫḥǝʷāṖ', 'EHHSSshhewaP')
    => lower-case()
};


declare function fo:indexes() {
    
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-Indexes">
        {fo:static('', 'Index')}
        <fo:flow
            flow-name="xsl-region-body"
            font-size="10.5pt"
            line-height="12.5pt"
            font-family="Ludolfus"
            text-align="justify"
            hyphenate="true">
            <fo:block>This output is based on collaboratively edited data from the project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens und Eritreas: eine multimediale Forschungsumgebung). Authoritative names for entries have been contributed by collaborators of the project who may not be listed in the acknowledgements. Please refer to the Identifier to retrieve full informations about these contributors in the website.</fo:block>
            {
            for $index in $local:settings/s:indexes/element()
                return
                    if ($index = 'yes') then
                        switch ($index/name())
                            case 'persons'
                                return
                                    <fo:block-container
                                        text-align="left">
                                        <fo:block
                                            page-break-after="avoid"
                                            id="IndexPersons"
                                            text-align="justify">{
                                                (attribute font-weight {'700'},
                                                attribute margin-top {'6.25pt'},
                                                attribute margin-bottom {'6.25pt'})
                                            }Index of Persons</fo:block>,
                                        {
                                            let $attestations := $local:catalogue//tei:persName[@ref][not(parent::tei:title)][not(ancestor::tei:explicit)][not(ancestor::tei:handNote)][not(ancestor::tei:provenance)][not(ancestor::tei:acquisition)][not(ancestor::tei:adminInfo)][not(ancestor::tei:listPerson)][not(ancestor::tei:item[starts-with(@xml:id, 'e')])]
                                            return
                                                for $personAttestation in $attestations
                                                let $ref := $personAttestation/@ref
                                                    group by $r := $ref
                                                let $persRecord := if (starts-with($r, '#')) then
                                                    $local:catalogue//tei:listPerson/tei:person[@xml:id = substring-after($r, '#')]
                                                else
                                                    fo:getFile($r)
                                                let $standardname := if (starts-with($r, '#')) then
                                                    if ($persRecord//tei:name) then
                                                        ($persRecord//tei:name/text())
                                                    else
                                                        ($persRecord//tei:surname/text() || ' ' || $persRecord//tei:forename/text())
                                                else
                                                    fo:printTitleID($r)
                                                let $rolename := $ref/tei:roleName/text()
                                                let $occupation := $persRecord//tei:occupation/text()
                                                let $allroles := ($rolename, $occupation)
                                                let $roles := distinct-values($allroles)
                                                let $cleanName := fo:sortingkey($standardname)
                                                    order by $cleanName
                                                let $label := string-join($standardname) || (if (count($roles) ge 1) then
                                                    (', ' || string-join($roles, ', '))
                                                else
                                                    ())
                                                return
                                                    <fo:block
                                                        start-indent="5mm"
                                                        text-indent="-5mm"
                                                        margin-bottom="1mm">
                                                        <fo:block><fo:basic-link
                                                                external-destination="https://betamasaheft.eu/{string($r)}"><fo:inline>{string($label)}</fo:inline></fo:basic-link>{
                                                                if (starts-with($r, '#')) then
                                                                    ': '
                                                                else
                                                                    ()
                                                            }</fo:block>
                                                        <fo:block
                                                            start-indent="3mm">{
                                                                if (starts-with($r, '#')) then
                                                                    ()
                                                                else
                                                                    (string($r) || ': ')
                                                            }
                                                            {
                                                                let $nodes := for $att in $personAttestation
                                                                let $identif := string(root($att)/tei:TEI/@xml:id) || generate-id($att) || string($r)
                                                                    order by $identif
                                                                return
                                                                    <fo:basic-link
                                                                        internal-destination="{$identif}"><fo:page-number-citation
                                                                            ref-id="{$identif}"/>{
                                                                            if ($att/ancestor::tei:note[ancestor::tei:div[@type = 'chapter']]) then
                                                                                ' n'
                                                                            else
                                                                                ()
                                                                        }</fo:basic-link>
                                                                
                                                                for $n at $p in $nodes
                                                                return
                                                                    ($n,
                                                                    if (($p = 1) and (count($personAttestation) gt 1)) then
                                                                        ', '
                                                                    else
                                                                        if ($p = count($personAttestation)) then
                                                                            ()
                                                                        else
                                                                            ', '
                                                                    )
                                                            }</fo:block>
                                                    </fo:block>
                                        }
                                    </fo:block-container>
                            case 'places'
                                return
                                    <fo:block-container
                                        text-align="justify">
                                        <fo:block
                                            page-break-after="avoid"
                                            page-break-before="always"
                                            id="IndexPlaces"
                                            text-align="justify">{
                                                (attribute font-weight {'700'},
                                                attribute margin-top {'6.25pt'},
                                                attribute margin-bottom {'6.25pt'})
                                            }Index of Places</fo:block>,
                                        {
                                            let $attestations := $local:catalogue//tei:placeName[@ref][not(parent::tei:title)][not(ancestor::tei:explicit)][not(ancestor::tei:handNote)][not(ancestor::tei:provenance)][not(ancestor::tei:acquisition)][not(ancestor::tei:item[starts-with(@xml:id, 'e')])]
                                            return
                                                for $placeAttestation in $attestations
                                                let $ref := $placeAttestation/@ref
                                                    group by $r := $ref
                                                let $standardname := fo:printTitleID($r)
                                                let $persRecord := fo:getFile($r)
                                                let $placeType := string($ref//tei:place/@type)
                                                let $label := $standardname || (if (count($placeType) ge 1) then
                                                    (', ' || string-join($placeType, ', '))
                                                else
                                                    ())
                                                let $cleanName := fo:sortingkey($standardname)
                                                    order by $cleanName
                                                return
                                                    <fo:block
                                                        start-indent="5mm"
                                                        text-indent="-5mm"
                                                        margin-bottom="1mm">
                                                        <fo:block><fo:basic-link
                                                                external-destination="{string($r)}"><fo:inline>{string($label)}</fo:inline></fo:basic-link></fo:block>
                                                        <fo:block>{string($r)}:
                                                            {
                                                                let $nodes := for $att in $placeAttestation
                                                                let $identif := string(root($att)/tei:TEI/@xml:id) || generate-id($att) || string($r)
                                                                    order by $identif
                                                                return
                                                                    <fo:basic-link
                                                                        internal-destination="{$identif}"><fo:page-number-citation
                                                                            ref-id="{$identif}"/></fo:basic-link>
                                                                
                                                                for $n at $p in $nodes
                                                                return
                                                                    ($n,
                                                                    if (($p = 1) and (count($placeAttestation) gt 1)) then
                                                                        ', '
                                                                    else
                                                                        if ($p = count($placeAttestation)) then
                                                                            ()
                                                                        else
                                                                            ', '
                                                                    )
                                                            }
                                                        </fo:block>
                                                    </fo:block>
                                        }
                                    </fo:block-container>
                            case 'works'
                                return
                                    <fo:block-container
                                        text-align="justify">
                                        <fo:block
                                            page-break-after="avoid"
                                            page-break-before="always"
                                            id="IndexWorks"
                                            text-align="justify">{
                                                (attribute font-weight {'700'},
                                                attribute margin-top {'6.25pt'},
                                                attribute margin-bottom {'6.25pt'})
                                            }Index of Texts</fo:block>,
                                        {
                                            let $workexceptions := tokenize($local:settings/s:contentsExceptions, ',')
                                            for $WorkAttestation in $local:catalogue//tei:title[@ref][not(ancestor::tei:explicit)][not(ancestor::tei:handNote)][not(ancestor::tei:provenance)][not(ancestor::tei:acquisition)][not(ancestor::tei:item[starts-with(@xml:id, 'e')])][not(ancestor::tei:msItem[tei:title/@ref = $workexceptions])]
                                            let $text := $WorkAttestation/text()
                                            let $ref := if (contains($WorkAttestation/@ref, '#')) then
                                                substring-before($WorkAttestation/@ref, '#')
                                            else
                                                $WorkAttestation/@ref
                                                group by $r := $ref
                                            let $workRecord := fo:getFile($r)
                                            let $standardname := if ($workRecord//tei:titleStmt//tei:title[@xml:lang = "gez"][@corresp = "#t1"][@type = "normalized"])
                                            then
                                                $workRecord//tei:titleStmt//tei:title[@xml:lang = "gez"][@corresp = "#t1"][@type = "normalized"][1]/text()
                                            else
                                                if ($workRecord//tei:titleStmt//tei:title[@xml:lang = 'en'][@corresp = "#t1"]) then
                                                    $workRecord//tei:titleStmt//tei:title[@xml:lang = 'en'][@corresp = "#t1"][1]/text()
                                                else
                                                    fo:printTitleID($r)
                                            let $cleanName := fo:sortingkey($standardname)
                                                order by $cleanName
                                            return
                                                <fo:block
                                                    start-indent="5mm"
                                                    text-indent="-5mm"
                                                    margin-bottom="1mm">
                                                    <fo:block><fo:basic-link
                                                            external-destination="{string($r)}"><fo:inline>{
                                                                    if ($workRecord//tei:titleStmt//tei:title[@xml:lang = "gez"][@corresp = "#t1"][@type = "normalized"]) then
                                                                        attribute font-style {'italic'}
                                                                    else
                                                                        ()
                                                                }{string($standardname)}</fo:inline></fo:basic-link></fo:block>
                                                    <fo:block
                                                        start-indent="5mm">CAe {substring($r, 4, 4)}:
                                                        {
                                                            let $nodes := for $att in $WorkAttestation
                                                            let $identif := string(root($att)/tei:TEI/@xml:id) || generate-id($att) || string($att/@ref)
                                                                order by $identif
                                                            return
                                                                <fo:basic-link
                                                                    internal-destination="{$identif}"><fo:page-number-citation
                                                                        ref-id="{$identif}"/></fo:basic-link>
                                                            
                                                            for $n at $p in $nodes
                                                            return
                                                                ($n,
                                                                if (($p = 1) and (count($WorkAttestation) gt 1)) then
                                                                    ', '
                                                                else
                                                                    if ($p = count($WorkAttestation)) then
                                                                        ()
                                                                    else
                                                                        ', '
                                                                )
                                                        }</fo:block></fo:block>
                                        }
                                    </fo:block-container>
                            case 'subjects'
                                return
                                    <fo:block-container
                                        text-align="justify">
                                        <fo:block
                                            page-break-after="avoid"
                                            page-break-before="always"
                                            id="IndexSubjects"
                                            text-align="justify">{
                                                (attribute font-weight {'700'},
                                                attribute margin-top {'6.25pt'},
                                                attribute margin-bottom {'6.25pt'})
                                            }Index of Subjects</fo:block>,
                                        {
                                            let $exceptions := tokenize($local:settings/s:keywordsExceptions, ',')
                                            let $keywords := $local:catalogue//tei:keywords/tei:term[not(@key = $exceptions)]
                                            for $sub in $keywords
                                            let $ref := $sub/@key
                                                group by $r := $ref
                                            let $label := fo:printTitleID($r)
                                                order by $label
                                            return
                                                if (not(matches($r, '\w+'))) then
                                                    ()
                                                else
                                                    <fo:block
                                                        start-indent="5mm"
                                                        text-indent="-5mm"
                                                        margin-bottom="1mm">
                                                        <fo:basic-link
                                                            external-destination="{string($r)}"><fo:inline>{string($label)}</fo:inline></fo:basic-link>: {$local:prefix}
                                                        {
                                                            let $nodes := for $att in $sub
                                                            let $root := $att/ancestor::tei:TEI
                                                                group by $FILE := $root
                                                            let $n := string($root/@xml:id)
                                                                order by $n
                                                            return
                                                                $n
                                                            for $n at $p in $nodes
                                                            return
                                                                ($n,
                                                                if (($p = 1) and (count($sub) gt 1)) then
                                                                    ', '
                                                                else
                                                                    if ($p = count($sub)) then
                                                                        ()
                                                                    else
                                                                        ', ')
                                                        }</fo:block>
                                        }
                                    </fo:block-container>
                            
                            case 'languages'
                                return
                                    <fo:block-container
                                        text-align="justify">
                                        <fo:block
                                            page-break-after="avoid"
                                            page-break-before="always"
                                            id="IndexLanguages"
                                            text-align="justify">{
                                                (attribute font-weight {'700'},
                                                attribute margin-top {'6.25pt'},
                                                attribute margin-bottom {'6.25pt'})
                                            }Index of Languages</fo:block>,
                                        {
                                            let $keywords := $local:catalogue//tei:language
                                            for $sub in $keywords
                                            let $ref := $sub/text()
                                                group by $r := $ref
                                                order by $r
                                            return
                                                <fo:block
                                                    start-indent="5mm"
                                                    text-indent="-5mm"
                                                    margin-bottom="1mm">
                                                    <fo:basic-link
                                                        external-destination="{string($r)}"><fo:inline>{string($r)}</fo:inline></fo:basic-link>: {$local:prefix}
                                                    {
                                                        let $nodes := for $att in $sub
                                                        let $root := $att/ancestor::tei:TEI
                                                        let $n := string($root/@xml:id)
                                                            group by $n
                                                            order by $n
                                                        return
                                                            $n
                                                        for $n at $p in $nodes
                                                        return
                                                            ($n,
                                                            if (($p = 1) and (count($sub) gt 1)) then
                                                                ', '
                                                            else
                                                                if ($p = count($sub)) then
                                                                    ()
                                                                else
                                                                    ', ')
                                                    }</fo:block>
                                        }
                                    </fo:block-container>
                            
                            case 'keywords'
                                return
                                    <fo:block-container
                                        text-align="justify">
                                        <fo:block
                                            page-break-after="avoid"
                                            page-break-before="always"
                                            id="IndexKeywords"
                                            text-align="justify">{
                                                (attribute font-weight {'700'},
                                                attribute margin-top {'6.25pt'},
                                                attribute margin-bottom {'6.25pt'})
                                            }Index of Keyword</fo:block>,
                                        {
                                            let $keywords := $local:catalogue//tei:term
                                            for $sub in $keywords
                                            let $ref := $sub/@key
                                                group by $r := $ref
                                                order by $r
                                            return
                                                if (not(matches($r, '\w+'))) then
                                                    ()
                                                else
                                                    <fo:block
                                                        start-indent="5mm"
                                                        text-indent="-5mm"
                                                        margin-bottom="1mm">
                                                        <fo:basic-link
                                                            external-destination="{string($r)}"><fo:inline>{string($r)}</fo:inline></fo:basic-link>: {$local:prefix}
                                                        {
                                                            let $nodes := for $att in $sub
                                                            let $root := $att/ancestor::tei:TEI
                                                            let $n := string($root/@xml:id)
                                                                group by $n
                                                                order by $n
                                                            return
                                                                $n
                                                            for $n at $p in $nodes
                                                            return
                                                                ($n,
                                                                if (($p = 1) and (count($sub) gt 1)) then
                                                                    ', '
                                                                else
                                                                    if ($p = count($sub)) then
                                                                        ()
                                                                    else
                                                                        ', ')
                                                        }</fo:block>
                                        }
                                    </fo:block-container>
                            default return
                                ()
                else
                    ()
        }
    </fo:flow>
</fo:page-sequence>
};


declare function fo:acknow($front) {
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-master"
        format="i">
        {fo:static('', 'Acknowledgement')}
        <fo:flow
            flow-name="xsl-region-body"
            font-size="10.5pt"
            line-height="12.5pt"
            font-family="Ludolfus"
            text-align="justify"
            hyphenate="true">
            <fo:block-container
                id="Acknowledgement">
                {fo:tei2fo($front)}
                <fo:block>This output is based on collaboratively edited data from the project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens und Eritreas: eine multimediale Forschungsumgebung). </fo:block>
                {
                    let $values := ($local:entries//(tei:author, tei:editor[not(@role = 'generalEditor')])/@key, $local:entries//tei:change/@who)
                    let $contribclean := for $contrib in $values
                    return
                        replace($contrib, '#', '')
                    let $list := for $contrib in distinct-values($contribclean)
                    return
                        fo:editorName($contrib)
                    return
                        <fo:block>Contributors to the files directly included are: {string-join($list, ', ')}. This list does not include contributors to other related entities. Please follow links to the source data where contributions are listed and versioned.</fo:block>
                }
            </fo:block-container>
        </fo:flow>
    </fo:page-sequence>
};


declare function fo:back($back) {
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-master">
        {fo:static('', 'Plates')}
        <fo:flow
            flow-name="xsl-region-body"
            font-size="10.5pt"
            line-height="12.5pt"
            font-family="Ludolfus"
            text-align="justify"
            hyphenate="true">
            <fo:block
                id="Appendix"
                font-size="12pt"
                space-before="25.2pt"
                space-after="12.24pt"
                font-family="Ludolfus"
                font-weight="700"
                text-align="center"
                display-align="center">Plates</fo:block>
            {fo:tei2fo($back)}
        </fo:flow>
    </fo:page-sequence>
};


declare function fo:static($topleft, $topright) {
    (
    (:top of odd page (right):)
    <fo:static-content
        flow-name="rest-region-before-odd">
        <fo:block-container
            height="100%"
            display-align="center">
            <fo:table>
                <fo:table-column
                    column-width="30%"/>
                <fo:table-column
                    column-width="40%"/>
                <fo:table-column
                    column-width="30%"/>
                
                <fo:table-body>
                    <fo:table-row>
                        <fo:table-cell>
                            <fo:block
                                text-align="right"></fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block
                                text-align="center"
                                font-size="9pt"
                                font-family="Ludolfus">{$topleft}</fo:block>
                        </fo:table-cell>
                        <fo:table-cell><fo:block
                                font-size="9pt"
                                font-family="Ludolfus"
                                text-align="right">
                                <fo:page-number/>
                            </fo:block>
                        </fo:table-cell>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
        </fo:block-container>
    </fo:static-content>
    ,
    (:            top of even page (left) :)
    <fo:static-content
        flow-name="rest-region-before-even">
        <fo:block-container
            height="100%"
            display-align="center">
            <fo:table>
                <fo:table-column
                    column-width="30%"/>
                <fo:table-column
                    column-width="40%"/>
                <fo:table-column
                    column-width="30%"/>
                
                <fo:table-body>
                    <fo:table-row>
                        <fo:table-cell>
                            <fo:block
                                font-size="9pt"
                                font-family="Ludolfus"
                                text-align="left"><fo:page-number/></fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block
                                text-align="center"
                                font-size="9pt"
                                font-family="Ludolfus">{$topright}</fo:block>
                        </fo:table-cell>
                        <fo:table-cell><fo:block
                                font-size="9pt"
                                font-family="Ludolfus"
                                text-align="right">
                            
                            </fo:block>
                        </fo:table-cell>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
        </fo:block-container>
    </fo:static-content>
    
    (:            first page of section:)
    ,
    <fo:static-content
        flow-name="rest-region-after-first">
        <fo:table>
            <fo:table-column
                column-width="30%"/>
            <fo:table-column
                column-width="40%"/>
            <fo:table-column
                column-width="30%"/>
            
            <fo:table-body>
                <fo:table-row>
                    <fo:table-cell><fo:block
                            font-size="9pt"
                            font-family="Ludolfus"
                            text-align="left"></fo:block>
                    </fo:table-cell>
                    <fo:table-cell>
                        <fo:block
                            text-align="center"
                            font-size="9pt"
                            font-family="Ludolfus"></fo:block>
                    </fo:table-cell>
                    <fo:table-cell>
                        <fo:block
                            text-align="right"
                            font-size="9pt"
                            font-family="Ludolfus"></fo:block>
                    </fo:table-cell>
                </fo:table-row>
            </fo:table-body>
        </fo:table>
    </fo:static-content>
    
    (:            bottom odd:)
    ,
    <fo:static-content
        flow-name="rest-region-after-odd">
        <fo:table>
            <fo:table-column
                column-width="30%"/>
            <fo:table-column
                column-width="40%"/>
            <fo:table-column
                column-width="30%"/>
            
            <fo:table-body>
                <fo:table-row>
                    <fo:table-cell>
                        <fo:block
                            text-align="right"></fo:block>
                    </fo:table-cell>
                    <fo:table-cell>
                        <fo:block
                            text-align="center"
                            font-size="9pt"
                            font-family="Ludolfus"><!--<fo:page-number/>--></fo:block>
                    </fo:table-cell>
                    <fo:table-cell><fo:block
                            font-size="9pt"
                            font-family="Ludolfus"
                            text-align="right">
                        </fo:block>
                    </fo:table-cell>
                </fo:table-row>
            </fo:table-body>
        </fo:table>
    </fo:static-content>
    
    (:            bottom even:)
    ,
    <fo:static-content
        flow-name="rest-region-after-even">
        <fo:table>
            <fo:table-column
                column-width="30%"/>
            <fo:table-column
                column-width="40%"/>
            <fo:table-column
                column-width="30%"/>
            
            <fo:table-body>
                <fo:table-row>
                    <fo:table-cell>
                        <fo:block
                            font-size="9pt"
                            font-family="Ludolfus"
                            text-align="left"></fo:block>
                    </fo:table-cell>
                    <fo:table-cell>
                        <fo:block
                            font-size="9pt"
                            font-family="Ludolfus"
                            text-align="center"><!--<fo:page-number/>--></fo:block>
                    </fo:table-cell>
                    <fo:table-cell>
                        <fo:block
                            text-align="left">
                        
                        </fo:block>
                    </fo:table-cell>
                
                </fo:table-row>
            </fo:table-body>
        </fo:table>
    </fo:static-content>
    ,
    <fo:static-content
        flow-name="rest-region-before-first">
        <fo:table>
            <fo:table-column
                column-width="30%"/>
            <fo:table-column
                column-width="40%"/>
            <fo:table-column
                column-width="30%"/>
            
            <fo:table-body>
                <fo:table-row>
                    <fo:table-cell>
                        <fo:block
                            text-align="right"></fo:block>
                    </fo:table-cell>
                    <fo:table-cell>
                        <fo:block
                            text-align="center"
                            font-size="9pt"
                            font-family="Ludolfus"></fo:block>
                    </fo:table-cell>
                    <fo:table-cell><fo:block
                            font-size="9pt"
                            font-family="Ludolfus"
                            text-align="right"></fo:block>
                    </fo:table-cell>
                </fo:table-row>
            </fo:table-body>
        </fo:table>
    </fo:static-content>
    
    (:            footnote space:)
    ,
    <fo:static-content
        flow-name="xsl-footnote-separator">
        <fo:block
            space-before="5mm"
            space-after="5mm">
            <fo:leader
                leader-length="30%"
                rule-thickness="0pt"/>
        </fo:block>
    </fo:static-content>
    )
};

declare function fo:layoutmaster($type) {
    if ($type = 'supplements') then
        <fo:layout-master-set>
            <fo:page-sequence-master
                master-name="Aethiopica-master">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference
                        master-reference="blank"
                        blank-or-not-blank="blank"/>
                    <fo:conditional-page-master-reference
                        page-position="first"
                        odd-or-even="odd"
                        master-reference="Aethiopica-chapter-first-odd"/>
                    <fo:conditional-page-master-reference
                        page-position="first"
                        odd-or-even="even"
                        master-reference="Aethiopica-chapter-first-even"/>
                    <fo:conditional-page-master-reference
                        page-position="rest"
                        odd-or-even="odd"
                        master-reference="Aethiopica-chapter-rest-odd"/>
                    <fo:conditional-page-master-reference
                        page-position="rest"
                        odd-or-even="even"
                        master-reference="Aethiopica-chapter-rest-even"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
            <fo:page-sequence-master
                master-name="Aethiopica-Indexes">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference
                        master-reference="indexes-blank"
                        blank-or-not-blank="blank"/>
                    <fo:conditional-page-master-reference
                        page-position="first"
                        odd-or-even="odd"
                        master-reference="Aethiopica-Indexes-first-odd"/>
                    <fo:conditional-page-master-reference
                        page-position="first"
                        odd-or-even="even"
                        master-reference="Aethiopica-Indexes-first-even"/>
                    <fo:conditional-page-master-reference
                        page-position="rest"
                        odd-or-even="odd"
                        master-reference="Aethiopica-Indexes-rest-odd"/>
                    <fo:conditional-page-master-reference
                        page-position="rest"
                        odd-or-even="even"
                        master-reference="Aethiopica-Indexes-rest-even"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
            <fo:simple-page-master
                
                page-height="297mm"
                page-width="210mm"
                master-name="blank"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
            
            </fo:simple-page-master>
            <fo:simple-page-master
                
                page-height="297mm"
                page-width="210mm"
                master-name="indexes-blank"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
            
            </fo:simple-page-master>
            <fo:simple-page-master
                
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-Indexes-rest-odd"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"
                    column-count="2"
                    column-gap="10mm"/>
                <fo:region-before
                    region-name="rest-region-before-odd"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-odd"
                    extent="12.5pt"/>
            </fo:simple-page-master>
            <fo:simple-page-master
                
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-Indexes-rest-even"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"
                    column-count="2"
                    column-gap="10mm"/>
                <fo:region-before
                    region-name="rest-region-before-even"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-even"
                    extent="12.5pt"/>
            </fo:simple-page-master>
            <fo:simple-page-master
                
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-Indexes-first-even"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"
                    column-count="2"
                    column-gap="10mm"/>
                
                <fo:region-after
                    extent="25pt"/>
            </fo:simple-page-master>
            <fo:simple-page-master
                
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-Indexes-first-odd"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"
                    column-count="2"
                    column-gap="10mm"/>
                <fo:region-before
                    region-name="rest-region-before-first"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-first"
                    extent="12.5pt"/>
            </fo:simple-page-master>
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-first-odd"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-before
                    region-name="rest-region-before-first"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-first"
                    extent="12.5pt"/>
            </fo:simple-page-master>
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-first-even"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-after
                    extent="25pt"/>
            </fo:simple-page-master>
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-rest-odd"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-before
                    region-name="rest-region-before-odd"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-odd"
                    extent="12.5pt"/>
            </fo:simple-page-master>
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-rest-even"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-before
                    region-name="rest-region-before-even"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-even"
                    extent="12.5pt"/>
            </fo:simple-page-master>
        </fo:layout-master-set>
    else
        <fo:layout-master-set>
            <fo:page-sequence-master
                master-name="Aethiopica-master">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference
                        page-position="first"
                        odd-or-even="odd"
                        master-reference="Aethiopica-chapter-first-odd"/>
                    <fo:conditional-page-master-reference
                        page-position="first"
                        odd-or-even="even"
                        master-reference="Aethiopica-chapter-first-even"/>
                    <fo:conditional-page-master-reference
                        page-position="rest"
                        odd-or-even="odd"
                        master-reference="Aethiopica-chapter-rest-odd"/>
                    <fo:conditional-page-master-reference
                        page-position="rest"
                        odd-or-even="even"
                        master-reference="Aethiopica-chapter-rest-even"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
            
            
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-first-odd"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-after
                    region-name="rest-region-after-first"
                    extent="25pt"/>
            </fo:simple-page-master>
            
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-first-even"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-after
                    extent="25pt"/>
            </fo:simple-page-master>
            
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-rest-odd"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-before
                    region-name="rest-region-before-odd"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-odd"
                    extent="12.5pt"/>
            </fo:simple-page-master>
            
            <fo:simple-page-master
                page-height="297mm"
                page-width="210mm"
                master-name="Aethiopica-chapter-rest-even"
                margin-top="45mm"
                margin-bottom="53mm"
                margin-left="45mm"
                margin-right="45mm">
                <fo:region-body
                    margin-top="37.5pt"
                    margin-bottom="37.5pt"/>
                <fo:region-before
                    region-name="rest-region-before-even"
                    extent="25pt"/>
                <fo:region-after
                    region-name="rest-region-after-even"
                    extent="12.5pt"/>
            </fo:simple-page-master>
        
        
        </fo:layout-master-set>
};

declare function fo:catalogue() {
    <fo:block-container>
        {
            for $file in $local:entries
            let $msmainid := number(substring-after($file//tei:msDesc/tei:msIdentifier/tei:idno[not(@xml:lang)]/text(), $local:prefix))
                order by $msmainid
            return
                (fo:msheader($file//tei:msDesc/tei:msIdentifier),
                <fo:block
                    text-align="center"
                    space-before="2mm"
                    space-after="3mm">{fo:tei2fo($file//tei:titleStmt/tei:title[@xml:lang = 'en'])}</fo:block>,
                if ($local:settings//s:structure = 'simple') then
                    fo:SimpleMsStructure($file)
                else
                    fo:ExtendedMsStructure($file)
                )
        }
    </fo:block-container>
};

declare function fo:ExtendedMsStructure($file) {
    fo:msStructure($file//tei:msDesc, 0),
    (:                                if there are parts :)
    if ($file//tei:msPart or $file//tei:msFrag)
    then
        (let $parts := ($file//tei:msPart, $file//tei:msFrag)
        (:  now that the main part is done, do the parts:)
        return
            (for $mP at $p in $parts
            return
                fo:msStructure($mP, $p)))
    else
        (),
    (: fo:condition($file//tei:msDesc/tei:physDesc/tei:objectDesc/tei:supportDesc/tei:condition),                               
fo:history($file//tei:history),:)
    fo:URL(string($file/@xml:id)
    )
};

declare function fo:bibliography($r) {
    <fo:block
        id="bibliography"
        page-break-before="always">{
            (attribute font-weight {'700'},
            attribute margin-bottom {'6.25pt'})
        }Bibliography</fo:block>,
    
    if ($local:bibtype = 'local')
    then
        $local:bibliography//fo:block[starts-with(@id, 'bm_')]
    else
        <fo:block>
            {
                let $mspointers := for $file in $local:entries
                for $ptr in $file//tei:bibl/tei:ptr/@target
                return
                    string($ptr)
                let $allptrs := distinct-values($mspointers)
                let $msID := $r/ancestor::tei:TEI/@xml:id
                let $articleptrs := distinct-values($r//tei:bibl/tei:ptr/@target)
                let $merge := ($allptrs, $articleptrs)
                return
                    let $allrefs := for $ptr in distinct-values($merge)
                        order by $ptr
                    return
                        <fo:block
                            id="{replace($ptr, ':', '_')}"
                            margin-bottom="2pt"
                            start-indent="0.5cm"
                            text-indent="-0.5cm">
                            {fo:Zotero($ptr)}
                            
                            {
                                for $bib in $r//tei:bibl[tei:ptr/@target = $ptr][not(parent::tei:listBibl[@type])]
                                let $bid := string($bib/ancestor::tei:TEI/@xml:id) || generate-id($bib/tei:ptr) || replace($bib/tei:ptr/@target, ':', '_')
                                return
                                    (:            If the place in the code where the citation occurs is not printed in the 
       manuscript record, this will remain empty and show up as a "blank line" in the output. This will be always the case for listBibl elements not printed from included manuscript records, hence the above limitation :)
                                    <fo:basic-link
                                        internal-destination="{$bid}">
                                        <fo:page-number-citation
                                            ref-id="{$bid}"/>
                                    </fo:basic-link>
                            }
                        
                        </fo:block>
                    
                    for $block in $allrefs
                        order by $block
                    return
                        $block
            }
        </fo:block>
};



declare function fo:introduction($r) {
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-master"
        format="i">
        {
            let $tr := fo:authorheader($r//tei:titleStmt/tei:author)
            let $tl := 'Introduction'
            return
                fo:static($tr, $tl)
        }
        <fo:flow
            flow-name="xsl-region-body"
            font-size="10.5pt"
            line-height="12.5pt"
            font-family="Ludolfus"
            text-align="justify"
            hyphenate="true">
            <!-- INTRODUCTION     -->
            <fo:block
                id="introduction">{
                    fo:tei2fo($r/node())
                }</fo:block>
        </fo:flow>
    </fo:page-sequence>

};


declare function fo:bibliographyb($r) {
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-master"
        format="i">
        {
            let $tr := fo:authorheader($r//tei:titleStmt/tei:author)
            let $tl := 'Bibliography'
            return
                fo:static($tr, $tl)
        }
        <fo:flow
            flow-name="xsl-region-body"
            font-size="10.5pt"
            line-height="12.5pt"
            font-family="Ludolfus"
            text-align="justify"
            hyphenate="true">
            <!-- BIBLIOGRAPHY           -->
            {fo:bibliography($r)}
            <!--  break  before Catalogue -->
            <fo:block
                page-break-after="always"/>
        </fo:flow>
    </fo:page-sequence>

};

declare function fo:maincontents($r) {
    <fo:page-sequence
        initial-page-number="auto-odd"
        master-reference="Aethiopica-master">
        {
            let $tr := fo:authorheader($r/tei:teiHeader//tei:titleStmt/tei:author)
            let $tl := 'Catalogue'
            return
                fo:static($tr, $tl)
        }
        <fo:flow
            flow-name="xsl-region-body"
            font-size="10.5pt"
            line-height="12.5pt"
            font-family="Ludolfus"
            text-align="justify"
            hyphenate="true">
            <!-- CATALOGUE     -->
            {fo:catalogue()}
            <!--  break  after Catalogue -->
            <fo:block
                page-break-after="always"/>
        </fo:flow>
    </fo:page-sequence>
};


declare function fo:main() {
    let $r := $local:catalogue
    return
        <fo:root
            xmlns:fo="http://www.w3.org/1999/XSL/Format">
            {
                if ($local:settings//s:format = 'book')
                then
                    fo:layoutmaster('supplements')
                else
                    fo:layoutmaster('article')
            }
            {
            for $settingsValue in $local:settings/s:orderOfParts/element()
                return
                    if ($settingsValue = 'yes') then
                        switch ($settingsValue/name())
                            case 'PDFbookmarks'
                                return
                                    fo:bookmarks()
                            case 'titlePage'
                                return
                                    fo:titlepage()
                            case 'aknowledgments'
                                return
                                    fo:acknow($r/tei:text/tei:front)
                            case 'tableofcontents'
                                return
                                    fo:table-of-contents()
                            case 'listofimages'
                                return
                                    fo:list-of-images()
                            case 'introduction'
                                return
                                    fo:introduction($r/tei:text/tei:body)
                            case 'bibliography'
                                return
                                    fo:bibliographyb($r)
                            case 'catalogue'
                                return
                                    fo:maincontents($r)
                            case 'indexes'
                                return
                                    fo:indexes()
                            case 'images'
                                return
                                    fo:back($r/tei:text/tei:back)
                            default return
                                ()
                else
                    ()
        }
    </fo:root>
};


fo:main()
