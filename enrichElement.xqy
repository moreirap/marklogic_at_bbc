(:  __________________________________________________________
 ::  
 ::  Enrich an entity
 :: __________________________________________________________
  :)

xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "/CustomModules/commons-master/memupdate/in-mem-update.xqy";

declare default element namespace "http://bbc.ww/common/content/v1.0";
declare namespace ch="http://bbc.ww/common/content/v1.0";
declare option xdmp:output "indent = yes";
declare option xdmp:output "indent-untyped = yes";

declare function local:passthru($x as node()) as node()* {
    (: for $z in $x/node() return local:dispatch($z,false):)
    $x
};

declare function local:enrichEpisode ($x as node(), $deep as xs:boolean) {
    local:dispatch($x/ch:ContentVersions,$deep)
                                
};

declare function local:enrichSeriesConfig ($x as node(), $deep as xs:boolean) {
    let $scv_s := local:dispatch($x/ch:SeriesConfigVersions,$deep)
    let $ep_s := local:dispatch($scv_s/ch:SeriesConfig/ch:Episodes,$deep)
    return $ep_s
};


declare function local:enrichTitle ($x as node(), $deep as xs:boolean) {
    let $sc_s := local:dispatch($x/ch:SeriesConfigs,$deep)
    let $tv_s := local:dispatch($sc_s/ch:Title/ch:TitleVersions,$deep)
    return $tv_s 
};

declare function local:enrichTitleGroup ($x as node(), $deep as xs:boolean) {
    local:dispatch($x/ch:Titles,$deep)
};

declare function local:enrichArrayNode ($x as node(), $childNodes as node()*, $deep as xs:boolean) {
    let $nodeName := fn:name($x) 
    return mem:node-replace(
            $x,
            element {xs:QName($nodeName)} {
                element {xs:QName(fn:string-join(("ArrayOf", $nodeName),""))} {
                    for $doc in $childNodes
                    return local:dispatch ($doc, $deep)  
                }
            }
        )
};


declare function local:dispatch($x as node(),$deep as xs:boolean) as node()*
{
    let $parentNodeIdentifier := $x/../ch:Identifier/text()
    return if (not($deep)) then $x
    else
        typeswitch ($x)
            (: Single top level Nodes :)
            case element (ch:TitleGroup) 
                return local:enrichTitleGroup($x, $deep)
            case element (ch:Title) 
                return local:enrichTitle($x, $deep)    
            case element (ch:SeriesConfig) 
                return local:enrichSeriesConfig($x, $deep)
            case element (ch:Episode) 
                return local:enrichEpisode($x, $deep)                        
            (: Version top level Nodes - passthrough:)
            case element (ch:TitleVersion) 
                return $x
            case element (ch:SeriesConfigVersion) 
                return $x
            case element (ch:ContentVersion) 
                return $x
            (: Multiple array Nodes:)
            case element (ch:Titles) 
                return local:enrichArrayNode ($x, //ch:Title[child::ch:TitleGroup/ch:Identifier = $parentNodeIdentifier], $deep)
            case element (ch:TitleVersions) 
                return local:enrichArrayNode ($x, //ch:TitleVersion[child::ch:Title/ch:Identifier = $parentNodeIdentifier], $deep)
            case element (ch:SeriesConfigs)
                return local:enrichArrayNode ($x, //ch:SeriesConfig[child::ch:Title/ch:Identifier = $parentNodeIdentifier], $deep)
            case element (ch:SeriesConfigVersions) 
                return local:enrichArrayNode ($x, //ch:SeriesConfigVersion[child::ch:SeriesConfig/ch:Identifier = $parentNodeIdentifier], $deep)
            case element (ch:Episodes) 
                return local:enrichArrayNode ($x, //ch:Episode[child::ch:SeriesConfig/ch:Identifier = $parentNodeIdentifier], $deep)
            case element (ch:ContentVersions) 
                return local:enrichArrayNode ($x, //ch:ContentVersion[child::ch:Episode/ch:Identifier = $parentNodeIdentifier], $deep)         
            (: Multiple array Nodes:)
            default return <ERROR>{local:passthru($x)}</ERROR>
};

let $request :=
    <rest:request uri="^/endpoint/(.+)/(\d+)$" endpoint="/endpoint.xqy">
      <rest:uri-param name="Identifier">$1</rest:uri-param>
      <rest:uri-param name="Deep" as="boolean" optional="true">$2</rest:uri-param>
    </rest:request>
 
let $map  := rest:process-request($request) 
let $identifier := map:get($map, "Identifier")
let $deep := fn:boolean(map:get($map, "Deep"))

return local:dispatch(/*[ch:Identifier = $identifier][1] , $deep )