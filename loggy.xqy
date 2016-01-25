xquery version "1.0-ml";

module namespace loggy = "http://halistechnology.com/dev/loggy";
declare variable $collection := "loggy-logs";

declare function loggy:date-parts-to-string($year, $month, $day) {
  let $year := xs:string($year)
  let $month := xs:string($month)
  let $month := loggy:pad($month)
  let $day := xs:string($day)
  let $day := loggy:pad($day)
  
  return ($year, $month, $day)
};

declare function loggy:directory($year, $month, $day) {
  fn:string-join(('/loggy/logs', $year, $month, $day, ''), '/')
};


declare function loggy:directory() {
  let $parts := loggy:date-parts()
  return loggy:directory($parts[1], $parts[2], $parts[3])
};

declare function loggy:pad($date-part) {
  if ($date-part < "10") then fn:concat("0", $date-part) 
  else $date-part
};

declare function loggy:date-parts() {
  let $date := xs:date(fn:current-dateTime())
  let $year := xs:string(fn:year-from-date($date))
  let $month := xs:string(fn:month-from-date($date))
  let $day := xs:string(fn:day-from-date($date))
  
  let $month := loggy:pad($month)
  let $day := loggy:pad($day)
  
  return ($year, $month, $day, $date)
};

declare function loggy:query($topics, $year, $month, $day) {
  let $query := (cts:collection-query($collection))
  let $directory := 
    if ($year ne '0' and $month ne '00' and $day ne '00') then loggy:directory($year, $month, $day)
    else ()
  let $query :=
    if ($directory) then ($query, cts:directory-query($directory))
    else $query
  let $query :=
    if ($topics) then
      let $topic-queries :=
        for $topic in $topics
          return cts:element-value-query(xs:QName('topic'), $topic)
      return ($query, $topic-queries)
    else $query
    
  return $query
};

declare function loggy:get-todays-logs() {
  let $directory := loggy:directory()
  return cts:search(/, 
    cts:and-query((
      cts:collection-query($collection),
      cts:directory-query($directory)
    ))
  )
};

declare function loggy:get-days-logs($year, $month, $day) {
  let $date-parts := loggy:date-parts-to-string($year, $month, $day)
  let $year := $date-parts[1]
  let $month := $date-parts[2]
  let $day := $date-parts[3]
  
  let $directory := loggy:directory($year, $month, $day)
  return cts:search(/, 
    cts:and-query((
      cts:collection-query($collection),
      cts:directory-query($directory)
    ))
  )
};

declare function loggy:log($topics, $messages) {
  let $directory := loggy:directory()
  let $uri := fn:concat($directory, sem:uuid-string(), '.xml')
  let $collections := ($collection)
  let $messages :=
    <messages>{
      for $message in $messages
        return <message>{ $message }</message>
    }
    </messages>
  let $topics :=
  <topics>{
      for $topic in $topics
        return <topic>{ $topic }</topic>
    }
  </topics>
  let $doc := 
    <log>
      <created_on>{ fn:current-dateTime() }</created_on>
      { $topics }
      { $messages }
    </log>
  let $_ := xdmp:document-insert($uri, $doc, (), $collections, 0, ())
  
  return (
    $uri,
    $doc,
    $collections
  )
};

declare function loggy:search($topics, $year, $month, $day) {
  let $date-parts := loggy:date-parts-to-string($year, $month, $day)
  let $year := $date-parts[1]
  let $month := $date-parts[2]
  let $day := $date-parts[3]
  
  let $query := loggy:query($topics, $year, $month, $day)
  return cts:search(/, cts:and-query($query))
};

declare function loggy:clear-all() {
  xdmp:collection-delete($collection)
};

declare function loggy:clear-logs($logs) {
  for $log in $logs
    let $uri := fn:document-uri($log)
    let $_ := xdmp:document-delete($uri)
    return $uri
};

declare function loggy:clear-day($year, $month, $day) {
  let $logs := loggy:get-days-logs($year, $month, $day)
  return loggy:clear-logs($logs)
};

declare function loggy:clear-today() {
  let $logs := loggy:get-todays-logs()
  return loggy:clear-logs($logs)
};
