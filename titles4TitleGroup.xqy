(:  __________________________________________________________
 ::  
 ::  Retrieves all titles of a TitleGroup
 :: __________________________________________________________
  :)

xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "/CustomModules/commons-master/memupdate/in-mem-update.xqy";

declare default element namespace "http://bbc.ww/common/content/v1.0";
declare namespace ch="http://bbc.ww/common/content/v1.0";
declare option xdmp:output "indent = yes";
declare option xdmp:output "indent-untyped = yes";

declare function local:listTitles ($identifier as xs:string, $deep as xs:boolean) { 
    for $doc in //ch:Title[child::ch:TitleGroup/ch:Identifier = $identifier]
    return  if ($deep) 
            then mem:node-replace($doc/ch:TitleGroup, //ch:TitleGroup[not(ancestor::ch:Title)][ch:Identifier = $identifier])
            else $doc
};

declare function local:listTitleVersions($identifier as xs:string, $deep as xs:boolean) {
    for $doc in //ch:TitleVersions[child::ch:Title/ch:Identifier = $identifier]
    return if ($deep) 
    then mem:node-replace($doc/ch:TitleGroup, //ch:TitleGroup[not(ancestor::ch:Title)][ch:Identifier = $identifier])
    else $doc
};

let $request :=
    <rest:request uri="^/endpoint/(.+)/(\d+)$" endpoint="/endpoint.xqy">
      <rest:uri-param name="Identifier">$1</rest:uri-param>
      <rest:uri-param name="Deep" as="boolean" optional="true">$2</rest:uri-param>
    </rest:request>
 
let $map  := rest:process-request($request) 
let $identifier := map:get($map, "Identifier")
let $deep := fn:boolean(map:get($map, "Deep"))

return element {xs:QName("Titles")} {
        attribute myatt { $identifier },
        attribute myatt2 { $deep },
        element {xs:QName("ArrayOfTitles")} {
        if ($identifier != '') then 
            local:listTitles($identifier,$deep)
        else ()
        } 
    }

