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
            (: Multiple array Nodes:)
            default return <ERROR>{$x}</ERROR>
};

let $request :=
    <rest:request uri="^/endpoint/(.+)/(\d+)$" endpoint="/endpoint.xqy">
      <rest:uri-param name="NodeName">$1</rest:uri-param>
      <rest:uri-param name="Identifier">$2</rest:uri-param>
    </rest:request>
 
let $map  := rest:process-request($request) 
let $identifier := map:get($map, "Identifier")
let $nodeName := map:get($map, "NodeName")


return root(//*[name() = $nodeName and ./ch:Code = $identifier])