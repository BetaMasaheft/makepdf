xquery version "3.1";
(:~
 : This module based on the one provided in the shakespare example app
 : produces a xslfo temporary object and passes it to FOP to produce a PDF
 : @author Pietro Liuzzo 
 :)

declare namespace http = "http://expath.org/ns/http-client";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace fo = "http://www.w3.org/1999/XSL/Format";
declare namespace xslfo = "http://exist-db.org/xquery/xslfo";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace file = "http://exist-db.org/xquery/file";
declare namespace functx = "http://www.functx.com";
declare namespace s = "local.print";

declare variable $local:catalogue := doc('driver.xml')/tei:teiCorpus;
declare variable $local:mss := $local:catalogue//tei:TEI;
declare variable $local:settings := doc('settings.xml')/s:settings;
declare variable $local:Z := if($local:settings/s:zotero/text()) then $local:settings/s:zotero/text() else 'https://api.zotero.org/groups/358366/items' ;
declare variable $local:zstyle := if($local:settings/s:zstyle/text()) then $local:settings/s:zstyle/text() else 'hiob-ludolf-centre-for-ethiopian-studies' ;
declare variable $local:bibexceptions := tokenize($local:settings/s:bibSettings/s:bibliographyexceptions, ',');
declare variable $local:bibintegration := tokenize($local:settings/s:bibSettings/s:bibliographyintegration, ',');

declare function local:zoteroCit($ZoteroUniqueBMtag as xs:string){
let $url := concat($local:Z,'?tag=', $ZoteroUniqueBMtag, '&amp;include=citation&amp;locale=en-GB&amp;style=',$local:zstyle)

let $parseedZoteroApiResponse :=json-doc($url)

let $string:= '<inline xmlns="http://www.w3.org/1999/XSL/Format">' || replace($parseedZoteroApiResponse?1?citation, '&lt;span&gt;', '') => replace('&lt;/span&gt;', '') => replace('&lt;/i&gt;', '</inline>') =>replace('&lt;i&gt;', '<inline font-style="italic">')  || '</inline>'

return 
parse-xml($string)
};

declare function local:sortingkey($input){ string-join($input)
             => replace('ʾ', '')
             =>replace('ʿ','')
             =>replace('ʿ','')
             =>replace('\s','')
             =>translate('ƎḤḪŚṢṣḫḥǝʷāṖĀ','EHHSSshhewaPA') 
             => lower-case()};

declare function local:tei2fo($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(html:a)
                return
                    <fo:basic-link
                        external-destination="{string($node/@href)}">{local:tei2fo($node/text())}</fo:basic-link>
            case element(html:i)
                return
                    <fo:inline
                        font-style="italic">{local:tei2fo($node/node())}</fo:inline>
            case element(html:sup)
                return
                <fo:inline
                vertical-align="sup" padding-left="-3pt" baseline-shift="5pt" font-size="8pt"
                >{local:tei2fo($node/node())}</fo:inline>
            case element(html:span)
                return
                    <fo:inline>{if($node/@style[.="font-style:normal;"]) then attribute font-style {'normal'} else ()}{$node/text()}</fo:inline>
                    case element()
        return
            local:tei2fo($node/node())
    default
        return
            $node
            };
            

declare function local:Zotero($ZoteroUniqueBMtag as xs:string) {
    let $xml-url := concat($local:Z,'?tag=', $ZoteroUniqueBMtag, '&amp;format=bib&amp;locale=en-GB&amp;style=',$local:zstyle,'&amp;linkwrap=1')
   let $request := <http:request 
        http-version="1.1" href="{xs:anyURI($xml-url)}" method="GET"/>
    let $data := doc($xml-url)
    let $frag := <html xmlns="http://www.w3.org/1999/xhtml">{$data//*:div[@class = 'csl-entry']}</html>
    let $datawithlink := local:tei2fo($frag/node())
    return
        $datawithlink
        };
      
      <fo:block>   {
                   let $mspointers := for $file in $local:mss
                                for $ptr in $file//tei:bibl/tei:ptr/@target return
                                string($ptr)
                   let $allptrs := distinct-values($mspointers) 
                 let $merge := ($allptrs, $local:bibintegration)
                 let $biblExceptions := $local:bibexceptions
                 return
                 let $allrefs := for $ptr in distinct-values($merge)
                    order by $ptr
                    return
                    if($ptr=$biblExceptions) then (
                     <fo:block id="cit_{replace($ptr, ':', '_')}">{local:zoteroCit($ptr)}</fo:block>
                    ) else 
                 (   <fo:block id="{replace($ptr, ':', '_')}" margin-bottom="2pt" start-indent="0.5cm" text-indent="-0.5cm" >
                    {local:Zotero($ptr)}                     
         
                  
                </fo:block>,
                           <fo:block id="cit_{replace($ptr, ':', '_')}">{local:zoteroCit($ptr)}</fo:block>)
                for $block in $allrefs
                let $sort := local:sortingkey(string-join($block//text()))
                order by $sort
                return
                $block}
                </fo:block>
        
